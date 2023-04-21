

format elfobj

include "../../_include/include.h"

function stage_scale_set()
    data currentpixbuf#1
    const ptr_currentpixbuf^currentpixbuf

    data entryw#1
    data entryh#1
    const ptr_entryw^entryw
    const ptr_entryh^entryh

    importx "_gtk_entry_get_text" gtk_entry_get_text

    import "strtoint" strtoint
    sd bool
    str valueserr="Number expected for scaling"
    sd text

    import "texter" texter

    sd width
    sd ptr_width^width
    setcall text gtk_entry_get_text(entryw)
    setcall bool strtoint(text,ptr_width)
    if bool==0
        call texter(valueserr)
        return valueserr
    endif
    sd height
    sd ptr_height^height
    setcall text gtk_entry_get_text(entryh)
    setcall bool strtoint(text,ptr_height)
    if bool==0
        call texter(valueserr)
        return valueserr
    endif

    import "pixbuf_scale" pixbuf_scale

    sd newpixbuf
    setcall newpixbuf pixbuf_scale(currentpixbuf,width,height)
    if newpixbuf==0
        return -1
    endif

    import "stage_get_sel_parent" stage_get_sel_parent
    sd eventbox
    sd ptr_eventbox^eventbox
    call stage_get_sel_parent(ptr_eventbox)

    importx "_g_object_unref" g_object_unref
    call g_object_unref(currentpixbuf)

    import "object_set_dword_name" object_set_dword_name
    call object_set_dword_name(eventbox,newpixbuf)

    import "stage_redraw" stage_redraw
    call stage_redraw()
endfunction

function stage_scale_init(sd vbox,sd *dialog)
    sd textw
    sd entryw
    sd texth
    sd entryh
    sd cells^textw

    data rows=2
    data cols=2

    importx "_gtk_label_new" gtk_label_new
    importx "_gtk_entry_new" gtk_entry_new

    import "connect_signal_data" connect_signal_data
    str signal_set="changed"
    data fn_set^scale_signal_changed

    str w="Width"
    setcall textw gtk_label_new(w)
    setcall entryw gtk_entry_new()
    call scale_width_entry((value_set),entryw)
    data fn_wd^scale_width_changed

    str h="Height"
    setcall texth gtk_label_new(h)
    setcall entryh gtk_entry_new()
    call scale_height_entry((value_set),entryh)
    data fn_hg^scale_height_changed

    data ptr_pix%ptr_currentpixbuf
    data pixbuf#1

    set pixbuf ptr_pix#

    importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
    importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
    sd width
    sd height
    setcall width gdk_pixbuf_get_width(pixbuf)
    setcall height gdk_pixbuf_get_height(pixbuf)

    chars dest#sign_int_null
    str strconv^dest

    str format="%u"

    importx "_sprintf" sprintf
    importx "_gtk_entry_set_text" gtk_entry_set_text

    call sprintf(strconv,format,width)
    call gtk_entry_set_text(entryw,strconv)

    call sprintf(strconv,format,height)
    call gtk_entry_set_text(entryh,strconv)

    sd p_w%ptr_entryw
    sd p_h%ptr_entryh

    set p_w# entryw
    set p_h# entryh

    import "tablefield_cells" tablefield_cells
    call tablefield_cells(vbox,rows,cols,cells)

    #toggle button
    sd ch_button
    importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
    ss txt="Preserve aspect ratio"
    setcall ch_button gtk_check_button_new_with_label(txt)
    import "packstart_default" packstart_default
    call scale_toggle_entry((value_set),ch_button)
    call packstart_default(vbox,ch_button)

    #set to preserve aspect ratio
    importx "_gtk_toggle_button_set_active" gtk_toggle_button_set_active
    call gtk_toggle_button_set_active(ch_button,1)

    #connect the on change signal to edit entries
    call connect_signal_data(entryw,signal_set,fn_set,fn_wd)
    call connect_signal_data(entryh,signal_set,fn_set,fn_hg)
