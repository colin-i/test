
import keyboard
import threading
import sys

def t3_f():
	while True:
		keyboard.wait('f8')
		print('s')
		sys.stdout.flush()
def t4_f():
	while True:
		keyboard.wait('f9')
		print('c')
		sys.stdout.flush()
t3 = threading.Thread(target=t3_f)
t3.start()
t4 = threading.Thread(target=t4_f)
t4.start()
