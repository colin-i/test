

import sys
import os
from multiprocessing.connection import Client

with open(os.path.expanduser('~')+"/rpi2_ip","rb") as f:
	address = (f.read(), 6000)
conn = Client(address)

pid=int(sys.argv[1])
conn.send(len(os.sched_getaffinity(pid)))

conn.close()