endfunction

function stage_scale_img()
    sd err
    import "stage_get_sel_pixbuf" stage_get_sel_pixbuf
    sd ptr_pixbuf%ptr_currentpixbuf
    setcall err stage_get_sel_pixbuf(ptr_pixbuf)
    if err!=(noerror)
        return err
    endif

    import "stage_frame_dialog" stage_frame_dialog
    ss title="Scale selection"
    data init^stage_scale_init
    data do^stage_scale_set
    call stage_frame_dialog(init,do,title)
endfunction






function scale_width_entry(sd action,sd value)
    data width_entry#1
    if action==(value_set)
        set width_entry value
    else
        return width_entry
    endelse
endfunction
function scale_height_entry(sd action,sd value)
    data height_entry#1
    if action==(value_set)
        set height_entry value
    else
        return height_entry
    endelse
endfunction
function scale_toggle_entry(sd action,sd value)
    data toggle_entry#1
    if action==(value_set)
        set toggle_entry value
    else
        return toggle_entry
    endelse
endfunction


function scale_signal_changed(sd widget,sd data)
    importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
    sd ch_button
    setcall ch_button scale_toggle_entry((value_get))
    sd toggled
    setcall toggled gtk_toggle_button_get_active(ch_button)
    if toggled==(FALSE)
        return 0
    endif

    #not count irrelevant cases
    ss text
    setcall text gtk_entry_get_text(widget)
    import "slen" slen
    sd len
    setcall len slen(text)
    if len==0
        return 0
    endif

    sd wd_entry
    setcall wd_entry scale_width_entry((value_get))
    sd hg_entry
    setcall hg_entry scale_height_entry((value_get))

    #disconnect for not trigger in chain
    data fn_set^scale_signal_changed
    importx "_g_signal_handlers_disconnect_matched" g_signal_handlers_disconnect_matched
    call g_signal_handlers_disconnect_matched(wd_entry,(G_SIGNAL_MATCH_FUNC),0,0,0,fn_set,0)
    call g_signal_handlers_disconnect_matched(hg_entry,(G_SIGNAL_MATCH_FUNC),0,0,0,fn_set,0)

    sd pixbuf
    sd p_pixbuf^pixbuf
    call stage_get_sel_pixbuf(p_pixbuf)

    sd width
    sd height
    setcall width gdk_pixbuf_get_width(pixbuf)
    setcall height gdk_pixbuf_get_height(pixbuf)

    call data(width,height,wd_entry,hg_entry)

    #connect back
    data fn_wd^scale_width_changed
    data fn_hg^scale_height_changed
    str signal_set="changed"
    call connect_signal_data(wd_entry,signal_set,fn_set,fn_wd)
    call connect_signal_data(hg_entry,signal_set,fn_set,fn_hg)
endfunction

import "entry_to_int_min_N" entry_to_int_min_N
import "int_to_entry" int_to_entry
import "numbers_proportion" numbers_proportion

function scale_width_changed(sd width,sd height,sd wd_entry,sd hg_entry)
    sd newwidth
    sd ptr_newwidth^newwidth

    sd bool
    setcall bool entry_to_int_min_N(wd_entry,ptr_newwidth,1)
    if bool!=1
        return 0
    endif

    sd newheight
    setcall newheight numbers_proportion(newwidth,height,width)
    if newheight==0
        set newheight 1
    endif

    call int_to_entry(newheight,hg_entry)
endfunction

function scale_height_changed(sd width,sd height,sd wd_entry,sd hg_entry)
    sd newheight
    sd ptr_newheight^newheight
    sd bool
    setcall bool entry_to_int_min_N(hg_entry,ptr_newheight,1)
    if bool!=1
        return 0
    endif

    sd newwidth
    setcall newwidth numbers_proportion(newheight,width,height)
    if newwidth==0
        set newwidth 1
    endif

    call int_to_entry(newwidth,wd_entry)
endfunction
