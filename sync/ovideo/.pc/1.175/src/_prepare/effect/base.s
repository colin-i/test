


format elfobj

include "../../_include/include.h"

import "hboxfield_cnt" hboxfield_cnt

##the number of frames

data nr_frames_entry#1
const p_nr_frames_entry^nr_frames_entry

function stage_effect_get_nr_frames_entry()
    sd p%p_nr_frames_entry
    return p#
endfunction

function stage_effect_nr_frames(sd vbox)
    sd hbox
    import "labelfield_l" labelfield_l
    #the effect frames
    setcall hbox hboxfield_cnt(vbox)
    ss text="Effect number of frames: "
    call labelfield_l(text,hbox)
    import "editfield_pack" editfield_pack
    sd p_edit%p_nr_frames_entry
    setcall p_edit# editfield_pack(hbox)
endfunction

importx "_gtk_entry_get_text" gtk_entry_get_text
importx "_gtk_radio_button_new_with_label" gtk_radio_button_new_with_label
importx "_gtk_radio_button_get_group" gtk_radio_button_get_group

##in or out

#out return
function stage_effect_in_out(sd vbox,ss t_in,ss t_out)
    sd hbox
    setcall hbox hboxfield_cnt(vbox)

    sd in
    setcall in gtk_radio_button_new_with_label(0,t_in)

    sd radiogroup
    setcall radiogroup gtk_radio_button_get_group(in)

    sd out
    setcall out gtk_radio_button_new_with_label(radiogroup,t_out)

    import "packstart_default" packstart_default
    call packstart_default(hbox,in)
    call packstart_default(hbox,out)

    return out
endfunction

##background

data color_button#1
const p_color_button^color_button
data image_button#1
const p_image_button^image_button

function stage_effect_get_image_button()
    sd p_image_button%p_image_button
    return p_image_button#
endfunction
function stage_effect_get_color_button()
    sd p_color_button%p_color_button
    return p_color_button#
endfunction

import "labelfield_left_default" labelfield_left_default

function stage_effect_background(sd vbox)
    import "hseparatorfield" hseparatorfield

    call hseparatorfield(vbox)

    #color
    sd p_color%p_color_button
    ss color_text="Color: "
    import "colorbuttonfield_leftlabel" colorbuttonfield_leftlabel
    setcall p_color# colorbuttonfield_leftlabel(color_text,vbox)

    ss text1="Selected frame OVER Color."
    call labelfield_left_default(text1,vbox)

    ss text_or="OR"
    call labelfield_left_default(text_or,vbox)

    import "fchooserbuttonfield_open" fchooserbuttonfield_open
    ss text2="Image from file fit (color at free space) OVER Selected frame:"
    call labelfield_left_default(text2,vbox)
    sd p_image_button%p_image_button
    ss ib_text="Image"
    setcall p_image_button# fchooserbuttonfield_open(vbox,ib_text)

    call hseparatorfield(vbox)
endfunction

##effect loop function

