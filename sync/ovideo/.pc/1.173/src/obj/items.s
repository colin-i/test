

format elfobj

importx "_g_object_unref" g_object_unref

include "../_include/include.h"


import "packstart" packstart
import "packstart_default" packstart_default
import "container_add" container_add

importx "_gtk_button_new" gtk_button_new
##########button
importx "_gtk_button_set_label" gtk_button_set_label

function buttonfield_prepare_with_label(ss text)
    sd button
    setcall button gtk_button_new()
    call gtk_button_set_label(button,text)
    return button
endfunction

function buttonfield(data container)
    data gtkwidget#1
    setcall gtkwidget gtk_button_new()
    data n=0
    call packstart(container,gtkwidget,n)
    return gtkwidget
endfunction

importx "_gtk_image_new_from_pixbuf" gtk_image_new_from_pixbuf

importx "_gtk_button_set_image" gtk_button_set_image
#void
function buttonfield_setimage_call(data gdkpixbuf,data button)
    data gtkimage#1
    setcall gtkimage gtk_image_new_from_pixbuf(gdkpixbuf)
    call gtk_button_set_image(button,gtkimage)
endfunction
#void
function buttonfield_setimage(str filename,data button)
    data setimage^buttonfield_setimage_call
    call pixbuf_from_file_forward_data(filename,setimage,button)
endfunction

#function buttonfield_label(sd box,sd text)
#    sd button
#    setcall button buttonfield(box)
#    call gtk_button_set_label(button,text)
#    return button
#endfunction


##########color
#uint32 rgb, little endian with alpha
function color_widget_get_color_to_rgb(sd color_entry)
    sd g_color#3
    #only 2.5
    sd ptr_g_color^g_color
    sd value_colors^g_color
    add value_colors 4

    #the color
    importx "_gtk_color_button_get_color" gtk_color_button_get_color
    call gtk_color_button_get_color(color_entry,ptr_g_color)

    sd red_const
    sd green_const
    sd blue_const

    import "gdkcolor2byte" gdkcolor2byte
    setcall red_const gdkcolor2byte(value_colors)
    add value_colors 2
    setcall green_const gdkcolor2byte(value_colors)
    add value_colors 2
    setcall blue_const gdkcolor2byte(value_colors)

    sd color
    setcall color colors_to_littlewithalpha_color(red_const,green_const,blue_const)
    return color
endfunction

#color
function color_widget_get_color(sd color_entry)
    sd g_color#3
    #only 2.5
    sd ptr_g_color^g_color
    sd value_colors^g_color
    add value_colors 4

    #the color
    call gtk_color_button_get_color(color_entry,ptr_g_color)

    sd red_const
    sd green_const
    sd blue_const

    setcall red_const gdkcolor2byte(value_colors)
    add value_colors 2
    setcall green_const gdkcolor2byte(value_colors)
    add value_colors 2
    setcall blue_const gdkcolor2byte(value_colors)

    sd color
    mult red_const (0x100*0x100)
    mult green_const 0x100
    set color blue_const
    or color red_const
    or color green_const
    return color
endfunction

function colors_to_littlewithalpha_color(sd red_const,sd green_const,sd blue_const)
    sd color
    mult red_const 0x1000000
    set color red_const
    mult green_const 0x10000
    or color green_const
    mult blue_const 0x100
    or color blue_const
    return color
endfunction

import "hboxfield_cnt" hboxfield_cnt

#color button
function colorbuttonfield_leftlabel(ss text,sd box)
    #the color
    sd hbox
    setcall hbox hboxfield_cnt(box)
    call labelfield_left_default(text,hbox)
    importx "_gtk_color_button_new" gtk_color_button_new
    sd color
    setcall color gtk_color_button_new()
    call packstart_default(hbox,color)
    return color
endfunction

##########draw
importx "_gtk_drawing_area_new" gtk_drawing_area_new
#draw
function drawfield(data container)
    data GtkWidget#1
    setcall GtkWidget gtk_drawing_area_new()
    data true=TRUE
    call packstart(container,GtkWidget,true)
    return GtkWidget
endfunction

