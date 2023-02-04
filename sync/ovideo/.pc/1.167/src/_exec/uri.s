
format elfobj

import "texter" texter

include "../_include/include.h"

function setplaybin2(data value)
    data playbin2#1
    const propagateplaybin2^playbin2
    set playbin2 value
endfunction

#playbin2
function getplaybin2ptr()
    data propagateplaybin2%propagateplaybin2
    return propagateplaybin2
endfunction

#void gtkwidget::realize
importx "_gtk_widget_get_window" gtk_widget_get_window
importx "_gdk_window_ensure_native" gdk_window_ensure_native
importx "_gst_x_overlay_set_window_handle" gst_x_overlay_set_window_handle
importx "_gst_x_overlay_get_type" gst_x_overlay_get_type
importx "_gst_implements_interface_cast" gst_implements_interface_cast
importx "_gst_element_implements_interface" gst_element_implements_interface

import "gdkGetdrawable" gdkGetdrawable

function video_realize(data widget)
	data window#1
	setcall window gtk_widget_get_window(widget)

	data false=0
	sd bool
	setcall bool gdk_window_ensure_native(window)
	if bool==false
		str noNative="Couldn't create native window needed for GstXOverlay!"
		call texter(noNative)
	endif

	#Pass it to playbin2, which implements XOverlay and will forward it to the video sink
	#on >= ubuntu 12 with debs from 2012.11(almost same place with 2012.11 msi file) this is a not
	sv playbin2
	setcall playbin2 getplaybin2ptr()
	set playbin2 playbin2#
	sd overlaytype
	setcall overlaytype gst_x_overlay_get_type()
	setcall bool gst_element_implements_interface(playbin2,overlaytype)
	if bool==(TRUE)
		sd interfacecast
		setcall interfacecast gst_implements_interface_cast(playbin2,overlaytype)
		sd drawablehandle
		setcall drawablehandle gdkGetdrawable(window)
		call gst_x_overlay_set_window_handle(interfacecast,drawablehandle)
		return (void)
	endif
	import "printer" printer
	call printer("gst_element_implements_interface false.")
endfunction

import "unset_playbool" unset_playbool

function gstset()
    data null=0
    call setplaybin2(null)
    call unset_playbool()
endfunction

importx "_gst_element_set_state" gst_element_set_state
function set_pipe_null(data pipe)
    call gst_element_set_state(pipe,(GST_STATE_NULL))
endfunction

#locations: 1. end of stream;
#           2. top level window closing;
#           3. stream start(stop 1,start 2);
#           4. stop click
#rec: same and also unref at error
function nullifyplaybin()
    data playbin2ptr#1
    setcall playbin2ptr getplaybin2ptr()
    call set_pipe_null(playbin2ptr#)
    call unset_playbool()
endfunction

import "rec_unset" rec_unset
function gstunset()
    #playbin
    data playbin2ptr#1
    setcall playbin2ptr getplaybin2ptr()
    data playbin#1
    set playbin playbin2ptr#
    data null=0
    if playbin!=null
        call nullifyplaybin()
        import "unset_pipe_and_watch" unset_pipe_and_watch
        call unset_pipe_and_watch(playbin)
    endif
    call rec_unset()
endfunction

import "connect_signal" connect_signal
function addSignals(data bus,sd *callbackdata)
    import "endofstream" endofstream
    str eos="message::eos"
    data endofstreamfn^endofstream
    call connect_signal(bus,eos,endofstreamfn)

    import "streamerror" streamerror
    str error="message::error"
    data errorfn^streamerror
    call connect_signal(bus,error,errorfn)

    import "statechanged" statechanged
    str state_changed="message::state-changed"
    data state^statechanged
    call connect_signal(bus,state_changed,state)
endfunction

importx "_gst_element_factory_make" gst_element_factory_make
#void/err
function gstplayinit(data videowidget)
    data null=0

    import "rec_set" rec_set
    call rec_set(null)

    data playbin2ptr#1
    str playbin2str="playbin2"
    setcall playbin2ptr getplaybin2ptr()

    setcall playbin2ptr# gst_element_factory_make(playbin2str,playbin2str)
    #needing gstreamer0.10-plugins-good

    data playbin2#1
    set playbin2 playbin2ptr#

    if playbin2==null
        str factoryerr="Not all elements could be created."
        call texter(factoryerr)
        return factoryerr
    endif
    import "add_bus_signal_watch" add_bus_signal_watch
    call add_bus_signal_watch(playbin2)

    #draw area
    data v_realize^video_realize
    str callrealize="realize"
    call connect_signal(videowidget,callrealize,v_realize)

    import "bus_signals" bus_signals
    #bus signals
    data add_signals^addSignals
    call bus_signals(playbin2,add_signals)
endfunction

