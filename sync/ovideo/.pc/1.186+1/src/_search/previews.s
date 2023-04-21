


format elfobj

include "../_include/include.h"

function getsubject()
    str nm="name"
    return nm
endfunction

function search_photo_set_scaled(sd pixbuf,sd img)
    importx "_gtk_image_set_from_pixbuf" gtk_image_set_from_pixbuf
    call gtk_image_set_from_pixbuf(img,pixbuf)
endfunction

#ve
function search_photo_set(sd pixbuf,sd img)
    importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height

    sd w
    sd h
    setcall w gdk_pixbuf_get_width(pixbuf)
    setcall h gdk_pixbuf_get_height(pixbuf)

    sd scale_w=200
    sd scale_h

    #w..h
    #sw..sh
    #sh=h*sw/w
    mult h scale_w
    div h w
    set scale_h h

    data fn^search_photo_set_scaled
    import "pixbuf_scale_forward_data" pixbuf_scale_forward_data
    call pixbuf_scale_forward_data(pixbuf,scale_w,scale_h,fn,img)
endfunction

function search_photo_prepare(sd elem,sd msg)
    import "object_get_dword_name" object_get_dword_name
    sd img
    setcall img object_get_dword_name(elem)

    data fn^search_photo_set
    import "msgelement_pixbuf_forward_data" msgelement_pixbuf_forward_data
    call msgelement_pixbuf_forward_data(msg,fn,img)
endfunction


function search_photo_get(sd iter,sd msg)
    import "iterate_next_forward_data_free" iterate_next_forward_data_free
    data f^search_photo_prepare
    call iterate_next_forward_data_free(iter,f,msg)
endfunction


function search_photo_received(sd *bus,sd msg,sd pipe)
    import "set_pipe_null" set_pipe_null
    call set_pipe_null(pipe)

    import "iterate_sinks_data" iterate_sinks_data
    data f^search_photo_get

    call iterate_sinks_data(pipe,f,msg)

    import "unset_pipe_and_watch" unset_pipe_and_watch
    call unset_pipe_and_watch(pipe)
endfunction



function search_connect_pixbuf(sd bus,sd pipe)
    str px="message::element"
    import "connect_signal_data" connect_signal_data
    data fn^search_photo_received
    call connect_signal_data(bus,px,fn,pipe)
endfunction

importx "_sprintf" sprintf

function search_get_image(ss uri,sd handle)
    ss launcher="uridecodebin uri=\"%s\" ! ffmpegcolorspace ! gdkpixbufsink %s=%u"
    ss src
    ss nm
    sd *term=0

    set src uri
    setcall nm getsubject()

    sd strs^launcher
    sd nrs=1

    sd mem
    sd ptrmem^mem

    import "allocsum_numbers_null" allocsum_numbers_null
    sd err
    data noerr=noerror

    setcall err allocsum_numbers_null(strs,nrs,ptrmem)
    if err!=noerr
        return err
    endif
    call sprintf(mem,launcher,uri,nm,handle)

    import "launch_pipe" launch_pipe
    sd pipeline
    data n=0

    setcall pipeline launch_pipe(mem)

    importx "_free" free
    call free(mem)
    if pipeline==n
        return n
    endif

    import "start_pipe" start_pipe
    setcall err start_pipe(pipeline)
    if err!=noerr
        return err
    endif

    import "bus_default_signals" bus_default_signals
    call bus_default_signals(pipeline)

    import "bus_signals_bin" bus_signals_bin
    data fn^search_connect_pixbuf
    call bus_signals_bin(pipeline,fn)
endfunction
