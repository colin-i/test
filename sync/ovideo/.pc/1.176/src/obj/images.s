

format elfobj

include "../_include/include.h"

##rgb,yuv

##rgb

#rgb
function yuv_rgb(ss Y,ss U,ss V,sd y_coef,sd u_coef,sd v_coef,sd add)
    sd value
    set value Y#
    mult value y_coef

    sd get
    set get U#
    mult get u_coef
    add value get

    set get V#
    mult get v_coef
    add value get

    mult add 100
    add value add

    div value 100
    if value<0
        set value 0
    elseif value>0xff
        set value 0xff
    endelseif
    return value
endfunction
import "multiple_of_nr" multiple_of_nr
#rgb size
function rgb_get_all_sizes(sd width,sd height,sd p_rowstride)
    sd rowstride
    setcall rowstride rgb_get_rowstride(width)
    sd rgb_size
    set rgb_size rowstride
    mult rgb_size height

    if p_rowstride!=0
        set p_rowstride# rowstride
    endif
    return rgb_size
endfunction
#rgb size
function rgb_get_size(sd width,sd height)
    sd rowstride
    setcall rowstride rgb_get_rowstride(width)
    sd rgb_size
    set rgb_size rowstride
    mult rgb_size height
    return rgb_size
endfunction
#rowstride
function rgb_get_rowstride(sd width)
    mult width 3
    setcall width multiple_of_nr(width,4)
    return width
endfunction
#void
function yuvi420_to_rgb(ss yuv,ss rgb,sd width,sd height)
    sd rgb_size
    sd rowstride
    sd p_rowstride^rowstride
    setcall rgb_size rgb_get_all_sizes(width,height,p_rowstride)

    sd planeY
    sd planeU
    sd planeV
    sd p_planeU^planeU
    sd p_planeV^planeV

    call yuv_get_all_sizes(width,height,p_planeU,p_planeV)

    set planeY yuv
    add planeU yuv
    add planeV yuv
#red
#   1	0	1.4	-179.93
#green
#   1	-0.33	-0.71	134.12
#blue
#   1	1.78	0.01	-228
    sd j=0
    sd uv_w
    sd uv_h
    sd uv_stride
    set uv_stride width
    div uv_stride 2
    while j!=height
        set uv_h j
        div uv_h 2
        sd i=0
        while i!=width
            set uv_w i
            div uv_w 2

            sd U
            sd V

            set U uv_stride
            mult U uv_h
            add U uv_w

            set V U

            add U planeU
            add V planeV

            #red
            setcall rgb# yuv_rgb(planeY,U,V,100,0,140,-180)
            inc rgb
            #green
            setcall rgb# yuv_rgb(planeY,U,V,100,-33,-71,134)
            inc rgb
            #blue
            setcall rgb# yuv_rgb(planeY,U,V,100,178,1,-228)
            inc rgb

            inc planeY
            inc i
        endwhile
        mult i 3
        while i!=rowstride
            set rgb# 0
            inc rgb
            inc i
        endwhile
        inc j
    endwhile
endfunction
#bool
function yuv_to_rgb_from_file(sd file,sd yuv,sd rgb,sd width,sd height)
    sd yuvsize
    setcall yuvsize yuv_get_size(width,height)
    import "file_read" file_read
    sd err
    setcall err file_read(yuv,yuvsize,file)
    if err!=(noerror)
        return 0
    endif
    call yuvi420_to_rgb(yuv,rgb,width,height)
    return 1
endfunction

##yuv

function rgb_yuv(ss bytes,ss dest,sd r_proc,sd g_proc,sd b_proc,sd plus)
    sd value

    sd r
    sd g
    sd b
    set r bytes#
    inc bytes
    set g bytes#
    inc bytes
    set b bytes#

    mult r r_proc
    mult g g_proc
    mult b b_proc
    mult plus 100

    set value r
    add value g
    add value b
    add value plus

    div value 100
    set dest# value
endfunction
#size
function yuv_get_all_sizes(sd width,sd height,sd p_planeU,sd p_planeV)
    sd size
    set size width
    mult size height

    if p_planeU!=0
        set p_planeU# size
    endif

    sd w_half
    set w_half width
    div w_half 2
    sd h_half
    set h_half height
    div h_half 2

    sd halfsize
    set halfsize w_half
    mult halfsize h_half

    add size halfsize
    if p_planeV!=0
        set p_planeV# size
    endif

    add size halfsize

    return size
