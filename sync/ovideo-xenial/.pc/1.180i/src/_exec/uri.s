
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

import "video_realize" video_realize

#void/err
function gstplayinit(data videowidget)
    data null=0

    import "rec_set" rec_set
    call rec_set(null)

    data playbin2ptr#1
    setcall playbin2ptr getplaybin2ptr()
	import "get_playbin_str" get_playbin_str
	ss playbin2str
	setcall playbin2str get_playbin_str()

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

importx "_gtk_widget_get_window" gtk_widget_get_window
importx "_gdk_window_ensure_native" gdk_window_ensure_native

#wind
function widget_gdk_window_native_get(sd widget)
	sd window
	setcall window gtk_widget_get_window(widget)
	sd bool
	setcall bool gdk_window_ensure_native(window)
	if bool==(TRUE)
		return window
	endif
	str noNative="Couldn't create native window needed for GstXOverlay!"
	call texter(noNative)
	return (NULL)
endfunction
