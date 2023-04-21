

format elfobj

include "../_include/include.h"

#hbox
function buttons_interface(sd destcontainer,sd lots,sd p_alignment)
    #alignment for buttons
    import "alignmentfield" alignmentfield
    setcall p_alignment# alignmentfield(destcontainer)

    import "hboxfield_cnt" hboxfield_cnt
    sd hbox
    setcall hbox hboxfield_cnt(p_alignment#)

    call buttons_lots(lots,hbox)
    return hbox
endfunction

function buttons_lots(sd ptr,sd buttons)
    call buttons_lots_ex(ptr,buttons,0,0)
endfunction
function buttons_lots_ex(sd ptr,sd buttons,sd match,sd forward)
    data z=0
    while ptr#!=z
        setcall ptr buttons_group_ex(ptr,buttons,match,forward)
    endwhile
endfunction

function buttons_group(sd ptr,sd container)
    call buttons_group_ex(ptr,container,0,0)
endfunction

#return: optional: ptr for next
function buttons_group_ex(sd ptr,sd container,sd match,sd forward)
    import "slen" slen
    data z=0
    data padgroups=5
    sd hbox
    import "hboxfield_pack_pad" hboxfield_pack_pad
    import "buttonfield" buttonfield
    importx "_gtk_widget_set_tooltip_markup" gtk_widget_set_tooltip_markup
    setcall hbox hboxfield_pack_pad(container,padgroups)
    while ptr#!=z
        sd button
        setcall button buttonfield(hbox)

        import "buttonfield_setimage" buttonfield_setimage
        call buttonfield_setimage(ptr,button)
        addcall ptr slen(ptr)
        inc ptr

        call gtk_widget_set_tooltip_markup(button,ptr)
        addcall ptr slen(ptr)
        inc ptr

        str clicked="clicked"
        import "connect_signal" connect_signal
        call connect_signal(button,clicked,ptr#)

        if match==ptr#
            call forward(button,match)
        endif

        data dword=4
        add ptr dword
    endwhile
    add ptr dword
    return ptr
endfunction


#alignment
function linked_instance(sd destcontainer,sd lots,sd trigbutton,sd callbackfunc,sd callbackdata,sd closefunc)
    importx "_g_signal_handlers_disconnect_matched" g_signal_handlers_disconnect_matched
    call g_signal_handlers_disconnect_matched(trigbutton,(G_SIGNAL_MATCH_FUNC|G_SIGNAL_MATCH_DATA),0,0,0,callbackfunc,callbackdata)

    sd buttonscontainer
    sd alignment
    sd p_alignment^alignment
    setcall buttonscontainer buttons_interface(destcontainer,lots,p_alignment)

    chars connect="close.bmp"
    chars *="Close the panel"
    data backfunc#1
    data *=0

    set backfunc closefunc

    data close_connect^connect
    call buttons_group(close_connect,buttonscontainer)

    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(alignment)

    return alignment
endfunction


