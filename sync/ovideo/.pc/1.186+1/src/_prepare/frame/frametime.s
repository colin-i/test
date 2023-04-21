



format elfobj

include "../../_include/include.h"

function stage_frame_time()
    import "stage_get_sel" stage_get_sel
    sd img
    setcall img stage_get_sel()
    if img==0
        return 0
    endif

    import "dialogfield" dialogfield
    ss title="Frame time length"
    data init^stage_frame_time_init
    data do^stage_frame_time_set
    call dialogfield(title,(GTK_DIALOG_MODAL),init,do)
endfunction

import "stage_get_sel_parent" stage_get_sel_parent

function stage_frame_time_init(sd vbox,sd *dialog)
    import "hboxfield_cnt" hboxfield_cnt
    sd hbox
    setcall hbox hboxfield_cnt(vbox)

    import "labelfield_l" labelfield_l
    ss text="Frame length: "
    call labelfield_l(text,hbox)
    import "editfield_pack" editfield_pack
    data number#1
    const ptr_number^number
    setcall number editfield_pack(hbox)

    #get the position of the current frame and the length
    sd container
    sd ptr_container^container
    call stage_get_sel_parent(ptr_container)
    sd length
    setcall length stage_get_fr_length(container)

    #convert to string and set to edit
    char nr#dword_null
    str ptr_nr^nr
    importx "_sprintf" sprintf
    ss dw="%u"
    call sprintf(ptr_nr,dw,length)
    importx "_gtk_entry_set_text" gtk_entry_set_text
    call gtk_entry_set_text(number,ptr_nr)
