#!/usr/bin/env python3

import shutil
import subprocess
import sys


if len(sys.argv) != 2:
    sys.exit(f"Usage: {sys.argv[0]} FILE")

aspell = shutil.which("aspell")
if aspell is None:
    sys.exit("aspell is not installed or not on PATH")

result = subprocess.call([aspell, "-c", sys.argv[1]])
if result == 0:
	with open(sys.argv[1], encoding="utf-8") as f:
		text = f.read()

	trimmed = text.rstrip()
	trailing = text[len(trimmed):]

	w=False
	if trimmed.endswith("?"):
		text = trimmed[:-1].rstrip() + " ?" + trailing
		w=True
	elif trimmed and trimmed[-1] not in ".!":
		text = trimmed + "." + trailing
		w=True
	if w:
		with open(sys.argv[1], "w", encoding="utf-8") as f:
			f.write(text)

sys.exit(result)

#.config/Claude/Preferences ,"spellcheck":{"dictionaries":["en-US","ro"],"dictionary":""}}