endfunction
#yuv size
function yuv_get_size(sd width,sd height)
    sd size
    setcall size yuv_get_all_sizes(width,height,0,0)
    return size
endfunction

function rgb_to_yuvi420(ss bitmap_rgb,ss yuv,sd width,sd height)
    sd bitmap_stride
    setcall bitmap_stride rgb_get_rowstride(width)

    sd planeY
    sd planeU
    sd planeV

    sd p_planeU^planeU
    sd p_planeV^planeV

    call yuv_get_all_sizes(width,height,p_planeU,p_planeV)

    set planeY yuv
    add planeU yuv
    add planeV yuv

##################################################
#Y    +U            +V
#(w*h)+((w/2)*(h/2))+((w/2)*(h/2))

    #Y  0.299    0.587    0.114   R
    #U -0.14713 -0.28886  0.436   G
    #V  0.615   -0.51499 -0.10001 B

    #Y  30  59  11 R
    #U -17 -33  50 G
    #V  50 -42 - 8 B
    sd j=0
    sd bitmap_rgb_cursor
    set bitmap_rgb_cursor bitmap_rgb
    while j!=height
        sd i=0
        set bitmap_rgb bitmap_rgb_cursor
        while i!=width
####
            call rgb_yuv(bitmap_rgb,planeY,30,59,11,0)
            inc planeY

            sd uv_j
            set uv_j j
            and uv_j 1
            if uv_j==0
                sd uv_i
                set uv_i i
                and uv_i 1
                if uv_i==0
                    call rgb_yuv(bitmap_rgb,planeU,-17,-33,50,128)
                    inc planeU
                    call rgb_yuv(bitmap_rgb,planeV,50,-42,-8,128)
                    inc planeV
                endif
            endif
####
            add bitmap_rgb 3
            inc i
        endwhile
        add bitmap_rgb_cursor bitmap_stride
        inc j
    endwhile
###################################################
endfunction

importx "_free" free

#e/forward
function rgb_to_yuvi420_forward_data(sd rgb,sd width,sd height,sd forward,sd data)
    sd size
    set size width
    mult size height

    sd w_half
    set w_half width
    div w_half 2
    sd h_half
    set h_half height
    div h_half 2

    sd halfsize
    set halfsize w_half
    mult halfsize h_half

    add size halfsize
    add size halfsize

    import "memoryalloc" memoryalloc
    sd err
    sd yuv
    sd ptr_yuv^yuv
    setcall err memoryalloc(size,ptr_yuv)
    if err!=(noerror)
        return err
    endif

    call rgb_to_yuvi420(rgb,yuv,width,height)

    setcall err forward(yuv,size,data)
    call free(yuv)
    return err
endfunction


##functions

#convert

function convert_row_rgba_to_rgb(ss src,ss dest,sd width)
    const regs=3*0x40
    const ecx_rm=1*8
    const esi_rm=6*8
    const edi_rm=7*8
    const shitright_imm=5*8
    const shifteax=regs|shitright_imm|eax

    hex 0x51,0x56,0x57

    import "getoneax" getoneax
    call getoneax(src)
    hex 0x8b,regs|esi_rm|eax
    call getoneax(dest)
    hex 0x8b,regs|edi_rm|eax
    call getoneax(width)
    hex 0x8b,regs|ecx_rm|eax

#
    hex 0xad

    hex 0xaa
    hex 0xc1,shifteax,8
    hex 0xaa
    hex 0xc1,shifteax,8
    hex 0xaa

    const jump_sz=1+ 1+3+ 1+3+ 1+ 2
    hex 0xe2,-1*jump_sz
#

    hex 0x59,0x5e,0x5f
endfunction

function color_pixel(sd r,sd g,sd b,ss pixel)
    set pixel# r
    inc pixel
    set pixel# g
    inc pixel
    set pixel# b
endfunction
function rgb_uint_to_colors(sd pixel,sd colors)
    set colors# pixel
    and colors# 0xff
    add colors 4
    set colors# pixel
    and colors# 0xff00
    div colors# 0x100
    add colors 4
    set colors# pixel
    and colors# 0xff0000
    div colors# 0x10000