function stage_effect_new(sd forward,sd data)
    sd bool
    data nr#1
    #the effect frames
    sd nr_edit
    setcall nr_edit stage_effect_get_nr_frames_entry()
    sd nr_text
    setcall nr_text gtk_entry_get_text(nr_edit)
    sd p_nr^nr
    import "strtoint_positive_twoorgreater" strtoint_positive_twoorgreater
    setcall bool strtoint_positive_twoorgreater(nr_text,p_nr)
    if bool==0
        set nr 2
    endif

    #get sel position
    import "stage_get_sel_pos" stage_get_sel_pos
    sd pos
    setcall pos stage_get_sel_pos()
    #total positions for reorder compare
    import "stage_get_frames" stage_get_frames
    sd total_pos
    setcall total_pos stage_get_frames()
    #new frames pos(without sel,that is also a new frame)
    inc pos
    #frames container for reorder
    import "stage_get_frames_container" stage_get_frames_container
    sd box
    setcall box stage_get_frames_container()
    #newframepos
    sd newframepos
    set newframepos pos
    #nr-1
    sd last_index
    set last_index nr
    dec last_index

    #new frames with length like sel
    import "stage_get_sel_fr_length" stage_get_sel_fr_length
    sd length
    setcall length stage_get_sel_fr_length()
    import "stage_frame_time_numbers" stage_frame_time_numbers
    call stage_frame_time_numbers((stage_frame_time_insert),pos,length,last_index)

    #pixbuf for the effect
    import "stage_get_sel_pixbuf" stage_get_sel_pixbuf
    sd pixbuf
    sd p_pixbuf^pixbuf
    call stage_get_sel_pixbuf(p_pixbuf)

    #test for not accessing invalid memory
    import "rgb_test" rgb_test
    setcall bool rgb_test(pixbuf)
    if bool==0
        return 0
    endif

    #get dimensions
    importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
    importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
    sd w
    setcall w gdk_pixbuf_get_width(pixbuf)
    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
    sd h
    setcall h gdk_pixbuf_get_height(pixbuf)
    importx "_gdk_pixbuf_get_rowstride" gdk_pixbuf_get_rowstride
    sd rowstride
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)

    #color and new image
    #color from bytes to dword
    import "color_widget_get_color_to_rgb" color_widget_get_color_to_rgb
    sd colors_entry
    setcall colors_entry stage_effect_get_color_button()
    sd uint_color
    setcall uint_color color_widget_get_color_to_rgb(colors_entry)
    #animation pixbuf from new image or the selected frame
    sd animpixbuf
    importx "_g_object_unref" g_object_unref

    sd newimage_entry
    setcall newimage_entry stage_effect_get_image_button()
    import "file_chooser_get_fname" file_chooser_get_fname
    import "new_pixbuf_color" new_pixbuf_color
    sd filename
    setcall filename file_chooser_get_fname(newimage_entry)
    if filename==0
        set animpixbuf pixbuf
    else
        setcall animpixbuf new_pixbuf_color(w,h,uint_color)
        if animpixbuf==0
            return 0
        endif
        import "pixbuf_from_file" pixbuf_from_file
        sd filepixbuf
        setcall filepixbuf pixbuf_from_file(filename)
        if filepixbuf==0
            return 0
        endif
        import "stage_pixbuf_in_container_pixbuf" stage_pixbuf_in_container_pixbuf
        call stage_pixbuf_in_container_pixbuf(filepixbuf,animpixbuf)
        call g_object_unref(filepixbuf)
        importx "_g_free" g_free
        call g_free(filename)
    endelse

    #get the in/out value
    sd in_out_entry
    setcall in_out_entry stage_effect_inout(1)
    importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
    sd in_out
    setcall in_out gtk_toggle_button_get_active(in_out_entry)

    import "stage_get_sel_parent" stage_get_sel_parent
    import "stage_new_click_area" stage_new_click_area
    sd effectpixbuf
    sd k=0
    while k!=nr
        sd ebox
        sd p_ebox^ebox
        if k==0
            call stage_get_sel_parent(p_ebox)
        else
            setcall ebox stage_new_click_area()
            if pos!=total_pos
                #insert the frame
                importx "_gtk_box_reorder_child" gtk_box_reorder_child
                call gtk_box_reorder_child(box,ebox,newframepos)
            endif
        endelse

        if filename==0
            #background is color
            setcall effectpixbuf new_pixbuf_color(w,h,uint_color)
        else
            #background is selected frame
            import "pixbuf_copy" pixbuf_copy
            setcall effectpixbuf pixbuf_copy(pixbuf)
        endelse
        if effectpixbuf==0
            return 0
        endif

        #transform
        sd pixels
        setcall pixels gdk_pixbuf_get_pixels(effectpixbuf)
        sd animpix
        setcall animpix gdk_pixbuf_get_pixels(animpixbuf)

        #function stage_tool(sd part,sd k,sd nr,sd pixels,sd w,sd h,sd rowstride,sd animpixels,sd animpixbuf,sd in_out)
        call forward(data,k,nr,pixels,w,h,rowstride,animpix,animpixbuf,in_out)

        if k==0
            #set the transformed pixbuf and display it
            import "object_set_dword_name" object_set_dword_name
            call object_set_dword_name(ebox,effectpixbuf)
            import "stage_redraw" stage_redraw
            call stage_redraw()
        else
            #add pixbuf to frame
            import "stage_pixbuf_to_container" stage_pixbuf_to_container
            call stage_pixbuf_to_container(effectpixbuf,ebox)
            inc newframepos
        endelse
        inc k
    endwhile

    call g_object_unref(pixbuf)

    if filename!=0
        call g_object_unref(animpixbuf)
    endif
