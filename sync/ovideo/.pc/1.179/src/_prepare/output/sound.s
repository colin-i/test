

format elfobj

include "../../_include/include.h"

const stage_sound_alloc_init=0
const stage_sound_alloc_free=1
const stage_sound_alloc_expand=2
const stage_sound_alloc_getremainingsize=3
const stage_sound_alloc_getbytes=4
const stage_sound_alloc_printtexter_time=5
const stage_sound_alloc_printdialog_time=6

import "texter" texter

##some variables

function stage_sound_file_entry(sd action,sd value)
    data file_entry#1
    if action==(value_set)
        set file_entry value
    else
        return file_entry
    endelse
endfunction
function stage_sound_file_path(sd action,sd value)
    data path#1
    if action==(value_set)
        set path value
    else
        return path
    endelse
endfunction
function stage_sound_pipe(sd action,sd value)
    data pipe#1
    if action==(value_set)
        set pipe value
    else
        return pipe
    endelse
endfunction
function stage_sound_dialog(sd action,sd value)
    data dialog#1
    if action==(value_set)
        set dialog value
    else
        return dialog
    endelse
endfunction




##main func

function stage_sound()
    sd bool
    import "sound_preview_bool" sound_preview_bool
    sd sound_prev
    setcall sound_prev sound_preview_bool()
    if sound_prev#!=0
        import "sound_preview_end_and_no_errors" sound_preview_end_and_no_errors

        setcall bool sound_preview_end_and_no_errors()
        if bool==(FALSE)
            str er="The sound is on, stop the stage preview first"
            call texter(er)
            return (void)
        endif
    endif

    call stage_sound_file_path((value_set),0)

    #dialog
    importx "_gtk_dialog_new_with_buttons" gtk_dialog_new_with_buttons
    import "mainwidget" mainwidget
    sd window
    setcall window mainwidget()

    str GTK_STOCK_OK="gtk-ok"
    str GTK_STOCK_CLOSE="gtk-close"
    ss title="Sound"

    sd dialog
    setcall dialog gtk_dialog_new_with_buttons(title,window,(GTK_DIALOG_DESTROY_WITH_PARENT|GTK_DIALOG_MODAL),GTK_STOCK_OK,(GTK_RESPONSE_OK),GTK_STOCK_CLOSE,(GTK_RESPONSE_CANCEL),0)

    importx "_gtk_dialog_get_content_area" gtk_dialog_get_content_area
    sd vbox
    setcall vbox gtk_dialog_get_content_area(dialog)
    call stage_sound_init(vbox)

    importx "_gtk_window_set_default_size" gtk_window_set_default_size
    call gtk_window_set_default_size(dialog,500,-1)

    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(dialog)

    #stop flag for imported sound, but is used at print threads environment
    sd stop_flag
    setcall stop_flag sound_stop_flag()
    set stop_flag# 0

    importx "_gtk_dialog_run" gtk_dialog_run
    sd response
    setcall response gtk_dialog_run(dialog)

    importx "_gtk_widget_destroy" gtk_widget_destroy

    if response==(GTK_RESPONSE_OK)
        call stage_sound_set()
        call gtk_widget_destroy(dialog)
        sd filepath
        setcall filepath stage_sound_file_path((value_get))
        if filepath!=0
                #for not messing the sound
            import "mass_remove_job" mass_remove_job
            setcall bool mass_remove_job()
            if bool==1
            #sound import
                call stage_sound_init_appsink(filepath)
            endif
            importx "_g_free" g_free
            call g_free(filepath)
        endif
    else
        call gtk_widget_destroy(dialog)
    endelse
    #redraw the visual sound pulse
    import "sound_pixbuf_redraw" sound_pixbuf_redraw
    call sound_pixbuf_redraw()
endfunction


##the pipe mechanism

