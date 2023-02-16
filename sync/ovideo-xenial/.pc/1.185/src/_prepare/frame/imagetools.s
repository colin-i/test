

format elfobj

include "../../_include/include.h"

import "stage_frame_dialog" stage_frame_dialog

function stage_color_under_image()
    ss title="Color under image"
    data init^stage_color_under_image_init
    data on_ok^stage_color_under_image_set
    call stage_frame_dialog(init,on_ok,title)
endfunction

function stage_color_under_image_init(sd vbox,sd *dialog)
    import "stage_frame_form_data_init" stage_frame_form_data_init
    call stage_frame_form_data_init(vbox,0)
endfunction

function stage_color_under_image_set()
    import "stage_frame_form_data" stage_frame_form_data
    sd newpixbuf
    setcall newpixbuf stage_frame_form_data((stage_frame_form_data_pixbuf))
    if newpixbuf==0
        return 0
    endif

    sd pixbuf
    sd p_pixbuf^pixbuf

    import "stage_get_sel_pixbuf" stage_get_sel_pixbuf
    call stage_get_sel_pixbuf(p_pixbuf)

    import "stage_pixbuf_in_container_pixbuf" stage_pixbuf_in_container_pixbuf
    call stage_pixbuf_in_container_pixbuf(pixbuf,newpixbuf)

    import "stage_sel_replace_pixbuf" stage_sel_replace_pixbuf
    call stage_sel_replace_pixbuf(newpixbuf)
endfunction


#headlights

function headline_dialog()
    import "frame_jobs" frame_jobs
    sd bool
    setcall bool frame_jobs()
    if bool!=1
        return 0
    endif

    ss title="Headlines"

    importx "_gtk_dialog_new_with_buttons" gtk_dialog_new_with_buttons
    import "mainwidget" mainwidget
    sd window
    setcall window mainwidget()

    ss ok_button="OK"
    ss close_button="Close"
    sd dialog
    setcall dialog gtk_dialog_new_with_buttons(title,window,(GTK_DIALOG_MODAL|GTK_DIALOG_DESTROY_WITH_PARENT),ok_button,(GTK_RESPONSE_OK),close_button,(GTK_RESPONSE_CANCEL),0)

    importx "_gtk_dialog_get_content_area" gtk_dialog_get_content_area
    sd vbox
    setcall vbox gtk_dialog_get_content_area(dialog)

    call headline_dlg((value_set),vbox)

    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(dialog)

    sd loop=1
    while loop==1
        importx "_gtk_dialog_run" gtk_dialog_run
        sd resp
        setcall resp gtk_dialog_run(dialog)
        set loop 0
        if resp==(GTK_RESPONSE_OK)
            sd err
            setcall err headline_dlg((value_get))
            if err!=(noerror)
                set loop 1
                import "message_dialog" message_dialog
                call message_dialog(err)
            endif
        endif
    endwhile

    importx "_gtk_widget_destroy" gtk_widget_destroy
    call gtk_widget_destroy(dialog)
endfunction

