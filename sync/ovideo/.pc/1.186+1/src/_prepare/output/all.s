

format elfobj

include "../../_include/include.h"

importx "_sprintf" sprintf

data dialog#1
const stage_file_dialog^dialog

function stage_progress_dialog(sd inits)
    data modal=GTK_DIALOG_MODAL
    import "dialogfield_size_button" dialogfield_size_button
    ss title="Save stage"
    data width=150
    data height=100
    str GTK_STOCK_CANCEL="gtk-cancel"
    data responsecancel=GTK_RESPONSE_CANCEL
    call dialogfield_size_button(title,modal,inits,0,width,height,GTK_STOCK_CANCEL,responsecancel)
    #set the dialog to null
    data ptr_dialog%stage_file_dialog
    set ptr_dialog# 0
endfunction
function stage_progress_dialog_inc(sd frame)
    ss value=100
    mult value frame
    import "stage_get_frames" stage_get_frames
    divcall value stage_get_frames()
	char s={_0,Period}
	char a#1
	char b#1
	char *=0
	set b value
	rem b 10
	add b (_0)
	set a value
	div a 10
	rem a 10
	add a (_0)
    sd doublelow
    sd doublehigh
    sd double^doublelow
    str doubleformat="%lf"
    importx "_sscanf" sscanf
    call sscanf(#s,doubleformat,double)
    importx "_gtk_progress_bar_set_fraction" gtk_progress_bar_set_fraction
    data pbar#1
    const progressbar^pbar
    call gtk_progress_bar_set_fraction(pbar,doublelow,doublehigh)
endfunction
function stage_file_dialog_inits(sd vbox,sd dialog)
    data ptr%stage_file_dialog
    set ptr# dialog

    #progress bar
    import "progressfield" progressfield
    sd widget
    setcall widget progressfield(vbox)

    importx "_gtk_progress_bar_set_text" gtk_progress_bar_set_text
    str save="Save to file"
    call gtk_progress_bar_set_text(widget,save)

    data pbar%progressbar
    set pbar# widget

    #new texter
    import "new_texter_modal" new_texter_modal
    call new_texter_modal(vbox,dialog)
endfunction
function stage_file_close()
    importx "_gtk_dialog_response" gtk_dialog_response
    sd d%stage_file_dialog
    data z=0
    if d#!=z
        data responsecancel=GTK_RESPONSE_CANCEL
        call gtk_dialog_response(d#,responsecancel)
        set d# z
    endif
endfunction




function stage_file_error(sd *bus,sd message,sd *data)
    import "def_error" def_error
    call def_error(message)
    call stage_file_close()
endfunction
function stage_file_eos(sd *bus,sd *message,sd *data)
    call stage_file_close()
endfunction

function stage_get_src_name()
    str s="source"
    return s
endfunction
#eventbox/0
function stage_nthwidgetFromcontainer(sd value)
    import "nthwidgetFromcontainer" nthwidgetFromcontainer
    import "stage_get_frames_container" stage_get_frames_container
    sd container
    setcall container stage_get_frames_container()
    sd eventbox
    setcall eventbox nthwidgetFromcontainer(container,value)
    return eventbox
endfunction

import "object_get_dword_name" object_get_dword_name

#pixbuf/0
function stage_nthPixbufFromContainer(sd value)
    sd container
    setcall container stage_get_frames_container()
    sd eventbox
    setcall eventbox nthwidgetFromcontainer(container,value)
    if eventbox==0
        return 0
    endif
    sd pixbuf
    setcall pixbuf object_get_dword_name(eventbox)
    return pixbuf
endfunction

import "texter" texter

function stage_prepare_pixbuf(sd pixbuf,sd mem,sd w,sd h)
    sd px_pixels
    importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
    setcall px_pixels gdk_pixbuf_get_pixels(pixbuf)

    sd px_bps
    importx "_gdk_pixbuf_get_bits_per_sample" gdk_pixbuf_get_bits_per_sample
    setcall px_bps gdk_pixbuf_get_bits_per_sample(pixbuf)

    data minbps=pixbuf_minbps
    if px_bps<minbps
        str bpser="Bits-per-sample to few."
        call texter(bpser)
        return bpser
    endif

    sd px_nchan
    importx "_gdk_pixbuf_get_n_channels" gdk_pixbuf_get_n_channels
    setcall px_nchan gdk_pixbuf_get_n_channels(pixbuf)

    data minnchan=pixbuf_minnchan
    if px_nchan<minnchan
        str nchaner="N-channels to few."
        call texter(nchaner)
        return nchaner
    endif

    sd px_rowstride
    importx "_gdk_pixbuf_get_rowstride" gdk_pixbuf_get_rowstride
    setcall px_rowstride gdk_pixbuf_get_rowstride(pixbuf)

    import "rgb_get_set" rgb_get_set
    data rowstart=0
    sd x
    sd y=0
    while y!=h
        set x rowstart
        while x!=w
            call rgb_get_set(mem,px_pixels,x,y,px_bps,px_nchan,px_rowstride,(get_rgb))
            data a=4
            add mem a
            inc x
        endwhile
        inc y
    endwhile
endfunction

function stage_frame_size(sd w,sd h)
    sd bpp=stage_bpp
    sd size
    set size w
    mult size h
    sd Bpp
    set Bpp bpp
    data bitsperbyte=8
    div Bpp bitsperbyte
    mult size Bpp
    return size
endfunction

function stage_file_frame_main_set(sd ptr_pack,sd eventbox)
    data a=4

    sd pix
    setcall pix object_get_dword_name(eventbox)
    set ptr_pack# pix
    add ptr_pack a

    importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
    setcall ptr_pack# gdk_pixbuf_get_width(pix)
    add ptr_pack a
    setcall ptr_pack# gdk_pixbuf_get_height(pix)
endfunction

importx "_free" free

#all returns of this timeout are false to not launch it again from here
function stage_file_need_fn(sd appsrc)
    data file_frames#1
    const stage_file_frames^file_frames
    data file_frames_portions#1
         #implementation for frame with length, like at mkv
    const stage_file_frames_portions^file_frames_portions
    sd eventbox
    setcall eventbox stage_nthwidgetFromcontainer(file_frames)
    if eventbox!=0
        sd d%stage_file_dialog
        data false=0
        if d#==false
            return false
        endif

        import "stage_get_fr_length" stage_get_fr_length
        if file_frames_portions==0
            setcall file_frames_portions stage_get_fr_length(eventbox)
            call stage_progress_dialog_inc(file_frames)
        endif
        dec file_frames_portions
        if file_frames_portions==0
            inc file_frames
        endif

        sd pixbuf
        sd w
        sd h

        sd ptr_pack^pixbuf
        call stage_file_frame_main_set(ptr_pack,eventbox)

        sd framesize
        setcall framesize stage_frame_size(w,h)

        import "memoryalloc" memoryalloc
        sd mem
        sd mem_ptr^mem
        sd err
        sd noerr=noerror
        setcall err memoryalloc(framesize,mem_ptr)
        if err!=noerr
            call stage_file_close()
            return false
        endif

        call stage_prepare_pixbuf(pixbuf,mem,w,h)

        importx "_gst_app_buffer_new" gst_app_buffer_new
        data free_fn^free
        sd buffer
        setcall buffer gst_app_buffer_new(mem,framesize,free_fn,mem)

        ss capsformat="video/x-raw-rgb,width=%u,height=%u,bpp=%u,endianness=4321,red_mask=0xFF000000,green_mask=0xFF0000,blue_mask=0xFF00,framerate=%u/1"
        char capsdata#200
        str gstcaps^capsdata
        sd bpp=stage_bpp
        sd fps
        import "stage_file_options_fps" stage_file_options_fps
        setcall fps stage_file_options_fps()
        call sprintf(gstcaps,capsformat,w,h,bpp,fps)

        importx "_gst_caps_from_string" gst_caps_from_string
        sd caps
        setcall caps gst_caps_from_string(gstcaps)

        importx "_gst_buffer_set_caps" gst_buffer_set_caps
        call gst_buffer_set_caps(buffer,caps)

        importx "_gst_caps_unref" gst_caps_unref
        call gst_caps_unref(caps)

        sd flow
        sd ptr_flow^flow
        importx "_g_signal_emit_by_name" g_signal_emit_by_name
        str push="push-buffer"
        call g_signal_emit_by_name(appsrc,push,buffer,ptr_flow)
        importx "_gst_mini_object_unref" gst_mini_object_unref
        call gst_mini_object_unref(buffer)
        data ok=GST_FLOW_OK
        if flow<ok
            str notok="The flow is not ok."
            call texter(notok)
            call stage_file_close()
            return false
        endif

        setcall eventbox stage_nthwidgetFromcontainer(file_frames)
        if eventbox==0
            #state must be play or pause
            importx "_gst_app_src_end_of_stream" gst_app_src_end_of_stream
            call gst_app_src_end_of_stream(appsrc)

            import "save_inform_saved" save_inform_saved
            data location#1
            const stage_file_path^location
            call save_inform_saved(location)
        endif
    endif
    #timeout stop
    return false
endfunction
function stage_file_need(sd appsrc,sd *arg1,sd *data)
    importx "_gdk_threads_add_timeout" gdk_threads_add_timeout
    #set a timeout to allow the progress bar redrawing
    data msec=0
    data f^stage_file_need_fn
    call gdk_threads_add_timeout(msec,f,appsrc)
endfunction

import "connect_signal" connect_signal

function stage_file_connects(sd bus)
    data er^stage_file_error
    str ermsg="message::error"
    call connect_signal(bus,ermsg,er)
    data es^stage_file_eos
    str esmsg="message::eos"
    call connect_signal(bus,esmsg,es)
endfunction

function stage_file_command(ss command)
    #creates the pipe
    import "launch_pipe_start" launch_pipe_start
    sd pipe
    setcall pipe launch_pipe_start(command)
    if pipe==0
        return 0
    endif

    #connect pipe error messages
    import "bus_signals" bus_signals
    data connects^stage_file_connects
    call bus_signals(pipe,connects)

    #connect appsrc to add pixbufs
    importx "_gst_bin_get_by_name" gst_bin_get_by_name
    ss srcname
    setcall srcname stage_get_src_name()
    sd appsrc
    setcall appsrc gst_bin_get_by_name(pipe,srcname)
    ss need="need-data"
    data start^stage_file_need
    call connect_signal(appsrc,need,start)
    #set frames queue size
    #use the first frame to set the frames queue size
    sd firstframe
    setcall firstframe stage_nthwidgetFromcontainer(0)
    sd pixbuf
    sd w
    sd h
    sd ptr_pack^pixbuf
    call stage_file_frame_main_set(ptr_pack,firstframe)
    sd queue
    setcall queue stage_frame_size(w,h)
    data queueframes=1
    mult queue queueframes
    importx "_gst_app_src_set_max_bytes" gst_app_src_set_max_bytes
    call gst_app_src_set_max_bytes(appsrc,queue)

    #launch a modal progress bar
    data inits^stage_file_dialog_inits
    call stage_progress_dialog(inits)

    #state null appsrc and unref
    importx "_gst_object_unref" gst_object_unref
    call gst_object_unref(appsrc)
    #state null pipe, remove the watch and unref the pipe
    import "default_unref" default_unref
    call default_unref(pipe)
endfunction

function stage_save_all()
    #verify for one frame and not mass remove
    import "frame_jobs" frame_jobs
    sd bool
    setcall bool frame_jobs()
    if bool!=1
        return 0
    endif

    #file format
    sd format
    import "stage_file_get_format" stage_file_get_format
    setcall format stage_file_get_format()
    import "cmpmem" cmpmem

    str mk="mkv"
    sd cmp
    setcall cmp cmpmem(format,mk,3)
    if cmp==(equalCompare)
        import "mkvfile" mkvfile
        call mkvfile((capture_flag_off))
        return 1
    endif

    import "is_local_avi" is_local_avi
    setcall bool is_local_avi()
    if bool==1
        import "aviwrite" aviwrite
        call aviwrite(0)
        return 1
    endif

    import "slen" slen
    str mp4="mp4"
    setcall cmp cmpmem(format,mp4,3)
    if cmp==(equalCompare)
        import "mp4_write" mp4_write
        call mp4_write()
        return 1
    endif

    data file_frames%stage_file_frames
    set file_frames# 0
    data file_frames_portions%stage_file_frames_portions
    set file_frames_portions 0

    ss pipeformat="appsrc is-live=true name=%s ! ffmpegcolorspace ! %s ! filesink location=\"%s\""
    ss srcname
    ss outformat
    ss location
    sd *=0
    sd strings^pipeformat

    setcall srcname stage_get_src_name()
    import "stage_file_get_format_name" stage_file_get_format_name
    setcall outformat stage_file_get_format_name()

    import "save_destination" save_destination
    setcall location save_destination(format)
    data copy%stage_file_path
    set copy# location

    import "allocsum_null" allocsum_null
    sd mem
    sd ptr_mem^mem
    sd err
    data noerr=noerror
    setcall err allocsum_null(strings,ptr_mem)
    if err!=noerr
        return err
    endif

    call sprintf(mem,pipeformat,srcname,outformat,location)

    call stage_file_command(mem)

    call free(mem)
endfunction


#bool
function stage_jpeg_write(sd file,sd pixbuf)
    import "jpeg_quality" jpeg_quality
    sd quality
    setcall quality jpeg_quality((value_get))

    #flip the value, so 1 is best 900 is lowest
    import "rule3_two_offsets" rule3_two_offsets
    setcall quality rule3_two_offsets((jpeg_min_quality),quality,(jpeg_max_quality),(jpeg_max_quality),(jpeg_min_quality))

    import "write_jpeg" write_jpeg
    sd bool
    setcall bool write_jpeg(file,pixbuf,quality)
    return bool
endfunction






function av_frames(sd action,sd value)
    data image_nr#1
    if action==(value_set)
        set image_nr value
    elseif action==(value_get)
        return image_nr
    else
        #const get_buffer=value_extra
    #0/pixbuf
        #image_nr = frame index
        sd eventbox
        setcall eventbox stage_nthwidgetFromcontainer(image_nr)
        if eventbox==0
            return 0
        endif

        sd pix
        setcall pix object_get_dword_name(eventbox)

        return pix
    endelse
endfunction

#return width*height
function av_frames_mainpixbuf_sizes(sd wh)
    import "pixbuf_get_wh" pixbuf_get_wh
    sd w
    sd h
    sd _w_h_^w
    sd pixbuf
    setcall pixbuf av_frames((get_buffer))
    call pixbuf_get_wh(pixbuf,_w_h_)
    import "cpymem" cpymem
    call cpymem(wh,_w_h_,(2*4))
    sd imagesize
    set imagesize w
    #rgb=3 bytes
    mult imagesize 3
    mult imagesize h
    return imagesize
endfunction

function av_good_fps(sd ptr_fps)
    if ptr_fps#==0
        set ptr_fps# 1
        str fpsnotzero="Frames-per-second can not be 0"
        call texter(fpsnotzero)
    endif
endfunction


import "alloc_block" alloc_block

function stage_read_values(sd action,sd append,sd append_size)
    data mem#1
    data size#1
    if action==(value_set)
    #bool
        setcall mem alloc_block((value_set))
        if mem==0
            return 0
        endif
        set size 0
        return 1
    elseif action==(value_unset)
        call free(mem)
    elseif action==(value_append)
    #bool
        sd appendresult
        setcall appendresult alloc_block((value_append),mem,size,append,append_size)
        if appendresult==0
            return 0
        endif
        set mem appendresult
        add size append_size
        return 1
    elseif action==(value_write)
        sd cursor
        set cursor mem
        sd pixbuf
        sd frames
        while size!=0
            set pixbuf cursor#
            sub size 4
            add cursor 4

            set frames cursor#
            sub size 4
            add cursor 4

            #add to stage
            import "stage_new_frame_with_timelength" stage_new_frame_with_timelength
            call stage_new_frame_with_timelength(pixbuf,frames)
        endwhile
    else
    #if action==(value_custom)
    #increment the last frame length
    #bool
        if size==0
            return 0
        endif
        sd pointer
        set pointer mem
        add pointer size
        sub pointer 4
        inc pointer#
        return 1
    endelse
endfunction




function stage_files_read()
    import "filechooserfield" filechooserfield
    sd filename
    setcall filename filechooserfield()
    if filename==0
        return 0
    endif

    import "path_extension" path_extension
    ss extension
    setcall extension path_extension(filename)
    sd length
    setcall length slen(extension)
    sd format=format_raw
    if length==3
        sd compare
        str avi="avi"
        setcall compare cmpmem(avi,extension,3)
        if compare==(equalCompare)
            set format (format_avi)
        else
            str mkv="mkv"
            setcall compare cmpmem(mkv,extension,3)
            if compare==(equalCompare)
                set format (format_mkv)
            endif
        endelse
    endif

    import "aviread" aviread
    import "stage_mkv_read" stage_mkv_read
    import "capture_raw_read" capture_raw_read
    if format==(format_avi)
        call aviread(filename)
    elseif format==(format_mkv)
        call stage_mkv_read(filename)
    else
        call capture_raw_read(filename)
    endelse

    #redraw the visual sound pulse
    import "sound_pixbuf_redraw" sound_pixbuf_redraw
    call sound_pixbuf_redraw()

    call free(filename)
endfunction



