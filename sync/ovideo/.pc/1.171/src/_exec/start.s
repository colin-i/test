



format elfobj

importx "_gtk_window_new" gtk_window_new
importx "_gtk_window_set_title" gtk_window_set_title
importx "_gtk_window_set_default_size" gtk_window_set_default_size
importx "_gtk_main_quit" gtk_main_quit
importx "_gtk_widget_show_all" gtk_widget_show_all

importx "_g_signal_connect_data" g_signal_connect_data

import "vboxfield" vboxfield
import "editfieldEnter" editfieldEnter
import "setwndicon" setwndicon
import "mainwidget" mainwidget
import "drawfield" drawfield
import "streamuri" streamuri

include "../_include/include.h"


##########images
import "movetoScriptfolder" movetoScriptfolder

#returns the stage function for set click on stage button
function buttons_combinations()
    import "stage_start" stage_start
    chars button="prepare.bmp"
    chars *="Media edit panel"
    data match^stage_start
    data *=0

    import "play_click" play_click
    chars *="play.bmp"
    chars *="Play the media"
    data *^play_click
    import "info_save_stream" info_save_stream
    chars *="save.bmp"
    chars *="Save the stream to a file"
    data *^info_save_stream
    import "gather_info" gather_info
    chars *="info.bmp"
    chars *="Detect if the stream has audio or video"
    data *^gather_info
    import "stop" stop
    chars *="close.bmp"
    chars *="Stop the play or the save actions"
    data *^stop
    data *=0

    import "search_parse" search_parse
    chars *="search.bmp"
    chars *="Search for all streams at the uri using the rules from the search preferences"
    data *^search_parse
    import "show_preferences" show_preferences
    chars *="preferences.bmp"
    chars *="Display the search preferences window"
    data *^show_preferences
    data *=0

    import "mix_start" mix_start
    chars *="mix.bmp"
    chars *="Mux video and audio from two uri-s"
    data *^mix_start
    data *=0

    import "view_use_file" view_use_file
    chars *="help.bmp"
    chars *="View informations about the program"
    data *^view_use_file
    data *=0

    data *=0

    const ptrpoiner_init^button

    return match
endfunction

function setsystems()
    #call to check new version
    import "update" update
    call update()

    #search markups
    import "search_preferences_init" search_preferences_init
    call search_preferences_init()

    #stage file options
    import "stage_file_options_init" stage_file_options_init
    call stage_file_options_init()
endfunction

import "buttons_lots_ex" buttons_lots_ex

function setimages()
    #icon
    str icon="1616.png"
    data widget#1
    setcall widget mainwidget()
    call setwndicon(widget,icon)

    #buttons
    data buttons#1
    import "buttonswidget" buttonswidget
    setcall buttons buttonswidget()
    data ptr%ptrpoiner_init
    sd match
    setcall match buttons_combinations()
    data forward_stagebutton^stagebutton_forward
    call buttons_lots_ex(ptr,buttons,match,forward_stagebutton)

    #stage buttons
    import "stage_buttons" stage_buttons
    call stage_buttons()
endfunction

function stagebutton_forward(sd widget,sd function)
    call function(widget)
endfunction

import "folder_enterleave" folder_enterleave
import "folder_enterleave_data" folder_enterleave_data
import "img_folder" img_folder

function img_folder_enterleave(sd forward)
    ss img
    setcall img img_folder()
    call folder_enterleave(img,forward)
endfunction
function img_folder_enterleave_data(sd forward,sd data)
    ss img
    setcall img img_folder()
    call folder_enterleave_data(img,forward,data)
endfunction

function sys_folder()
    str system="sys"
    return system
endfunction

function sys_folder_enterleave(sd forward)
    sd system
    setcall system sys_folder()
    call folder_enterleave(system,forward)
endfunction

importx "_free" free

import "file_get_content" file_get_content
import "init_user" init_user
import "texter" texter

#v
function callbackprocessfolder()
	#set stage trace sizes
	import "stage_trace_min_size_set" stage_trace_min_size_set
	call stage_trace_min_size_set()

	#move to imgs
	data imgforward^setimages
	call img_folder_enterleave(imgforward)

	sd err

	str localversion="version.txt"
	vstr mem#1
	data size#1
	sd ptrmem^mem
	sd ptrsize^size
	setcall err file_get_content(localversion,ptrsize,ptrmem)
	if err==(noerror)
		call update_mem_version((NULL),mem,size)
		setcall err init_user()
		if err==(noerror)
			#move to settings
			data sysforward^setsystems
			call sys_folder_enterleave(sysforward)
		else
			call texter(err)
		endelse
		call free(mem)
	endif
endfunction
function update_mem_version(sd p,sd m,sd s)
	vstr mem#1
	data size#1
	if p==(NULL)
		set mem m
		set size s
		return (void)
	endif
	set p# mem
	incst p
	set p# size
endfunction

######main
#void
function initfn()
    data null=NULL

    data GTK_WINDOW_TOPLEVEL=GTK_WINDOW_TOPLEVEL
    data window#1
    setcall window gtk_window_new(GTK_WINDOW_TOPLEVEL)

    chars programname="OStream"
    str program^programname
    call gtk_window_set_title(window,program)

    data width=800
    #832
    #848
    data height=600
    #624
    #662
    call gtk_window_set_default_size(window,width,height)

    data ptr_gtk_main_quit^gtk_main_quit
    chars destr="destroy"
    str destroy^destr
    call g_signal_connect_data(window,destroy,ptr_gtk_main_quit,null,null,null)

    data vbox#1
    setcall vbox vboxfield(window)

    data length=0xffff
    data callback^streamuri
    call editfieldEnter(vbox,length,callback)

    data video#1
    setcall video drawfield(vbox)
    #gtk_widget_set_double_buffered(video_window,FALSE)

    #to keep the stage frames
    import "stage_sel_prepare_img_space" stage_sel_prepare_img_space
    call stage_sel_prepare_img_space()
    #add event expose
    import "connect_signal" connect_signal
    import "stage_paint_event" stage_paint_event
    str expose="expose-event"
    data f^stage_paint_event
    call connect_signal(video,expose,f)

    import "alignmentfield" alignmentfield
    import "hboxfield_cnt" hboxfield_cnt
    data alignment#1
    setcall alignment alignmentfield(vbox)
    data hbox#1
    setcall hbox hboxfield_cnt(alignment)

    import "stage_init" stage_init
    sd edits
    setcall edits stage_init()

    #texter added
    import "editinfofield_green" editinfofield_green
    data maintexter#1
    const ptr_maintexter^maintexter
    setcall maintexter editinfofield_green(vbox)

    import "gstplayinit" gstplayinit
    call gstplayinit(video)

    #get the process folder to load the images
    data ptrcallback^callbackprocessfolder

    call movetoScriptfolder(ptrcallback)

    call gtk_widget_show_all(window)
    #importx "_gtk_widget_hide_all" gtk_widget_hide_all
    #call gtk_widget_hide_all(edits)
endfunction
#void

function get_current_texter_pointer()
    data retvalue%ptr_maintexter
    return retvalue
endfunction

