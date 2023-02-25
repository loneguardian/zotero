# Why?
- Bibliography library extracted from Endnote has asterisk in some of their tags.
- Zotero does not have a mass editing tool for tags to solve this problem[^1].
- This query snippet will allow you to remove the asterisks from the tags in your library.

# How?
You will require an `sqlite` application to run this query. I have written and tested this query in [VSCode](https://code.visualstudio.com/) with [SQLite extension (v0.14.1)](https://marketplace.visualstudio.com/items?itemName=alexcvzz.vscode-sqlite) on a Zotero 6.0.22 database and it worked fine.

Locate the `zotero.sqlite` file in your Zotero data folder.

Make a backup of that file.

**Always backup the database file before any SQL operation**, there is no redo button once a query has been executed.

Run [this query](remove-asterisk-from-tags.sql) on the `zotero.sqlite` file.

# Questions or feedback
Visit my Zotero repo's [issue tracker](https://github.com/loneguardian/zotero/issues) or [discussion board](https://github.com/loneguardian/zotero/discussions).

[^1]: [Zotero forum thread 1](https://forums.zotero.org/discussion/35051/better-way-to-batch-edit-tags)
  [Zotero forum thread 2](https://forums.zotero.org/discussion/12678/deleting-a-large-number-of-tags-efficiently)