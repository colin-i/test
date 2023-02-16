


format elfobj

include "../_include/include.h"


const left_coord=0
const top_coord=1
const width_coord=2
const height_coord=3
const capture_cursor=4
const capture_temporary=5
const capture_raw=6

const value_setrect=value_custom

function capture()
    import "dialogfield" dialogfield
    sd init^capture_init
    sd set^capture_start
    ss title="Capture"
    call dialogfield(title,(GTK_DIALOG_MODAL),init,set)
endfunction

import "capture_alternative_init" capture_alternative_init
import "capture_alternative_set" capture_alternative_set
import "capture_alternative_prepare" capture_alternative_prepare
import "capture_alternative_append" capture_alternative_append
import "capture_alternative_free" capture_alternative_free

function capture_init(sd vbox,sd *dialog)
    import "labelfield_l" labelfield_l
    ss text="Desktop Crop"
    call labelfield_l(text,vbox)
    import "tablefield_cells" tablefield_cells
    import "labelfield_left_prepare" labelfield_left_prepare
    importx "_gtk_entry_new" gtk_entry_new
    sd left_text
    sd left_entry
    sd top_text
    sd top_entry
    sd width_text
    sd width_entry
    sd height_text
    sd height_entry
    sd size_text
    sd size_entry
    sd string

    importx "_gtk_entry_set_text" gtk_entry_set_text
    ss l="Left"
    ss t="Top"
    ss w="Width"
    ss h="Height"
    ss sz="File split size(bytes)"
    #rect
    setcall left_text labelfield_left_prepare(l)
    setcall left_entry gtk_entry_new()
    setcall string capture_left_string()
    call gtk_entry_set_text(left_entry,string)
    #
    setcall top_text labelfield_left_prepare(t)
    setcall top_entry gtk_entry_new()
    setcall string capture_top_string()
    call gtk_entry_set_text(top_entry,string)
    #
    setcall width_text labelfield_left_prepare(w)
    setcall width_entry gtk_entry_new()
    setcall string capture_width_string()
    call gtk_entry_set_text(width_entry,string)
    #
    setcall height_text labelfield_left_prepare(h)
    setcall height_entry gtk_entry_new()
    setcall string capture_height_string()
    call gtk_entry_set_text(height_entry,string)
    #size limit
    setcall size_text labelfield_left_prepare(sz)
    setcall size_entry gtk_entry_new()
    setcall string capture_size_string()
    call gtk_entry_set_text(size_entry,string)
    #set the values
    sd cells^left_text
    call tablefield_cells(vbox,5,2,cells)
    call capture_rect((value_set),(left_coord),left_entry)
    call capture_rect((value_set),(top_coord),top_entry)
    call capture_rect((value_set),(width_coord),width_entry)
    call capture_rect((value_set),(height_coord),height_entry)
    call capture_split((value_set),size_entry)

    importx "_gtk_toggle_button_set_active" gtk_toggle_button_set_active
    import "packstart_default" packstart_default

    #cursor
    importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
    ss txt="Capture the cursor"
    sd cursor
    setcall cursor gtk_check_button_new_with_label(txt)
    sd cursor_flag
    setcall cursor_flag capture_cursor_option((value_get))
    call gtk_toggle_button_set_active(cursor,cursor_flag)
    call packstart_default(vbox,cursor)
    call capture_rect((value_set),(capture_cursor),cursor)

    #temp file
    ss temp_txt="Temporary file first"
    sd temp
    setcall temp gtk_check_button_new_with_label(temp_txt)
    importx "_gtk_widget_set_tooltip_markup" gtk_widget_set_tooltip_markup
    ss temp_info="Ignored if Raw file(s) selected"
    call gtk_widget_set_tooltip_markup(temp,temp_info)
    sd temp_flag
    setcall temp_flag capture_temp_option((value_get))
    call gtk_toggle_button_set_active(temp,temp_flag)
    call packstart_default(vbox,temp)
    call capture_rect((value_set),(capture_temporary),temp)
    call capture_direct((value_set))

    #raw file
    ss raw_info="Raw file(s)"
    sd raw
    setcall raw gtk_check_button_new_with_label(raw_info)
    call packstart_default(vbox,raw)
    sd raw_flag
    setcall raw_flag capture_raw_option((value_get))
    call gtk_toggle_button_set_active(raw,raw_flag)
    call capture_rect((value_set),(capture_raw),raw)

    #alternative
    call capture_alternative_init(vbox)
