# Why?
- Bibliography library extracted from Endnote has asterisk in some of their tags.
- Zotero does not have a mass editing tool for tags and it drives some people crazy.
    - https://forums.zotero.org/discussion/35051/better-way-to-batch-edit-tags
    - https://forums.zotero.org/discussion/12678/deleting-a-large-number-of-tags-efficiently
- This piece of query will allow you to remove the asterisks from the tags in your library and merge them.

# How?
You will require an `sqlite` application to run this query.

I used vscode with `SQLite` extension (v0.14.1) and it worked fine.

Run the following query on the `zotero.sqlite` file in your Zotero data folder:

https://github.com/loneguardian/zotero/blob/main/sql-remove-asterisk-from-tags/remove-asterisk-from-tags.sql