function headline_dlg(sd action,sd vbox)
    if action==(value_set)
        data headline_txt#1
        data headline_entry#1

        data hsep1#1
        data pos_chbox#1

        data pos_txt#1
        data left_txt#1
        data left_entry#1
        data top_txt#1
        data top_entry#1

        data location#1

        data hsep2#1

        data size_txt#1
        data size_x#1
        data color_txt#1
        data color_x#1

        data size_entry#1
        data color_entry#1

        data frames_txt#1
        data frames_entry#1

        importx "_gtk_table_new" gtk_table_new
        importx "_gtk_table_attach" gtk_table_attach
        const hl_rows=5
        const hl_cols=2
        sd table
        setcall table gtk_table_new((hl_rows),(hl_cols),(FALSE))

        import "labelfield_left_prepare" labelfield_left_prepare
        importx "_gtk_entry_new" gtk_entry_new
        importx "_gtk_hbox_new" gtk_hbox_new
        import "packstart_default" packstart_default

        sd j=0
        sd j_next=1

        #headline
        ss hl="Headline "
        setcall headline_txt labelfield_left_prepare(hl)
        setcall headline_entry gtk_entry_new()
        call gtk_table_attach(table,headline_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,headline_entry,1,2,j,j_next,(GTK_FILL),0,0,0)

        #hsep1
        importx "_gtk_hseparator_new" gtk_hseparator_new
        setcall hsep1 gtk_hseparator_new()
        inc j
        inc j_next
        call gtk_table_attach(table,hsep1,0,2,j,j_next,(GTK_FILL|GTK_EXPAND),0,0,10)

        #coord or zone
        importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
        ss pos_chbox_txt="Use Coordinates"
        setcall pos_chbox gtk_check_button_new_with_label(pos_chbox_txt)
        inc j
        inc j_next
        call gtk_table_attach(table,pos_chbox,0,2,j,j_next,(GTK_FILL|GTK_EXPAND),0,0,0)

        #pos
        str pos_text="Coordinates:"
        setcall pos_txt labelfield_left_prepare(pos_text)
        inc j
        inc j_next
        call gtk_table_attach(table,pos_txt,0,2,j,j_next,(GTK_FILL),0,0,0)

        #position
        ss lf="Left"
        setcall left_txt labelfield_left_prepare(lf)
        setcall left_entry gtk_entry_new()
        inc j
        inc j_next
        call gtk_table_attach(table,left_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,left_entry,1,2,j,j_next,(GTK_FILL),0,0,0)

        ss tp="Top"
        setcall top_txt labelfield_left_prepare(tp)
        setcall top_entry gtk_entry_new()
        inc j
        inc j_next
        call gtk_table_attach(table,top_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,top_entry,1,2,j,j_next,(GTK_FILL),0,0,0)

        #location
        import "stage_effect_orientation" stage_effect_orientation
        ss loc="Location"
        setcall location stage_effect_orientation(0,0,(TRUE),loc)
        inc j
        inc j_next
        call gtk_table_attach(table,location,0,2,j,j_next,(GTK_FILL),0,0,0)

        #hsep2
        setcall hsep2 gtk_hseparator_new()
        inc j
        inc j_next
        call gtk_table_attach(table,hsep2,0,2,j,j_next,(GTK_FILL|GTK_EXPAND),0,0,10)

        #size
        ss sz="Size"
        setcall size_txt labelfield_left_prepare(sz)
        importx "_gtk_combo_box_text_new" gtk_combo_box_text_new
        setcall size_x gtk_hbox_new(0,0)
        setcall size_entry gtk_combo_box_text_new()
        call packstart_default(size_x,size_entry)
        chars str_data#30
        str nr_ascii^str_data
        str format="%u"
        sd nr=10
        importx "_sprintf" sprintf
        while nr!=51
            call sprintf(nr_ascii,format,nr)
            importx "_gtk_combo_box_text_append_text" gtk_combo_box_text_append_text
            call gtk_combo_box_text_append_text(size_entry,nr_ascii)
            inc nr
        endwhile
        importx "_gtk_combo_box_set_active" gtk_combo_box_set_active
        call gtk_combo_box_set_active(size_entry,10)
        inc j
        inc j_next
        call gtk_table_attach(table,size_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,size_x,1,2,j,j_next,(GTK_FILL),0,0,0)

        #color
        ss cl="Color"
        setcall color_txt labelfield_left_prepare(cl)
        importx "_gtk_color_button_new" gtk_color_button_new
        setcall color_x gtk_hbox_new(0,0)
        setcall color_entry gtk_color_button_new()
        call packstart_default(color_x,color_entry)
        inc j
        inc j_next
        call gtk_table_attach(table,color_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,color_x,1,2,j,j_next,(GTK_FILL),0,0,0)

        #frames
        ss fr="Frames"
        setcall frames_txt labelfield_left_prepare(fr)
        setcall frames_entry gtk_entry_new()
        inc j
        inc j_next
        call gtk_table_attach(table,frames_txt,0,1,j,j_next,(GTK_FILL),0,0,0)
        call gtk_table_attach(table,frames_entry,1,2,j,j_next,(GTK_FILL),0,0,0)

        call packstart_default(vbox,table)
    else
        import "stage_get_selection_pixbuf" stage_get_selection_pixbuf
        sd px
        setcall px stage_get_selection_pixbuf()

        #headlight
        importx "_gtk_entry_get_text" gtk_entry_get_text
        sd headline
        setcall headline gtk_entry_get_text(headline_entry)

        #coord or location
        importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
        sd coordinates_flag
        setcall coordinates_flag gtk_toggle_button_get_active(pos_chbox)

        sd x
        sd y
        sd p_y^y

        if coordinates_flag==1
            #test on coordinates
            import "pixbuf_get_wh" pixbuf_get_wh
            sd w
            sd h
            sd wh^w
            call pixbuf_get_wh(px,wh)

            import "strtoint" strtoint
            str integer_err="Text coordinate to number failed"
            str coord_err="Positive coordinate expected"
            str toobig_err="A lower coordinate value expected"
            sd p_x^x
            setcall x gtk_entry_get_text(left_entry)
            sd bool
            setcall bool strtoint(x,p_x)
            if bool==0
                return integer_err
            endif
            if x<0
                return coord_err
            endif
            if x>=w
                return toobig_err
            endif

            setcall y gtk_entry_get_text(top_entry)
            setcall bool strtoint(y,p_y)
            if bool==0
                return integer_err
            endif
            if y<0
                return coord_err
            endif
            if y>=h
                return toobig_err
            endif
            #
        else
            #location
            setcall x stage_effect_orientation(1,p_y)
        endelse

        #size
        importx "_gtk_combo_box_text_get_active_text" gtk_combo_box_text_get_active_text
        sd sz_text
        setcall sz_text gtk_combo_box_text_get_active_text(size_entry)
        sd fontsize
        sd p_fontsize^fontsize
        call strtoint(sz_text,p_fontsize)

        #color
        import "color_widget_get_color" color_widget_get_color
        sd color
        setcall color color_widget_get_color(color_entry)

        #number of frames
        import "stage_get_sel_pos" stage_get_sel_pos
        sd nr_text
        sd frames
        sd p_frames^frames
        sd pos
        setcall pos stage_get_sel_pos()
        setcall nr_text gtk_entry_get_text(frames_entry)
        setcall bool strtoint(nr_text,p_frames)
        if bool==1
            if frames<=0
                str moreframes="More frames expected"
                return moreframes
            endif
            import "stage_get_frames" stage_get_frames
            sd totalframes
            setcall totalframes stage_get_frames()
            sub totalframes pos
                #2 frames total, 1 is sel, 1 is available, frame>available is err
            if frames>totalframes
                str toomanyframes="Too many frames value"
                return toomanyframes
            endif
        else
            #set default 1 frame
            set frames 1
        endelse

        while frames!=0
            import "stage_nthwidgetFromcontainer" stage_nthwidgetFromcontainer
            sd ebox
            setcall ebox stage_nthwidgetFromcontainer(pos)

            import "object_get_dword_name" object_get_dword_name
            sd pbuf
            setcall pbuf object_get_dword_name(ebox)

            import "pixbuf_draw_text" pixbuf_draw_text
            sd newpixbuf
            setcall newpixbuf pixbuf_draw_text(pbuf,headline,x,y,fontsize,color,coordinates_flag)

            import "unref_pixbuf_frame" unref_pixbuf_frame
            call unref_pixbuf_frame(ebox)

            import "object_set_dword_name" object_set_dword_name
            call object_set_dword_name(ebox,newpixbuf)

            inc pos
            dec frames
        endwhile

        import "stage_redraw" stage_redraw
        call stage_redraw()

        return (noerror)
    endelse