function drawfield_cnt(sd container)
    data GtkWidget#1
    setcall GtkWidget gtk_drawing_area_new()
    call container_add(container,GtkWidget)
    return GtkWidget
endfunction

############edit
importx "_gtk_entry_buffer_new" gtk_entry_buffer_new
importx "_gtk_entry_buffer_set_max_length" gtk_entry_buffer_set_max_length
importx "_gtk_entry_new_with_buffer" gtk_entry_new_with_buffer
importx "_g_signal_connect_data" g_signal_connect_data
#GtkWidget
function editfield(data container,data length)
    data GtkWidget#1
    data null=NULL
    data GtkEntryBuffer#1

    setcall GtkEntryBuffer gtk_entry_buffer_new(null,null)

    call gtk_entry_buffer_set_max_length(GtkEntryBuffer,length)

    setcall GtkWidget gtk_entry_new_with_buffer(GtkEntryBuffer)

    call g_object_unref(GtkEntryBuffer)

    call packstart(container,GtkWidget,null)

    return GtkWidget
endfunction

#GtkWidget
import "recoverEnter" recoverEnter
function editfieldEnter(data container,data length,data forward)
    data GtkWidget#1
    setcall GtkWidget editfield(container,length)

    chars key="key-press-event"
    str keypress^key
    data enter^recoverEnter
    data null=NULL
    call g_signal_connect_data(GtkWidget,keypress,enter,forward,null,null)
    return GtkWidget
endfunction

importx "_gtk_entry_get_text" gtk_entry_get_text

