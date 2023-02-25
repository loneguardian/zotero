BEGIN TRANSACTION;

-- list of tags with asterisk
SELECT *
FROM tags
WHERE name LIKE '%*%'
ORDER BY name;

-- list of duplicate tags.name when asterisk is removed
-- tagNameDuplicate
CREATE TEMP TABLE temp_duplicateFixedNames
(
    fixed_name TEXT
);

INSERT INTO temp_duplicateFixedNames
SELECT REPLACE(tags.name, '*', '') AS fixed_name
FROM tags
GROUP BY fixed_name
HAVING COUNT() > 1;

SELECT * FROM temp_duplicateFixedNames;

-- # Select a tagID as a target for merge
--
-- select list from tags where fixed_name can duplicate
CREATE TEMP TABLE temp_tags
(
    tagID INTEGER,
    name TEXT,
    fixed_name TEXT
);

INSERT INTO temp_tags
SELECT
    tagID,
    name,
    REPLACE(tags.name, '*', '') AS fixed_name
FROM tags
WHERE fixed_name IN (
    SELECT fixed_name FROM temp_duplicateFixedNames
)
ORDER BY fixed_name;

SELECT * FROM temp_tags;

-- choose one tagID per fixed_name from temp_tags as the target of merge
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
        FROM temp_tags t2
        WHERE t2.fixed_name = t1.fixed_name
        LIMIT 1
    ) AS tagID
FROM temp_duplicateFixedNames AS t1;

SELECT * FROM temp_mergeTarget;

-- # Create lookup table for merge
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
INNER JOIN temp_tags AS t ON (m.fixed_name = t.fixed_name);

SELECT * FROM temp_lookup;

-- # ItemTags table duplicate handler
--
-- this handler delete tags from itemID if merging causes duplication for
-- (itemID, to_tagID) unique constraint
-- did not happen in my case handled and tested with one single test case
-- by tagging an item with the same text tags having different asterisk positions
--
-- btw rowid trick is amazing for sqlite to simulate DELETE JOIN operation
-- https://stackoverflow.com/questions/24511153/how-delete-table-inner-join-with-other-table-in-sqlite

-- debug
-- select rows from itemTags where it
-- can cause duplicate after a transformation, these rows can be deleted
-- SELECT
--     i.itemID,
--     t.from_tagID,
--     t.to_tagID
-- FROM itemTags AS i
-- INNER JOIN (
--     SELECT
--         t.itemID,
--         l.from_tagID,
--         l.to_tagID
--     FROM temp_lookup AS l
--     INNER JOIN (
--         SELECT
--             i.itemID,
--             l.to_tagID
--         FROM itemTags AS i
--         INNER JOIN temp_lookup AS l ON l.from_tagID = i.tagID
--         GROUP BY itemID, to_tagID
--         HAVING COUNT() > 1
--     ) AS t ON l.to_tagID = t.to_tagID
--     WHERE l.from_tagID <> l.to_tagID
-- ) AS t ON (i.itemID = t.itemID AND i.tagID = t.from_tagID);

DELETE FROM itemTags
WHERE rowid IN (
    SELECT
        i.rowid
    FROM itemTags AS i
    INNER JOIN (
        SELECT
            t1.itemID,
            l.from_tagID
        FROM temp_lookup AS l
        INNER JOIN (
            SELECT
                itemID,
                to_tagID
            FROM itemTags AS i1
            INNER JOIN temp_lookup AS l ON l.from_tagID = i1.tagID
            GROUP BY itemID, to_tagID
            HAVING COUNT() > 1
        ) AS t1 ON l.to_tagID = t1.to_tagID
        WHERE l.from_tagID <> l.to_tagID
    ) AS t2 ON (i.itemID = t2.itemID AND i.tagID = t2.from_tagID)
);

-- merge tags by updating tagID in itemTags
UPDATE itemTags
SET tagID = (
    SELECT l.to_tagID
    FROM temp_lookup AS l
    WHERE l.from_tagID = tagID
)
WHERE rowid IN (
    SELECT i.rowid
    FROM itemTags AS i
    INNER JOIN temp_lookup AS l ON i.tagID = l.from_tagID
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

-- rename all asterisk-containing tags
UPDATE tags
SET name = REPLACE(tags.name, '*', '')
WHERE name LIKE '%*%';

COMMIT;

-- post-op check for asterisk tags
SELECT *
FROM tags
WHERE name LIKE '%*%'
ORDER BY name;

-- TODO: remove/migrate asterisk tags from coloured tags