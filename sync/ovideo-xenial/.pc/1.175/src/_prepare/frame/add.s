

format elfobj

include "../../_include/include.h"

import "filechooserfield_forward" filechooserfield_forward
import "pixbuf_from_file" pixbuf_from_file

#new frame
function stage_new_frame()
    data f^stage_new_frame_got_filename
    call filechooserfield_forward(f)
endfunction
function stage_new_frame_got_filename(ss filename)
    sd pixbuf
    setcall pixbuf pixbuf_from_file(filename)
    sd z=0
    if pixbuf!=z
        call stage_new_pixbuf(pixbuf)
    endif
endfunction
function stage_new_pixbuf(sd pixbuf)
    str text="Frame added. Total frames: "
    import "stage_new_pix" stage_new_pix
    call stage_new_pix(pixbuf,text)
    import "stage_display_last" stage_display_last
    call stage_display_last()
endfunction


function stage_filechooser_verify_noframes(sd forward_fn)
    import "stage_get_sel" stage_get_sel
    sd img
    setcall img stage_get_sel()
    if img==0
        return 0
    endif
    call filechooserfield_forward(forward_fn)
endfunction

import "stage_get_sel_pixbuf" stage_get_sel_pixbuf

#new frame centered on existing
function stage_add_centered()
    data f^stage_add_centered_fn
    call stage_filechooser_verify_noframes(f)
endfunction
function stage_add_centered_fn(sd filename)
    sd newpixbuf
    setcall newpixbuf pixbuf_from_file(filename)
    if newpixbuf==0
        return 0
    endif
    sd pixbuf
    sd p_pixbuf^pixbuf
    call stage_get_sel_pixbuf(p_pixbuf)
    call stage_pixbuf_in_container_pixbuf(newpixbuf,pixbuf)
    importx "_g_object_unref" g_object_unref
    call g_object_unref(newpixbuf)
    import "stage_redraw" stage_redraw
    call stage_redraw()
endfunction

import "pixbuf_get_wh" pixbuf_get_wh

function stage_pixbuf_in_container_pixbuf(sd newpixbuf,sd containerpixbuf)
    sd width
    sd height
    sd p_height^height
    sd p_new^width
    sd c_width
    sd c_height
    sd p_c^c_width
    call pixbuf_get_wh(newpixbuf,p_new)
    call pixbuf_get_wh(containerpixbuf,p_c)

    import "rectangle_fit_container_rectangle" rectangle_fit_container_rectangle
    setcall width rectangle_fit_container_rectangle(width,height,c_width,c_height,p_height)

    #test for not accessing invalid memory
    import "rgb_test" rgb_test
    sd bool
    setcall bool rgb_test(containerpixbuf)
    if bool==0
        return 0
    endif
    setcall bool rgb_test(newpixbuf)
    if bool==0
        return 0
    endif

    import "pixbuf_scale_forward_data" pixbuf_scale_forward_data
    data f^stage_pixbuf_in_container_pixbuf_set
    call pixbuf_scale_forward_data(newpixbuf,width,height,f,containerpixbuf)
endfunction

function stage_pixbuf_in_container_pixbuf_set(sd newpixbuf,sd containerpixbuf)
    sd width
    sd height
    sd c_width
    sd c_height
    sd p_new_coord^width
    sd p_cnt_coord^c_width
    call pixbuf_get_wh(newpixbuf,p_new_coord)
    call pixbuf_get_wh(containerpixbuf,p_cnt_coord)

    sd x=0
    sd y=0
    if width<c_width
        set x c_width
        sub x width
        div x 2
    elseif height<c_height
        set y c_height
        sub y height
        div y 2
    endelseif

    import "rgb_pixbuf_get_pixel" rgb_pixbuf_get_pixel
    import "rgb_pixbuf_set_pixel" rgb_pixbuf_set_pixel
    sd j=0
    sd x_off
    set x_off x
    while j!=height
        sd i=0
        set x x_off
        while i!=width
            sd value
            setcall value rgb_pixbuf_get_pixel(newpixbuf,i,j,8,3)
            call rgb_pixbuf_set_pixel(value,containerpixbuf,x,y,8,3)
            inc x
            inc i
        endwhile
        inc y
        inc j
    endwhile
