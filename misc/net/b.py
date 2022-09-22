
from multiprocessing.connection import Client

address = ('localhost', 6000)
conn = Client(address, authkey=b'secret password')
a=conn.recv()
#conn.close() is closed there

import sys

seconds=int(sys.argv[1])
to_k=1000
dif=a/seconds/to_k
if dif<1:
	if dif==0:
		print(0)
	else:
		print("0+")
else:
	print(int(dif))
