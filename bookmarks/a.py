import sqlite3
from html import escape

import sys
DB_PATH = sys.argv[1] #"places.sqlite"
OUTPUT = sys.argv[2]  #"bookmarks.html"
counter=0

def load(cur):
    cur.execute("""
        SELECT
            b.id,
            b.parent,
            b.type,
            b.position,
            b.title,
            b.dateAdded,
            p.url
        FROM moz_bookmarks b
        LEFT JOIN moz_places p ON b.fk = p.id
        WHERE b.type IN (1,2,3)
    """)

    nodes = {}
    children = {}

    for r in cur.fetchall():
        node = {
            "id": r[0],
            "parent": r[1],
            "type": r[2],
            "pos": r[3],
            "title": r[4] or "",
            "date": (r[5] or 0) // 1_000_000,
            "url": r[6],
        }
        nodes[node["id"]] = node
        children.setdefault(node["parent"], []).append(node)

    for lst in children.values():
        lst.sort(key=lambda x: x["pos"])

    return nodes, children

def emit(f, node, children, indent):
    if node["type"] == 2:  # folder
        f.write(f'{indent}<DT><H3 ADD_DATE="{node["date"]}">{escape(node["title"])}</H3>\n')
        f.write(f"{indent}<DL><p>\n")
        for c in children.get(node["id"], []):
            emit(f, c, children, indent + "    ")
        f.write(f"{indent}</DL><p>\n")

    elif node["type"] == 1 and node["url"]:
        global counter
        counter+=1
        f.write(
            f'{indent}<DT><A HREF="{escape(node["url"])}" '
            f'ADD_DATE="{node["date"]}">{escape(node["title"])}</A>\n'
        )

    elif node["type"] == 3:
        f.write(f"{indent}<DT><HR>\n")

def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    nodes, children = load(cur)

    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write("""<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
""")

        # 🔑 ONLY start from parent=1
        for n in children.get(1, []):
            emit(f, n, children, "    ")

        f.write("</DL>\n")

    conn.close()
    print("Exported:", OUTPUT)
    print(str(counter), "bookmarks")

main()