endfunction
function rgb_colors_to_uint(sd colors)
    sd pixel
    set pixel colors#

    sd value
    add colors 4
    set value colors#
    mult value 0x100
    or pixel value

    add colors 4
    set value colors#
    mult value 0x10000
    or pixel value

    return pixel
endfunction

function bytes_swap_reverse(sd bytes,sd width,sd height)
    call rgb_reverse(bytes,width,height)
    call rgb_color_swap(bytes,width,height)
endfunction

function rgb_reverse(sd bytes,sd width,sd height)
    sd src
    sd dest
    set src bytes
    set dest bytes

    sd rowstride
    setcall rowstride rgb_get_rowstride(width)

    sd size
    set size rowstride
    mult size height
    sub size rowstride
    add src size

    sd j=0
    div height 2
    while j!=height
        sd i=0
        sd aux
        sd src_cursor
        sd dest_cursor
        set src_cursor src
        set dest_cursor dest
        while i!=rowstride
            set aux src_cursor#
            set src_cursor# dest_cursor#
            set dest_cursor# aux
            add src_cursor 4
            add dest_cursor 4
            add i 4
        endwhile

        sub src rowstride
        add dest rowstride
        inc j
    endwhile
endfunction
function rgb_color_swap(ss bytes,sd width,sd height)
    sd stride_diff
    set stride_diff width
    mult stride_diff 3
    subcall stride_diff rgb_get_rowstride(width)
    mult stride_diff -1
    sd j=0
    while j!=height
        sd i=0
        while i!=width
            sd a
            set a bytes#
            inc bytes
            sd b
            set b bytes#
            inc bytes
            sd c
            set c bytes#
            sub bytes 2
            set bytes# c
            inc bytes
            set bytes# b
            inc bytes
            set bytes# a
            inc bytes
            inc i
        endwhile
        add bytes stride_diff
        inc j
    endwhile
endfunction

#e
function rgb_to_yuvi420_write_fn(sd yuv,sd size,sd file)
    import "file_write" file_write
    sd err
    setcall err file_write(yuv,size,file)
    return err
endfunction
#e
function rgb_to_yuvi420_write(sd rgb,sd width,sd height,sd file)
    data f^rgb_to_yuvi420_write_fn
    sd err
    setcall err rgb_to_yuvi420_forward_data(rgb,width,height,f,file)
    return err
endfunction

importx "_gdk_pixbuf_get_rowstride" gdk_pixbuf_get_rowstride
importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
importx "_g_object_unref" g_object_unref
import "texter" texter

#pixbuf
function rgb_test(sd pixbuf)
#    if pixbuf==0
#        return 0
#    endif
	importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
	sd w
	setcall w gdk_pixbuf_get_width(pixbuf)
	sd teststride
	setcall teststride gdk_pixbuf_get_rowstride(pixbuf)
	sd stride
	set stride w
	mult stride 3
	sd multiple_of_3
	set multiple_of_3 stride
	setcall stride multiple_of_nr(stride,4)
	if stride!=teststride
	#this is with alpha
		importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height
		sd h
		setcall h gdk_pixbuf_get_height(pixbuf)
		sd size
		set size stride
		mult size h
		import "memalloc" memalloc
		sd newmem
		setcall newmem memalloc(size)
		if newmem!=(NULL)
			ss bytes
			setcall bytes gdk_pixbuf_get_pixels(pixbuf)
			sd end
			set end h
			mult end teststride
			add end bytes
			ss pointer
			set pointer newmem
			while bytes!=end
				sd row
				set row bytes
				add row teststride
				while bytes!=row
					set pointer# bytes#
					inc pointer;inc bytes;set pointer# bytes#
					inc pointer;inc bytes;set pointer# bytes#
					inc pointer;add bytes 2
				endwhile
				if multiple_of_3!=stride
					inc pointer
				endif
			endwhile
			importx "_gdk_pixbuf_new_from_data" gdk_pixbuf_new_from_data
			sd newpixbuf
			setcall newpixbuf gdk_pixbuf_new_from_data(newmem,(GDK_COLORSPACE_RGB),(FALSE),8,w,h,stride,free,newmem)
			if newpixbuf!=(NULL)
				call g_object_unref(pixbuf)
				return newpixbuf
			endif
			call texter("error at new pixbuf")
			call free(newmem)
		endif
		return (NULL)
	endif
	return pixbuf