endfunction





#new frame with defined color and width height from selected frame(or nothing if there is no frame)
function stage_new_frame_form()
    ss title="Add a frame"
    import "dialogfield" dialogfield
    data init^stage_new_frame_form_init
    data on_ok^stage_new_frame_form_set
    call dialogfield(title,(GTK_DIALOG_MODAL),init,on_ok)
endfunction

function stage_new_frame_form_init(sd vbox,sd *dialog)
    import "stage_get_sel_pixbuf_nowarning" stage_get_sel_pixbuf_nowarning

    sd px=0
    sd p_px^px
    call stage_get_sel_pixbuf_nowarning(p_px)

    call stage_frame_form_data_init(vbox,px)
endfunction

function stage_new_frame_form_set()
    sd pixbuf
    setcall pixbuf stage_frame_form_data((stage_frame_form_data_pixbuf))
    if pixbuf==0
        return 0
    endif
    call stage_new_pixbuf(pixbuf)
endfunction

function stage_frame_form_data_init(sd vbox,sd pixbuf)
    importx "_gtk_table_new" gtk_table_new
    importx "_gtk_table_attach_defaults" gtk_table_attach_defaults
    import "labelfield_left_prepare" labelfield_left_prepare
    importx "_gtk_entry_new" gtk_entry_new
    import "int_to_entry" int_to_entry

    sd value
    sd table
    setcall table gtk_table_new(2,2,0)

    ss w_text="Width: "
    setcall value labelfield_left_prepare(w_text)
    call gtk_table_attach_defaults(table,value,0,1,0,1)
    setcall value gtk_entry_new()
    if pixbuf!=0
        importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
        sd wd
        setcall wd gdk_pixbuf_get_width(pixbuf)
        call int_to_entry(wd,value)
    endif

    call stage_frame_form_data((stage_frame_form_data_width),value)
    call gtk_table_attach_defaults(table,value,1,2,0,1)

    ss h_text="Height: "
    setcall value labelfield_left_prepare(h_text)
    call gtk_table_attach_defaults(table,value,0,1,1,2)
    setcall value gtk_entry_new()
    if pixbuf!=0
        importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
        sd hg
        setcall hg gdk_pixbuf_get_height(pixbuf)
        call int_to_entry(hg,value)
    endif
    call stage_frame_form_data((stage_frame_form_data_height),value)
    call gtk_table_attach_defaults(table,value,1,2,1,2)

    importx "_gtk_container_add" gtk_container_add
    call gtk_container_add(vbox,table)

    import "colorbuttonfield_leftlabel" colorbuttonfield_leftlabel
    ss bgcolor="Color: "
    setcall value colorbuttonfield_leftlabel(bgcolor,vbox)
    call stage_frame_form_data((stage_frame_form_data_color),value)
endfunction

function stage_frame_form_data(sd action,sd value)
    if action==0
        data width_entry#1
        set width_entry value
        return 0
    elseif action==1
        data height_entry#1
        set height_entry value
        return 0
    elseif action==2
        data color_entry#1
        set color_entry value
        return 0
    endelseif

    import "entry_to_nr_minValue" entry_to_nr_minValue

    sd width
    sd p_w^width
    call entry_to_nr_minValue(width_entry,p_w,4)

    sd height
    sd p_h^height
    call entry_to_nr_minValue(height_entry,p_h,4)

    import "color_widget_get_color_to_rgb" color_widget_get_color_to_rgb
    sd color
    setcall color color_widget_get_color_to_rgb(color_entry)

    import "new_pixbuf_color" new_pixbuf_color
    sd pixbuf
    setcall pixbuf new_pixbuf_color(width,height,color)
    if pixbuf==0
        return 0
    endif

    return pixbuf
endfunction

