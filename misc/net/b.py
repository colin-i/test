
from multiprocessing.connection import Client

address = ('localhost', 6000)
conn = Client(address, authkey=b'secret password')
a=conn.recv()
conn.close() #and is closed there too

'''
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
'''

b='B'
if a>=1000:
	b='K'
	a/=1000
	if a>=1000:
		b='M'
		a/=1000
#		if a>=1000:
#			b='G'
#			a/=1000

print(str(int(a))+' '+b)
