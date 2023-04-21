



format elfobj

import "timeNode" time
importx "_sprintf" sprintf

include "../../_include/include.h"

function rec_get()
    data recbin#1
    const ptrrecbin^recbin
    return recbin
endfunction

function rec_set(data value)
    data ptrrecbin%ptrrecbin
    set ptrrecbin# value
endfunction

import "set_pipe_null" set_pipe_null
function rec_unset()
    data rec#1
    setcall rec rec_get()
    data n=0
    if rec!=n
        call set_pipe_null(rec)
        import "unset_pipe_and_watch" unset_pipe_and_watch
        call unset_pipe_and_watch(rec)
        call rec_set(n)
    endif
endfunction

import "stream_error" stream_error
function rec_stream_error(data *bus,data message)
    call stream_error(message)
    call rec_unset()
endfunction

function save_inform_saved(ss location)
    str sv="File saved as: "
    data ss=stringstring
    import "strvaluedisp" strvaluedisp
    call strvaluedisp(sv,location,ss)
endfunction

function rec_endofstream(data *bus,data *message,str passdata)
    call save_inform_saved(passdata)
    call rec_unset()
endfunction

import "connect_signal" connect_signal
import "connect_signal_data" connect_signal_data
function recSignals(data bus,data dest)
    str eos="message::eos"
    data end^rec_endofstream
    call connect_signal_data(bus,eos,end,dest)

    str error="message::error"
    data errorfn^rec_stream_error
    call connect_signal(bus,error,errorfn)
endfunction

function capture_location()
const capture_char_start=!
	char folder="captures/"
const capture_char=!-capture_char_start-1
	return #folder
endfunction
#ogg
#temp
#raw
#jpeg

#avi
#mxf
#mkv
#mp4
#   mux

import "move_to_home_core" move_to_home_core
function capture_path(ss format,sd extrabool,sd extranumber)
	char capture_data#capture_char+dword_max+1+dword_max+1+format_max+1
	ss capture_str^capture_data
	ss folder
	setcall folder capture_location()
	sd tm
	setcall tm time(0)
	ss fmt="%s%s%u.%s"
	ss extra
	if extrabool==0
		ss null=""
		set extra null
	else
		sd extra_data#5
		ss extra_str^extra_data
		str f_extra="%u."
		call sprintf(extra_str,f_extra,extranumber)
		set extra extra_str
	endelse
	call sprintf(capture_str,fmt,folder,extra,tm,format)
	call move_to_home_core(#capture_str)
	return capture_str
endfunction

function save_destination(ss format)
    sd path
    setcall path capture_path(format,0)
    return path
endfunction



str chain_uri#1
data chain_streams#1
const ptr_chain_uri^chain_uri
const ptr_chain_streams^chain_streams

function save_get_main_format()
    str mediaform="uridecodebin uri=\"%s\" %s ! queue ! %s ! oggmux name=mux ! filesink location=\"%s\"%s"
    return mediaform
endfunction
function save_get_sec_format()
    str mediasecform=" %s ! queue ! %s ! mux."
    return mediasecform
endfunction
function save_get_video_format()
    str video="theoraenc"
    return video
endfunction
function save_get_audio_format()
    str audio="vorbisenc"
    return audio
endfunction
function save_get_ogg_dest()
#these formats are related to format_max
    str format="ogg"
    sd dest
    setcall dest save_destination(format)
    return dest
endfunction

#v
function save_stream_dest_ready(str dest)
    data ptrsrc%ptr_chain_uri
    str src#1
    set src ptrsrc#
    data ptrstreams%ptr_chain_streams
    str streams#1
    set streams ptrstreams#

    ss video
    ss audio
    setcall video save_get_video_format()
    setcall audio save_get_audio_format()

    str srcname="src"

    str nullstr=""

    data flagA=audio
    data flagVA=audiovideo

    char src_prop_data#20

    str format#1
    str sr#1
    str sr_prop^src_prop_data
    str m1#1
    str dst#1
    str secondstream#1
    data *=0
    sd strings^format

    setcall format save_get_main_format()
    set sr src
    str nameformat="name=%s"
    call sprintf(sr_prop,nameformat,srcname)
    set dst dest

    set m1 video
    if streams==flagVA
        str makename="%s."
        char save_secname_data#15
        str save_src_name^save_secname_data
        call sprintf(save_src_name,makename,srcname)
        char save_va_data#40
        str save_va^save_va_data
        ss secformat
        setcall secformat save_get_sec_format()
        call sprintf(save_va,secformat,save_src_name,audio)
        set secondstream save_va
    else
        set secondstream nullstr
        if streams==flagA
            set m1 audio
        endif
    endelse

    data mem#1
    data ptrmem^mem

    import "allocsum_null" allocsum_null
    importx "_free" free
    data err#1
    setcall err allocsum_null(strings,ptrmem)
    data noerr=noerror
    if err!=noerr
        return err
    endif

    call sprintf(mem,format,src,sr_prop,m1,dest,secondstream)

    importx "_gst_parse_launch" gst_parse_launch

    import "getptrgerr" getptrgerr
    import "gerrtoerr" gerrtoerr
    data ptrgerr#1
    setcall ptrgerr getptrgerr()

    data pipe#1
    setcall pipe gst_parse_launch(mem,ptrgerr)
    call free(mem)
    data n=0
    if pipe==n
        call gerrtoerr(ptrgerr)
        return ptrgerr
    endif
    import "add_bus_signal_watch" add_bus_signal_watch
    call add_bus_signal_watch(pipe)
    call rec_set(pipe)

    import "bus_signals_data" bus_signals_data
    data sg^recSignals
    call bus_signals_data(pipe,sg,dest)

    importx "_gst_element_set_state" gst_element_set_state
    data play=GST_STATE_PLAYING
    call gst_element_set_state(pipe,play)
endfunction

#v
function save_stream_prepare_dest()
    sd dest
    setcall dest save_get_ogg_dest()
    call save_stream_dest_ready(dest)
endfunction

#v
function save_stream(str uri,data streams)
    #unset the previous if any
    call rec_unset()

    data save_uri%ptr_chain_uri
    set save_uri# uri
    data save_streams%ptr_chain_streams
    set save_streams# streams

    call save_stream_prepare_dest()
endfunction

import "collect_info" collect_info
#v
function info_save_stream()
    char rec="recording from"

    str capture^rec
    data *forward^save_stream
    data st^capture

    call collect_info(st)
endfunction
