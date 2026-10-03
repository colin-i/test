#!/usr/bin/env python3
"""Extract the project list (title, status, completion %) from the WordPress REST API
responses stored in a cnir.ro .har file and write it to a CSV.
Usage: python3 har_cnir_to_csv.py file.har output.csv [spec]
The optional spec has two parts separated by ";":
  columns;filter_column
  - columns: comma-separated list of columns to keep (if empty or missing, all columns are written)
  - filter_column: if present, only rows where this column is not blank are kept
Examples:
  title_clean,completion_pct,modified;completion_pct   -> 3 columns, only the rows with a percentage
  title_clean,completion_pct                           -> 2 columns, all rows
  ;completion_pct                                      -> all columns, only rows with a percentage
"""
import sys, json, csv, re, html

# Lookalike characters found in the titles (Cyrillic / Greek) -> plain Latin letters,
# plus cedilla forms -> Romanian comma-below forms, and en/em dash -> hyphen
CLEAN_MAP = str.maketrans({
    # Cyrillic capitals
    'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P',
    'С': 'C', 'Т': 'T', 'Х': 'X', 'І': 'I',
    # Cyrillic small letters
    'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'х': 'x', 'у': 'y', 'і': 'i',
    # Greek lookalikes
    'ο': 'o', 'Ο': 'O', 'Α': 'A', 'Β': 'B', 'Ε': 'E', 'Ι': 'I', 'Κ': 'K', 'Μ': 'M',
    'Ν': 'N', 'Ρ': 'P', 'Τ': 'T', 'Χ': 'X', 'Υ': 'Y', 'Ζ': 'Z',
    # Cedilla -> comma-below (Romanian)
    'ş': 'ș', 'Ş': 'Ș', 'ţ': 'ț', 'Ţ': 'Ț',
    # Dashes
    '–': '-', '—': '-',
})

def main():
    har, outp = sys.argv[1], sys.argv[2]
    projects = {}  # keyed by WordPress post id, so repeated or paged responses merge cleanly
    for e in json.load(open(har))['log']['entries']:
        url = e['request']['url']
        # The map page loads every project from this endpoint (per_page=100 covers all of them)
        if '/wp-json/wp/v2/proiecte' not in url: continue
        text = e['response']['content'].get('text')
        if not text: continue
        try:
            data = json.loads(text)
        except ValueError:
            continue
        if not isinstance(data, list): continue
        for p in data:
            projects[p['id']] = p
    # Optional spec from argv[3]: "columns;filter_column"
    spec = sys.argv[3] if len(sys.argv) > 3 else ""
    cols_part, _, filter_col = spec.partition(';')
    keep_cols = [c.strip() for c in cols_part.split(',') if c.strip()]
    filter_col = filter_col.strip()
    rows = []
    for p in projects.values():
        status = (p.get('status') or '').strip()
        # Completion percentage exists only in some status texts, e.g. "... Stadiu lucrări execuție - 71%"
        m = re.search(r'(\d+(?:[.,]\d+)?)\s*%', status)
        rows.append({
            'id': p['id'],
            'title': html.unescape(p['title']['rendered']),   # decode entities such as &#8211;
            'title_clean': html.unescape(p['title']['rendered']).translate(CLEAN_MAP),
            'status': status,
            'completion_pct': m.group(1).replace(',', '.') if m else '',
            'deadline': p.get('deadline') or '',
            'link': p.get('link', ''),
            'geojson': p.get('geojson', ''),
            'modified': p.get('modified', ''),
        })
    all_cols = list(rows[0].keys()) if rows else []
    for c in keep_cols + ([filter_col] if filter_col else []):
        if c not in all_cols:
            sys.exit("Unknown column %r. Available: %s" % (c, ", ".join(all_cols)))
    # Filter rows first (on the full row), then select columns
    if filter_col:
        rows = [r for r in rows if str(r[filter_col]).strip() != '']
    fieldnames = keep_cols or all_cols
    with open(outp, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        w.writeheader(); w.writerows(rows)
    print(len(rows), "projects ->", outp)

main()