endfunction
import "stage_frame_index" stage_frame_index
import "stage_sel_img_set" stage_sel_img_set
function stage_frame_time_set()
    data edit%ptr_number
    importx "_gtk_entry_get_text" gtk_entry_get_text
    ss text
    setcall text gtk_entry_get_text(edit#)

    import "strtoint_positive_not_zero" strtoint_positive_not_zero
    sd value
    sd ptr_value^value
    sd bool
    setcall bool strtoint_positive_not_zero(text,ptr_value)
    if bool==0
        return 0
    endif

    sd container
    sd ptr_container^container
    call stage_get_sel_parent(ptr_container)
    sd pos
    setcall pos stage_frame_index(container)
    call stage_frame_time_numbers((stage_frame_time_set_frame_length),pos,value)
    call stage_sel_img_set(container)
    import "stage_display_info" stage_display_info
    call stage_display_info(container)
endfunction

#method is defined at olang.h

function stage_frame_time_numbers(sd method,sd arg1,sd newvalue,sd numberoftimes)
    sd index
    set index arg1
    if method==(stage_frame_time_init)
        #const stage_frame_time_init=0
        data frames#1
        data size#1
        data ptr_frames^frames
        set size 0
        set frames 0
        return 1
    elseif method==(stage_frame_time_append)
        #const stage_frame_time_append=1
        import "memoryrealloc" memoryrealloc
        add size 4
        sd err
        setcall err memoryrealloc(ptr_frames,size)
        if err==(noerror)
            sd pointer
            set pointer frames
            add pointer size
            sub pointer 4
            set pointer# arg1
        endif
        return 1
    elseif method==(stage_frame_time_free)
        #const stage_frame_time_free=2
        importx "_free" free
        if frames!=0
            call free(frames)
        endif
        return 1
    elseif method==(stage_frame_time_get_at_index)
    #get the index from the created database
        mult index 4
        if index>=size
            return 1
        endif
        sd value
        set value frames
        add value index
        return value#
    elseif method==(stage_frame_time_set_frame_length)
    #modify a frame length
        mult index 4
        if index>=size
            return 1
        endif
        sd loc
        set loc frames
        add loc index
        set loc# newvalue
        return 1
    elseif method==(stage_frame_time_insert)
    #insert at index newvalue and numberoftimes
        sd newzone
        set newzone numberoftimes
        mult newzone 4
        add size newzone
        setcall err memoryrealloc(ptr_frames,size)
        if err==(noerror)
            #take cursor for adding frames
            sd walker
            set walker index
            mult walker 4
            add walker frames
            #
            sd dest
            set dest frames
            add dest size
            sd cursor
            set cursor dest
            sub cursor newzone

            sd blocksize
            set blocksize cursor
            sub blocksize walker
            while blocksize!=0
                sub dest 4
                sub cursor 4
                set dest# cursor#
                sub blocksize 4
            endwhile
            while newzone!=0
                set walker# newvalue
                add walker 4
                sub newzone 4
            endwhile
        endif
        return 1
    elseif method==(stage_frame_time_delete_frame)
    #a frame was deleted
        mult index 4
        if index>=size
            return 1
        endif

        sd mem_src_cursor
        sd mem_dest_cursor
        set mem_src_cursor frames
        set mem_dest_cursor frames

        add mem_dest_cursor index
        add index 4
        add mem_src_cursor index

        while index!=size
            set mem_dest_cursor# mem_src_cursor#
            add mem_src_cursor 4
            add mem_dest_cursor 4
            add index 4
        endwhile
        sub size 4
        return 1
    elseif method==(stage_frame_time_sum_at_index)
    #length at pos returned
        mult index 4
        if index>=size
            return 0
        endif

        sd frames_cursor
        set frames_cursor frames
        add frames_cursor index
        sd length_at_pos=0
        while index!=0
            sub frames_cursor 4
            add length_at_pos frames_cursor#
            sub index 4
        endwhile
        return length_at_pos
    else
    #if method==(stage_frame_time_total_sum)
    #total length returned
        sd frames_pointer
        set frames_pointer frames
        add frames_pointer size
        sd total_length=0
        while frames_pointer!=frames
            sub frames_pointer 4
            add total_length frames_pointer#
        endwhile
        return total_length
    endelse
endfunction


#length of the stage eventbox
function stage_get_fr_length(sd eventbox)
    sd pos
    setcall pos stage_frame_index(eventbox)
    sd length
    setcall length stage_frame_time_numbers((stage_frame_time_get_at_index),pos)
    return length
endfunction

#length of the stage sel
function stage_get_sel_fr_length()
    sd container
    sd ptr_container^container
    call stage_get_sel_parent(ptr_container)
    sd length
    setcall length stage_get_fr_length(container)
    return length
endfunction

const frame_unit_red=0xff
const frame_unit_green=0
const frame_unit_blue=0

import "stage_sel_framebar_pixbuf" stage_sel_framebar_pixbuf
importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels

function stage_split_frame()
    sd framebarpixbuf
    setcall framebarpixbuf stage_sel_framebar_pixbuf()
    if framebarpixbuf==0
        return 0
    endif

    import "stage_get_sel_pos" stage_get_sel_pos
    sd pos
    setcall pos stage_get_sel_pos()
    sd length
    setcall length stage_frame_time_numbers((stage_frame_time_get_at_index),pos)

    if length==1
        import "texter" texter
        ss lengthlow="Frame length must be greater than 1."
        call texter(lengthlow)
        return 0
    endif

    sd pixels
    setcall pixels gdk_pixbuf_get_pixels(framebarpixbuf)
    sd terminator
    setcall terminator gdk_pixbuf_get_width(framebarpixbuf)

    sd unit_size
    set unit_size terminator
    div unit_size length

    mult terminator 3
    add terminator pixels
    sd cursor
    set cursor pixels
    sd noselection=0
    #find the selected unit position
    while cursor!=terminator
        char unit_color_data={frame_unit_red,frame_unit_green,frame_unit_blue}
        str unit_color^unit_color_data
        import "cmpmem" cmpmem
        sd memcmp
        setcall memcmp cmpmem(cursor,unit_color,3)
        if memcmp==(equalCompare)
            sub cursor pixels
            div cursor 3
            set terminator cursor
            set noselection 1
        else
            add cursor 3
        endelse
    endwhile

    if noselection==0
        str selerr="Press on the selection to create a frame slot."
        call texter(selerr)
        return 0
    endif

    div cursor unit_size
    if cursor==0
        str notatzero="Split the selection not from the first frame."
        call texter(notatzero)
        return 0
    endif

    #rearrange the previous part
    #frame length
    call stage_frame_time_numbers((stage_frame_time_set_frame_length),pos,cursor)
    import "stage_new_click_area" stage_new_click_area
    #frames container
    import "stage_get_frames_container" stage_get_frames_container
    sd box
    setcall box stage_get_frames_container()
    #frame objects
    sd ebox
    setcall ebox stage_new_click_area()
    importx "_gtk_box_reorder_child" gtk_box_reorder_child
    call gtk_box_reorder_child(box,ebox,pos)
    #pixbuf to previous
    import "stage_get_sel_pixbuf" stage_get_sel_pixbuf
    sd pix
    sd p_pix^pix
    call stage_get_sel_pixbuf(p_pix)
    import "pixbuf_copy" pixbuf_copy
    sd prevpx
    setcall prevpx pixbuf_copy(pix)
    import "stage_pixbuf_to_container" stage_pixbuf_to_container
    call stage_pixbuf_to_container(prevpx,ebox)

    inc pos
    sub length cursor
    #new length for selection
    call stage_frame_time_numbers((stage_frame_time_insert),pos,length,1)

    #show at framebar the new length and show info about the new number of frames
    sd ev
    sd p_ev^ev
    call stage_get_sel_parent(p_ev)
    call stage_sel_img_set(ev)
    call stage_display_info(ev)
endfunction

function stage_frame_unit_select(sd widget,sd event)
    import "eventbutton_get_coords" eventbutton_get_coords
    sd mouse_x
    setcall mouse_x eventbutton_get_coords(event,0)

    sd pixbuf

    setcall pixbuf stage_sel_framebar_pixbuf()
    sd length
    setcall length stage_get_fr_length(widget)
    sd width
    setcall width gdk_pixbuf_get_width(pixbuf)
    sd unit
    set unit width
    div unit length
    div mouse_x unit
    mult mouse_x unit

    sd cursor1
    sd cursor2

    set cursor1 mouse_x
    mult cursor1 3
    addcall cursor1 gdk_pixbuf_get_pixels(pixbuf)

    sd startpoint
    set startpoint cursor1

    set cursor2 unit
    dec cursor2
    mult cursor2 3
    add cursor2 cursor1

    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
    importx "_gdk_pixbuf_get_rowstride" gdk_pixbuf_get_rowstride

    sd height
    setcall height gdk_pixbuf_get_height(pixbuf)
    sd rowstride
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)
    import "color_pixel" color_pixel
    while height!=0
        call color_pixel((frame_unit_red),(frame_unit_green),(frame_unit_blue),cursor1)
        call color_pixel((frame_unit_red),(frame_unit_green),(frame_unit_blue),cursor2)
        add cursor1 rowstride
        add cursor2 rowstride
        dec height
    endwhile
    sub cursor1 rowstride
    set cursor2 startpoint
    while unit!=0
        call color_pixel((frame_unit_red),(frame_unit_green),(frame_unit_blue),cursor1)
        call color_pixel((frame_unit_red),(frame_unit_green),(frame_unit_blue),cursor2)
        add cursor1 3
        add cursor2 3
        dec unit
    endwhile
