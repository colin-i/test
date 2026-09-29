#!/usr/bin/env python3

import shutil
import subprocess
import sys


if len(sys.argv) != 2:
    sys.exit(f"Usage: {sys.argv[0]} FILE")

aspell = shutil.which("aspell")
if aspell is None:
    sys.exit("aspell is not installed or not on PATH")

sys.exit(subprocess.call([aspell, "-c", sys.argv[1]]))