endfunction

importx "_g_object_unref" g_object_unref

function capture_start()
    #set capture rect, can return if arguments are not right
    sd bool
    setcall bool capture_rect((value_setrect))
    if bool!=1
        return 0
    endif

    #verify for output format
    setcall bool capture_format()
    if bool!=1
        return 0
    endif

    #init max allowed
    call capture_split((value_write))
    #call the loop
    call capture_files_loop((value_run))
endfunction

#bool
function capture_format()
    sd raw_flag
    setcall raw_flag capture_raw_option((value_get))
    if raw_flag==1
        return 1
    endif
    import "stage_file_options_output" stage_file_options_output
    sd output
    setcall output stage_file_options_output()
    sd capture_bool=1
    if output<(format_mkv)
        set capture_bool 0
    else
        if output>(format_mkv_last)
            set capture_bool 0
        else
            import "stage_file_get_mkv_encoder" stage_file_get_mkv_encoder
            sd encoder
            setcall encoder stage_file_get_mkv_encoder()
            if encoder!=(format_mkv_i420)
                if encoder!=(format_mkv_mjpg)
                    if encoder!=(format_mkv_rgb24)
                        set capture_bool 0
                    endif
                endif
            endif
        endelse
    endelse
    if capture_bool==0
        import "message_dialog" message_dialog
        str txt="Capture with MKV(I420,MJPEG,RGB24) selected at Stage Options"
        call message_dialog(txt)
        return 0
    endif
    return 1
endfunction

function capture_files_loop(sd action)
    data loop#1
    if action==(value_set)
        set loop 1
    else
        set loop 1

        sd bool
        setcall bool capture_pixbuf((value_set))
        if bool!=1
            return 0
        endif

        #tempfile
        call capture_temp_file((value_set),0)

        #don't display the result message inter-files
        import "stage_file_options_info_message" stage_file_options_info_message
        sd info
        setcall info stage_file_options_info_message((value_get))
        call stage_file_options_info_message((value_set),0)

        #file index
        sd file_index=0

        #get the time and start the loop files
        call capture_time((value_set))
        while loop==1
            #loop 1 can be if max size detected
            set loop 0

            # can be temp/raw
            setcall bool capture_direct((value_run))
            if bool==1
            #mkv
                import "mkvfile" mkvfile
                call mkvfile((capture_flag_on),file_index)
            endif

            #next file index
            inc file_index
        endwhile
        #restore info message
        call stage_file_options_info_message((value_set),info)

        sd temp_file
        setcall temp_file capture_temp_file((value_get))
        if temp_file!=0
            importx "_fclose" fclose
            call fclose(temp_file)
        endif

        call capture_pixbuf((value_unset))
    endelse
endfunction

import "entry_to_int_min_N_max_M" entry_to_int_min_N_max_M

const max_file_size=0x3fFFffFF

const split_maxsize_value=value_custom

function capture_split(sd action,sd value)
    data split_entry#1
    data maxsize#1

    data p_maxsize^maxsize
    if action==(value_set)
        set split_entry value
    elseif action==(value_get)
        return split_entry
    elseif action==(value_write)
        sd bool
        setcall bool entry_to_int_min_N_max_M(split_entry,p_maxsize,1,(max_file_size))
        if bool!=1
            set maxsize (max_file_size)
        endif
    elseif action==(split_maxsize_value)
        return maxsize
    else
    #bool: 0 stop, 1 continue
        #if action==(value_get)
        #value is file
        import "file_tell" file_tell
        sd pos
        sd p_pos^pos
        sd err

        setcall err file_tell(value,p_pos)
        if err!=(noerror)
            return 0
        endif
        if pos>=maxsize
            call capture_files_loop((value_set))
            return 0
        endif
        return 1
    endelse
endfunction

importx "_gdk_get_default_root_window" gdk_get_default_root_window
import "sleepMs" sleepMs
import "texter" texter

const value_init=0
const value_screenshot=1