endfunction


import "av_dialog_run_simple" av_dialog_run_simple
import "av_dialog_close" av_dialog_close
import "av_dialog_stop" av_dialog_stop

function stage_lines()
    ss title="Add/Remove lines"
    data init^stage_lines_init
    data on_ok^stage_lines_set
    call stage_frame_dialog(init,on_ok,title)
endfunction

function stage_lines_init(sd vbox)
    import "label_and_edit" label_and_edit
    ss frames="Lines on a side: "
    sd entry
    setcall entry stage_line_entry()
    setcall entry# label_and_edit(vbox,frames)
    str default="1"
    importx "_gtk_entry_set_text" gtk_entry_set_text
    call gtk_entry_set_text(entry#,default)
    #
    importx "_gtk_radio_button_new_with_label" gtk_radio_button_new_with_label
    importx "_gtk_radio_button_get_group" gtk_radio_button_get_group
    ss add_text="Add"
    sd add
    setcall add gtk_radio_button_new_with_label(0,add_text)
    sd add_rem_radiogroup
    setcall add_rem_radiogroup gtk_radio_button_get_group(add)
    ss rem_text="Remove"
    sd rem
    setcall rem gtk_radio_button_new_with_label(add_rem_radiogroup,rem_text)
    sd add_remove_entry
    setcall add_remove_entry stage_lines_add_remove_entry()
    importx "_gtk_container_add" gtk_container_add
    sd add_rem_hbox
    setcall add_rem_hbox gtk_hbox_new(0,0)
    call gtk_container_add(add_rem_hbox,add)
    call gtk_container_add(add_rem_hbox,rem)
    call gtk_container_add(vbox,add_rem_hbox)
    set add_remove_entry# rem
    #
    ss color_text="Color: "
    import "colorbuttonfield_leftlabel" colorbuttonfield_leftlabel
    sd color_entry
    setcall color_entry stage_line_color_entry()
    setcall color_entry# colorbuttonfield_leftlabel(color_text,vbox)
    #
    ss row_text="Rows"
    sd row
    setcall row gtk_radio_button_new_with_label(0,row_text)
    sd radiogroup
    setcall radiogroup gtk_radio_button_get_group(row)
    ss col_text="Columns"
    sd col
    setcall col gtk_radio_button_new_with_label(radiogroup,col_text)
    sd row_col_entry
    setcall row_col_entry stage_line_row_col_entry()
    sd hbox
    setcall hbox gtk_hbox_new(0,0)
    call gtk_container_add(hbox,row)
    call gtk_container_add(hbox,col)
    call gtk_container_add(vbox,hbox)
    set row_col_entry# col
    #
    import "hseparatorfield_nopad" hseparatorfield_nopad
    call hseparatorfield_nopad(vbox)
    sd start_entry
    sd end_entry
    sd start
    sd end
    setcall start_entry stage_lines_start_entry()
    setcall end_entry stage_lines_end_entry()
    setcall start stage_lines_start()
    setcall end stage_lines_end()
    set start# 0
    setcall end# stage_get_frames()
    ss start_text="Start frame: "
    ss end_text="End frame: "
    setcall start_entry# label_and_edit(vbox,start_text)
    setcall end_entry# label_and_edit(vbox,end_text)
endfunction

function stage_lines_number()
    data number#1
    return #number
endfunction
function stage_line_entry()
    data add_entry#1
    return #add_entry
endfunction
function stage_line_color_entry()
    data entry#1
    return #entry
endfunction
function stage_line_color()
    data color#1
    return #color
endfunction
function stage_line_row_col_entry()
    data entry#1
    return #entry
endfunction
function stage_line_row_col()
    data row_col#1
    return #row_col
endfunction
function stage_lines_start_entry()
    data start_entry#1
    return #start_entry
endfunction
function stage_lines_end_entry()
    data end_entry#1
    return #end_entry
endfunction
function stage_lines_start()
    data start#1
    return #start
endfunction
function stage_lines_end()
    data end#1
    return #end
endfunction
function stage_lines_add_remove_entry()
    data entry#1
    return #entry
endfunction
function stage_lines_add_remove()
    data add_remove#1
    return #add_remove
endfunction

function stage_lines_set()
    import "entry_to_int_min_N" entry_to_int_min_N
    sd bool
    sd entry
    setcall entry stage_line_entry()
    sd nr
    setcall nr stage_lines_number()
    setcall bool entry_to_int_min_N(entry#,nr,1)
    if bool==(FALSE)
        return (void)
    endif
    #get add/remove
    sd add_rem_entry
    setcall add_rem_entry stage_lines_add_remove_entry()
    sd rem_active
    setcall rem_active gtk_toggle_button_get_active(add_rem_entry#)
    sd add_rem
    setcall add_rem stage_lines_add_remove()
    set add_rem# rem_active
    #get color
    import "color_widget_get_color_to_rgb" color_widget_get_color_to_rgb
    import "dword_reverse" dword_reverse
    sd color_entry
    setcall color_entry stage_line_color_entry()
    sd uint_color
    setcall uint_color color_widget_get_color_to_rgb(color_entry#)
    setcall uint_color dword_reverse(uint_color)
    sd color
    setcall color stage_line_color()
    set color# uint_color
    #get on row or or col
    sd row_col_entry
    setcall row_col_entry stage_line_row_col_entry()
    sd col_active
    setcall col_active gtk_toggle_button_get_active(row_col_entry#)
    sd row_col
    setcall row_col stage_line_row_col()
    set row_col# col_active
    #get [start,end]
    sd start_entry
    sd end_entry
    sd start
    sd end
    setcall start_entry stage_lines_start_entry()
    setcall end_entry stage_lines_end_entry()
    setcall start stage_lines_start()
    setcall end stage_lines_end()
    sd value
    setcall bool entry_to_int_min_N(start_entry#,#value,0)
    if bool==(TRUE)
        set start# value
    endif
    setcall bool entry_to_int_min_N(end_entry#,#value,0)
    if bool==(TRUE)
        set end# value
    endif
    #handle the selection first for conflicts with expose event
    sd sel_pos
    setcall sel_pos stage_get_sel_pos()
    call stage_lines_modify_img(sel_pos)
    #
    import "stage_file_options_info_message" stage_file_options_info_message
    sd info
    setcall info stage_file_options_info_message((value_get))
    call stage_file_options_info_message((value_set),0)
    data f^stage_lines_thread
    call av_dialog_run_simple(f)
    #restore info message
    call stage_file_options_info_message((value_set),info)
endfunction

function stage_lines_thread()
    call stage_lines_thread_loop()
    call av_dialog_close()
    call stage_redraw()
    str res="Resized"
    import "texter" texter
    call texter(res)
endfunction

import "stage_nthPixbufFromContainer" stage_nthPixbufFromContainer

function stage_lines_thread_loop()
    sd img_nr=0
    sd sel_pos
    setcall sel_pos stage_get_sel_pos()
    sd nr_frames
    setcall nr_frames stage_get_frames()
    #loop
    while 1==1
        sd stop
        setcall stop av_dialog_stop((value_get))
        if stop==1
            return (void)
        endif
        #
        if img_nr!=sel_pos
            call stage_lines_modify_img(img_nr)
        endif
        #
        inc img_nr
        if img_nr==nr_frames
            return (void)
        endif
        #
        import "dialog_modal_texter_draw" dialog_modal_texter_draw
        sd totalframes
        setcall totalframes stage_get_frames()
        const imagetoolsbufstart=!
        ss format="Images: %u/%u"
        chars buf#!-imagetoolsbufstart-2-2+dword_max+dword_max
        str buffer^buf
        call sprintf(buffer,format,img_nr,totalframes)
        call dialog_modal_texter_draw(buffer)
    endwhile
endfunction

function stage_lines_modify_img(sd img_nr)
    sd start
    sd end
    setcall start stage_lines_start()
    setcall end stage_lines_end()
    if img_nr<start#
        return (void)
    endif
    if end#<img_nr
        return (void)
    endif
    #
    sd pixbuf
    setcall pixbuf stage_nthPixbufFromContainer(img_nr)
    if pixbuf==0
        return (void)
    endif
    #
    sd number_ptr
    setcall number_ptr stage_lines_number()
    sd number
    set number number_ptr#
    #
    sd w
    sd h
    sd wh^w
    call pixbuf_get_wh(pixbuf,wh)
    sd size
    sd stride
    import "rgb_get_all_sizes" rgb_get_all_sizes
    sd p_stride^stride
    setcall size rgb_get_all_sizes(w,h,p_stride)
    importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
    sd bytes
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)
    sd newmem=0
    #
    sd row_col
    setcall row_col stage_line_row_col()
    sd add_rem
    setcall add_rem stage_lines_add_remove()
    if add_rem#==0
        if row_col#==0
            call img_row_add(#newmem,w,#h,number,stride,bytes,size)
        else
            call img_col_add(#newmem,#w,h,number,#stride,bytes)
        endelse
    else
        if row_col#==0
            call img_row_remove(#newmem,#h,number,stride,bytes)
        else
            call img_col_remove(#newmem,#w,h,number,#stride,bytes)
        endelse
    endelse
    if newmem==0
        return (void)
    endif
    #
    importx "_gdk_pixbuf_new_from_data" gdk_pixbuf_new_from_data
    importx "_free" free
    data free_callback^free
    sd newpixbuf
    setcall newpixbuf gdk_pixbuf_new_from_data(newmem,(GDK_COLORSPACE_RGB),(FALSE),8,w,h,stride,free_callback,newmem)
    if newpixbuf==0
        call free(newmem)
        return (void)
    endif
    #
    sd ebox
    setcall ebox stage_nthwidgetFromcontainer(img_nr)
    sd oldpixbuf
    setcall oldpixbuf object_get_dword_name(ebox)
        #
    call object_set_dword_name(ebox,newpixbuf)
        #
    importx "_g_object_unref" g_object_unref
    call g_object_unref(oldpixbuf)
endfunction
import "memalloc" memalloc
import "cpymem" cpymem

#add

function img_row_add(sd p_newmem,sd w,sd p_h,sd number,sd stride,ss bytes,sd size)
    sd newsize
    set newsize size
    #
    sd newrows
    set newrows number
    mult newrows 2
    mult newrows stride
    add newsize newrows
    #
    sd newmem
    setcall newmem memalloc(newsize)
    if newmem==0
        return (void)
    endif
    set p_newmem# newmem
    sd cursor
    sd color
    setcall color stage_line_color()
    #
    sd i_top=0
    while i_top<number
        sd j_top=0
        set cursor newmem
        while j_top<w
            call cpymem(cursor,color,3)
            add cursor 3
            inc j_top
        endwhile
        add newmem stride
        inc i_top
    endwhile
    call cpymem(newmem,bytes,size)
    add newmem size
    sd i_bottom=0
    while i_bottom<number
        sd j_bottom=0
        set cursor newmem
        while j_bottom<w
            call cpymem(cursor,color,3)
            add cursor 3
            inc j_bottom
        endwhile
        add newmem stride
        inc i_bottom
    endwhile
    #
    add p_h# number
    add p_h# number
endfunction

function img_col_add(sd p_newmem,sd p_w,sd h,sd number,sd p_stride,ss prevpixels)
    import "rgb_get_rowstride" rgb_get_rowstride
    sd newsize
    sd newwidth
    set newwidth p_w#
    add newwidth number
    add newwidth number
    sd prevstride
    set prevstride p_stride#
    setcall p_stride# rgb_get_rowstride(newwidth)
    set newsize p_stride#
    mult newsize h
    #
    sd newmem
    setcall newmem memalloc(newsize)
    if newmem==0
        return (void)
    endif
    set p_newmem# newmem
    sd color
    setcall color stage_line_color()
    #
    sd prev_row_size
    set prev_row_size p_w#
    mult prev_row_size 3
    sd cursor
    sd y=0
    while y<h
        set cursor newmem
        #
        sd x_left=0
        while x_left<number
            call cpymem(cursor,color,3)
            add cursor 3
            inc x_left
        endwhile
        #
        call cpymem(cursor,prevpixels,prev_row_size)
        add prevpixels prevstride
        add cursor prev_row_size
        #
        sd x_right=0
        while x_right<number
            call cpymem(cursor,color,3)
            add cursor 3
            inc x_right
        endwhile
        #
        add newmem p_stride#
        inc y
    endwhile
    #
    set p_w# newwidth
endfunction

#remove

function img_row_remove(sd p_newmem,sd p_h,sd number,sd stride,ss prevpixels)
    sd newrows
    set newrows number
    mult newrows 2
    if newrows>=p_h#
        call texter("remove rows error")
        return (void)
    endif
    sub p_h# newrows
    #
    sd newsize
    set newsize p_h#
    mult newsize stride

    sd newmem
    setcall newmem memalloc(newsize)
    if newmem==0
        return (void)
    endif
    set p_newmem# newmem

    sd removesize
    set removesize number
    mult removesize stride
    add prevpixels removesize

    call cpymem(newmem,prevpixels,newsize)
endfunction

function img_col_remove(sd p_newmem,sd p_w,sd h,sd number,sd p_stride,ss prevpixels)
    sd newcols
    set newcols number
    mult newcols 2
    if newcols>=p_w#
        call texter("remove cols error")
        return (void)
    endif
    sub p_w# newcols
    #
    sd newstride
    setcall newstride rgb_get_rowstride(p_w#)
    #
    sd newsize
    set newsize newstride
    mult newsize h
    #
    sd newmem
    setcall newmem memalloc(newsize)
    if newmem==0
        return (void)
    endif
    set p_newmem# newmem
    #
    sd removesize
    set removesize number
    mult removesize 3
    sd copysize
    set copysize p_w#
    mult copysize 3
    #
    ss old_cursor
    sd j=0
    while j<h
        set old_cursor prevpixels
        #
        add old_cursor removesize
        call cpymem(newmem,old_cursor,copysize)
        #
        add newmem newstride
        add prevpixels p_stride#
        inc j
    endwhile
    set p_stride# newstride
endfunction
