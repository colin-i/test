


format elfobj

include "../_include/include.h"

importx "_sprintf" sprintf

import "stage_get_frames_container" stage_get_frames_container

#get the number of frames
function stage_get_frames()
    #write the number of frames
    sd box
    setcall box stage_get_frames_container()

    import "widget_get_children_number" widget_get_children_number
    sd elements
    setcall elements widget_get_children_number(box)
    return elements
endfunction

#display the index of frames and the string
function stage_display_index(ss string,sd add)
    sd elements
    setcall elements stage_get_frames()

    dec elements
    add elements add

    import "strdworddisp" strdworddisp

    call strdworddisp(string,elements)
endfunction

import "texter" texter

#frame position in stage
function stage_frame_index(sd frame)
    import "widget_position_in_container" widget_position_in_container
    sd box
    setcall box stage_get_frames_container()
    sd pos
    setcall pos widget_position_in_container(frame,box)
    return pos
endfunction

#frame clicked function
function stage_frame_clicked(sd widget,sd event,sd *data)
    #info
    call stage_display_pixbuf(widget)
    #select
    import "stage_frame_unit_select" stage_frame_unit_select
    call stage_frame_unit_select(widget,event)
    #link to mass remove
    import "link_mass_remove" link_mass_remove
    call link_mass_remove((value_write))
endfunction

import "stage_frame_time_numbers" stage_frame_time_numbers

function stage_display_info(sd widget)
    #display the frame position and time informations
    str format="Frame: %u/%u; Time: %u:%02u from %u:%02u; Position: %u from %u"
    chars data#200
    str string^data
    sd length_at_index
    sd length_total

    sd position
    setcall position stage_frame_index(widget)
    #
    sd position_total
    setcall position_total stage_get_frames()
    dec position_total
    #
    import "stage_file_options_fps" stage_file_options_fps
    import "rest" rest
    sd fps
    setcall fps stage_file_options_fps()

    sd seconds_pos
    setcall length_at_index stage_frame_time_numbers((stage_frame_time_sum_at_index),position)
    set seconds_pos length_at_index
    div seconds_pos fps
    sd minutes_pos
    set minutes_pos seconds_pos
    setcall seconds_pos rest(seconds_pos,60)
    div minutes_pos 60
    #
    sd seconds_total
    setcall length_total stage_frame_time_numbers((stage_frame_time_total_sum))
    set seconds_total length_total
    import "multiple_of_nr" multiple_of_nr
    setcall seconds_total multiple_of_nr(seconds_total,fps)
    div seconds_total fps
    sd minutes_total
    set minutes_total seconds_total
    setcall seconds_total rest(seconds_total,60)
    div minutes_total 60
    #
    call sprintf(string,format,position,position_total,minutes_pos,seconds_pos,minutes_total,seconds_total,length_at_index,length_total)
    call texter(string)
endfunction

function stage_display_pixbuf(sd widget)
    #info
    call stage_display_info(widget)

    #select the frame
    import "stage_sel_reparent" stage_sel_reparent
    call stage_sel_reparent(widget)

    #draw the selection
    import "stage_redraw" stage_redraw
    call stage_redraw()
endfunction

function img_folder()
const img_folder_start=!
	chars img="img"
const img_folder_size=!-img_folder_start-1
	return #img
endfunction
function edit_folder()
const edit_folder_start=!
	chars edit="edit"
const edit_folder_size=!-edit_folder_start-1
	return #edit
endfunction
function unselectedframe()
const unselected_bmp_start=!
    vstr frame="frame.bmp"
const unselected_bmp_size=!-unselected_bmp_start-1
    ss file
    setcall file stage_get_image(frame)
    return file
endfunction
function selectedframe()
    vstr frame="sel.bmp"
    ss file
    setcall file stage_get_image(frame)
    return file
endfunction