function capture_rect(sd action,sd index,sd value)
    #widgets
    data left#1
    data top#1
    data width#1
    data height#1
    data cursor#1
    data temporary#1
    data raw#1

    if action==(value_set)
        if index==(left_coord)
            set left value
        elseif index==(top_coord)
            set top value
        elseif index==(width_coord)
            set width value
        elseif index==(height_coord)
            set height value
        elseif index==(capture_cursor)
            set cursor value
        elseif index==(capture_temporary)
            set temporary value
        else
        #if index==(capture_raw)
            set raw value
        endelse
    elseif action==(value_get)
        return #left
    else
    #if action==(value_setrect)
    #bool
        importx "_gdk_drawable_get_size" gdk_drawable_get_size
        sd root
        setcall root gdk_get_default_root_window()
        sd maxwidth
        sd maxheight
        sd p_maxwidth^maxwidth
        sd p_maxheight^maxheight
        call gdk_drawable_get_size(root,p_maxwidth,p_maxheight)

        sd left_val
        sd top_val
        sd values
        sd M
        sd bool

        #x
        set M maxwidth
        dec M
        setcall values capture_rect_screenshot((value_init))
        setcall bool entry_to_int_min_N_max_M(left,values,0,M)
        if bool!=1
            return 0
        endif
        set left_val values#
        #y
        set M maxheight
        dec M
        add values 4
        setcall bool entry_to_int_min_N_max_M(top,values,0,M)
        if bool!=1
            return 0
        endif
        set top_val values#
        #w
        set M maxwidth
        sub M left_val
        add values 4
        setcall bool entry_to_int_min_N_max_M(width,values,1,M)
        if bool!=1
            return 0
        endif
            #multiple of 4 for unstrided rgb24 cases
        sd dworded
        set dworded values#
        and dworded 0x3
        if dworded!=0
            str dw_er="The Width must be a multiple of 4"
            call texter(dw_er)
            return 0
        endif
        #h
        set M maxheight
        sub M top_val
        add values 4
        setcall bool entry_to_int_min_N_max_M(height,values,1,M)
        if bool!=1
            return 0
        endif
        #cursor
        importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
        add values 4
        setcall values# gtk_toggle_button_get_active(cursor)
        #temporary
        add values 4
        setcall values# gtk_toggle_button_get_active(temporary)
        #raw
        add values 4
        setcall values# gtk_toggle_button_get_active(raw)

        import "file_write_forward_sys_folder_enter_leave" file_write_forward_sys_folder_enter_leave
        data forw_capture^capture_settings_set_write
        import "capture_file" capture_file
        ss capture_fl_str
        setcall capture_fl_str capture_file()
        call file_write_forward_sys_folder_enter_leave(capture_fl_str,forw_capture)

        return 1
    endelse
endfunction

import "file_write" file_write

function capture_left_string()
    chars c#dword_null
    return #c
endfunction
function capture_top_string()
    chars c#dword_null
    return #c
endfunction
function capture_width_string()
    chars c#dword_null
    return #c
endfunction
function capture_height_string()
    chars c#dword_null
    return #c
endfunction
function capture_size_string()
    chars c#dword_null
    return #c