endfunction

#bool
function rgb_sizes_test(sd width,sd height,sd newpixbuf)
    import "pixbuf_get_wh" pixbuf_get_wh
    sd test_w
    sd test_h
    sd p_test^test_w
    call pixbuf_get_wh(newpixbuf,p_test)
    if test_w<width
        str w_err="New frame width is too small"
        call texter(w_err)
        return 0
    endif
    if test_h<height
        str h_err="New frame height is too small"
        call texter(h_err)
        return 0
    endif
    return 1
endfunction

#byte color
function gdkcolor2byte(ss ptr_g)
    sd word_color=0
    sd p_word_color^word_color
    set p_word_color# ptr_g#
    inc ptr_g
    inc p_word_color
    set p_word_color# ptr_g#
    import "rule3" rule3
    sd x
    setcall x rule3(word_color,0xffFF,255)
    return x
endfunction

#considering bps=8(<8 will be bad, >8 the return will be strange)
#            n_chan=3(<3 bad,>3 doesnt care)
#rowstride = row[N] - row[N-1]
function rgb_get_set(ss pointerOut,ss bytes,sd x,sd y,sd bps,sd n_chan,sd rowstride,sd getORset)
    mult y rowstride
    add bytes y

    mult x bps
    data a=bitsperbyte
    div x a
    mult x n_chan

    add bytes x

    sd i=0
    sd n=3
    while i<n
        if getORset==(get_rgb)
            set pointerOut# bytes#
        else
            set bytes# pointerOut#
        endelse
        inc i
        inc pointerOut
        inc bytes
    endwhile
    if getORset==(get_rgb)
        set pointerOut# 0
    endif
endfunction

function rgb_px_get(ss bytes,sd x,sd y,sd bps,sd n_chan,sd rowstride)
    sd value
    sd p_value^value
    call rgb_get_set(p_value,bytes,x,y,bps,n_chan,rowstride,(get_rgb))
    return value
endfunction
function rgb_px_set(sd value,ss bytes,sd x,sd y,sd bps,sd n_chan,sd rowstride)
    sd p_value^value
    call rgb_get_set(p_value,bytes,x,y,bps,n_chan,rowstride,(set_rgb))
endfunction

function rgb_pixbuf_get_pixel(ss pixbuf,sd x,sd y,sd bps,sd n_chan)
    sd pixels
    setcall pixels gdk_pixbuf_get_pixels(pixbuf)
    sd rowstride
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)
    sd value
    setcall value rgb_px_get(pixels,x,y,bps,n_chan,rowstride)
    return value
endfunction
function rgb_pixbuf_set_pixel(sd value,ss pixbuf,sd x,sd y,sd bps,sd n_chan)
    sd pixels
    setcall pixels gdk_pixbuf_get_pixels(pixbuf)
    sd rowstride
    setcall rowstride gdk_pixbuf_get_rowstride(pixbuf)
    call rgb_px_set(value,pixels,x,y,bps,n_chan,rowstride)
endfunction

function rgb_copy(sd srcpixels,sd destpixels,sd left,sd top,sd right,sd bottom,sd rowstride)
    sd left_start
    set left_start left
    while top!=bottom
        set left left_start
        while left!=right
            sd value
            setcall value rgb_px_get(srcpixels,left,top,8,3,rowstride)
            call rgb_px_set(value,destpixels,left,top,8,3,rowstride)
            inc left
        endwhile
        inc top
    endwhile
endfunction