endfunction

##entry,inout and background

function stage_effect_common_fields(sd vbox,ss in_text,ss out_text)
    call stage_effect_nr_frames(vbox)
    sd in_out
    setcall in_out stage_effect_in_out(vbox,in_text,out_text)
    call stage_effect_inout(0,in_out)
    call stage_effect_background(vbox)
endfunction

function stage_effect_inout(sd part,sd value)
    data in_out#1
    if part==0
        set in_out value
    else
        return in_out
    endelse
endfunction



function stage_effect_orientation(sd part,sd argument,sd use_center_bool,sd text)
    if part==0
    #returns the frame
        data use_center#1
        set use_center use_center_bool

        sd vbox
        set vbox argument
        #frame
        import "framefield" framefield
        sd frame
        setcall frame framefield(vbox,text)

        sd framechild
        import "tablefield" tablefield
        setcall framechild tablefield(frame,3,3)

        data o_top_left#1
        data o_top#1
        data o_top_right#1
        data o_left#1
        data o_center#1
        data o_right#1
        data o_bottom_left#1
        data o_bottom#1
        data *o_bottom_right#1
        ss o_top_left_text="Top-Left"
        ss *o_top_text="Top"
        ss *o_top_right_text="Top-Right"
        ss *o_left_text="Left"
        ss *o_center_text="Center"
        ss *o_right_text="Right"
        ss *o_bottom_left_text="Bottom-Left"
        ss *o_bottom_text="Bottom"
        ss *o_bottom_right_text="Bottom-Right"

        import "table_attach" table_attach
        sd p_orientation^o_top_left
        sd p_text_orientation^o_top_left_text
        sd o_y=0
        sd radio=0
        while o_y!=3
            sd o_x
            set o_x 0
            while o_x!=3
                sd skip
                set skip (FALSE)
                if use_center==(FALSE)
                    if o_y==1
                        if o_x==1
                            set skip (TRUE)
                        endif
                    endif
                endif
                if skip==(FALSE)
                    if radio!=0
                        setcall radio gtk_radio_button_get_group(radio)
                    endif
                    setcall radio gtk_radio_button_new_with_label(radio,p_text_orientation#)

                    call table_attach(framechild,radio,o_x,o_y)
                endif

                set p_orientation# radio
                add p_orientation 4
                add p_text_orientation 4
                inc o_x
            endwhile
            inc o_y
        endwhile
        importx "_gtk_toggle_button_set_active" gtk_toggle_button_set_active
        call gtk_toggle_button_set_active(o_center,1)
        return frame
    else
        sd p_top
        set p_top argument

        sd bool

        #top-left
        setcall bool gtk_toggle_button_get_active(o_top_left)
        if bool==1
            set p_top# -1
            return -1
        endif
        #top
        setcall bool gtk_toggle_button_get_active(o_top)
        if bool==1
            set p_top# -1
            return 0
        endif
        #top-right
        setcall bool gtk_toggle_button_get_active(o_top_right)
        if bool==1
            set p_top# -1
            return 1
        endif
        #left
        setcall bool gtk_toggle_button_get_active(o_left)
        if bool==1
            set p_top# 0
            return -1
        endif
        #center
        if use_center==(TRUE)
            setcall bool gtk_toggle_button_get_active(o_center)
            if bool==1
                set p_top# 0
                return 0
            endif
        endif
        #right
        setcall bool gtk_toggle_button_get_active(o_right)
        if bool==1
            set p_top# 0
            return 1
        endif
        #bottom-left
        setcall bool gtk_toggle_button_get_active(o_bottom_left)
        if bool==1
            set p_top# 1
            return -1
        endif
        #bottom
        setcall bool gtk_toggle_button_get_active(o_bottom)
        if bool==1
            set p_top# 1
            return 0
        endif
        #bottom-right
        set p_top# 1
        return 1
    endelse
endfunction
