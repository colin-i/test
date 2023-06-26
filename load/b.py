"""
class bcolors:
    red = '\033[101m'
    green = '\033[102m'
    yellow = '\033[103m'
    end = '\033[0m'
    bold = '\033[1m'
    underline = '\033[4m'
#{bcolors.bold}{bcolors.underline}
print(f"{bcolors.red} {bcolors.green} {bcolors.yellow} {bcolors.end}")  #if not end will continue at next print

import os
print(os.get_terminal_size().columns)
"""

from multiprocessing.connection import Listener

address = ('192.168.1.15', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address)

def t2_f():
	try:
		while True:
			conn = listener.accept()
			print(conn.recv())
			conn.close()
	except Exception:
		print("closed")

import threading
t2 = threading.Thread(target=t2_f)
t2.start()

while True:
	import readchar
	c=readchar.readchar()
	if c=='q':
		break
listener.close()   #this will close after accept gets next client
print("will close")
#if there are threads python will not exit
