
import subprocess
import re
import sys
import select
from datetime import datetime

cmd = [
    "journalctl",
    "--since","now",
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

while True:
    ready, _, _ = select.select([proc.stdout, sys.stdin], [], [])

    if proc.stdout in ready:
        line = proc.stdout.readline()
        if not line:
            break

        line = line.strip()

        if pattern.match(line):
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"Time: {now}")

    if sys.stdin in ready:
        sys.stdin.readline()  # consume Enter
        print("Enter pressed, exiting.")
        proc.terminate()
        break
