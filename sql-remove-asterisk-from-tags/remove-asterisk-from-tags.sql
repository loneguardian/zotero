BEGIN TRANSACTION;

-- list of tags with asterisk (A)
SELECT *
FROM tags
WHERE name LIKE '%*%'
ORDER BY name;

-- n(A)
SELECT COUNT(*) AS [n(A)]
FROM tags
WHERE name LIKE '%*%';

-- list of duplicate tags.name when asterisk is removed (B)
SELECT REPLACE(tags.name, '*', '') AS fixed_name
FROM tags
GROUP BY fixed_name
HAVING COUNT() > 1;

-- # Rename non-duplicating asterisk tags
-- create list of non-duplicating asterisk tags
-- nonDupe = (A and (not B))
CREATE TEMP TABLE temp_nonDupe
(
    tagID INTEGER
);

INSERT INTO temp_nonDupe
SELECT t1.tagID
FROM (
    SELECT
        tagID,
        REPLACE(tags.name, '*', '') AS fixed_name
    FROM tags
    WHERE name LIKE '%*%'
) AS t1
LEFT JOIN (
    SELECT REPLACE(tags.name, '*', '') AS fixed_name
    FROM tags
    GROUP BY fixed_name
    HAVING COUNT() > 1
) AS t2 ON t1.fixed_name = t2.fixed_name
WHERE t2.fixed_name IS NULL;

SELECT tagID FROM temp_nonDupe;

-- n(nonDupe)
SELECT COUNT(*) AS [n(nonDupe)]
FROM temp_nonDupe;

-- update tags
UPDATE tags
SET name = REPLACE(tags.name, '*', '')
WHERE tagID IN (SELECT tagID FROM temp_nonDupe);

SELECT * FROM tags;

-- # Merge duplicating asterisks
-- Create a list for duplicate asterisk tags
-- select list of duplicating asterisk tags
-- dupe = (A and (not nonDupe))
CREATE TEMP TABLE temp_dupe
(
    tagID INTEGER,
    name TEXT,
    fixed_name TEXT
);

INSERT INTO temp_dupe
SELECT
    A.tagID,
    name,
    REPLACE(A.name, '*', '') AS fixed_name
FROM (
    SELECT *
    FROM tags
    WHERE name LIKE '%*%'
    ORDER BY name
) AS A LEFT JOIN temp_nonDupe AS t ON A.tagID = t.tagID
WHERE t.tagID IS NULL;

SELECT * from temp_dupe;

-- ## TALLY CHECK:
-- n(dupe) = n(A) - n(nonDupe)
SELECT COUNT(*) AS [n(dupe)]
FROM temp_dupe;

-- # Select a target tagID for merge
-- select list from tags where fixed_name can duplicate
CREATE TEMP TABLE temp_tags
(
    tagID INTEGER,
    name TEXT,
    fixed_name TEXT
);

INSERT INTO temp_tags
SELECT
    *,
    REPLACE(tags.name, '*', '') AS fixed_name
FROM tags
WHERE fixed_name IN (
    SELECT fixed_name
    FROM temp_dupe AS t
    GROUP BY t.fixed_name
)
ORDER BY fixed_name;

SELECT * FROM temp_tags;

-- choose one tagID as target of merge
-- mergeTarget
CREATE TEMP TABLE temp_mergeTarget
(
    fixed_name INTEGER,
    tagID INTEGER
);

INSERT INTO temp_mergeTarget
SELECT
    t1.fixed_name,
    (
        SELECT tagID
        FROM temp_tags t
        WHERE t.fixed_name = t1.fixed_name
        LIMIT 1
    ) AS tagID
FROM (SELECT DISTINCT fixed_name from temp_dupe) AS t1;

SELECT * FROM temp_mergeTarget;

-- create lookup table for merge
CREATE TEMP TABLE temp_lookup
(
    from_tagID INTEGER,
    to_tagID INTEGER,
    name TEXT,
    fixed_name TEXT
);

INSERT INTO temp_lookup
SELECT
    t.tagID AS from_tagID,
    m.tagID AS to_tagID,
    t.name,
    t.fixed_name
FROM temp_mergeTarget AS m
INNER JOIN temp_tags AS t ON m.fixed_name = t.fixed_name;

SELECT * FROM temp_lookup;

-- delete tags from itemID if merging causes duplication for (itemID, to_tagID)
-- due to unique constraint for (itemID, tagID) pair
-- did not happen in my case handled and tested with one single test case
-- by tagging an item with the same text tags having different asterisk positions
--
-- rowid trick is amazing for in sqlite for DELETE JOIN operation
-- https://stackoverflow.com/questions/24511153/how-delete-table-inner-join-with-other-table-in-sqlite
DELETE FROM itemTags
WHERE rowid IN (
    SELECT i.rowid
    FROM itemTags AS i
    INNER JOIN (
        SELECT
            t.itemID,
            l.from_tagID AS tagID
        FROM temp_lookup AS l
        INNER JOIN (
            SELECT
                i.itemID,
                l.to_tagID
            FROM itemTags AS i
            INNER JOIN temp_lookup AS l ON l.from_tagID = i.tagID
            GROUP BY itemID, to_tagID
            HAVING COUNT() > 1
        ) AS t ON l.to_tagID = t.to_tagID
        WHERE l.from_tagID <> l.to_tagID
    ) AS t ON (i.itemID = t.itemID AND i.tagID = t.tagID)
);

-- debug
-- SELECT i.rowid, *
-- FROM itemTags AS i
-- INNER JOIN temp_lookup AS l ON i.tagID = l.from_tagID
-- WHERE l.from_tagID <> l.to_tagID;

-- merge tags by updating tagID in itemTags
UPDATE itemTags
SET tagID = (
    SELECT to_tagID
    FROM temp_lookup AS l
    WHERE l.from_tagID = tagID
)
WHERE rowid IN (
    SELECT i.rowid
    FROM itemTags AS i
    INNER JOIN temp_lookup AS l ON i.tagID = l.from_tagID
    WHERE l.from_tagID <> l.to_tagID
);

-- debug
-- SELECT *
-- FROM tags AS t
-- LEFT JOIN itemTags AS i ON t.tagID = i.tagID
-- WHERE i.tagID IS NULL;

-- delete orphan tags
DELETE FROM tags
WHERE tagID IN (
    SELECT t.tagID
    FROM tags AS t
    LEFT JOIN itemTags AS i ON t.tagID = i.tagID
    WHERE i.tagID IS NULL
);

-- rename all asterisk tags
UPDATE tags
SET name = REPLACE(tags.name, '*', '')
WHERE name LIKE '%*%';

SELECT * FROM tags;

COMMIT;

-- post-op check for asterisk tags
SELECT *
FROM tags
WHERE name LIKE '%*%'
ORDER BY name;