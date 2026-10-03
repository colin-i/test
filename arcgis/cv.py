#!/usr/bin/env python3
import ast
import csv
import os
import re
import sys

csv_path = sys.argv[1]

nw="_new"
rcs="recs"
tehnic=rcs+nw
files = [rcs, tehnic, rcs+"0", rcs+"1", rcs+"x"]
recs = {}

basef=os.path.join(os.path.expanduser("~"), "measures")
for idx, name in enumerate(files):
	path = os.path.join(basef, name)
	with open(path, "r", encoding="utf-8") as f:
		recs[name] = ast.literal_eval(f.read())

# after the `files = [...]` line
CATEGORY_COLUMN = "categorie_drum"

expected = {
	rcs: {
		"AUTOSTRAZI IN EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
		"DRUMURI EXPRES PROIECTE IN EXECUTIE",
	},
	rcs + "1": {
		"AUTOSTRAZI IN LICITATIE FAZA EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
		"DRUM EXPRES IN LICITATIE FAZA EXECUTIE / PROIECTARE SI EXECUTIE LUCRARI",
	},
	rcs + "0": {
		"AUTOSTRAZI IN PREGATIRE FAZA PROIECTARE (SF, PT)",
		"DRUMURI DE MARE VITEZA IN FAZA PROIECTARE (SF, PT)",
		"DRUMURI EXPRES IN PREGATIRE FAZA PROIECTARE (SF, PT)",
	},
	# recsx: not checked
}
expected[tehnic] = expected[rcs]   # recs and recs_new share the same categories

def norm(s):
	return " ".join(str(s).split()).upper()

expected = {k: {norm(v) for v in vs} for k, vs in expected.items()}

def wrstate(r,s,nw):
	d = r['stadiu_actual_fizic']
	if d==' ':
		d=''
	else:
		ex_path = os.path.join(basef, "ex" + nw, s)
		if os.path.isfile(ex_path):
			with open(ex_path, encoding="utf-8") as ex_file:
				a = ex_file.read().splitlines()
			if len(a) < 2:
				raise ValueError(f"{ex_path} must contain a marker and mode")
			marker, mode = a[0], a[1]
			if mode == "0":
				matches = [
					match.group(1)
					for line in d.splitlines()
					for match in re.finditer(re.escape(marker) + r"([^ ]*)", line)
				]
				if not matches:
					raise ValueError(f"{marker!r} not found in stadiu_actual_fizic for {s}")
				if nw == "":
					d = matches[0]
					if not d.endswith("%"):
						d += "%"
				else:
					d = "".join(matches)
			else:
				lines = d.splitlines()
				matching_line = next((i for i, line in enumerate(lines) if marker in line), None)
				if matching_line is None or matching_line + 1 >= len(lines):
					raise ValueError(f"{marker!r} and its following line not found for {s}")
				d = lines[matching_line + 1]
				if nw == "":
					match = re.match(r" *[^ ]*", d)
					d = match.group(0) if match else ""
		else:
			d = d.splitlines()[0] if d.splitlines() else ""
			match = re.match(r"[^ ]*", d)
			d = match.group(0) if match else ""
	with open(os.path.join(basef, "current" + nw, s), 'w') as f:
		f.write(d)

with open(csv_path, newline="", encoding="utf-8-sig") as f:
	reader = csv.DictReader(f)
	i = 0
	for row in reader:
		oid = str(row["objectid"])
		cat = norm(row[CATEGORY_COLUMN])

		# every set that contains this id (an id could be in more than one)
		found = [(name, r) for name in files for r in recs[name] if oid == str(r[3])]
		if not found:
			print(f"{oid} is not found")
			exit(1)

		# prefer a set whose category matches; otherwise report the mismatch
		good = next(((n, r) for n, r in found
		             if n == "recsx" or cat in expected[n]), None)
		if good is None:
			print(f"{oid} is in the wrong set: found in {[n for n, _ in found]}, "
			      f"category is {row[CATEGORY_COLUMN]!r}")
			exit(1)

		name, r = good
		print(f"{oid} is ok ({name})")
		if name == tehnic:
			wrstate(row, r[2], nw)
		elif name == rcs:
			wrstate(row, r[2], '')
		i += 1
	print(i)