##draw
function draw_expose_text(sd widget,ss text)
    #get the gdk window
    importx "_gtk_widget_get_window" gtk_widget_get_window
    sd wind
    setcall wind gtk_widget_get_window(widget)

    #creates the cairo context
    importx "_gdk_cairo_create" gdk_cairo_create
    sd cairo
    setcall cairo gdk_cairo_create(wind)
    import "int_to_double" int_to_double
    sd cairo_double_low
    sd cairo_double_high
    sd p_cairo_double^cairo_double_low

    #set a black source
    importx "_cairo_set_source_rgb" cairo_set_source_rgb
    call cairo_set_source_rgb(cairo,0,0,0,0,0,0)

    #set text size
    importx "_cairo_set_font_size" cairo_set_font_size
    call int_to_double(20,p_cairo_double)
    call cairo_set_font_size(cairo,cairo_double_low,cairo_double_high)

    #move to let text space
    importx "_cairo_move_to" cairo_move_to
    call cairo_move_to(cairo,0,0,cairo_double_low,cairo_double_high)

    #draw text
    importx "_cairo_show_text" cairo_show_text
    call cairo_show_text(cairo,text)

    #free cairo
    importx "_cairo_destroy" cairo_destroy
    call cairo_destroy(cairo)
endfunction

import "get_higher" get_higher
import "get_lower" get_lower

function pixbuf_draw_text(sd pixbuf,ss text,sd x,sd y,sd size,sd color,sd coordinates_flag)
    sd width
    sd height
    sd p_wh^width

    call pixbuf_get_wh(pixbuf,p_wh)

    importx "_gdk_pixmap_new" gdk_pixmap_new
    sd pixmap
    setcall pixmap gdk_pixmap_new(0,width,height,24)

    importx "_gdk_gc_new" gdk_gc_new
    sd gc
    setcall gc gdk_gc_new(pixmap)

    importx "_gdk_draw_pixbuf" gdk_draw_pixbuf
    call gdk_draw_pixbuf(pixmap,gc,pixbuf,0,0,0,0,width,height,(GDK_RGB_DITHER_NONE),0,0)

    importx "_gtk_window_new" gtk_window_new
    sd scratch
    setcall scratch gtk_window_new((GTK_WINDOW_TOPLEVEL))
    importx "_gtk_widget_realize" gtk_widget_realize
    call gtk_widget_realize(scratch)
    importx "_gtk_widget_create_pango_layout" gtk_widget_create_pango_layout
    sd pangolayout
    setcall pangolayout gtk_widget_create_pango_layout(scratch,0)
    importx "_gtk_widget_destroy" gtk_widget_destroy
    call gtk_widget_destroy(scratch)

    importx "_g_strdup_printf" g_strdup_printf
    ss format="<b><span foreground='#%06x' font='%u'>%s</span></b>"
    ss markup
    setcall markup g_strdup_printf(format,color,size,text)

    importx "_pango_layout_set_markup" pango_layout_set_markup
    call pango_layout_set_markup(pangolayout,markup,-1)

    #determine the positioning method: coordinates(x,y) or location(x factor,y factor)
    if coordinates_flag==0
        #location
        importx "_pango_layout_get_pixel_size" pango_layout_get_pixel_size
        sd text_width
        sd text_height
        sd p_text_width^text_width
        sd p_text_height^text_height
        call pango_layout_get_pixel_size(pangolayout,p_text_width,p_text_height)

        sd available_w
        set available_w width
        sub available_w text_width
        setcall available_w get_higher(available_w,0)

        sd available_h
        set available_h height
        sub available_h text_height
        setcall available_h get_higher(available_h,0)

        inc x
        inc y
        setcall x rule3(x,2,available_w)
        setcall y rule3(y,2,available_h)
    endif

    importx "_gdk_draw_layout" gdk_draw_layout
    call gdk_draw_layout(pixmap,gc,x,y,pangolayout)

    importx "_gdk_pixbuf_get_from_drawable" gdk_pixbuf_get_from_drawable
    sd pix_buf
    setcall pix_buf gdk_pixbuf_get_from_drawable((NULL),pixmap,(NULL),0,0,0,0,width,height)

    importx "_g_free" g_free
    call g_free(markup)
    call g_object_unref(pangolayout)
    call g_object_unref(gc)
    call g_object_unref(pixmap)

    return pix_buf
endfunction


