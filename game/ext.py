import subprocess
import re
from datetime import datetime

cmd = [
    "journalctl",
    "-f",
    "-o", "cat",
    "/usr/bin/gnome-shell"
]

proc = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1
)

pattern = re.compile(r"^\[FocusWatch\] extensie$")

for line in proc.stdout:
    line = line.strip()

    if pattern.match(line):
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"Time: {now}")