#void
importx "_gtk_entry_set_text" gtk_entry_set_text
#edit texter
import "get_current_texter_pointer" get_current_texter_pointer
function texter(ss text)
	sd info#1
	setcall info get_current_texter_pointer()
	call gtk_entry_set_text(info#,text)
	call printer(text)
endfunction
function printer(ss text)
    importx "_printf" printf
    call printf(text)
    chars nl={0xa,0}
    str newline^nl
    call printf(newline)
endfunction

function new_texter_close(sd *dialog,sd previous_texter)
    #texter pointer
    sd info
    setcall info get_current_texter_pointer()

    #replace texter pointer
    sd text
    setcall text gtk_entry_get_text(info#)
    set info# previous_texter

    #pass the text to the previous texter
    call texter(text)
endfunction

function new_texter_modal(sd container,sd dialog)
    import "editinfofield_green" editinfofield_green_
    sd newtexter
    setcall newtexter editinfofield_green_(container)

    import "connect_signal_data" connect_signal_data
    str destr="destroy"
    data f^new_texter_close
    sd info#1
    setcall info get_current_texter_pointer()
    call connect_signal_data(dialog,destr,f,info#)

    set info# newtexter
endfunction
#

importx "_gtk_entry_new" gtk_entry_new

function editfield_pack(sd container)
    sd edit
    setcall edit gtk_entry_new()
    call packstart_default(container,edit)
    return edit
endfunction

#field
function edit_info_prepare(sd ptrcolors,ss text)
    importx "_gtk_editable_set_editable" gtk_editable_set_editable
    import "setWidgetBase" setWidgetBase
    sd info
    setcall info gtk_entry_new()
    data false=0
    call gtk_editable_set_editable(info,false)
    call setWidgetBase(info,ptrcolors)
    call gtk_entry_set_text(info,text)
    return info
endfunction

#field
function edit_info_prepare_green(ss text)
    chars infocolors={0xe0,0xff,0xe0}
    data infoptrcolors^infocolors
    sd widget
    setcall widget edit_info_prepare(infoptrcolors,text)
    return widget
endfunction

#field
function edit_info_prepare_blue(ss text)
    chars infocolors={0xe0,0xe0,0xff}
    data infoptrcolors^infocolors
    sd widget
    setcall widget edit_info_prepare(infoptrcolors,text)
    return widget
endfunction

function editinfofield_green(sd box)
    str x=""
    sd field
    setcall field edit_info_prepare_green(x)
    call packstart_default(box,field)
    return field
endfunction

function editfield_with_int(sd int)
    chars spc#sign_int_null
    str intstring^spc
    str frm="%i"
    importx "_sprintf" sprintf
    call sprintf(intstring,frm,int)
    sd entry
    setcall entry gtk_entry_new()
    call gtk_entry_set_text(entry,intstring)
    return entry
endfunction

import "strtoint_positive_N_or_Greater" strtoint_positive_N_or_Greater

#void
function entry_to_nr_minValue(sd entry,sd p_out,sd min)
    sd text
    setcall text gtk_entry_get_text(entry)
    sd bool
    setcall bool strtoint_positive_N_or_Greater(text,p_out,min)
    if bool==0
        set p_out# min
    endif
endfunction

function int_to_entry(sd int,sd entry)
    sd number#4
    sd p_nr^number
    ss frm="%i"
    call sprintf(p_nr,frm,int)
    call gtk_entry_set_text(entry,p_nr)
endfunction

#edit return
function label_and_edit(sd box,ss text)
    sd hbox
    setcall hbox hboxfield_cnt(box)
    call labelfield_l(text,hbox)
    sd edit
    setcall edit editfield_pack(hbox)
    return edit
endfunction

#bool
function entry_to_int_min_N(sd entry,sd p_int,sd N)
    ss text
    setcall text gtk_entry_get_text(entry)
    sd bool
    setcall bool strtoint_positive_N_or_Greater(text,p_int,N)
    return bool
endfunction

#bool
function entry_to_int_min_N_max_M(sd entry,sd p_int,sd N,sd M)
    sd bool
    setcall bool entry_to_int_min_N(entry,p_int,N)
    if bool==0
        return 0
    endif
    if p_int#>M
        import "strdworddisp" strdworddisp
        str errnr="Expecting a number lower or equal with "
        call strdworddisp(errnr,M)
        return 0
    endif
    return 1
endfunction

##############hscale
function hscalefield_main(sd box,sd min,sd max,sd step,sd pos,sd packexpand)
    import "int_to_double" int_to_double

    importx "_gtk_hscale_new_with_range" gtk_hscale_new_with_range
    sd min_d_low
    sd min_d_high
    sd max_d_low
    sd max_d_high
    sd step_d_low
    sd step_d_high
    sd p_min_d^min_d_low
    sd p_max_d^max_d_low
    sd p_step_d^step_d_low
    call int_to_double(min,p_min_d)
    call int_to_double(max,p_max_d)
    call int_to_double(step,p_step_d)

    sd hscale
    setcall hscale gtk_hscale_new_with_range(min_d_low,min_d_high,max_d_low,max_d_high,step_d_low,step_d_high)

    importx "_gtk_range_set_value" gtk_range_set_value
    sd doublepos_low
    sd doublepos_high
    sd p_doublepos^doublepos_low
    call int_to_double(pos,p_doublepos)
    call gtk_range_set_value(hscale,doublepos_low,doublepos_high)

    call packstart(box,hscale,packexpand)

    return hscale
endfunction

function hscalefield(sd box,sd min,sd max,sd step,sd pos)
    sd hscale
    setcall hscale hscalefield_main(box,min,max,step,pos,(TRUE))
    return hscale
endfunction

#int pos
function hscale_get(sd hscale)
    importx "_gtk_range_get_value" gtk_range_get_value
    sd value
    sd p_value^value
    import "fistp" fistp
    call gtk_range_get_value(hscale)
    call fistp(p_value)
    return value
endfunction

##############hseparator
importx "_gtk_hseparator_new" gtk_hseparator_new
function hseparatorfield(sd box)
    sd hsep
    setcall hsep gtk_hseparator_new()
    import "boxpackstart" boxpackstart
    call boxpackstart(box,hsep,0,10)
    return hsep
endfunction

function hseparatorfield_nopad(sd box)
    sd hsep
    setcall hsep gtk_hseparator_new()
    call packstart_default(box,hsep)
    return hsep
endfunction

function hseparatorfield_table(sd table)
    sd hsep
    setcall hsep gtk_hseparator_new()
    import "table_add_row" table_add_row
    call table_add_row(table,hsep)
    return hsep
endfunction

##############icon
importx "_gtk_window_set_icon" gtk_window_set_icon
function window_set_icon(sd pixbuf,sd window)
    call gtk_window_set_icon(window,pixbuf)
endfunction
function setwndicon(data window,str filename)
    data icon^window_set_icon
    call pixbuf_from_file_forward_data(filename,icon,window)
endfunction



importx "_gtk_widget_new" gtk_widget_new
importx "_gtk_label_get_type" gtk_label_get_type
##############label
function labelfield_left_prepare(ss text)
    sd widget
    sd GTK_TYPE_LABEL
    str label="label"
    str x="xalign"
    data left=0
    data n=0

    setcall GTK_TYPE_LABEL gtk_label_get_type()
    setcall widget gtk_widget_new(GTK_TYPE_LABEL,label,text,x,left,left,n)
    return widget
endfunction
function labelfield_l(ss text,sd box)
    sd label
    setcall label labelfield_left_prepare(text)
    call packstart(box,label,(TRUE))
    return label
endfunction
function labelfield_left_default(ss text,sd box)
    sd label
    setcall label labelfield_left_prepare(text)
    call packstart(box,label,(FALSE))
    return label
endfunction

function labelfield_left_table(ss text,sd table)
    sd label
    setcall label labelfield_left_prepare(text)
    call table_add_row(table,label)
    return label
endfunction

#########message dialog
function message_dialog(sd print)
    import "mainwidget" mainwidget
    sd main
    setcall main mainwidget()
    importx "_gtk_message_dialog_new" gtk_message_dialog_new
    importx "_gtk_dialog_run" gtk_dialog_run
    importx "_gtk_widget_destroy" gtk_widget_destroy
    sd dialog
    setcall dialog gtk_message_dialog_new(main,(GTK_DIALOG_DESTROY_WITH_PARENT),(GTK_MESSAGE_INFO),(GTK_BUTTONS_OK),print)
    call gtk_dialog_run(dialog)
    call gtk_widget_destroy(dialog)
endfunction

##############pixbuf
#pixbuf/0
function new_pixbuf(sd width,sd height)
    importx "_gdk_pixbuf_new" gdk_pixbuf_new
    sd pixbuf
    setcall pixbuf gdk_pixbuf_new((GDK_COLORSPACE_RGB),0,8,width,height)
    if pixbuf==0
        str pxerr="Can't create a pixbuf"
        call texter(pxerr)
        return 0
    endif
    return pixbuf
endfunction

#pixbuf/0
function new_pixbuf_color(sd width,sd height,sd color)
    sd pixbuf
    setcall pixbuf new_pixbuf(width,height)
    if pixbuf==0
        return 0
    endif
    importx "_gdk_pixbuf_fill" gdk_pixbuf_fill
    call gdk_pixbuf_fill(pixbuf,color)
    return pixbuf
endfunction

#return a pixbuf
function msgelement_pixbuf(sd msg)
    importx "_gst_message_get_structure" gst_message_get_structure
    sd struct
    setcall struct gst_message_get_structure(msg)

    str pix="pixbuf"
    importx "_gst_structure_get_value" gst_structure_get_value
    sd value
    setcall value gst_structure_get_value(struct,pix)

    importx "_g_value_dup_object" g_value_dup_object
    sd pixbuf
    setcall pixbuf g_value_dup_object(value)

    return pixbuf
endfunction

function msgelement_pixbuf_forward_data(sd msg,sd forward,sd data)
    sd pixbuf
    setcall pixbuf msgelement_pixbuf(msg)

    call forward(pixbuf,data)

    call g_object_unref(pixbuf)
endfunction

importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
importx "_gdk_pixbuf_get_rowstride" gdk_pixbuf_get_rowstride

import "rgb_px_get" rgb_px_get
import "rgb_px_set" rgb_px_set

#0/pixbuf
function pixbuf_scale(sd pixbuf,sd w,sd h)
    sd newpixbuf
    setcall newpixbuf new_pixbuf(w,h)
    if newpixbuf==0
        return 0
    endif
    sd old_w
    sd old_h
    setcall old_w gdk_pixbuf_get_width(pixbuf)
    setcall old_h gdk_pixbuf_get_height(pixbuf)

    sd w_ratio
    set w_ratio old_w
    div w_ratio w
    if w_ratio==0
        set w_ratio 1
    endif
    sd h_ratio
    set h_ratio old_h
    div h_ratio h
    if h_ratio==0
        set h_ratio 1
    endif

    sd red
    sd green
    sd blue
    sd colors^red
    sd sum_red
    sd sum_green
    sd sum_blue
    sd sum_colors^sum_red

    sd old_pixels
    sd pixels
    setcall old_pixels gdk_pixbuf_get_pixels(pixbuf)
    setcall pixels gdk_pixbuf_get_pixels(newpixbuf)
    sd old_stride
    sd stride
    setcall old_stride gdk_pixbuf_get_rowstride(pixbuf)
    setcall stride gdk_pixbuf_get_rowstride(newpixbuf)

    sd j=0
    while j!=h
        import "rule3" rule3
        sd top
        setcall top rule3(j,h,old_h)
        sd bottom
        set bottom top
        add bottom h_ratio
        if bottom>old_h
            set bottom old_h
        endif
        #left,right.. on old pixbuf
        sd i=0
        while i!=w
            sd left
            setcall left rule3(i,w,old_w)
            sd right
            set right left
            add right w_ratio
            if right>old_w
                set right old_w
            endif

            import "rgb_uint_to_colors" rgb_uint_to_colors
            import "rgb_colors_to_uint" rgb_colors_to_uint

            sd number_of_colors=0

            sd x
            sd y
            set y top
            while y!=bottom
                set x left
                while x!=right
                    sd value
                    setcall value rgb_px_get(old_pixels,x,y,8,3,old_stride)

                    if number_of_colors==0
                        call rgb_uint_to_colors(value,sum_colors)
                    else
                        call rgb_uint_to_colors(value,colors)
                        add sum_red red
                        add sum_green green
                        add sum_blue blue
                    endelse

                    inc number_of_colors
                    inc x
                endwhile
                inc y
            endwhile
            div sum_red number_of_colors
            div sum_green number_of_colors
            div sum_blue number_of_colors

            setcall value rgb_colors_to_uint(sum_colors)
            call rgb_px_set(value,pixels,i,j,8,3,stride)

            inc i
        endwhile
        inc j
    endwhile
    return newpixbuf
endfunction

function pixbuf_scale_forward_data(sd pixbuf,sd scale_w,sd scale_h,sd forward,sd data)
    sd newpix

    setcall newpix pixbuf_scale(pixbuf,scale_w,scale_h)
    if newpix==0
        return (error)
    endif

    call forward(newpix,data)

    call g_object_unref(newpix)
endfunction

#forward the fit pixbuf in window
function pixbuf_in_window_scale_forward(sd pixbuf,sd window,sd forward)
    sd W
    sd H
    sd p_H^H

    sd w
    sd h

    importx "_gdk_window_get_width" gdk_window_get_width
    importx "_gdk_window_get_height" gdk_window_get_height

    setcall W gdk_window_get_width(window)
    if W==0
        return 0
    endif
    setcall H gdk_window_get_height(window)
    if H==0
        return 0
    endif
    setcall w gdk_pixbuf_get_width(pixbuf)
    setcall h gdk_pixbuf_get_height(pixbuf)

    import "rectangle_fit_container_rectangle" rectangle_fit_container_rectangle
    setcall W rectangle_fit_container_rectangle(w,h,W,H,p_H)

    call pixbuf_scale_forward_data(pixbuf,W,H,forward,window)
endfunction



#forward a pixbuf
include "../_include/difl.h" "../_include/difw.h"
import "gerrtoerr" gerrtoerr
import "getptrgerr" getptrgerr
#function pixbuf from file
function pixbuf_from_file(ss filename)
    sd pixbuf#1
    data null=NULL
    sd ptrgerror#1

    setcall ptrgerror getptrgerr()

    setcall pixbuf gdk_pixbuf_new_from_file(filename,ptrgerror)
    if pixbuf==null
            call gerrtoerr(ptrgerror)
            return null
    endif
    return pixbuf
endfunction
#returns the forward or null
function pixbuf_from_file_forward_data(ss filename,sd forward,sd data)
    sd pixbuf
    setcall pixbuf pixbuf_from_file(filename)
    sd null=0
    if pixbuf==null
        return null
    endif
    sd ret
    setcall ret forward(pixbuf,data)
    call g_object_unref(pixbuf)
    return ret
endfunction

#function pixbuf_from_file_forward(ss filename,sd forward)
#    data z=0
#    call pixbuf_from_file_forward_data(filename,forward,z)
#endfunction

importx "_gdk_pixbuf_copy" gdk_pixbuf_copy
function pixbuf_copy(sd pixbuf)
    sd px
    setcall px gdk_pixbuf_copy(pixbuf)
    if px==0
        str er="Could not create a pixbuf"
        call texter(er)
        return 0
    endif
    return px
endfunction

function pixbuf_get_wh(sd pixbuf,sd p_coord)
    setcall p_coord# gdk_pixbuf_get_width(pixbuf)
    add p_coord 4
    setcall p_coord# gdk_pixbuf_get_height(pixbuf)
endfunction

#rowstride
#function pixbuf_get_wh_rowstride_pixels(sd pixbuf,sd p_p,sd wh)
#    setcall p_p# gdk_pixbuf_get_pixels(pixbuf)
#    call pixbuf_get_wh(pixbuf,wh)
#    sd rw
#    setcall rw gdk_pixbuf_get_rowstride(pixbuf)
#    return rw
#endfunction

#0/pixbuf
function pixbuf_new_subpixels(sd pixbuf,sd left,sd top,sd right,sd bottom)
    sd w
    sd h
    set w right
    sub w left
    set h bottom
    sub h top

    sd newpixbuf
    setcall newpixbuf new_pixbuf(w,h)
    if newpixbuf==0
        return 0
    endif

    sd pixels
    sd newbytes
    setcall pixels gdk_pixbuf_get_pixels(pixbuf)
    setcall newbytes gdk_pixbuf_get_pixels(newpixbuf)

    sd mainwidth
    sd mainheight
    sd rowstr
    setcall mainwidth gdk_pixbuf_get_width(pixbuf)
    setcall mainheight gdk_pixbuf_get_height(pixbuf)
    setcall rowstr gdk_pixbuf_get_rowstride(pixbuf)

    import "rgb_get_all_sizes" rgb_get_all_sizes
    sd rowstride
    sd p_rowstride^rowstride
    call rgb_get_all_sizes(w,h,p_rowstride)

    sd i
    sd j

    sd y=0

    set j top
    while j!=bottom
        set i left
        sd x=0
        while i!=right
            sd value
            setcall value rgb_px_get(pixels,i,j,8,3,rowstr)
            call rgb_px_set(value,newbytes,x,y,8,3,rowstride)
            inc i
            inc x
        endwhile
        inc j
        inc y
    endwhile
    return newpixbuf
endfunction

#display the pixbuf
function pixbuf_draw_onwindow(sd pixbuf,sd drawable)
    data diether=GDK_RGB_DITHER_NONE
    importx "_gdk_draw_pixbuf" gdk_draw_pixbuf
    #(GdkDrawable *drawable,GdkGC *gc,const GdkPixbuf *pixbuf,
    #gint src_x,gint src_y,gint dest_x,gint dest_y,
    #gint width,gint height,GdkRgbDither dither,gint x_dither,gint y_dither)
    data default_size=-1
    data null=0
    call gdk_draw_pixbuf(drawable,null,pixbuf,null,null,null,null,default_size,default_size,diether,null,null)
endfunction

function pixbuf_set_pixel(sd pixbuf,sd value,sd x,sd y)
    sd bytes
    sd rowstride
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)
    call rgb_px_set(value,bytes,x,y,8,3,rowstride)
endfunction

#value
function pixbuf_get_pixel(sd pixbuf,sd x,sd y)
    sd bytes
    sd rowstride
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)
    sd value
    setcall value rgb_px_get(bytes,x,y,8,3,rowstride)
    return value
endfunction

function pixbuf_over_pixbuf(sd overpixbuf,sd laypixbuf,sd min_i,sd max_i,sd min_j,sd max_j)
    sd y=0
    sd i
    sd j
    set j min_j
    while j!=max_j
    sd x=0
        set i min_i
        while i!=max_i
            sd value
            setcall value pixbuf_get_pixel(overpixbuf,x,y)
            call pixbuf_set_pixel(laypixbuf,value,i,j)
            inc x
            inc i
        endwhile
        inc y
        inc j
    endwhile
endfunction

function surface_to_pixbufdata(sd surface,sd pixbuf)
    sd width
    sd height
    sd wh^width
    call pixbuf_get_wh(pixbuf,wh)
    importx "_cairo_image_surface_get_data" cairo_image_surface_get_data
    sd bytes
    setcall bytes cairo_image_surface_get_data(surface)
    sd pixels
    setcall pixels gdk_pixbuf_get_pixels(pixbuf)
    import "rgb_get_rowstride" rgb_get_rowstride
    sd p_stride
    setcall p_stride rgb_get_rowstride(width)
    sd b_stride
    set b_stride width
    mult b_stride 4

    sd b_sz
    set b_sz b_stride
    mult b_sz height
    sub b_sz b_stride
    add bytes b_sz

    import "convert_row_rgba_to_rgb" convert_row_rgba_to_rgb
    sd j=0
    while j!=height
        call convert_row_rgba_to_rgb(bytes,pixels,width)

        sub bytes b_stride
        add pixels p_stride
        inc j
    endwhile
endfunction

#pixbuf/0
function pixbuf_from_pixbuf_reverse(sd pixbuf_reverse)
	#the new pixbuf
	sd pixbuf
	setcall pixbuf pixbuf_copy(pixbuf_reverse)
	if pixbuf==0
		return 0
	endif

	#get width height
	sd w
	sd h
	sd p_wh^w
	call pixbuf_get_wh(pixbuf,p_wh)
	#reverse bytes
	sd bytes
	setcall bytes gdk_pixbuf_get_pixels(pixbuf)
	import "rgb_color_swap" rgb_color_swap
	call rgb_color_swap(bytes,w,h)

	return pixbuf
endfunction

##############progressbar
importx "_gtk_progress_bar_new" gtk_progress_bar_new
function progressfield(sd container)
    sd wid
    setcall wid gtk_progress_bar_new()
    importx "_gtk_box_pack_start" gtk_box_pack_start
    data true=1
    data false=0
    call gtk_box_pack_start(container,wid,true,false,false)
    return wid
endfunction

##############radio
#function radiofield_prepare(sd previousbutton,ss text)
#    importx "_gtk_radio_button_new_with_label" gtk_radio_button_new_with_label
#    importx "_gtk_radio_button_get_group" gtk_radio_button_get_group

#    sd radiogroup
#    setcall radiogroup gtk_radio_button_get_group(previousbutton)

#    sd rd
#    setcall rd gtk_radio_button_new_with_label(radiogroup,text)
#    return rd
#endfunction

#function radiofield(sd previousbutton,ss text,sd box)
#    sd rd
#    setcall rd radiofield_prepare(previousbutton,text)
#    call packstart_default(box,rd)
#    return rd
#endfunction

##############widget
#ancestor
function widget_get_ancestor(sd widget,sd ancestor_parent)
    importx "_gtk_widget_get_parent" gtk_widget_get_parent
    sd ancestor
    while widget!=ancestor_parent
        set ancestor widget
        setcall widget gtk_widget_get_parent(widget)
    endwhile
    return ancestor
endfunction

function widget_draw_pixbuf(sd widget,sd pixbuf)
    importx "_gtk_widget_get_window" gtk_widget_get_window
    sd drawable
    setcall drawable gtk_widget_get_window(widget)
    data fn^pixbuf_draw_onwindow
    call pixbuf_in_window_scale_forward(pixbuf,drawable,fn)
endfunction

function widget_redraw(sd widget)
    sd drawable
    setcall drawable gtk_widget_get_window(widget)
    if drawable==0
        str nodraw="No drawing area error."
        call texter(nodraw)
        return nodraw
    endif
    importx "_gdk_window_invalidate_rect" gdk_window_invalidate_rect
    call gdk_window_invalidate_rect(drawable,0,0)
endfunction
