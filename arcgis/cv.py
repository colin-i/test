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
	i=0
	for row in reader:
		oid = str(row["objectid"])
		a=False
		for f in files:
			for r in recs[f]:
				if oid == str(r[3]):
					print(f"{oid} is ok")
					a=True
					if f==tehnic:
						wrstate(row,r[2],nw)
					elif f==rcs:
						wrstate(row,r[2],'')
					break
			if a: break
		if not a:
			print(f"{oid} is not found")
			exit(1)
		i+=1
	print(i)
