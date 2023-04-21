


format elfobj

include "../../_include/include.h"

function stage_cover_panel(sd action,sd button,sd backfn,sd panel)
    data openbutton#1
    data backfunction#1

    data panelwidget#1

    if action==(buttons_panel_open)
        set openbutton button
        set panelwidget panel
        set backfunction backfn
    else
    #if action==(buttons_panel_close)
        importx "_gtk_widget_destroy" gtk_widget_destroy
        call gtk_widget_destroy(panelwidget)
        import "connect_signal" connect_signal
        str click="clicked"
        call connect_signal(openbutton,click,backfunction)
    endelse
endfunction
function stage_cover_panel_open(sd button,sd *user_data)
    import "img_edit_folder_enterleave_data" img_edit_folder_enterleave_data
    data f^stage_cover_panel_open_fn
    sd p_data^button
    call img_edit_folder_enterleave_data(f,p_data)
endfunction
function stage_cover_panel_open_fn(sd p_data)
    sd button
    sd user_data
    set button p_data#
    add p_data 4
    set user_data p_data#

    import "stage_cover" stage_cover
    chars cover_lot="cover.bmp"
    chars *="Uncover/Cover sides effects"
    data *^stage_cover
    #
    chars *="center_cover.bmp"
    chars *="Uncover/Cover center lines effects"
    data *^stage_reveal_centerline
    #
    import "stage_reveal_rectangle" stage_reveal_rectangle
    chars *="rectangle_cover.bmp"
    chars *="Uncover/Cover rectangle effects"
    data *^stage_reveal_rectangle
    #
    import "stage_reveal_diamond" stage_reveal_diamond
    chars *="diamond_cover.bmp"
    chars *="Uncover/Cover diamond effects"
    data *^stage_reveal_diamond
    #
    import "stage_reveal_curve" stage_reveal_curve
    chars *="curve_cover.bmp"
    chars *="Uncover/Cover curve effects"
    data *^stage_reveal_curve
    #
    import "stage_reveal_diagonal" stage_reveal_diagonal
    chars *="diagonal_cover.bmp"
    chars *="Uncover/Cover diagonal effects"
    data *^stage_reveal_diagonal
    #
    data *=0
    #
    data *=0
    #
    data lots^cover_lot

    import "stage_new_panel" stage_new_panel
    sd newpanel
    data f^stage_cover_panel_open
    data closef^stage_cover_panel_close
    setcall newpanel stage_new_panel(lots,button,f,user_data,closef)

    call stage_cover_panel((buttons_panel_open),button,f,newpanel)
endfunction
function stage_cover_panel_close()
    call stage_cover_panel((buttons_panel_close))
endfunction







function stage_reveal_centerline()
    import "stage_frame_dialog" stage_frame_dialog
    ss title="Uncover/Cover center lines effect"
    data init^stage_reveal_centerline_init
    data do^stage_reveal_centerline_set
    call stage_frame_dialog(init,do,title)
endfunction

import "stage_effect_common_fields" stage_effect_common_fields

function stage_reveal_centerline_init(sd vbox,sd *dialog)
    call stage_effect_common_cover_fields(vbox)

    ss wd="Width Axis"
    ss hg="Height Axis"
    data h#1
    const ptr_h_axis^h
    import "stage_effect_in_out" stage_effect_in_out
    setcall h stage_effect_in_out(vbox,wd,hg)
endfunction

function stage_reveal_centerline_set()
    call stage_reveal_centerline_tool(0)
    data f^stage_reveal_centerline_tool
    import "stage_effect_new" stage_effect_new
    call stage_effect_new(f,1)
endfunction

function stage_reveal_centerline_tool(sd part,sd k,sd nr,sd pixels,sd w,sd h,sd rowstride,sd animpixels,sd *animpixbuf,sd in_out)
    data init#1
    if part==0
        set init 0
        return 0
    endif
    if init==0
        data last_frame#1
        set last_frame nr
        dec last_frame

        const width_axis=0
        #const height_axis=1

        importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active

        data axis#1
        sd axis_entry%ptr_h_axis
        setcall axis gtk_toggle_button_get_active(axis_entry#)

        data start_width#1
        data end_width#1
        data start_height#1
        data end_height#1


        if in_out==(uncover)
            set start_width 0
            set end_width w
            set start_height 0
            set end_height h
        else
            set start_width w
            set end_width 0
            set start_height h
            set end_height 0
        endelse

        set init 1
    endif

    import "rule3_offset" rule3_offset
    import "centered" centered
    sd left
    sd top
    sd right
    sd bottom
    if axis==(width_axis)
        set left 0
        set right w
        setcall bottom rule3_offset(k,last_frame,start_height,end_height)
        setcall top centered(h,bottom)
        add bottom top
    else
        set top 0
        set bottom h
        setcall right rule3_offset(k,last_frame,start_width,end_width)
        setcall left centered(w,right)
        add right left
    endelse

    sd j
    set j top
    while j!=bottom
        sd i
        set i left
        while i!=right
            import "rgb_px_get" rgb_px_get
            import "rgb_px_set" rgb_px_set
            sd value
            setcall value rgb_px_get(animpixels,i,j,8,3,rowstride)
            call rgb_px_set(value,pixels,i,j,8,3,rowstride)
            inc i
        endwhile
        inc j
    endwhile
endfunction













#functions

function stage_effect_common_cover_fields(sd vbox)
    ss textin="Uncover"
    ss textout="Cover"
    call stage_effect_common_fields(vbox,textin,textout)
endfunction
