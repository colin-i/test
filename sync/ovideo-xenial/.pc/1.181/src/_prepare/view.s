


format elfobj

include "../_include/include.h"

#inits

function stage_buttons_enter(sd container)
        #newuri
    chars button="new.bmp"
    chars *="Creates a blank new media"
    data *^stage_prepare_blank
        #
    chars *="newuri.bmp"
    chars *="Open the media from the uri bar"
    data *^stage_prepare_uri_start
        #
    import "stage_preview" stage_preview
    chars *="preview.bmp"
    chars *="Preview the stage"
    data *^stage_preview
        #
    import "stage_pause" stage_pause
    chars *="pause.bmp"
    chars *="Pause the preview"
    data *^stage_pause
        #
    chars *="close.bmp"
    chars *="Close the stage bar"
    data *^stage_buttons_close
        #
    data *=0
        #
    import "stage_save_all" stage_save_all
    chars *="file.bmp"
    chars *="Save the stage to a file"
    data *^stage_save_all
        #
    import "av_expand" av_expand
    chars *="expand.bmp"
    chars *="Expand a mp4 or avi(i420,mjpeg,mpg4-asp) file"
    data *^av_expand
        #
    import "stage_file_options" stage_file_options
    chars *="fileoptions.bmp"
    chars *="Set the stage file options"
    data *^stage_file_options
        #
    data *=0
        #
    import "stage_files_read" stage_files_read
    chars *="open.bmp"
    chars *="Append a file created with mkv(i420,mjpeg,rgb24), avi(i420,mjpeg), raw capture output format"
    data *^stage_files_read
        #
    import "stage_sound" stage_sound
    chars *="sound.bmp"
    chars *="Add sound to be used at mkv, avi(i420,mjpeg,mpg4-asp) or mp4 files"
    data *^stage_sound
        #
    data *=0
        #
    import "capture" capture
    chars *="capture.bmp"
    chars *="Screen capture"
    data *^capture
        #
    data *=0
        #
    import "stage_new_frame_form" stage_new_frame_form
    chars *="add.bmp"
    chars *="Add a new frame selecting width,height and color"
    data *^stage_new_frame_form
        #
    import "stage_new_frame" stage_new_frame
    chars *="addfromfile.bmp"
    chars *="Add a new frame from a file"
    data *^stage_new_frame
        #
    import "stage_remove" stage_remove
    chars *="remove.bmp"
    chars *="Remove the selected frame"
    data *^stage_remove
        #
    import "mass_remove" mass_remove
    chars *="removeframes.bmp"
    chars *="Remove a frames interval"
    data *^mass_remove
        #
    import "stage_frame_time" stage_frame_time
    chars *="ftime.bmp"
    chars *="Modify the frame time"
    data *^stage_frame_time
        #
    import "stage_split_frame" stage_split_frame
    chars *="split.bmp"
    chars *="Split the selection into two parts"
    data *^stage_split_frame
        #
    import "stage_frame_equalize" stage_frame_equalize
    chars *="equalize.bmp"
    chars *="Equalize the frames lengths starting with selection; last interval frame can be truncated"
    data *^stage_frame_equalize
        #
    data *=0
        #
    import "stage_frame_panel_open" stage_frame_panel_open
    chars *="framepanel.bmp"
    chars *="Open the frame panel"
    data *^stage_frame_panel_open
        #
    data *=0
        #
    import "stage_fade" stage_fade
    chars *="fade.bmp"
    chars *="Fade In/Fade Out effects"
    data *^stage_fade
        #
    import "stage_move" stage_move
    chars *="move.bmp"
    chars *="Move In/Move Out effects"
    data *^stage_move
        #
    import "stage_cover_panel_open" stage_cover_panel_open
    chars *="cover_effects.bmp"
    chars *="Uncover/Cover effects"
    data *^stage_cover_panel_open
        #
    import "stage_effect_scale" stage_effect_scale
    chars *="scale_effect.bmp"
    chars *="Scale In/Scale Out effects"
    data *^stage_effect_scale
        #
    data *=0
        #
    data *=0

    sd ptr^button
    import "buttons_lots" buttons_lots
    call buttons_lots(ptr,container)
endfunction








import "stagewidget" stagewidget

importx "_gtk_widget_destroy" gtk_widget_destroy