endfunction

#equalize

function stage_frame_equalize()
    import "stage_frame_dialog" stage_frame_dialog
    data init^stage_frame_equalize_init
    data on_ok^stage_frame_equalize_set
    ss title="Equalize"
    call stage_frame_dialog(init,on_ok,title)
endfunction

function stage_frame_equalize_edit(sd action,sd value)
    data equalize_edit#1
    if action==(value_set)
        set equalize_edit value
    else
        return equalize_edit
    endelse
endfunction

function stage_frame_equalize_init(sd vbox)
    import "label_and_edit" label_and_edit
    ss txt="Frame length "
    sd edit
    setcall edit label_and_edit(vbox,txt)
    call stage_frame_equalize_edit((value_set),edit)
endfunction

function stage_frame_equalize_set()
    #get the number
    import "entry_to_int_min_N" entry_to_int_min_N
    sd entry
    setcall entry stage_frame_equalize_edit((value_get))
    sd nr
    sd p_nr^nr
    sd bool
    setcall bool entry_to_int_min_N(entry,p_nr,1)
    if bool!=1
        return 0
    endif

    #get sel pos
    sd selpos
    setcall selpos stage_get_sel_pos()

    #calculate if equalization is possible
    import "stage_get_frames" stage_get_frames
    sd totalframes
    setcall totalframes stage_get_frames()
    sd equalization_end_frame
    set equalization_end_frame selpos
    sd dif=0
    sd prev
    sd can_be_truncation
    sd loop=1
    while loop==1
        sd framelength
        setcall framelength stage_frame_time_numbers((stage_frame_time_get_at_index),equalization_end_frame)
        sub framelength nr
        add dif framelength
        set can_be_truncation nr
        if dif==0
            set loop 0
        else
            #test to truncate last equalization frame
            sd sign_dif
            set sign_dif dif
            and sign_dif 0x80000000
            if selpos!=equalization_end_frame
                if sign_dif!=prev
                    if dif<0
                        mult dif -1
                    endif
                    sub can_be_truncation dif
                    set loop 0
                endif
            endif
            if loop!=0
                set prev sign_dif

                inc equalization_end_frame
                if equalization_end_frame==totalframes
                    str not_possible="Equalization not possible with the specified number"
                    call texter(not_possible)
                    return 0
                endif
            endif
        endelse
    endwhile
    while selpos!=equalization_end_frame
        call set_frame_length_and_redraw(selpos,nr)
        inc selpos
    endwhile
    call set_frame_length_and_redraw(selpos,can_be_truncation)
endfunction

function set_frame_length_and_redraw(sd pos,sd nr)
    call stage_frame_time_numbers((stage_frame_time_set_frame_length),pos,nr)
    #display
    import "stage_nthwidgetFromcontainer" stage_nthwidgetFromcontainer
    sd ebox
    setcall ebox stage_nthwidgetFromcontainer(pos)
    sd selpos
    setcall selpos stage_get_sel_pos()
    if selpos==pos
        import "stage_sel_img" stage_sel_img
        call stage_sel_img(ebox)
    else
        import "stage_unselected_frame" stage_unselected_frame
        call stage_unselected_frame(ebox)
    endelse
    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(ebox)
endfunction
