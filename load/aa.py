

import sys
import os
from multiprocessing.connection import Client

with open(os.path.expanduser('~')+"/load_ip","rb") as f:
	address = (f.read(), 6000)
conn = Client(address)

pid=int(sys.argv[1])
if pid:
	conn.send(len(os.sched_getaffinity(pid)))
else:
	conn.send(1) #system overall case

conn.close()