endfunction
import "file_write_string" file_write_string
function capture_settings_set_write(sd capture_fl)
    sd value
    sd p_value^value
    sd err
    sd entries
    sd bool
    sd string
    setcall entries capture_rect((value_get))
    importx "_gtk_entry_get_text" gtk_entry_get_text

    setcall string gtk_entry_get_text(entries#)
    setcall bool file_write_string(string,capture_fl)
    if bool!=1
        return (void)
    endif
    add entries (DWORD)
    #
    setcall string gtk_entry_get_text(entries#)
    setcall bool file_write_string(string,capture_fl)
    if bool!=1
        return (void)
    endif
    add entries (DWORD)
    #
    setcall string gtk_entry_get_text(entries#)
    setcall bool file_write_string(string,capture_fl)
    if bool!=1
        return (void)
    endif
    add entries (DWORD)
    #
    setcall string gtk_entry_get_text(entries#)
    setcall bool file_write_string(string,capture_fl)
    if bool!=1
        return (void)
    endif
    add entries (DWORD)
    #
    setcall entries capture_split((value_get))
    setcall string gtk_entry_get_text(entries)
    setcall bool file_write_string(string,capture_fl)
    if bool!=1
        return (void)
    endif

    setcall value capture_cursor_option((value_get))
    setcall err file_write(p_value,4,capture_fl)
    if err!=(noerror)
        return (void)
    endif
    setcall value capture_temp_option((value_get))
    setcall err file_write(p_value,4,capture_fl)
    if err!=(noerror)
        return (void)
    endif
    setcall value capture_raw_option((value_get))
    setcall err file_write(p_value,4,capture_fl)
    if err!=(noerror)
        return (void)
    endif
endfunction

function capture_time(sd action)
    import "get_time" get_time
    #start capture time
    data starttime#1
    #total frames captured
    data totalframes#1
    #time increment decided by fps
    data timeincrement#1

    import "stage_file_options_fps" stage_file_options_fps
    sd fps
    setcall fps stage_file_options_fps()
    if action==(value_set)
        setcall starttime get_time()
        set totalframes 0
        set timeincrement 1000
        div timeincrement fps
    else
    #frame length return
        #sleep time increment
        call sleepMs(timeincrement)
        #get correct time position
        sd seconds
        set seconds totalframes
        div seconds fps
        mult seconds 1000

        import "rest" rest
        sd nth_sec
        setcall nth_sec rest(totalframes,fps)
        mult nth_sec timeincrement

        sd time
        set time starttime
        add time seconds
        add time nth_sec

        #get new time
        sd newtime
        setcall newtime get_time()
        sub newtime time

        #convert it to frames
        import "get_higher" get_higher
        sd newframes
        div newtime timeincrement
        setcall newframes get_higher(1,newtime)

        #add new length to total frames
        add totalframes newframes

        return newframes
    endelse
endfunction

function capture_obtain_screenshot()
    call capture_rect_screenshot((value_screenshot))
    sd pixbuf
    setcall pixbuf capture_pixbuf((value_get))
    return pixbuf
endfunction

const CAIRO_FORMAT_RGB24=1

const sizeofrect=4*4
const cursor_flag_pointer=sizeofrect
const cursor_temp_pointer=cursor_flag_pointer+4
const cursor_raw_pointer=cursor_temp_pointer+4

function capture_rect_screenshot(sd action)
    data x#1
    data y#1
    data wdt#1
    data hgt#1
    data cursor_option#1
    data *temp_option#1
    data *raw_option#1

    data values_rect^x
    if action==(value_init)
    #get the pointer
        return values_rect
    else
    #if action==(value_screenshot)
        sd temporary_flag
        setcall temporary_flag capture_temp_flag((value_get))
        if temporary_flag==0
        #live screenshot
            call capture_pixbuf((value_append),x,y,wdt,hgt,cursor_option)
        else
        #screenshot from temp file
            call capture_read_temp_screenshot(wdt,hgt)
        endelse
    endelse
endfunction

importx "_cairo_destroy" cairo_destroy
importx "_cairo_surface_destroy" cairo_surface_destroy
function capture_free_cairo(sd cairo,sd surface)
    call cairo_destroy(cairo)
    call cairo_surface_destroy(surface)
endfunction

import "memalloc" memalloc
importx "_free" free

function capture_free_cairo_and_mem(sd cairo,sd surface,sd mem)
    call capture_free_cairo(cairo,surface)
    call free(mem)
endfunction

function capture_terminal(sd action,sd value)
    data terminal#1
    if action==(value_set)
        set terminal value
    else
        return terminal
    endelse
endfunction

function capture_free_stuff(sd cairo_flag,sd cairo,sd surface,sd mem)
    if cairo_flag==1
        #use cairo
        call capture_free_cairo_and_mem(cairo,surface,mem)
    else
        call capture_alternative_free()
    endelse
endfunction
function capture_free_more_stuff(sd cairo_flag,sd cairo,sd surface,sd mem,sd pixbuf)
    call capture_free_stuff(cairo_flag,cairo,surface,mem)
    call g_object_unref(pixbuf)
endfunction

import "bytes_swap_reverse" bytes_swap_reverse

function capture_pixbuf(sd action,sd x,sd y,sd pix_width,sd pix_height,sd cursor_flag)
    data pixbuf#1
    data mem#1
    data cairo_flag#1

    data cairo#1
    data surface#1

    if action==(value_set)
    #bool
        sd bool
        #init capture mem
        import "rgb_get_all_sizes" rgb_get_all_sizes
        sd width
        sd height
        sd wh^width
        call capture_get_width_height(wh)
        sd rowstr
        sd p_rowstr^rowstr
        sd sz
        setcall sz rgb_get_all_sizes(width,height,p_rowstr)
        sd term=0
        sd p_term^term
        set cairo_flag 1
        sd p_flag^cairo_flag
        call capture_alternative_set(p_flag,p_term)
        if cairo_flag==1
        #cairo is default
            #cairo surface and cairo context
            sd root
            setcall root gdk_get_default_root_window()
            importx "_cairo_image_surface_create" cairo_image_surface_create
            setcall surface cairo_image_surface_create((CAIRO_FORMAT_RGB24),width,height)
            if surface==0
                str surf="Image surface error"
                call texter(surf)
                return 0
            endif

            importx "_cairo_create" cairo_create
            setcall cairo cairo_create(surface)
            sd x_value
            sd y_value
            sd p_xy_value^x_value
            call capture_get_xy(p_xy_value)
            importx "_gdk_cairo_set_source_window" gdk_cairo_set_source_window
            sd double_x_low
            sd double_x_high
            sd double_y_low
            sd double_y_high
            sd double_x^double_x_low
            sd double_y^double_y_low
            import "int_to_double" int_to_double
            sd value
            set value x_value
            mult value -1
            call int_to_double(value,double_x)
            set value y_value
            mult value -1
            call int_to_double(value,double_y)
            call gdk_cairo_set_source_window(cairo,root,double_x_low,double_x_high,double_y_low,double_y_high)
            #memory
            setcall mem memalloc(sz)
            if mem==0
                call capture_free_cairo(cairo,surface)
                return 0
            endif
        else
            sd p_mem^mem
            setcall bool capture_alternative_prepare(p_mem,width,height)
            if bool!=1
                return 0
            endif
        endelse
        importx "_gdk_pixbuf_new_from_data" gdk_pixbuf_new_from_data
        setcall pixbuf gdk_pixbuf_new_from_data(mem,(GDK_COLORSPACE_RGB),(FALSE),8,width,height,rowstr,0,0)
        if pixbuf==0
            call capture_free_stuff(cairo_flag,cairo,surface,mem)
            return 0
        endif
        if term==1
            setcall bool capture_alternative_prepare()
            if bool!=1
                call capture_free_more_stuff(cairo_flag,cairo,surface,mem,pixbuf)
                return 0
            endif
            call capture_terminal((value_set),1)
        endif
        return 1
    elseif action==(value_get)
        return pixbuf
    elseif action==(value_unset)
        call capture_free_more_stuff(cairo_flag,cairo,surface,mem,pixbuf)
        sd t
        setcall t capture_terminal((value_get))
        if t==1
            call capture_alternative_free()
            call capture_terminal((value_set),0)
        endif
    else
    #if action==(value_append)
        if cairo_flag==1
            #use cairo
            call capture_get_cairo_pixbuf(x,y,pix_width,pix_height,cursor_flag,cairo,surface)
        else
            call capture_alternative_append(x,y,pix_width,pix_height,cursor_flag)
        endelse
        sd raw_flag
        setcall raw_flag capture_raw_option((value_get))
        if raw_flag==0
            sd encoder
            setcall encoder stage_file_get_mkv_encoder()
            if encoder!=(format_mkv_rgb24)
                #reverse bytes
                call bytes_swap_reverse(mem,pix_width,pix_height)
            endif
        endif
    endelse
endfunction


function capture_cursor_option(sd action,sd value)
    sd capture_set
    setcall capture_set capture_rect_screenshot((value_set))
    add capture_set (cursor_flag_pointer)
    if action==(value_set)
        set capture_set# value
    else
        return capture_set#
    endelse
endfunction
function capture_temp_option(sd action,sd value)
    sd capture_set
    setcall capture_set capture_rect_screenshot((value_set))
    add capture_set (cursor_temp_pointer)
    if action==(value_set)
        set capture_set# value
    else
        return capture_set#
    endelse
endfunction
function capture_raw_option(sd action,sd value)
    sd capture_set
    setcall capture_set capture_rect_screenshot((value_set))
    add capture_set (cursor_raw_pointer)
    if action==(value_set)
        set capture_set# value
    else
        return capture_set#
    endelse
endfunction


########temp capture

function capture_temp_flag(sd action,sd value)
    data temp_flag#1
    if action==(value_set)
        set temp_flag value
    else
        return temp_flag
    endelse
endfunction

function capture_direct(sd action)
    data temp_viewed#1
    if action==(value_set)
        set temp_viewed 0
        call capture_temp_flag((value_set),0)
    else
    #bool
    #value_run
        if temp_viewed==1
            return 1
        endif
        set temp_viewed 1

        sd direct_way
        setcall direct_way capture_temp_option((value_get))
        if direct_way==0
            setcall direct_way capture_raw_option((value_get))
        endif
        if direct_way==0
            return 1
        endif

        import "av_dialog_run" av_dialog_run
        data forward^capture_direct_start
        sd bool
        setcall bool av_dialog_run(forward,0)

        #temp flag
        #before dialog run no;after dialog run for capture_take_screenshot
        call capture_temp_flag((value_set),1)

        return bool
    endelse
endfunction

function capture_temp_file(sd action,sd value)
    data temp_file#1
    if action==(value_set)
        set temp_file value
    else
        return temp_file
    endelse
endfunction
function capture_direct_frames(sd action,sd value)
    data temp_frames#1
    if action==(value_set)
        set temp_frames value
    elseif action==(value_append)
        inc temp_frames
    else
        #if action==(value_get)
        return temp_frames
    endelse
endfunction

function capture_get_xy(sd p_xy)
    sd rect
    setcall rect capture_rect_screenshot((value_init))
    set p_xy# rect#
    add p_xy 4
    set p_xy# rect#
endfunction

function capture_get_width_height(sd wh)
    sd rect
    setcall rect capture_rect_screenshot((value_init))
    add rect 8
    set wh# rect#
    add wh 4
    add rect 4
    set wh# rect#
endfunction

#bool
function capture_direct_start(sd *data)
    #init captured frames counter
    call capture_direct_frames((value_set),0)

    ss format
    ss method
    sd raw_flag
    setcall raw_flag capture_raw_option((value_get))
    if raw_flag==0
#these formats are related to format_max
        ss temp_format="temp"
        ss temp_method="w+Db"
        set format temp_format
        set method temp_method
    else
        ss raw_method="wb"
        setcall format capture_raw_extension()
        set method raw_method
    endelse
    import "save_destination" save_destination
    sd output_file
    setcall output_file save_destination(format)

    sd bool
    setcall bool capture_direct_run(output_file,method)

    if raw_flag==1
    #here all raw files will be processed
        call capture_raw_files(output_file)
        set bool 0
    endif

    import "av_dialog_close" av_dialog_close
    call av_dialog_close()
    return bool
endfunction

function capture_raw_extension()
#these formats are related to format_max
    str raw_format="raw"
    return raw_format
endfunction

#bool
function capture_direct_run(sd output_file,sd method)
    sd file
    sd er
    #open file
    import "openfile" openfile
    sd p_file^file
    setcall er openfile(p_file,output_file,method)
    if er!=(noerror)
        return 0
    endif
    call capture_temp_file((value_set),file)

    #get rect size
    sd width
    sd height
    sd p_wh^width
    call capture_get_width_height(p_wh)
    import "rgb_get_size" rgb_get_size
    sd rgb_rect_size
    setcall rgb_rect_size rgb_get_size(width,height)
    #draw a text
    import "dialog_modal_texter_draw" dialog_modal_texter_draw
    ss text="Recording.."
    call dialog_modal_texter_draw(text)
    #loop the screenshots
    while 1==1
        #take screenshot
        sd pixbuf
        setcall pixbuf capture_obtain_screenshot()
        if pixbuf==0
            return 0
        endif
        #write screenshot
        importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
        sd bytes
        setcall bytes gdk_pixbuf_get_pixels(pixbuf)
        setcall er file_write(bytes,rgb_rect_size,file)
        if er!=(noerror)
            return 0
        endif
        #take and write frame length
        sd frames_rise
        sd p_frames_rise^frames_rise
        setcall frames_rise capture_time((value_get))
        setcall er file_write(p_frames_rise,4,file)
        if er!=(noerror)
            return 0
        endif
        #count the screenshots
        call capture_direct_frames((value_append))
        #see if stop pressed
        import "av_dialog_stop" av_dialog_stop
        sd stop
        setcall stop av_dialog_stop((value_get))
        if stop==1
            #seek at the start for reading
            import "file_seek_set" file_seek_set
            setcall er file_seek_set(file,0)
            if er!=(noerror)
                return 0
            endif
            return 1
        endif
    endwhile
endfunction

function capture_read_temp_screenshot(sd width,sd height)
    sd pixbuf
    setcall pixbuf capture_pixbuf((value_get))

    sd bytes
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)

    sd size
    setcall size rgb_get_size(width,height)

    sd temp_file
    setcall temp_file capture_temp_file((value_get))

    import "file_read" file_read
    call file_read(bytes,size,temp_file)
endfunction






########

import "draw_default_cursor" draw_default_cursor

function capture_get_cairo_pixbuf(sd x,sd y,sd wdt,sd hgt,sd cursor_flag,sd cairo,sd surface)
    importx "_cairo_paint" cairo_paint
    call cairo_paint(cairo)

    if cursor_flag==1
        sd root
        setcall root gdk_get_default_root_window()
        call draw_default_cursor(root,x,y,wdt,hgt,cairo)
    endif

    import "surface_to_pixbufdata" surface_to_pixbufdata
    sd pixbuf
    setcall pixbuf capture_pixbuf((value_get))
    call surface_to_pixbufdata(surface,pixbuf)
endfunction


##file options
function capture_get_data(sd mem,sd *size)
    import "get_mem_int_advance" get_mem_int_advance
    sd mem_sz^mem
    sd err
    sd value
    sd p_value^value
    sd dest

    import "get_str_advance" get_str_advance
    setcall dest capture_left_string()
    setcall err get_str_advance(dest,(dword_null),mem_sz)
    if err!=(noerror)
        return 0
    endif
    setcall dest capture_top_string()
    setcall err get_str_advance(dest,(dword_null),mem_sz)
    if err!=(noerror)
        return 0
    endif
    setcall dest capture_width_string()
    setcall err get_str_advance(dest,(dword_null),mem_sz)
    if err!=(noerror)
        return 0
    endif
    setcall dest capture_height_string()
    setcall err get_str_advance(dest,(dword_null),mem_sz)
    if err!=(noerror)
        return 0
    endif
    setcall dest capture_size_string()
    setcall err get_str_advance(dest,(dword_null),mem_sz)
    if err!=(noerror)
        return 0
    endif

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call capture_cursor_option((value_set),value)

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call capture_temp_option((value_set),value)

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call capture_raw_option((value_set),value)
endfunction


##raw files

const raw_width_height_off=0
const raw_nr_of_frames_off=raw_width_height_off+8
const raw_frames_per_file_off=raw_nr_of_frames_off+4
const raw_files_off=raw_frames_per_file_off+4

const raw_size=raw_files_off+4

const raw_get_value=value_extra

function raw_structure(sd action,sd value)
    data structure#1
    if action==(value_set)
        set structure value
    elseif action==(value_get)
        return structure
    else
        sd member
        set member structure
        add member value
        return member#
    endelse
endfunction

#write

function capture_raw_files(sd output_file)
    data width#1
    data height#1
    data nr_of_frames#1
    data frames_per_file#1
    data files#1

    sd struct^width
    call raw_structure((value_set),struct)

    call capture_get_width_height(struct)

    sd maxsize
    setcall maxsize capture_split((split_maxsize_value))
    sd frame_size
    setcall frame_size rgb_get_size(width,height)
    #add the frame length storage space
    add frame_size 4
    set frames_per_file maxsize
    div frames_per_file frame_size
    if frames_per_file==0
        set frames_per_file 1
    endif

    set files 0

    sd all_frames
    setcall all_frames capture_direct_frames((value_get))
    while all_frames!=0
        if all_frames<=frames_per_file
            set nr_of_frames all_frames
            set all_frames 0
        else
            set nr_of_frames frames_per_file
            sub all_frames frames_per_file
        endelse

        importx "_sprintf" sprintf
        chars outfile_data#100
        str outfile^outfile_data
        str outformat="%s.%u"
        call sprintf(outfile,outformat,output_file,files)
        import "file_write_forward" file_write_forward
        data forward_raw^capture_raw_writeOnFile
        call file_write_forward(outfile,forward_raw)

        inc files
    endwhile
endfunction

function capture_raw_writeOnFile(sd file)
    sd struct
    setcall struct raw_structure((value_get))
    call file_write(struct,(raw_size),file)
endfunction

#read

function capture_raw_read(ss filepath)
    #values init
    import "stage_read_values" stage_read_values
    sd bool
    setcall bool stage_read_values((value_set))
    if bool!=1
        return 0
    endif

    data f^capture_raw_read_start
    call av_dialog_run(f,filepath)

    #values write and free
    call stage_read_values((value_write))
    call stage_read_values((value_unset))
endfunction

function capture_raw_read_start(ss filepath)
    import "file_forward_read" file_forward_read
    data f_raw^capture_raw_read_file
    call file_forward_read(filepath,f_raw)
    call av_dialog_close()
endfunction

function capture_raw_read_file(sd file,sd path)
    data struct_data#raw_size
    data struct^struct_data
    sd err
    setcall err file_read(struct,(raw_size),file)
    if err!=(noerror)
        return 0
    endif
    call raw_structure((value_set),struct)

    import "valinmemsens" valinmemsens
    import "slen" slen
    sd sz
    setcall sz slen(path)
    ss filepath
    set filepath path
    add filepath sz
    chars delim="."
    setcall sz valinmemsens(filepath,sz,delim) #,(BACKWARD)
    sub filepath sz
    set filepath# 0

    data f_raw^capture_raw_read_filedata
    call file_forward_read(path,f_raw)
endfunction

function capture_raw_read_filedata(sd file)
    sd width
    sd height
    sd frames_per_file
    sd files_before
    setcall width raw_structure((raw_get_value),(raw_width_height_off))
    setcall height raw_structure((raw_get_value),(raw_width_height_off+4))
    setcall frames_per_file raw_structure((raw_get_value),(raw_frames_per_file_off))
    setcall files_before raw_structure((raw_get_value),(raw_files_off))

    sd size
    sd rgb_size
    setcall size rgb_get_size(width,height)
    set rgb_size size
    add size 4
    mult size frames_per_file

    sd er
    sd i=0
    while i!=files_before
        import "file_seek_dif_cursor" file_seek_dif_cursor
        setcall er file_seek_dif_cursor(file,size)
        if er!=(noerror)
            return 0
        endif
        inc i
    endwhile

    sd nr_of_frames
    setcall nr_of_frames raw_structure((raw_get_value),(raw_nr_of_frames_off))
    set i 0

    import "rgb_get_rowstride" rgb_get_rowstride
    sd pixbuf
    sd length
    sd entry^pixbuf
    sd p_length^length
    sd rowstride
    setcall rowstride rgb_get_rowstride(width)

    while i!=nr_of_frames
        sd stop
        setcall stop av_dialog_stop((value_get))
        if stop==1
            return 0
        endif

        sd mem
        setcall mem memalloc(rgb_size)
        if mem==0
            return 0
        endif

        setcall er file_read(mem,rgb_size,file)
        if er!=(noerror)
            return 0
        endif
        call bytes_swap_reverse(mem,width,height)
        data free_mem^free
        setcall pixbuf gdk_pixbuf_new_from_data(mem,(GDK_COLORSPACE_RGB),(FALSE),8,width,height,rowstride,free_mem,mem)

        setcall er file_read(p_length,4,file)
        if er!=(noerror)
            return 0
        endif

        sd bool
        setcall bool stage_read_values((value_append),entry,8)
        if bool!=1
            return 0
        endif

        #info display
        import "av_display_info" av_display_info
        call av_display_info((value_write),0,-1,rgb_size)

        inc i
    endwhile
endfunction