function draw_default_cursor(sd root,sd def_x,sd def_y,sd width,sd height,sd cairo)
    importx "_gdk_window_get_pointer" gdk_window_get_pointer
    sd x
    sd y
    sd p_x^x
    sd p_y^y
    call gdk_window_get_pointer(root,p_x,p_y,(NULL))
    sub x def_x
    sub y def_y

    importx "_gdk_display_get_default" gdk_display_get_default
    sd display
    setcall display gdk_display_get_default()
    if display==0
        str disp_err="No default display found"
        call texter(disp_err)
        return 0
    endif
    importx "_gdk_cursor_new_for_display" gdk_cursor_new_for_display
    importx "_gdk_cursor_get_image" gdk_cursor_get_image
    importx "_gdk_cursor_unref" gdk_cursor_unref
    sd Cursor
    setcall Cursor gdk_cursor_new_for_display(display,(GDK_LEFT_PTR))
    call draw_cursor(Cursor,x,y,width,height,cairo)
    call gdk_cursor_unref(Cursor)
endfunction

function draw_cursor(sd Cursor,sd x,sd y,sd width,sd height,sd cairo)
    sd cPixbuf
    setcall cPixbuf gdk_cursor_get_image(Cursor)
    if cPixbuf==0
        str pxerr="The cursor image data can't be retrived"
        call texter(pxerr)
        return 0
    endif
    call draw_pixbuf_cursor(cPixbuf,x,y,width,height,cairo)
    call g_object_unref(cPixbuf)
endfunction

function draw_pixbuf_cursor(sd cPixbuf,sd x,sd y,sd width,sd height,sd cairo)
    #some tests to determine the visible area for overlaying the cursor
    sd left
    sd top
    sd cWidth
    sd cHeight
    sd rect^left

    sd bool
    setcall bool cursor_tests(cPixbuf,x,y,width,height,rect)
    if bool==0
        return 0
    endif

    call cairo_draw_default_cursor(cairo,cPixbuf,x,y,left,top,cWidth,cHeight)
endfunction
#bool
function cursor_tests(sd cPixbuf,sd left,sd top,sd pxWidth,sd pxHeight,sd rect)
    #if bool,rect get x,y,width,heigth truncated
    if left>=pxWidth
        return 0
    endif
    if top>=pxHeight
        return 0
    endif

    sd cursor_width
    sd cursor_height
    sd cursor_wh^cursor_width
    call pixbuf_get_wh(cPixbuf,cursor_wh)

    sd right
    set right left
    add right cursor_width
    if right<=0
        return 0
    endif
    sd bottom
    set bottom top
    add bottom cursor_height
    if bottom<=0
        return 0
    endif

    setcall rect# get_higher(0,left)
    add rect 4
    setcall rect# get_higher(0,top)
    add rect 4
    setcall rect# get_lower(right,pxWidth)
    sub rect# left
    add rect 4
    setcall rect# get_lower(bottom,pxHeight)
    sub rect# top
endfunction

##cairo

function cairo_draw_default_cursor(sd cairo,sd cPixbuf,sd x,sd y,sd left,sd top,sd cWidth,sd cHeight)
    importx "_gdk_cairo_set_source_pixbuf" gdk_cairo_set_source_pixbuf
    importx "_cairo_rectangle" cairo_rectangle
    importx "_cairo_fill" cairo_fill
    sd double_x_low
    sd double_x_high
    sd double_y_low
    sd double_y_high
    sd double_x^double_x_low
    sd double_y^double_y_low
    call int_to_double(x,double_x)
    call int_to_double(y,double_y)
    call gdk_cairo_set_source_pixbuf(cairo,cPixbuf,double_x_low,double_x_high,double_y_low,double_y_high)
    sd double_left_low
    sd double_left_high
    sd double_top_low
    sd double_top_high
    sd double_left^double_left_low
    sd double_top^double_top_low
    call int_to_double(left,double_left)
    call int_to_double(top,double_top)
    sd double_cWidth_low
    sd double_cWidth_high
    sd double_cHeight_low
    sd double_cHeight_high
    sd double_cWidth^double_cWidth_low
    sd double_cHeight^double_cHeight_low
    call int_to_double(cWidth,double_cWidth)
    call int_to_double(cHeight,double_cHeight)
    call cairo_rectangle(cairo,double_left_low,double_left_high,double_top_low,double_top_high,double_cWidth_low,double_cWidth_high,double_cHeight_low,double_cHeight_high)
    call cairo_fill(cairo)
endfunction
