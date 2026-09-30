#!/usr/bin/env python3
"""Extrage rândurile (atributele) din răspunsurile ArcGIS f=pbf dintr-un fișier .har și le scrie în CSV.
Utilizare: python3 har_pbf_to_csv.py fisier.har iesire.csv [numar_strat]
"""
import sys, json, base64, csv, struct

def varint(b, i):
    r = s = 0
    while True:
        c = b[i]; i += 1
        r |= (c & 0x7f) << s
        if not c & 0x80: return r, i
        s += 7

def parse(b):
    """Returnează {număr_câmp: [valori]}; LEN rămâne bytes, varint -> int, fixed -> bytes."""
    out, i = {}, 0
    while i < len(b):
        k, i = varint(b, i)
        f, w = k >> 3, k & 7
        if w == 0: v, i = varint(b, i)
        elif w == 2:
            n, i = varint(b, i); v = b[i:i+n]; i += n
        elif w == 1: v = b[i:i+8]; i += 8
        elif w == 5: v = b[i:i+4]; i += 4
        else: raise ValueError("wire type %d" % w)
        out.setdefault(f, []).append(v)
    return out

def zz(n): return (n >> 1) ^ -(n & 1)

def value(b):
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
    marker = "/FeatureServer/%s/query" % layer
    merged, cols = {}, []
    for e in json.load(open(har))['log']['entries']:
        url = e['request']['url']
        if marker not in url or 'f=pbf' not in url: continue
        c = e['response']['content']
        if not c.get('text'): continue
        raw = base64.b64decode(c['text']) if c.get('encoding') == 'base64' else c['text'].encode('latin1')
        try:
            fr = parse(parse(parse(raw)[2][0])[1][0])   # FeatureCollection -> QueryResult -> FeatureResult
        except Exception as ex:
            print("sar peste", url[-60:], ex); continue
        names = [parse(f)[1][0].decode() for f in fr.get(13, [])]
        if not names: continue
        cols += [n for n in names if n not in cols]
        oid = fr.get(1, [b'OBJECTID'])[0].decode()
        for fb in fr.get(15, []):
            vals = [value(v) for v in parse(fb).get(1, [])]
            r = dict(zip(names, vals))
            key = r.get(oid, id(fb))
            merged.setdefault(key, {}).update({k: v for k, v in r.items() if v != ""})
        if fr.get(9, [0])[0]: print("ATENȚIE: exceededTransferLimit în", url[-60:])
    with open(outp, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
        rows = list(merged.values()); w.writeheader(); w.writerows(rows)
    print(len(rows), "rânduri unice ->", outp)

main()