#free pixbufs
function unref_pixbuf_frame(sd widget,sd *data)
    import "object_get_dword_name" object_get_dword_name
    sd pixbuf
    setcall pixbuf object_get_dword_name(widget)
    importx "_g_object_unref" g_object_unref
    call g_object_unref(pixbuf)
endfunction


#free pipe and pbufs
function stage_container_destroy(sd object,sd *data)
    data null=0
    import "stage_get_pipeline" stage_get_pipeline
    sd pipe
    setcall pipe stage_get_pipeline()
    if pipe!=null
        import "default_unref" default_unref
        call default_unref(pipe)
    endif

    importx "_gtk_container_foreach" gtk_container_foreach
    data f^unref_pixbuf_frame
    data n=0
    call gtk_container_foreach(object,f,n)
endfunction


importx "_gtk_widget_set_sensitive" gtk_widget_set_sensitive

import "stage_frame_time_numbers" stage_frame_time_numbers

import "stage_sel_prepare_img_space" stage_sel_prepare_img_space

function stage_scroll()
    data scroll#1
    return #scroll
endfunction

#clean the stage
function stage_clean()
    #delete the container and trigger the destroy signal for closing the pipeline and freeing the pixbufs
    sd scroll
    setcall scroll stage_scroll()
    import "firstwidgetFromcontainer" firstwidgetFromcontainer
    sd widget
    setcall widget firstwidgetFromcontainer(scroll#)

    #if exists only
    if widget!=0
##########################
        #set selection to 0 to stop the redrawings
        call stage_sel_prepare_img_space()
        #destroy the frame container
        call gtk_widget_destroy(widget)
        #free frame lengths
        call stage_frame_time_numbers((stage_frame_time_free))
        #stop the preview
        call stage_pause()
        #free the sound
        import "stage_sound_alloc_free" stage_sound_alloc_free
        call stage_sound_alloc_free()
############################
    endif
endfunction

import "hboxfield_cnt" hboxfield_cnt
import "vboxfield_pack" vboxfield_pack
importx "_gtk_widget_show_all" gtk_widget_show_all
import "hseparatorfield" hseparatorfield
importx "_gtk_widget_set_size_request" gtk_widget_set_size_request

#prepare the stage
function stage_prepare()
    #clean previous if exists
    call stage_clean()

####################
    #init the frame lengths
    call stage_frame_time_numbers((stage_frame_time_init))

    #init the sound container
    import "stage_sound_alloc_init" stage_sound_alloc_init
    call stage_sound_alloc_init()

    #these two: the pipeline and the frames container, are initialized here and closed when the stage is closed
    import "stage_set_pipeline" stage_set_pipeline
    call stage_set_pipeline(0)

    #visual for frames and sound
    sd min_size
    setcall min_size stage_trace_min_size_get()
    importx "_gtk_vbox_new" gtk_vbox_new
    import "container_add" container_add
    sd ptr_scroll
    setcall ptr_scroll stage_scroll()
    sd scroll
    set scroll ptr_scroll#
    sd scroll_height
    set scroll_height min_size
    mult scroll_height 2
    add scroll_height (10+10+10)
    call gtk_widget_set_size_request(scroll,-1,scroll_height)
    sd vbox
    setcall vbox gtk_vbox_new(0,0)
    call container_add(scroll,vbox)
    #frames container
    import "hseparatorfield_nopad" hseparatorfield_nopad
    sd container
    setcall container stage_get_frames_container_pointer()
    import "hboxfield_prepare" hboxfield_prepare
    import "packstart_default" packstart_default
    setcall container# hboxfield_prepare()
    call packstart_default(vbox,container#)
    call gtk_widget_set_size_request(container#,-1,min_size)
    import "connect_signal" connect_signal
    str destroy="destroy"
    data f^stage_container_destroy
    call connect_signal(container#,destroy,f)
    #separator
    call hseparatorfield_nopad(vbox)
    #sound pulse
    import "eventboxfield" eventboxfield
    sd ebox
    sd pulseWidget
    setcall pulseWidget sound_widget()
    setcall pulseWidget# eventboxfield(vbox)
    set ebox pulseWidget#
    call gtk_widget_set_size_request(ebox,-1,min_size)
    importx "_gtk_widget_set_tooltip_markup" gtk_widget_set_tooltip_markup
    str move_info="Hold the left mouse button and drag up to increase the size of the sound pulse or drag down to decrease the size"
    call gtk_widget_set_tooltip_markup(ebox,move_info)
        #on click is the pencil color point
    str press="button-press-event"
    data clickfunction^sound_widget_onclick
    call connect_signal(ebox,press,clickfunction)
        #on mouse moving
    str motion="motion-notify-event"
    data motionfunction^sound_widget_motion
    call connect_signal(ebox,motion,motionfunction)
        #
    import "drawfield_cnt" drawfield_cnt
    sd sound_pixbuf_draw_widget
    setcall sound_pixbuf_draw_widget drawfield_cnt(ebox)
    sd draw_area
    setcall draw_area sound_pixbuf_draw_area()
    set draw_area# sound_pixbuf_draw_widget
    #separator
    call hseparatorfield_nopad(vbox)
    #show all for realize for get size at sound_pixbuf_paint, else: here showall vbox but for some rules showall scroll
    import "mainwidget" mainwidget
    sd mainwd
    setcall mainwd mainwidget()
    call gtk_widget_show_all(mainwd)
        #continue at sound
        #add the pulse pixbuf
    sd pixbuf_location
    setcall pixbuf_location sound_pixbuf()
    set pixbuf_location# 0
    call sound_pixbuf_paint()
        #remove pixbuf at end
    data sound_draw_dest^sound_widget_destroy
    call connect_signal(sound_pixbuf_draw_widget,destroy,sound_draw_dest)
        #expose the pixbuf
    str expose="expose-event"
    data exp^sound_widget_expose
    call connect_signal(sound_pixbuf_draw_widget,expose,exp)

    #set the sel frame to uninit, 0
    call stage_sel_prepare_img_space()
#######################
endfunction
function stage_get_frames_container_pointer()
    data c#1
    return #c
endfunction
function stage_get_frames_container()
    sd c
    setcall c stage_get_frames_container_pointer()
    return c#
endfunction

#prepare a blank stage
function stage_prepare_blank()
    str new="Ready"
    import "texter" texter
    call texter(new)
    call stage_prepare()
endfunction

#prepare the stage and start from the uri
function stage_prepare_uri_start()
    import "stage_frame_dialog_solo" stage_frame_dialog_solo
    call stage_frame_dialog_solo(stage_prepare_uri_init,stage_prepare_uri_set,"Media from uri")
endfunction
function stage_prepare_uri_init(sd vbox)
    importx "_gtk_table_new" gtk_table_new
    importx "_gtk_table_attach" gtk_table_attach
    sd table
    setcall table gtk_table_new(2,2,(FALSE))

    import "labelfield_left_prepare" labelfield_left_prepare
    importx "_gtk_entry_new" gtk_entry_new
    sd entry
    sd store

    setcall entry labelfield_left_prepare("Start frame")
    call gtk_table_attach(table,entry,0,1,0,1,0,0,0,0)
    setcall entry gtk_entry_new()
    call gtk_table_attach(table,entry,1,2,0,1,(GTK_FILL),0,0,0)
    setcall store stage_prepare_uri_first_entry()
    set store# entry

    setcall entry labelfield_left_prepare("Last frame")
    call gtk_table_attach(table,entry,0,1,1,2,0,0,0,0)
    setcall entry gtk_entry_new()
    call gtk_table_attach(table,entry,1,2,1,2,(GTK_FILL),0,0,0)
    setcall store stage_prepare_uri_last_entry()
    set store# entry

    importx "_gtk_container_add" gtk_container_add
    call gtk_container_add(vbox,table)

    import "labelfield_l" labelfield_l
    call labelfield_l("Leave blank for no limit",vbox)
endfunction
function stage_prepare_uri_set()
    sd f_entry
    sd l_entry
    setcall f_entry stage_prepare_uri_first_entry()
    setcall l_entry stage_prepare_uri_last_entry()
    ss text
    sd len
    sd first
    sd last
    setcall first stage_prepare_uri_first()
    setcall last stage_prepare_uri_last()

    importx "_gtk_entry_get_text" gtk_entry_get_text
    import "strtoint_positive" strtoint_positive
    import "slen" slen
    sd bool
    setcall text gtk_entry_get_text(f_entry#)
    setcall len slen(text)
    if len==0
        set first# -1
    else
        setcall bool strtoint_positive(text,first)
        if bool!=(TRUE)
            return (void)
        endif
    endelse
    setcall text gtk_entry_get_text(l_entry#)
    setcall len slen(text)
    if len==0
        set last# -1
    else
        setcall bool strtoint_positive(text,last)
        if bool!=(TRUE)
            return (void)
        endif
    endelse
    sd pos
    setcall pos stage_prepare_uri_pos()
    set pos# 0

    call stage_prepare()
    import "editWidgetBufferForward" editWidgetBufferForward
    import "stage_start_pipe" stage_start_pipe
    data nextFn^stage_start_pipe
    call editWidgetBufferForward(nextFn)
endfunction
function stage_prepare_uri_first_entry()
    data first#1
    return #first
endfunction
function stage_prepare_uri_last_entry()
    data last#1
    return #last
endfunction
function stage_prepare_uri_first()
    data first#1
    return #first
endfunction
function stage_prepare_uri_last()
    data last#1
    return #last
endfunction
function stage_prepare_uri_pos()
    data pos#1
    return #pos
endfunction

#clicks
#stage click
function stage_start(data widget)
const stage_button_const^widget
    data null=0

    #set the prepare button to disable state, can be reenabled if the prepare it's closed
    call gtk_widget_set_sensitive(widget,null)

    call stage_prepare_blank()

    sd vbox
    setcall vbox stagewidget()
    call gtk_widget_show_all(vbox)
endfunction


#close click
function stage_buttons_close(sd *button)
    call stage_clean()

    sd vbox
    setcall vbox stagewidget()
    importx "_gtk_widget_hide_all" gtk_widget_hide_all
    call gtk_widget_hide_all(vbox)

    data b%stage_button_const
    data true=1
    call gtk_widget_set_sensitive(b#,true)
endfunction



import "img_folder_enterleave_data" img_folder_enterleave_data
import "folder_enterleave_data" folder_enterleave_data
import "edit_folder" edit_folder

import "move_to_share_v" move_to_share_v
function img_edit_folder_enterleave_data(sd forward,sd data)
	call move_to_share_v()
	sd df
	sd df2
	set df forward
	set df2 data
	call img_folder_enterleave_data(edit_folder_enterleave_data_forward,#df)
endfunction
function edit_folder_enterleave_data_forward(sv data)
	sd forward
	set forward data#
	add data :
	call edit_folder_enterleave_data(forward,data#)
endfunction

#inits

#at runtime
#creates stage buttons
function stage_buttons()
    data stage_buttons_container#1
    const stage_buttons_container_linker^stage_buttons_container

    data f^stage_buttons_enter
    call edit_folder_enterleave_data(f,stage_buttons_container)
endfunction

function edit_folder_enterleave_data(sd forward,sd data)
    ss e
    setcall e edit_folder()
    call folder_enterleave_data(e,forward,data)
endfunction

#return: edit vbox
function stage_init()
    #add a vbox to the main window
    import "boxwidget" boxwidget
    sd mainbox
    setcall mainbox boxwidget()
    sd vbox
    setcall vbox vboxfield_pack(mainbox)

    #a separator
    call hseparatorfield(vbox)

    #scroll for frames/sound
    import "scrollfield" scrollfield
    sd scroll
    setcall scroll stage_scroll()
    setcall scroll# scrollfield(vbox)
    importx "_gtk_scrolled_window_set_policy" gtk_scrolled_window_set_policy
    data always=GTK_POLICY_ALWAYS
    data auto=GTK_POLICY_AUTOMATIC

    call gtk_scrolled_window_set_policy(scroll#,always,auto)

    #alignment for buttons
    import "alignmentfield" alignmentfield
    data alignment#1
    setcall alignment alignmentfield(vbox)
    sd hbox%stage_buttons_container_linker
    setcall hbox# hboxfield_cnt(alignment)

    call stage_vbox(0,vbox)

    return vbox
endfunction

function stage_vbox(sd part,sd value)
    data vbox#1
    if part==0
        set vbox value
    else
        return vbox
    endelse
endfunction

#new panel returned
function stage_new_panel(sd lots,sd trigbutton,sd callbackfunc,sd callbackdata,sd closefunc)
    sd vbox
    setcall vbox stage_vbox(1)

    import "linked_instance" linked_instance
    sd newpanel
    setcall newpanel linked_instance(vbox,lots,trigbutton,callbackfunc,callbackdata,closefunc)

    import "widget_get_ancestor" widget_get_ancestor
    sd ancestor
    setcall ancestor widget_get_ancestor(trigbutton,vbox)

    import "widget_position_in_container" widget_position_in_container
    sd pos
    setcall pos widget_position_in_container(ancestor,vbox)

    importx "_gtk_box_reorder_child" gtk_box_reorder_child
    call gtk_box_reorder_child(vbox,newpanel,pos)

    return newpanel
endfunction



function stage_display_last()
    import "stage_get_frames" stage_get_frames
    sd pos
    setcall pos stage_get_frames()

    #display the selection
    dec pos
    import "stage_nthwidgetFromcontainer" stage_nthwidgetFromcontainer
    sd ebox
    setcall ebox stage_nthwidgetFromcontainer(pos)
    import "stage_display_pixbuf" stage_display_pixbuf
    call stage_display_pixbuf(ebox)
endfunction




#######sound view

function sound_widget()
    data widget#1
    return #widget
endfunction

importx "_gdk_window_get_height" gdk_window_get_height

#min size ptr
function stage_trace_min_size()
    data min_size#1
    return #min_size
endfunction
#min size
function stage_trace_min_size_get()
    sd sz
    setcall sz stage_trace_min_size()
    return sz#
endfunction
function stage_trace_min_size_set()
    sd sz
    setcall sz stage_trace_min_size()
    setcall sz# stage_init_frame_sizes()
endfunction
#min size
function stage_init_frame_sizes()
    ss normalframe
    import "unselectedframe" unselectedframe
    setcall normalframe unselectedframe()
    import "pixbuf_from_file" pixbuf_from_file
    sd frame_width
    setcall frame_width stage_frame_width()
    #
    sd pixbuf
    setcall pixbuf pixbuf_from_file(normalframe)
    if pixbuf==0
        set frame_width# 10
        return 25
    endif
    importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
    setcall frame_width# gdk_pixbuf_get_width(pixbuf)
    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
    sd height
    setcall height gdk_pixbuf_get_height(pixbuf)
    add height 5
    call g_object_unref(pixbuf)
    return height
endfunction
#free size
function sound_widget_free_size()
    import "drawwidget" drawwidget
    importx "_gtk_widget_get_window" gtk_widget_get_window
    sd drawW
    setcall drawW drawwidget()
    #get size
    sd drawWindow
    setcall drawWindow gtk_widget_get_window(drawW)
    sd height
    setcall height gdk_window_get_height(drawWindow)
    sub height 35
    return height
endfunction

function sound_widget_last_point()
    data last_point#1
    return #last_point
endfunction
function sound_widget_last_point_set(sd value)
    sd p
    setcall p sound_widget_last_point()
    set p# value
endfunction
function sound_widget_last_point_get()
    sd p
    setcall p sound_widget_last_point()
    return p#
endfunction

import "eventbutton_get_coords" eventbutton_get_coords

#bool false, continue events
function sound_widget_onclick(sd *ebox,sd event,sd *data)
    #set last point for resizing if mouse move
    sd lp
    setcall lp sound_widget_last_point()
    call eventbutton_get_coords(event,lp)
    return (TRUE)
endfunction

importx "_gtk_widget_size_request" gtk_widget_size_request
#bool false to continue
function sound_widget_motion(sd *widget,sd EventMotion,sd *data)
    sd state
    sd p_state^state
    importx "_gdk_event_get_state" gdk_event_get_state
    call gdk_event_get_state(EventMotion,p_state)
    and state (GDK_BUTTON1_MASK)
    if state!=0
        #left is pressed, verify next step for resizing
        sd current_point
        call eventbutton_get_coords(EventMotion,#current_point)
        sd last_point
        setcall last_point sound_widget_last_point_get()
        #new size will be dif+old size, dif can also be negative
        sd dif
        set dif current_point
        sub dif last_point
        #up is bigger down is smaller
        mult dif -1
        #
        sd sd_wid
        setcall sd_wid sound_widget()
        sd width
        sd height
        sd requisition^width
        call gtk_widget_size_request(sd_wid#,requisition)
        #
        add height dif
        #verify with the limits
        sd min_size
        setcall min_size stage_trace_min_size_get()
        if height<min_size
            return (TRUE)
        endif
        sd free_space
        setcall free_space sound_widget_free_size()
        if dif>free_space
            return (TRUE)
        endif
        #ok to resize
        #resize the sound box
        call sound_widget_last_point_set(current_point)
        call gtk_widget_set_size_request(sd_wid#,-1,height)
        #resize the scroll ancestor
        sd scroll
        setcall scroll stage_scroll()
        sd wd
        sd hg
        sd req^wd
        call gtk_widget_size_request(scroll#,req)
        add hg dif
        call gtk_widget_set_size_request(scroll#,wd,hg)
        #paint the pixbuf
        call sound_pixbuf_paint()
    endif
    return (TRUE)
endfunction

function sound_widget_destroy()
    sd pixbuf_location
    setcall pixbuf_location sound_pixbuf()
    if pixbuf_location#!=0
        call g_object_unref(pixbuf_location#)
    endif
endfunction

import "fild" fild
#true to not propagate
function sound_widget_expose(sd drawWd,sd ev_expose,sd *data)
    sd pixbuf_location
    setcall pixbuf_location sound_pixbuf()
    sd pixbuf
    set pixbuf pixbuf_location#
    if pixbuf!=0
        importx "_gdk_cairo_create" gdk_cairo_create
        importx "_gdk_cairo_set_source_pixbuf" gdk_cairo_set_source_pixbuf
        importx "_cairo_paint" cairo_paint
        importx "_cairo_destroy" cairo_destroy
        import "structure_get_int" structure_get_int

        sd left
        setcall left structure_get_int(ev_expose,(ev_expose_left))
        sd width
        setcall width structure_get_int(ev_expose,(ev_expose_width))
        sd px_width
        setcall px_width gdk_pixbuf_get_width(pixbuf)
        sd px_height
        setcall px_height gdk_pixbuf_get_height(pixbuf)

        sd right
        set right left
        add right width
        if right>px_width
            set width px_width
            sub width left
        endif

        #width can come wrong
        if width<=0
            return (TRUE)
        endif
        importx "_gdk_pixbuf_new_subpixbuf" gdk_pixbuf_new_subpixbuf
        sd expose_pixbuf
        setcall expose_pixbuf gdk_pixbuf_new_subpixbuf(pixbuf,left,0,width,px_height)
        if expose_pixbuf!=0
            import "fstp_quad" fstp_quad
            sd double_x_low
            sd double_x_high
            call fild(#left)
            call fstp_quad(#double_x_low)

            sd window
            setcall window gtk_widget_get_window(drawWd)
            sd cairo
            setcall cairo gdk_cairo_create(window)
                                             #cr    px    double x                   double y
            call gdk_cairo_set_source_pixbuf(cairo,expose_pixbuf,double_x_low,double_x_high,0,0)
            call cairo_paint(cairo)
            call cairo_destroy(cairo)

            call g_object_unref(expose_pixbuf)
        endif
    endif
    return (FALSE)
endfunction


#painting the pulse pixbuf

function sound_pixbuf()
    data pixbuf#1
    return #pixbuf
endfunction

function stage_frame_width()
    data frame_size#1
    return #frame_size
endfunction

function sound_pixbuf_draw_area()
    data draw_area#1
    return #draw_area
endfunction

function sound_pixbuf_redraw()
    call sound_pixbuf_paint()
    sd px
    setcall px sound_pixbuf()
    if px#!=0
        import "widget_redraw" widget_redraw
        sd draw
        setcall draw sound_pixbuf_draw_area()
        sd px_width
        setcall px_width gdk_pixbuf_get_width(px#)
        call gtk_widget_set_size_request(draw#,px_width,-1)
        call widget_redraw(draw#)
    endif
endfunction

function sound_pixbuf_paint()
    sd width
    sd height
    sd soundWd
    setcall soundWd sound_widget()
    sd requisition^width
    call gtk_widget_size_request(soundWd#,requisition)
    #
    import "stage_sound_subsize" stage_sound_subsize
    import "stage_file_options_fps" stage_file_options_fps
    sd fps
    sd sound_size
    setcall fps stage_file_options_fps()
    setcall sound_size stage_sound_subsize((value_get))
    #
    import "stage_sound_blockalign" stage_sound_blockalign
    import "stage_sound_rate" stage_sound_rate
    sd all_samples
    set all_samples sound_size
    divcall all_samples stage_sound_blockalign()
    #
    import "stage_sound_channels" stage_sound_channels
    import "stage_sound_bps" stage_sound_bps
    sd nr_of_channels
    setcall nr_of_channels stage_sound_channels((value_get))
    sd sample_rate
    setcall sample_rate stage_sound_rate((value_get))
    sd bps
    setcall bps stage_sound_bps((value_get))
    if bps!=8
        if bps!=16
            return (void)
        endif
    endif
    #
    sd frame_width
    setcall frame_width stage_frame_width()
    sd a_second_video_width
    set a_second_video_width frame_width#
    mult a_second_video_width fps
    #width=all_samples x a_second_video_width
    #      sample_rate
    import "fimul" fimul
    import "fidiv" fidiv
    import "fst_quad" fst_quad
    import "fistp" fistp
    import "fmul_quad" fmul_quad
    #store the fraction for fast use
    sd fraction#2
    call fild(#a_second_video_width)
    call fidiv(#sample_rate)
    call fst_quad(#fraction)
    #
    call fimul(#all_samples)
    call fistp(#width)
    #rounding AND to see the area at 0
    add width 10
    #
    import "new_pixbuf" new_pixbuf
    sd pixbuf
    setcall pixbuf new_pixbuf(width,height)
    if pixbuf!=0
        importx "_gdk_pixbuf_fill" gdk_pixbuf_fill
        call gdk_pixbuf_fill(pixbuf,0xffFFffFF)
        #sound pulse
        #draw all samples
        import "stage_sound_alloc_getbytes" stage_sound_alloc_getbytes

        ss sound_bytes_cursor
        setcall sound_bytes_cursor stage_sound_alloc_getbytes()

        sd bytespersample
        set bytespersample bps
        div bytespersample 8
        #
        importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
        import "rgb_get_rowstride" rgb_get_rowstride
        sd half
        set half height
        div half 2
        sd pixels
        setcall pixels gdk_pixbuf_get_pixels(pixbuf)
        sd stride
        setcall stride rgb_get_rowstride(width)
        sd x
        sd y
        sd value
        sd value_max
        sd y_sens
        #
        sd i=0
        while i!=all_samples
            call fild(#i)
            call fmul_quad(#fraction)
            call fistp(#x)
            sd channels=0
            while channels!=nr_of_channels
                if bps==8
                    set value_max 0x7f
                    set value sound_bytes_cursor#
                    if value>=0x80
                        sub value 0x80
                        set y_sens -1
                    else
                        #flip the value
                        mult value -1
                        add value 0x7f
                        set y_sens 1
                    endelse
                    inc sound_bytes_cursor
                else
                #if bps==16
                    import "short_get_to_int" short_get_to_int
                    set value_max 0x7fFF
                    setcall value short_get_to_int(sound_bytes_cursor)
                    if value>=0
                        set y_sens -1
                    else
                        mult value -1
                        dec value
                        set y_sens 1
                    endelse
                    add sound_bytes_cursor 2
                endelse
                #a     value
                #half  value_max
                sd number
                set number value
                mult number half
                div number value_max
                mult number y_sens

                sd y_last
                set y_last half
                add y_last number

                set y half
                if y==y_last
                    #do at least a dot
                    add y_last y_sens
                endif

                while y!=y_last
                    #
                    ss pixels_cursor
                    set pixels_cursor pixels
                    sd rows
                    set rows y
                    mult rows stride
                    add pixels_cursor rows
                    sd lines
                    set lines x
                    mult lines 3
                    add pixels_cursor lines
                    set pixels_cursor# 0
                    inc pixels_cursor
                    set pixels_cursor# 0
                    inc pixels_cursor
                    set pixels_cursor# 0
                    #
                    add y y_sens
               endwhile
               inc channels
           endwhile
           inc i
        endwhile
        #set for expose
        sd pixbuf_location
        setcall pixbuf_location sound_pixbuf()
        if pixbuf_location#!=0
            call g_object_unref(pixbuf_location#)
        endif
        set pixbuf_location# pixbuf
    endif
endfunction
