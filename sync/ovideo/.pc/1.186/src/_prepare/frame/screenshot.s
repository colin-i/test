



format elfobj

include "../../_include/include.h"

function stage_screenshot()
    importx "_gdk_get_default_root_window" gdk_get_default_root_window
    importx "_gdk_drawable_get_size" gdk_drawable_get_size
    importx "_gdk_window_get_origin" gdk_window_get_origin
    sd root
    setcall root gdk_get_default_root_window()
    sd width
    sd height
    sd x_orig
    sd y_orig
    sd p_width^width
    sd p_height^height
    sd p_x_orig^x_orig
    sd p_y_orig^y_orig
    call gdk_drawable_get_size(root,p_width,p_height)
    call gdk_window_get_origin(root,p_x_orig,p_y_orig)

    importx "_gdk_pixbuf_get_from_drawable" gdk_pixbuf_get_from_drawable
    sd pixbuf
    setcall pixbuf gdk_pixbuf_get_from_drawable((NULL),root,(NULL),x_orig,y_orig,0,0,width,height)
    if pixbuf==0
        import "texter" texter
        str er="Pixbuf error"
        call texter(er)
        return 0
    endif
    import "stage_new_pix" stage_new_pix
    str nrofframes="Total frames: "
    call stage_new_pix(pixbuf,nrofframes)

    import "stage_display_last" stage_display_last
    call stage_display_last()
endfunction
