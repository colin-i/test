#!/usr/bin/env python3
"""Extract feature attributes from ArcGIS f=pbf responses in a .har file and write them to a CSV.
Usage: python3 har_pbf_to_csv.py file.har output.csv [layer_number] [sort_column]
Default layer is 0; default sort column is categorie_drum (column E).
"""
import sys, json, base64, csv, struct, os

# Only rows whose categorie_drum is one of these are kept (set to an empty list to keep everything)
KEEP_CATEGORIES = [
    "AUTOSTRAZI IN EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
    "AUTOSTRAZI IN LICITATIE FAZA EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
    "AUTOSTRAZI IN PREGATIRE FAZA PROIECTARE (SF, PT)",
    "DRUM EXPRES IN LICITATIE FAZA EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
    "DRUMURI DE MARE VITEZA IN FAZA PROIECTARE (SF, PT)",
    "DRUMURI EXPRES IN PREGATIRE FAZA PROIECTARE (SF, PT)",
    "DRUMURI EXPRES PROIECTE IN EXECUTIE",
]

def varint(b, i):
    # Read a base-128 varint starting at position i; return (value, next position)
    r = s = 0
    while True:
        c = b[i]; i += 1
        r |= (c & 0x7f) << s
        if not c & 0x80: return r, i
        s += 7

def parse(b):
    """Decode one protobuf message into {field_number: [values]}.
    Length-delimited fields stay as bytes, varints become ints, fixed-width fields stay as bytes."""
    out, i = {}, 0
    while i < len(b):
        k, i = varint(b, i)
        f, w = k >> 3, k & 7
        if w == 0: v, i = varint(b, i)
        elif w == 2:
            n, i = varint(b, i); v = b[i:i+n]; i += n
        elif w == 1: v = b[i:i+8]; i += 8
        elif w == 5: v = b[i:i+4]; i += 4
        else: raise ValueError("unsupported wire type %d" % w)
        out.setdefault(f, []).append(v)
    return out

def zz(n):
    # Zigzag decoding for sint32 / sint64
    return (n >> 1) ^ -(n & 1)

def value(b):
    # Decode an Esri "Value" message (a oneof: string, float, double, ints, bool)
    d = parse(b)
    if 1 in d: return d[1][0].decode('utf8', 'replace')
    if 2 in d: return struct.unpack('<f', d[2][0])[0]
    if 3 in d: return struct.unpack('<d', d[3][0])[0]
    if 4 in d: return zz(d[4][0])          # sint32
    if 5 in d: return d[5][0]              # uint32
    if 6 in d: return d[6][0]              # int64
    if 7 in d: return d[7][0]              # uint64
    if 8 in d: return zz(d[8][0])          # sint64
    if 9 in d: return bool(d[9][0])
    return ""

def main():
    har, outp = sys.argv[1], sys.argv[2]
    layer = sys.argv[3] if len(sys.argv) > 3 else "0"
    sort_col = sys.argv[4] if len(sys.argv) > 4 else "categorie_drum"
    marker = "/FeatureServer/%s/query" % layer
    merged, cols = {}, []
    for e in json.load(open(har))['log']['entries']:
        url = e['request']['url']
        # Only feature queries for the chosen layer that were requested as pbf
        if marker not in url or 'f=pbf' not in url: continue
        c = e['response']['content']
        if not c.get('text'): continue
        raw = base64.b64decode(c['text']) if c.get('encoding') == 'base64' else c['text'].encode('latin1')
        try:
            # FeatureCollection -> QueryResult -> FeatureResult
            fr = parse(parse(parse(raw)[2][0])[1][0])
        except Exception as ex:
            print("skipping", url[-60:], ex); continue
        # Field names of this response (different queries may request different outFields)
        names = [parse(f)[1][0].decode() for f in fr.get(13, [])]
        if not names: continue
        cols += [n for n in names if n not in cols]
        oid = fr.get(1, [b'OBJECTID'])[0].decode()
        for fb in fr.get(15, []):
            vals = [value(v) for v in parse(fb).get(1, [])]
            r = dict(zip(names, vals))
            # Merge rows that appear in several responses, keyed by the object id
            key = r.get(oid, id(fb))
            merged.setdefault(key, {}).update({k: v for k, v in r.items() if v != ""})
        if fr.get(9, [0])[0]: print("WARNING: exceededTransferLimit in", url[-60:])
    rows = list(merged.values())
    # Keep only the categories of interest
    if os.environ.get('no_categories') is None:
        rows = [r for r in rows if r.get("categorie_drum") in KEEP_CATEGORIES]
    # Sort by the chosen column; empty values go last, ties keep their original order
    rows.sort(key=lambda r: (str(r.get(sort_col, "")) == "", str(r.get(sort_col, ""))))
    with open(outp, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
        w.writeheader(); w.writerows(rows)
    print(len(rows), "unique rows, sorted by", sort_col, "->", outp)

main()
