

import time, os, sys
from threading import Thread
from keyring import get_credential

password = sys.argv[1]

path=os.environ["HOME"]+"/"+"autokeyring"
if not os.path.exists(path):
	import tkinter
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
        get_credential("service", "login")
    except:
        print("Keyring unlock popup closed! (cancelled)")

# Create a thread to trigger the keyring unlock popup.
popup = Thread(target = trigger_keyring_unlock_popup)
popup.start()

def is_locked(): return popup.is_alive()

# Wait a moment for the system to react
# Then check if the system is locked or not
time.sleep(2)
if (is_locked()):
	#for x11, xdotool without sudo maybe
	os.system("sudo ydotool type " + password)
	os.system("sudo ydotool key enter")
