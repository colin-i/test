
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk,GLib,Gdk

import json
import Xlib.display

from . import query

#data=query.full()
#print(json.dumps(data, indent=1))

disp=Gdk.Display.get_default()
rect=disp.get_primary_monitor().get_geometry()
y=30
w=rect.width/6
h=rect.height-y
x=rect.width-w

win = Gtk.Window()
t="Activity"
win.set_title(t)
win.set_decorated(False)
#win.set_default_size(w,h)
loop = GLib.MainLoop()
win.show()

#xid=win.get_surface().get_xid()
#xdisp=disp.get_xdisplay()
#xwin = Xlib.display.drawable.Window(xdisp, id)
#xwin = Xlib.display.drawable.Window(Xlib.display.Display(), id)
#xwin.configure will not work

d = Xlib.display.Display()
r = d.screen().root
window_ids = r.get_full_property(
	d.intern_atom('_NET_CLIENT_LIST'), Xlib.X.AnyPropertyType
).value
for window_id in window_ids:
	xwin = d.create_resource_object('window', window_id)
	if t==xwin.get_wm_name():
		xwin.configure(
			x=x.__int__(),
			y=y.__int__(),
			width=w.__int__(),
			height=h.__int__()
			#border_width=10
			#,stack_mode=Xlib.X.Above
		)
		d.sync()

loop.run()