function stage_sound_init_appsink(sd filepath)
    #the command for gst-launch
    ss launchformat="filesrc location=\"%s\" ! decodebin2 ! audioconvert ! audioresample ! audio/x-raw-int,channels=%u,rate=%u,signed=(boolean)true,width=%u,depth=%u,endianness=%u ! appsink emit-signals=TRUE sync=false"
    sd flocation
    sd *=0
    str sound_format^launchformat

    #location
    #escape path
    import "string_alloc_escaped" string_alloc_escaped
    ss escapedpath
    setcall escapedpath string_alloc_escaped(filepath)
    if escapedpath==0
        return 0
    endif
    #set
    set flocation escapedpath

    import "allocsum_numbers_null" allocsum_numbers_null
    sd command
    sd p_command^command

    sd err
    setcall err allocsum_numbers_null(sound_format,5,p_command)
    if err!=(noerror)
        return err
    endif

    #concatenate the command
    importx "_sprintf" sprintf
    sd channels
    setcall channels stage_sound_channels((value_get))
    sd rate
    setcall rate stage_sound_rate((value_get))
    sd bps
    setcall bps stage_sound_bps((value_get))
    call sprintf(command,launchformat,flocation,channels,rate,bps,bps,(sound_endian_def))
    sd com
    setcall com stage_sound_comm()
    set com# command
    call stage_sound_command()

    #clean
    importx "_free" free
    call free(escapedpath)
    call free(command)
endfunction
function stage_sound_command()
    #sync mem
    sd global_flag
    setcall global_flag sound_global_flag()
    set global_flag# 1
    sd stop_flag
    setcall stop_flag sound_stop_flag()

    #launch the modal parser
    import "dialogfield_modal_texter_sync" dialogfield_modal_texter_sync
    ss title="Sound"
    data f_init^stage_sound_command_init
    ss button="Stop"
    call dialogfield_modal_texter_sync(title,f_init,button,global_flag,stop_flag)

    #stop and free the pipe
    sd pipe
    setcall pipe stage_sound_pipe((value_get))
    import "default_unref" default_unref
    call default_unref(pipe)
endfunction

