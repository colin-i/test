


format elfobj

include "../_include/include.h"

import "getptrgerr" getptrgerr
import "gerrtoerr" gerrtoerr

function add_bus_signal_watch_got_bus(sd bus)
    importx "_gst_bus_add_signal_watch" gst_bus_add_signal_watch
    call gst_bus_add_signal_watch(bus)
endfunction
function add_bus_signal_watch(sd pipe)
    data f^add_bus_signal_watch_got_bus
    call bus_signals(pipe,f)
endfunction
function remove_bus_signal_watch_got_bus(sd bus)
    importx "_gst_bus_remove_signal_watch" gst_bus_remove_signal_watch
    call gst_bus_remove_signal_watch(bus)
endfunction
function remove_bus_signal_watch(sd pipe)
    data f^remove_bus_signal_watch_got_bus
    call bus_signals(pipe,f)
endfunction

importx "_gst_object_unref" gst_object_unref
function unset_pipe_and_watch(sd pipe)
    call remove_bus_signal_watch(pipe)
    call gst_object_unref(pipe)
endfunction

#return gst_parse_launch
function launch_pipe(ss mem)
    sd ptrgerr
    setcall ptrgerr getptrgerr()

    importx "_gst_parse_launch" gst_parse_launch
    sd pipe
    setcall pipe gst_parse_launch(mem,ptrgerr)

    data n=0
    if pipe==n
        call gerrtoerr(ptrgerr)
    endif
    call add_bus_signal_watch(pipe)
    return pipe
endfunction


importx "_gst_element_set_state" gst_element_set_state
#e
function start_pipe(sd pipe)
    data play=GST_STATE_PLAYING
    data error=GST_STATE_CHANGE_FAILURE
    data noe=noerror
    sd ret
    setcall ret gst_element_set_state(pipe,play)
    if ret!=error
        return noe
    endif

    str er="Unable to set the pipeline to the playing state."
    import "texter" texter
    call texter(er)
    call unset_pipe_and_watch(pipe)
    return er
endfunction

#null or pipeline
function launch_pipe_start(ss command)
    sd pipeline
    data n=0

    setcall pipeline launch_pipe(command)
    if pipeline==n
        return n
    endif

    sd err
    data noerr=noerror
    setcall err start_pipe(pipeline)
    if err!=noerr
        return n
    endif
    return pipeline
endfunction


import "set_pipe_null" set_pipe_null
#
function default_unref(sd pipe)
    call set_pipe_null(pipe)
    call unset_pipe_and_watch(pipe)
endfunction

function default_unref_ptr(sd ptr_pipe)
    sd pipe
    set pipe ptr_pipe#
    call default_unref(pipe)
    data z=0
    set ptr_pipe# z
endfunction
#

#
importx "_gst_message_parse_error" gst_message_parse_error
function def_error(sd message)
    sd ptrgerr#1
    setcall ptrgerr getptrgerr()
    data null=NULL
    call gst_message_parse_error(message,ptrgerr,null)
    call gerrtoerr(ptrgerr)
endfunction
function default_error(sd *bus,sd message,sd pipeline)
    call def_error(message)
    call default_unref(pipeline)
endfunction
function default_error_ptr(sd *bus,sd message,sd ptrpipeline)
    call def_error(message)
    call default_unref_ptr(ptrpipeline)
endfunction

function default_eos(sd *bus,sd *message,sd pipeline)
    str eos="End Of Stream"
    call texter(eos)
    call default_unref(pipeline)
endfunction
#

import "connect_signal_data" connect_signal_data

#
function pipe_default_error(sd bus,sd pipe)
    data er^default_error
    str ermsg="message::error"
    call connect_signal_data(bus,ermsg,er,pipe)
endfunction

function pipe_default_signals(sd bus,sd pipe)
    call pipe_default_error(bus,pipe)

    data eos^default_eos
    str eosmsg="message::eos"
    call connect_signal_data(bus,eosmsg,eos,pipe)
endfunction
#

#
function bus_signals_data(sd element,sd forwardToSignals,sd forwardToSignalsData)
    sd bus#1
    importx "_gst_element_get_bus" gst_element_get_bus
    setcall bus gst_element_get_bus(element)

    call forwardToSignals(bus,forwardToSignalsData)

    call gst_object_unref(bus)
endfunction

function bus_signals(sd element,sd forwardToSignals)
    data n=0
    call bus_signals_data(element,forwardToSignals,n)
endfunction
#

#pipe as data callback
function bus_signals_bin(sd pipe,sd forward)
    call bus_signals_data(pipe,forward,pipe)
endfunction
#
#def
function bus_default_signals(sd pipe)
    data next^pipe_default_signals
    call bus_signals_bin(pipe,next)
endfunction
#

#default err and eos pipe and modal
importx "_gtk_dialog_response" gtk_dialog_response
function default_err_modal(sd *bus,sd message,sd dialog)
    call def_error(message)
    call gtk_dialog_response(dialog,(GTK_RESPONSE_CANCEL))
endfunction
function default_eos_modal(sd *bus,sd *message,sd dialog)
    call gtk_dialog_response(dialog,(GTK_RESPONSE_OK))
endfunction
#err and eos
function default_signals_for_modal_set(sd bus,sd dialog)
    data er^default_err_modal
    str ermsg="message::error"
    call connect_signal_data(bus,ermsg,er,dialog)

    data eos^default_eos_modal
    str eosmsg="message::eos"
    call connect_signal_data(bus,eosmsg,eos,dialog)
endfunction
function default_signals_for_modal(sd pipe,sd dialog)
    data f^default_signals_for_modal_set
    call bus_signals_data(pipe,f,dialog)
endfunction
#err at modal when dialog is not known, but function to close dialog
function err_modal(sd *bus,sd message,sd closemodalForward)
    call def_error(message)
    call closemodalForward()
    #sound flag if required
    import "sound_global_flag_set" sound_global_flag_set
    call sound_global_flag_set(0)
endfunction
function err_signal_modal_set(sd bus,sd closemodalForward)
    data er^err_modal
    str ermsg="message::error"
    call connect_signal_data(bus,ermsg,er,closemodalForward)
endfunction
function err_signal_modal(sd pipe,sd closemodalForward)
    data f^err_signal_modal_set
    call bus_signals_data(pipe,f,closemodalForward)
endfunction

importx "_gst_bin_iterate_sinks" gst_bin_iterate_sinks
importx "_gst_iterator_free" gst_iterator_free
function iterate_sinks_data(sd pipe,sd forward,sd data)
    sd iter
    setcall iter gst_bin_iterate_sinks(pipe)
    call forward(iter,data)
    call gst_iterator_free(iter)
endfunction

function iterate_firstsink(sd pipe,sd forward)
    sd iter
    setcall iter gst_bin_iterate_sinks(pipe)

    call iterate_next_forward_data_free(iter,forward,0)

    call gst_iterator_free(iter)
endfunction

importx "_gst_iterator_next" gst_iterator_next
#e
function iterate_next_forward_data_free(sd iter,sd forward,sd data)
    sd elem
    sd ptr_elem^elem
    sd ret
    setcall ret gst_iterator_next(iter,ptr_elem)
    data er=GST_ITERATOR_ERROR
    if ret==er
        str e="Iterator error"
        call texter(e)
        return e
    endif
    call forward(elem,data)
    call gst_object_unref(elem)
    data noe=noerror
    return noe
endfunction