import "move_to_share_core" move_to_share_core
#name of the img/edit+(image)
function stage_get_image(ss image)
	ss i
	ss e
	setcall i img_folder()
	setcall e edit_folder()
	chars bytes#img_folder_size+1+edit_folder_size+1+unselected_bmp_size+1
	ss file^bytes
	str form="%s/%s/%s"
	call sprintf(file,form,i,e,image)
	call move_to_share_core(#file)
	return file
endfunction

#eventbox
function stage_new_click_area()
    #get frames container
    sd box
    setcall box stage_get_frames_container()
    #eventbox
    import "eventboxfield" eventboxfield
    sd eventbox
    setcall eventbox eventboxfield(box)
    return eventbox
endfunction

import "connect_signal" connect_signal

#add a pixbuf to eventbox
function stage_pixbuf_to_container(sd pixbuf,sd eventbox)
    #set the name of the image to the pixbuf handle for remember at select,scale,free...(more actions can be)
    import "object_set_dword_name" object_set_dword_name
    call object_set_dword_name(eventbox,pixbuf)

    #add one more frame,selection(blue) or normal(white)
    import "stage_sel_img_listen" stage_sel_img_listen
    sd img
    setcall img stage_sel_img_listen(eventbox)
    data null=0
    if img!=null
        call stage_redraw()
    else
        import "stage_unselected_frame" stage_unselected_frame
        setcall img stage_unselected_frame(eventbox)
    endelse

    #add mouse detection to display pixbuf when clicked
    str pressed="button-press-event"
    data f^stage_frame_clicked
    call connect_signal(eventbox,pressed,f)
    importx "_gtk_widget_add_events" gtk_widget_add_events
    sd events=GDK_BUTTON_PRESS_MASK
    call gtk_widget_add_events(eventbox,events)

    #display the widget
    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(eventbox)
endfunction

#add a new frame to the stage
#err
function stage_new_frame_with_timelength(sd pixbuf,sd length)
    #add the frame length at the end
    call stage_frame_time_numbers((stage_frame_time_append),length)

    #add eventbox for mouse detection
    sd eventbox
    setcall eventbox stage_new_click_area()

    #pixbuf to eventbox
    call stage_pixbuf_to_container(pixbuf,eventbox)
endfunction
#add a frame,length=1
function stage_new_pix(sd pixbuf,ss text_ok)
    call stage_new_frame_with_timelength(pixbuf,1)

    #show the message and the received number of frames
    data one=1
    call stage_display_index(text_ok,one)
endfunction
import "default_unref_ptr" default_unref_ptr
#incoming frame arrange
function stage_element(sd *bus,sd message,sd ptrpipeline)
    #get the pixbuf for future usage
    import "msgelement_pixbuf" msgelement_pixbuf
    sd pixbuf
    setcall pixbuf msgelement_pixbuf(message)
    #can be an error
    if pixbuf!=0
        sd skip=0
        #verify with the limits
        import "stage_prepare_uri_pos" stage_prepare_uri_pos
        import "stage_prepare_uri_first" stage_prepare_uri_first
        import "stage_prepare_uri_last" stage_prepare_uri_last
        sd pos
        setcall pos stage_prepare_uri_pos()
        sd first
        sd last
        setcall first stage_prepare_uri_first()
        setcall last stage_prepare_uri_last()
        #
        if first#!=-1
            if pos#<first#
                set skip 1
            endif
        endif
        #
        if last#!=-1
            if pos#>last#
                set skip 2
                call default_unref_ptr(ptrpipeline)
            endif
        endif
        #
		if skip==0
			import "rgb_test" rgb_test
			setcall pixbuf rgb_test(pixbuf)
			if pixbuf!=(NULL)
				vstr text="Received frames: "
				call stage_new_pix(pixbuf,text)
			else
				set skip 1
			endelse
		endif
		if skip!=0
			importx "_g_object_unref" g_object_unref
			call g_object_unref(pixbuf)
			if skip==1
				call strdworddisp("Skipped frame: ",pos#)
			else
				call stage_display_index("Total frames: ",1)
			endelse
		endif
		#
		inc pos#
	endif
endfunction


function stage_eos(sd *bus,sd *message,sd ptrpipeline)
    #display the total number of frames
    str text="Total frames at end of stream: "
    data one=1
    call stage_display_index(text,one)
    call default_unref_ptr(ptrpipeline)
endfunction

function stage_connect_signals(sd bus,sd ptrpipe)
    import "connect_signal_data" connect_signal_data
    #element
    str px="message::element"
    data fn^stage_element
    call connect_signal_data(bus,px,fn,ptrpipe)

    #error
    import "default_error_ptr" default_error_ptr
    data er^default_error_ptr
    str error="message::error"
    call connect_signal_data(bus,error,er,ptrpipe)

    #eos
    data eos^stage_eos
    str eosmsg="message::eos"
    call connect_signal_data(bus,eosmsg,eos,ptrpipe)
endfunction

function stage_start_pipe(ss uri)
#gdkpixbufsink plugins-good
    ss launcher="uridecodebin uri=\"%s\" ! ffmpegcolorspace ! gdkpixbufsink"
    ss str
    sd *=0
    sd strs^launcher

    set str uri

    sd err

    sd mem
    sd ptr_mem^mem

    import "allocsum_null" allocsum_null
    setcall err allocsum_null(strs,ptr_mem)
    if err!=(noerror)
        return err
    endif

    call sprintf(mem,launcher,uri)

    import "launch_pipe_start" launch_pipe_start
    data pipe#1
    sd ptrpipe^pipe
    const stage_pipeline^pipe

    setcall pipe launch_pipe_start(mem)

    importx "_free" free
    call free(mem)
    if pipe==0
        return (void)
    endif

    import "bus_signals_data" bus_signals_data
    data fn^stage_connect_signals
    call bus_signals_data(pipe,fn,ptrpipe)
endfunction

function stage_get_pipeline()
    data s%stage_pipeline
    return s#
endfunction
function stage_set_pipeline(sd value)
    data s%stage_pipeline
    set s# value
endfunction
