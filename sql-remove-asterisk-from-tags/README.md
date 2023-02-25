# Zotero - SQL Query - remove asterisks from tags
## Why?
- Bibliography library imported from Endnote has asterisks in some of their tags. I am not sure what function those asterisks serve.
- For some users, it is an annoyance. Zotero does not have a mass editing tool for tags to tackle this problem[^1].
- This SQL query will allow you to remove the asterisks from the tags in your library.

## Requirements
You will need an `sqlite` application to run this query. I have written and run this query in [VSCode](https://code.visualstudio.com/) with [SQLite extension (v0.14.1)](https://marketplace.visualstudio.com/items?itemName=alexcvzz.vscode-sqlite) on a Zotero 6.0.22 database, and it worked fine.

## Instructions
Locate the `zotero.sqlite` file in your Zotero data folder.

Make a backup of that file.

**Always backup the database file before any SQL operation**; there is no undo button once a query has been executed.

Run [this query](remove-asterisk-from-tags.sql) on the `zotero.sqlite` file.

## Questions or feedback
Visit my Zotero repo's [issue tracker](https://github.com/loneguardian/zotero/issues) or [discussion board](https://github.com/loneguardian/zotero/discussions).

[^1]: [Zotero forum thread 1](https://forums.zotero.org/discussion/35051/better-way-to-batch-edit-tags)
  [Zotero forum thread 2](https://forums.zotero.org/discussion/12678/deleting-a-large-number-of-tags-efficiently)