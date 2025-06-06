

import time, os, sys
from threading import Thread
from keyring import get_credential  # python3-keyring

password = sys.argv[1]

path=os.environ["HOME"]+"/"+"autokeyring"
if not os.path.exists(path):
	import tkinter  # python3-tk
	from tkinter import messagebox
	root = tkinter.Tk()
	root.withdraw()
	messagebox.showwarning('Keyring', 'Call get_credential?')

# Triggers the keyring popup if the keyring is not unlocked already.
# Locks the thread until the popup is closed.
#
# The credentials requested are arbitrary, they are not of interest.
def trigger_keyring_unlock_popup():
	try:
		#if adding kwallet but still want gnome: in .config/python_keyring/keyringrc.cfg add:
		#[backend]
		#default-keyring=keyring.backends.SecretService.Keyring
		get_credential("service", "login")
	except:
		print("Keyring unlock popup closed! (cancelled)")

# Create a thread to trigger the keyring unlock popup.
popup = Thread(target = trigger_keyring_unlock_popup)
popup.start()

def is_locked(): return popup.is_alive()

# Wait a moment for the system to react
# Then check if the system is locked or not
time.sleep(3)
if (is_locked()):
	os.system("~/test/dotool type " + password)
	time.sleep(2)
	os.system("~/test/dotool key Enter")