function stage_sound_command_init(sd *vbox,sd dialog)
    #keep the dialog for eos at appsink or error at pipe
    call stage_sound_dialog((value_set),dialog)

    #make the pipe
    sd com
    setcall com stage_sound_comm()
    import "launch_pipe_start" launch_pipe_start
    sd pipeline
    setcall pipeline launch_pipe_start(com#)
    if pipeline==0
        return 0
    endif

    #put the pipeline to a static place
    call stage_sound_pipe((value_set),pipeline)

    #add error signal to pipe
    #sd pipe
    #setcall pipe stage_sound_pipe((value_get))
    import "err_signal_modal" err_signal_modal
    data f^stage_sound_closedialog
    call err_signal_modal(pipeline,f)

    import "iterate_firstsink" iterate_firstsink
    #new-buffer signal to appsink, and eos
    data f_newbuffer^stage_sound_connect_appsink
    call iterate_firstsink(pipeline,f_newbuffer)
endfunction

function stage_sound_connect_appsink(sd appsink)
    #new buffer signal
    import "connect_signal" connect_signal
    ss buffer="new-buffer"
    data f_nb^stage_sound_expand
    call connect_signal(appsink,buffer,f_nb)

    #add eos at appsink(sometimes eos comes only here)
    ss eos="eos"
    data f_eos^stage_sound_closedialog
    call connect_signal(appsink,eos,f_eos)
endfunction
#close the dialog when it is called
function stage_sound_closedialog()
	#not in main is here
	importx "_g_idle_add" g_idle_add
	call g_idle_add(stage_sound_realclosedialog,(void))
endfunction
function stage_sound_realclosedialog()
    sd dialog
    setcall dialog stage_sound_dialog((value_get))
    importx "_gtk_dialog_response" gtk_dialog_response
    call gtk_dialog_response(dialog,(GTK_RESPONSE_OK))
    call sound_global_flag_set(0)
endfunction




##user init input

function stage_sound_init(sd vbox)
    #button to add a new sound
    import "fchooserbuttonfield_open_label" fchooserbuttonfield_open_label
    ss text="Open File "
    sd file
    setcall file fchooserbuttonfield_open_label(vbox,text)
    call stage_sound_file_entry((value_set),file)

    import "buttonfield_prepare_with_label" buttonfield_prepare_with_label
    importx "_gtk_table_new" gtk_table_new
    importx "_gtk_table_attach" gtk_table_attach
    sd table
    setcall table gtk_table_new(6,2,0)

    #button to remove all sounds
    ss rem="Remove prepared sound"
    sd button
    setcall button buttonfield_prepare_with_label(rem)
    call gtk_table_attach(table,button,0,1,0,1,(GTK_FILL),0,0,0)
    #add signal
    import "connect_clicked" connect_clicked
    data f^stage_sound_remove
    call connect_clicked(button,f)

    #button to view how much times is in the prepared sound memory
    #add button
    ss view="View prepared sound time"
    sd time
    setcall time buttonfield_prepare_with_label(view)
    call gtk_table_attach(table,time,0,1,1,2,(GTK_FILL),0,0,0)
    #add signal
    data f_viewtime^stage_sound_viewtime
    call connect_clicked(time,f_viewtime)

    #button to cut extra sound time to be equal with the video time
    ss cut="Cut extra sound"
    sd cuttime
    setcall cuttime buttonfield_prepare_with_label(cut)
    call gtk_table_attach(table,cuttime,0,1,2,3,(GTK_FILL),0,0,0)
    #add signal
    data f_cuttime^stage_sound_cut
    call connect_clicked(cuttime,f_cuttime)

    #button to copy sound created with the program Sound Recorder from oapplications
    ss cpy="Copy sound"
    sd copy
    setcall copy buttonfield_prepare_with_label(cpy)
    importx "_gtk_widget_set_tooltip_markup" gtk_widget_set_tooltip_markup
    ss cpy_inf="Copy sound from a wav file with a RIFF,fmt ,data chunks (ex: created with the program Sound Recorder)"
    call gtk_widget_set_tooltip_markup(copy,cpy_inf)
    call gtk_table_attach(table,copy,0,1,3,4,(GTK_FILL),0,0,0)
    #add signal
    data f_copy^stage_sound_copy
    call connect_clicked(copy,f_copy)

    #button to fade out sound
    ss fade="Fade out last two seconds"
    sd fade_button
    setcall fade_button buttonfield_prepare_with_label(fade)
    call gtk_table_attach(table,fade_button,0,1,4,5,(GTK_FILL),0,0,0)
    #add signal
    data f_fade^stage_sound_fade
    call connect_clicked(fade_button,f_fade)

    #button to amplify the sound
    ss amplify="Amplify all sound (%)"
    sd amplify_button
    setcall amplify_button buttonfield_prepare_with_label(amplify)
    call gtk_table_attach(table,amplify_button,0,1,5,6,(GTK_FILL),0,0,0)
    #number
    importx "_gtk_entry_new" gtk_entry_new
    sd entry
    setcall entry gtk_entry_new()
    call gtk_table_attach(table,entry,1,2,5,6,0,0,0,0)
    #add signal
    import "connect_clicked_data" connect_clicked_data
    call connect_clicked_data(amplify_button,stage_amplify,entry)

    #add the table
    import "packstart_default" packstart_default
    call packstart_default(vbox,table)
endfunction
import "rest" rest
import "rule3" rule3
import "multiple_of_nr" multiple_of_nr
import "message_dialog" message_dialog
function stage_sound_remove(sd *widget,sd *data)
    call stage_sound_alloc_free()
    call stage_sound_alloc_init()

    ss done="Removed"
    call message_dialog(done)
endfunction
function stage_sound_viewtime(sd *widget,sd *data)
    call stage_sound_alloc((stage_sound_alloc_printdialog_time))
endfunction
function stage_sound_cut(sd *widget,sd *data)
    import "stage_frame_time_numbers" stage_frame_time_numbers
    sd t_length
    setcall t_length stage_frame_time_numbers((stage_frame_time_total_sum))

    import "stage_file_options_fps" stage_file_options_fps
    sd fps
    setcall fps stage_file_options_fps()

    sd avgbytes_persec
    sd blockalign
    setcall avgbytes_persec stage_sound_avgbytespersec()
    setcall blockalign stage_sound_blockalign()

    #sound time
    sd sound_time
    setcall sound_time stage_sound_framelength_to_soundlength(t_length)

    sd current_sound_size
    setcall current_sound_size stage_sound_subsize((value_get))
    if current_sound_size>sound_time
         call stage_sound_subsize((value_set),sound_time)
         ss ok="Extra sound removed. Sound time is now equal with video time."
         call message_dialog(ok)
    else
        ss not_needed="There is not extra sound. Sound time is lower or equal with video time."
        call message_dialog(not_needed)
    endelse
endfunction
import "file_chooser_get_fname" file_chooser_get_fname
function stage_sound_copy()
    sd fileentry
    setcall fileentry stage_sound_file_entry((value_get))

    sd filename
    setcall filename file_chooser_get_fname(fileentry)

    if filename==0
        return 0
    endif

    import "file_get_content_forward" file_get_content_forward
    data f_copy_sound^stage_sound_copy_action
    call file_get_content_forward(filename,f_copy_sound)

    call g_free(filename)
endfunction
function stage_sound_set()
    sd fileentry
    setcall fileentry stage_sound_file_entry((value_get))

    sd filename
    setcall filename file_chooser_get_fname(fileentry)

    if filename==0
        str no_f="No file name selected"
        call texter(no_f)
        return 0
    endif

    call stage_sound_file_path((value_set),filename)
endfunction

import "cpymem" cpymem

function stage_sound_fade()
    sd fadebytes
    setcall fadebytes stage_sound_avgbytespersec()
    mult fadebytes 2
    sd current_sound_size
    setcall current_sound_size stage_sound_subsize((value_get))

    sd cursor
    if fadebytes>=current_sound_size
        set cursor 0
	set fadebytes current_sound_size
    else
        set cursor current_sound_size
        sub cursor fadebytes
    endelse

    ss bytes
    sd last
    setcall bytes stage_sound_alloc((stage_sound_alloc_getbytes))
    set last bytes
    add bytes cursor
    add last current_sound_size
    sd blockalign
    setcall blockalign stage_sound_blockalign()
    sd BYps
    setcall BYps stage_sound_bps((value_get))
    div BYps 8
    sd channels
    sd rate=0
    sd value
    sd p_value^value
    while bytes!=last
        setcall channels stage_sound_channels((value_get))
        while channels!=0
            sd pos
            if BYps==1
                set value bytes#
                sub value 0x80
            else
                import "short_get_to_int" short_get_to_int
                setcall value short_get_to_int(bytes)
            endelse
	    #x            fadebytes-rate
	    #value        fadebytes

            set pos fadebytes
            sub pos rate
            data double_data#2
            data double^double_data
            import "fild_value" fild_value
            import "fstp_quad" fstp_quad
            import "fmul_quad" fmul_quad
            import "fdiv_quad" fdiv_quad
            import "fistp" fistp
            call fild_value(pos)
            call fstp_quad(double)
            call fild_value(value)
            call fmul_quad(double)
            call fild_value(fadebytes)
            call fstp_quad(double)
            call fdiv_quad(double)
            call fistp(p_value)

            if BYps==1
                add value 0x80
                set bytes# value
            else
                import "int_into_short" int_into_short
                call int_into_short(value,bytes)
            endelse
            add rate BYps
            add bytes BYps
            dec channels
        endwhile
    endwhile
    str fade="End sound faded"
    call message_dialog(fade)
endfunction

function stage_amplify(sd *widget,sd entry)
    import "entry_to_int_min_N_max_M" entry_to_int_min_N_max_M
    sd nr
    sd bool
    setcall bool entry_to_int_min_N_max_M(entry,#nr,1,1000)
    if bool!=(TRUE)
        return (FALSE)
    endif

    call fild_value(nr)
    sd multp#2
    sd procent=100
    import "fidiv" fidiv
    call fidiv(#procent)
    import "fiadd" fiadd
    sd addnr=1
    call fiadd(#addnr)
    call fstp_quad(#multp)

    sd channels
    sd bits_per_sample
    setcall channels stage_sound_channels((value_get))
    setcall bits_per_sample stage_sound_bps((value_get))

    sd sound_size
    setcall sound_size stage_sound_subsize((value_get))
    ss buf
    setcall buf stage_sound_alloc_getbytes()
    sd value
    sd item
    sd all_samples
    set all_samples sound_size
    divcall all_samples stage_sound_blockalign()
    sd pos=0
    while pos<all_samples
        sd chn=0
        while chn<channels
            if bits_per_sample==8
                set item buf#
                if item<0x80
                    set value 0x80
                    sub value item
                else
                    set value item
                    sub value 0x80
                endelse
            elseif bits_per_sample==16
                setcall value short_get_to_int(buf)
            else
                call texter("wrong bits-per-sample")
                return (void)
            endelse
            call fild_value(value)
            call fmul_quad(#multp)
            call fistp(#value)
            sd res_value
            if bits_per_sample==8
                if item<0x80
                    set res_value 0x80
                    sub res_value value
                    if res_value<0
                        set res_value 0
                    endif
                else
                    set res_value 0x80
                    add res_value value
                    if res_value>0xff
                        set res_value 0xff
                    endif
                endelse
                set buf# res_value
                inc buf
            else
            #if bits_per_sample==16
                if value>0x7fFF
                    set res_value 0x7fFF
                elseif value<0xffFF8000
                    set res_value 0xffFF8000
                else
                    set res_value value
                endelse
                call int_into_short(res_value,buf)
                add buf 2
            endelse
            inc chn
        endwhile
        inc pos
    endwhile
    call message_dialog("Amplifyed")
endfunction



##expand and keep for output

function stage_sound_alloc_init()
    call stage_sound_alloc((stage_sound_alloc_init))
endfunction
function stage_sound_alloc_free()
    call stage_sound_alloc((stage_sound_alloc_free))
endfunction
function stage_sound_alloc_expand(sd newblock,sd newblock_size)
    call stage_sound_alloc((stage_sound_alloc_expand),newblock,newblock_size)
endfunction
#sz
function stage_sound_alloc_getremainingsize()
    sd sz
    setcall sz stage_sound_alloc((stage_sound_alloc_getremainingsize))
    return sz
endfunction
#bytes
function stage_sound_alloc_getbytes()
    sd bytes
    setcall bytes stage_sound_alloc((stage_sound_alloc_getbytes))
    return bytes
endfunction

function stage_sound_subsize(sd action,sd value)
    data subsize#1
    if action==(value_set)
        set subsize value
    else
        return subsize
    endelse
endfunction
function stage_sound_alloc(sd action,sd newblock,sd newblock_size)
    import "memoryrealloc" memoryrealloc
    data alloc#1
    data p_alloc^alloc
    data size#1

    if action==(stage_sound_alloc_init)
    #init the memory
        set alloc 0
        set size 0
        call stage_sound_subsize((value_set),0)
        call memoryrealloc(p_alloc,size)
        return 0
    elseif action==(stage_sound_alloc_getremainingsize)
    #get the remaining size
        sd sz
        setcall sz stage_sound_subsize((value_get))
        subcall sz stage_sound_sizedone((value_get))
        return sz
    elseif action==(stage_sound_alloc_getbytes)
        return alloc
    endelseif
    if alloc==0
        return 0
    endif
    if action==(stage_sound_alloc_free)
        call free(alloc)
    elseif action==(stage_sound_alloc_expand)
        sd newsubsize
        setcall newsubsize stage_sound_subsize((value_get))
        add newsubsize newblock_size

        sd newsize
        setcall newsize multiple_of_nr(newsubsize,0x1000)

        if newsize!=size
            sd err
            setcall err memoryrealloc(p_alloc,newsize)
            if err!=(noerror)
                return err
            endif
            set size newsize
        endif

        sd cursor
        set cursor alloc
        addcall cursor stage_sound_subsize((value_get))

        call cpymem(cursor,newblock,newblock_size)

        call stage_sound_subsize((value_set),newsubsize)
    else
    #stage_sound_alloc_printtexter_time
    #stage_sound_alloc_printdialog_time
        sd stop_flag
        setcall stop_flag sound_stop_flag()
        if stop_flag#==1
            #safe close the main thread if stop pressed
            call sound_global_flag_set(0)
            return (void)
        endif

        sd bytespersec
        setcall bytespersec stage_sound_avgbytespersec()

        #seconds
        sd subsize
        setcall subsize stage_sound_subsize((value_get))
        sd seconds
        set seconds subsize
        div seconds bytespersec

        #decimal part
        const numbers=4
        sd bytesrest
        setcall bytesrest rest(subsize,bytespersec)
        sd sec_rest
        setcall sec_rest rule3(bytesrest,bytespersec,(10$numbers-1))

        #print
        const sountformbufstart=!
        chars format="Prepared sound time: %u.%u"
        chars datastring#!-sountformbufstart-2-2+modal_texter_mark
        vstr print^datastring
        call sprintf(print,#format,seconds,sec_rest)
        if action==(stage_sound_alloc_printtexter_time)
            import "dialog_modal_texter_draw" dialog_modal_texter_draw
            call dialog_modal_texter_draw(print)
        else
            #if action==(stage_sound_alloc_printdialog_time)
            call message_dialog(print)
        endelse
    endelse
endfunction

function stage_sound_expand(sd gstappsink,sd *user_data)
    importx "_g_signal_emit_by_name" g_signal_emit_by_name
    ss method="pull-buffer"
    sd buffer
    sd p_buffer^buffer
    call g_signal_emit_by_name(gstappsink,method,p_buffer)

    import "structure_get_int" structure_get_int
    sd data
    sd size

    #GstBuffer
        #GstMiniObject
            #GTypeInstance instance
            #gint refcount
            #guint flags
        #guint8              *data
        #guint               size

    setcall data structure_get_int(buffer,0x10)
    setcall size structure_get_int(buffer,0x14)

    #append the new buffer at the sound memory
    call stage_sound_alloc((stage_sound_alloc_expand),data,size)
    #print time
    call stage_sound_alloc((stage_sound_alloc_printtexter_time))

    importx "_gst_mini_object_unref" gst_mini_object_unref
    call gst_mini_object_unref(buffer)
endfunction


function stage_sound_sizedone(sd action,sd value)
    data done#1
    if action==(value_set)
        set done value
    else
        return done
    endelse
endfunction

function stage_sound_removeframe(sd frame_pos)
    sd start_point
    setcall start_point stage_frame_time_numbers((stage_frame_time_sum_at_index),frame_pos)
    sd sound_sum_at_index
    setcall sound_sum_at_index stage_sound_framelength_to_soundlength(start_point)

    sd length_at_point
    setcall length_at_point stage_frame_time_numbers((stage_frame_time_get_at_index),frame_pos)
    sd sound_at_index
    setcall sound_at_index stage_sound_framelength_to_soundlength(length_at_point)

    sd bytes
    setcall bytes stage_sound_alloc((stage_sound_alloc_getbytes))
    sd soundsize
    setcall soundsize stage_sound_subsize((value_get))
    sd soundtotal
    set soundtotal soundsize

    if sound_sum_at_index>=soundsize
        return 0
    endif

    add bytes sound_sum_at_index

    sub soundsize sound_sum_at_index
    if soundsize<sound_at_index
        set sound_at_index soundsize
    endif

    sd cursor
    set cursor bytes
    add cursor sound_at_index

    sub soundsize sound_at_index
    call cpymem(bytes,cursor,soundsize)

    sub soundtotal sound_at_index
    call stage_sound_subsize((value_set),soundtotal)
endfunction

#soundlength
function stage_sound_framelength_to_soundlength(sd framelength)
    sd fps
    setcall fps stage_file_options_fps()
    sd rest_frame
    setcall rest_frame rest(framelength,fps)
    div framelength fps

    sd bytes_per_sec
    setcall bytes_per_sec stage_sound_avgbytespersec()

    mult framelength bytes_per_sec
    setcall rest_frame rule3(rest_frame,fps,bytes_per_sec)
    #round to multiple of blockalign
    sd blockalign
    setcall blockalign stage_sound_blockalign()
    setcall rest_frame multiple_of_nr(rest_frame,blockalign)

    add framelength rest_frame
    return framelength
endfunction

############################sound values

function stage_sound_channels(sd action,sd value)
    data channels=2
    if action==(value_set)
        set channels value
    else
        return channels
    endelse
endfunction
function stage_sound_rate(sd action,sd value)
    data rate=48000
    if action==(value_set)
        set rate value
    else
        return rate
    endelse
endfunction
function stage_sound_bps(sd action,sd value)
    data bps=16
    if action==(value_set)
        set bps value
    else
        return bps
    endelse
endfunction

function stage_sound_blockalign()
    sd value
    setcall value stage_sound_channels((value_get))
    multcall value stage_sound_bps((value_get))
    div value 8
    return value
endfunction
function stage_sound_avgbytespersec()
    sd value
    setcall value stage_sound_blockalign()
    multcall value stage_sound_rate((value_get))
    return value
endfunction

function sound_get_values(sd mem,sd *size)
    sd mem_sz^mem

    sd value
    sd p_value^value
    import "get_mem_int_advance" get_mem_int_advance
    sd err

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call stage_sound_channels((value_set),value)

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call stage_sound_rate((value_set),value)

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call stage_sound_bps((value_set),value)
endfunction

function stage_sound_copy_action(sd mem,sd *size)
    str r="RIFF"
    str r_ex="WAVE"
    str f="fmt "
    str d="data"
    sd bool
    import "riff_head" riff_head
    sd mem_sz^mem
    sd chunk_size
    sd p_chunk_size^chunk_size

    setcall bool riff_head(mem_sz,r,p_chunk_size,r_ex)
    if bool!=1
        return 0
    endif
    setcall bool riff_head(mem_sz,f,p_chunk_size,0)
    if bool!=1
        return 0
    endif
    import "move_cursors" move_cursors
    call move_cursors(mem_sz,chunk_size)
    setcall bool riff_head(mem_sz,d,p_chunk_size,0)
    if bool!=1
        return 0
    endif

    call stage_sound_alloc_expand(mem,chunk_size)
    call stage_sound_alloc((stage_sound_alloc_printdialog_time))
endfunction


function sound_global_flag()
    data global_flag#1
    data p^global_flag
    return p
endfunction
function sound_global_flag_set(sd value)
    sd global_flag
    setcall global_flag sound_global_flag()
    set global_flag# value
endfunction

function sound_stop_flag()
    data stop_flag#1
    data p^stop_flag
    return p
endfunction

function stage_sound_comm()
    data sound_command#1
    data p^sound_command
    return p
endfunction
