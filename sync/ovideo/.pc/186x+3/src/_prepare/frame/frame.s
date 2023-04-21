

format elfobj

include "../../_include/include.h"


function stage_frame_panel(sd action,sd button,sd backfn,sd panel)
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
function stage_frame_panel_open(sd button,sd *user_data)
    import "img_edit_folder_enterleave_data" img_edit_folder_enterleave_data
    data f^stage_frame_panel_open_fn
    sd p_data^button
    call img_edit_folder_enterleave_data(f,p_data)
endfunction
function stage_frame_panel_open_fn(sd p_data)
    sd button
    sd user_data
    set button p_data#
    add p_data 4
    set user_data p_data#

    import "stage_save_img" stage_save_img
    chars frame_lot="img.bmp"
    chars *="Save the current selection to a file"
    data *^stage_save_img
    #
    import "stage_add_centered" stage_add_centered
    chars *="addcenter.bmp"
    chars *="Add an image scaled and centered on the selected frame"
    data *^stage_add_centered
    #
    import "stage_color_under_image" stage_color_under_image
    chars *="addmargins.bmp"
    chars *="Create an image selecting width,height and color, then place over it the selected frame scaled and centered"
    data *^stage_color_under_image
    #
    import "stage_scale_img" stage_scale_img
    chars *="scale.bmp"
    chars *="Scale the selection to new values"
    data *^stage_scale_img
    #
    import "stage_crop" stage_crop
    chars *="crop.bmp"
    chars *="Crop the selection"
    data *^stage_crop
    #
    import "stage_pencil" stage_pencil
    chars *="pencil.bmp"
    chars *="Pencil tool"
    data *^stage_pencil
    #
    import "stage_screenshot" stage_screenshot
    chars *="screenshot.bmp"
    chars *="Print screen and add to stage button"
    data *^stage_screenshot
    #
    import "stage_brightness" stage_brightness
    chars *="bright.bmp"
    chars *="Brighten or darken the selection"
    data *^stage_brightness
    #
    import "stage_overlay" stage_overlay
    chars *="overlay.bmp"
    chars *="Add an image over selection"
    data *^stage_overlay
    #
    import "stage_rotate_left" stage_rotate_left
    chars *="rotateleft.bmp"
    chars *="Rotate the selection 90 degrees at left"
    data *^stage_rotate_left
    #
    import "stage_rotate_right" stage_rotate_right
    chars *="rotateright.bmp"
    chars *="Rotate the selection 90 degrees at right"
    data *^stage_rotate_right
    #
    import "headline_dialog" headline_dialog
    chars *="headline.bmp"
    chars *="Draw headline text"
    data *^headline_dialog
    #
    import "stage_lines" stage_lines
    chars *="resize.bmp"
    chars *="Add/Remove rows or columns at sides at all stage images"
    data *^stage_lines
    #
    data *=0
    #
    data *=0
    #
    data lots^frame_lot

    import "stage_new_panel" stage_new_panel
    sd newpanel
    data f^stage_frame_panel_open
    data closef^stage_frame_panel_close
    setcall newpanel stage_new_panel(lots,button,f,user_data,closef)

    call stage_frame_panel((buttons_panel_open),button,f,newpanel)
endfunction
function stage_frame_panel_close()
    call stage_frame_panel((buttons_panel_close))
endfunction
