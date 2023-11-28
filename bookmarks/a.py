
"""
Author:  Ian Fisher
"""

import sys
import pprint
import sqlite3
from collections import namedtuple


# The `add_date` and `last_modified` fields are integer timestamps, which can be
# converted to human-readable strings by the time.ctime standard library functions.
# The `tags` field is a list of strings; all other fields are just strings.
Bookmark = namedtuple(
    "Bookmark", ["title", "url", "add_date", "last_modified", "tags", "parent"]
)

conn = sqlite3.connect(sys.argv[1])
cursor = conn.cursor()
cursor.execute("""
    SELECT
        moz_places.id,
        moz_bookmarks.title,
        moz_places.url,
        moz_bookmarks.dateAdded,
        moz_bookmarks.lastModified,
        moz_bookmarks.parent
    FROM
        moz_bookmarks
    LEFT JOIN
        -- The actual URLs are stored in a separate moz_places table, which is pointed
        -- at by the moz_bookmarks.fk field.
        moz_places
    ON
        moz_bookmarks.fk = moz_places.id
    WHERE
        -- Type 1 is for bookmarks; type 2 is for folders and tags.
        moz_bookmarks.type = 1
    AND
        moz_bookmarks.title IS NOT NULL
    ;
""")
rows = cursor.fetchall()

# A loop to get the tags for each bookmark.
bookmarks = []
for place_id, title, url, date_added, last_modified, parent_id in rows:
    # A tag relationship is established by row in the moz_bookmarks table with NULL
    # title where parent is the tag ID (in moz_bookmarks) and fk is the URL.
    cursor.execute("""
        SELECT
            A.title
        FROM
            moz_bookmarks A, moz_bookmarks B
        WHERE
            A.id <> B.id
        AND
            B.parent = A.id
        AND
            B.title IS NULL
        AND
            B.fk = ?;
    """, (place_id,))
    tag_names = [r[0] for r in cursor.fetchall()]
    cursor.execute("SELECT title FROM moz_bookmarks WHERE id=?", (parent_id,))
    parent = cursor.fetchone()[0]
    bookmarks.append(Bookmark(title, url, date_added, last_modified, tag_names, parent))

conn.close()


# Print out the bookmarks, or do whatever else you'd like with them.
pprint.pprint(bookmarks)
print()
print(len(bookmarks), "bookmark(s) total.")
