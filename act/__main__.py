
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk,GLib,Gdk

from . import datacode

loop = GLib.MainLoop()
container = [0]

win = Gtk.Window()
win.set_title(datacode.title)
win.set_decorated(False)
win.set_child(Gtk.ScrolledWindow(child=datacode.init(loop,container)))
win.show()

datacode.screen(win)

loop.run()

#exit() needs closing the second thread, more at the second thread
import os
os._exit(container[0])
