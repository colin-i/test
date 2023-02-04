Format ElfObj64

include "../include/prog.h"

#win32 with _
importx "memcpy" memcpy
importx "strlen" strlen
importx "memcmp" memcmp

import "printEr" printEr
import "identifiers_set" identifiers_set
import "identifiers_get" identifiers_get
import "rect_prepare" rect_prepare
import "button_mem" button_mem

import "dword_to_word_arg" dword_to_word_arg
import "dword_swap" dword_swap
import "args_advance" args_advance
import "bits_packs" bits_packs
import "NumFill_NumLin" NFill_NLin
import "shapewithstyle_records" shapewithstyle_records
import "word_arg_to_dword" word_arg_to_dword
import "file_get_content__resources_free" file_get_content__resources_free
import "file_resources_set" file_resources_set
import "file_resources_free" file_resources_free
importx "freereset" freereset
import "struct_ids" struct_ids
import "matrix_translate" matrix_translate
import "block_get_size" block_get_size
import "block_get_mem" block_get_mem
import "free_sprite_id" free_sprite_id
import "block_reset_size" block_reset_size




importaftercall ebool

import "swf_tag" swf_tag
import "swf_mem" swf_mem
import "swf_mem_add" swf_mem_add
import "swf_actionblock" swf_actionblock
import "rect_add" rect_add
import "swf_tag_recordheader_entry" swf_tag_recordheader_entry
import "error" error
import "swf_shape_simple" swf_shape_simple

import "swf_button_base" swf_button_base
import "swf_text_initial_font_centered" swf_text_initial_font_centered
#id
functionX swf_button(sd width,sd height,sd ButtonData)
data def_fill#1
data def_line_h#1;#no pad
data def_line#1

data ov_fill#1;#no pad
data ov_line_h#1
data ov_line#1;#no pad

data dn_fill#1;#no pad
data dn_line_h#1
data dn_line#1;#no pad

data xcurve#1
data ycurve#1;#no pad

str text#:/DWORD
data font_id#1;data font_height#1;#no pad
data font_vertical_offset#1;data font_color#1;#no pad

str actions#:/DWORD

#width                  is the button width
#height                 is the button height

#def_fill               is the ButtonStateUp RGBA fill color
#def_line_sz            line height in pixels
#def_line               is the line RGBA
#ov_fill                is the ButtonStateOver RGBA
#ov_line_sz             line height
#ov_line                RGBA
#dn_fill                is the ButtonStateDown|ButtonStateHitTest RGBA
#dn_line_sz             line height
#dn_line                RGBA
#x_curve                x curve shape value
#y_curve                y curve shape value
#text                   button text
#font_id                a font created with swf_font
#font_height            font height in pixels
#font_vertical_offset   font y offset
#font_color             font RGBA
#actions                is a string with actionscript

    const button_top_args=11*DWORD
    call memcpy(#def_fill,ButtonData,(button_top_args))
    add ButtonData (button_top_args);call memcpy(#text,ButtonData,:)
    const button_font_args=4*DWORD
    add ButtonData :;call memcpy(#font_id,ButtonData,(button_font_args))
    add ButtonData (button_font_args);call memcpy(#actions,ButtonData,:)
#
    if font_height>height;call error("font_height>height error at button");endif
    #
    sd bmem
    setcall bmem button_mem()
    #
    sd shape_up
    sd shape_over
	sd shape_down
    setcall shape_up swf_shape_simple(width,height,def_fill,def_line_h,def_line,xcurve,ycurve)
    setcall shape_over swf_shape_simple(width,height,ov_fill,ov_line_h,ov_line,xcurve,ycurve)
	setcall shape_down swf_shape_simple(width,height,dn_fill,dn_line_h,dn_line,xcurve,ycurve)

    set bmem# shape_up
    add bmem (DWORD)
    set bmem# shape_over
    add bmem (DWORD)
	set bmem# shape_down
	add bmem (DWORD)

    set bmem# width;add bmem (DWORD)
    set bmem# height;add bmem (DWORD)

    sd noText=FALSE;sd text_id
    data t_null={0,0}
    sd b;setcall b memcmp(#t_null,#text,:)
    if b==0
        set noText (TRUE)
        set bmem# noText
    else
        sd text_y
        set text_y height
        sub text_y font_height
        div text_y 2
        add text_y font_vertical_offset

        set bmem# noText;add bmem (DWORD)
        set bmem# font_id;add bmem (DWORD)
        set bmem# font_height;add bmem (DWORD)
        set bmem# text_y;add bmem (DWORD)
        set bmem# font_color

        setcall text_id swf_text_initial_font_centered(width,height,text,font_id,font_height,font_color)
    endelse

    sd id
    setcall id swf_button_base(shape_up,shape_over,shape_down,noText,text_id,text_y,actions)
    return id
endfunction
#id
functionX swf_button_last(ss newtext,ss actions)
#ss newtext  is the new text for a new button with the attributes from the previous swf_button call
#ss actions  button actions
    data shape_up#1
    data shape_over#1
	data shape_down#1
    data width#1
    data height#1
    data noText#1
    data font_id#1
    data font_height#1
    data text_y#1
    data font_color#1
    sd bmem
    setcall bmem button_mem()
    call memcpy(#shape_up,bmem,(9*DWORD))

    if noText==(FALSE)
        sd newtext_id
        setcall newtext_id swf_text_initial_font_centered(width,height,newtext,font_id,font_height,font_color)
    endif

    sd id
    setcall id swf_button_base(shape_up,shape_over,shape_down,noText,newtext_id,text_y,actions)
    return id
endfunction

#font

#id
functionX swf_font(ss fontname,sd font_flags)
#ss fontname    = a string with the browser font, for example "_sans"
#sd font_flags  = prog.h file is with the flags
    const font_hd_start=!

    chars id#2
    chars Flags#1
    chars *Language=0
    chars FontNameLen#1

    const font_hd_start_size=!-font_hd_start
    vdata font_hd_start^id

    data NumGlyphs=0

    sd fontid
    setcall fontid identifiers_get()
    call dword_to_word_arg(fontid,#id)

    set Flags font_flags

    setcall FontNameLen strlen(fontname)

    sd size=font_hd_start_size+2

    sd has_layout=FontFlagsHasLayout
    and has_layout font_flags
    add size FontNameLen
    if has_layout!=0
        add size (2+2+2+2)
    endif

    call swf_tag_recordheader_entry((DefineFont2),size)
    call swf_mem_add(font_hd_start,(font_hd_start_size))
    call swf_mem_add(fontname,FontNameLen)
    call swf_mem_add(#NumGlyphs,2)
    if has_layout!=0
        chars FontAscent={0,0}
        chars *FontDescent={0,0}
        chars *FontLeading={0,0}
        chars *KerningCount={0,0}
        call swf_mem_add(#FontAscent,(2+2+2+2))
    endif
    return fontid
endfunction
#id
functionX swf_font_basic(ss fontname)
#ss fontname    = a string with the browser font, for example "_sans"
    sd id
    setcall id swf_font(fontname,0)
    return id
endfunction

#text

#id
functionX swf_text(sd bound_width,sd bound_height,ss variablename,sd flags,sd structure)
#sd bound_width  width of the text
#sd bound_height height
#ss variablename to change it with actionscript
#sd flags        see include/text.h
#sd structure    see edittext_struct()  from character.s, set the flags first
    #CharacterID
    sd size=2
    #RECT
    sd rect
    sd rectsz
    call rect_prepare(#rect,#rectsz,bound_width,bound_height)
    add size rectsz
    #flags
    add size 2
    #FontID
    sd p_fontid
    sd hasfont=HasFont
    and hasfont flags
    if hasfont!=0
        set p_fontid structure
        add size 2
    endif
    #FontClass
    ss fontclassname
    sd fontclasssize
    sd hasfontclass=HasFontClass
    and hasfontclass flags
    add structure (2*DWORD)
    if hasfontclass!=0
        if hasfont!=0
            call error("HasFontClass can't be true if HasFont is true.")
        endif
        set fontclassname structure#
        setcall fontclasssize strlen(fontclassname)
        inc fontclasssize
        add size fontclasssize
    endif
    #FontHeight
    sd p_font_height
    sub structure (DWORD)
    if hasfont!=0
        set p_font_height structure
        add size 2
    endif
    #TextColor
    sd p_rgba
    sd hastextcolor=HasTextColor
    and hastextcolor flags
    add structure (DWORD+:)
    if hastextcolor!=0
        set p_rgba structure
        add size 4
    endif
    #MaxLength
    sd p_maxlength
    sd hasmaxlength=HasMaxLength
    and hasmaxlength flags
    add structure (DWORD)
    if hasmaxlength!=0
        set p_maxlength structure
        add size 2
    endif
    #layout
    sd p_layout
    data layout_size=4*WORD+BYTE
    sd haslayout=HasLayout
    and haslayout flags
    add structure (DWORD+:)
    if haslayout!=0
        set p_layout structure
        add size layout_size
    endif
    #VariableName
    sd vlen
    setcall vlen strlen(variablename)
    inc vlen
    add size vlen
    #InitialText
    ss initialtext
    sd initialtextsize
    sd hastext=HasText
    and hastext flags
    sub structure :
    if hastext!=0
        set initialtext structure#
        setcall initialtextsize strlen(initialtext)
        inc initialtextsize
        add size initialtextsize
    endif

    call swf_tag_recordheader_entry((DefineEditText),size)
    sd id
    setcall id identifiers_get()
    call swf_mem_add(#id,2)
    call swf_mem_add(rect,rectsz)
    call swf_mem_add(#flags,2)
    #
    if hasfont!=0
        call swf_mem_add(p_fontid,2)
    endif
    if hasfontclass!=0
        call swf_mem_add(fontclassname,fontclasssize)
    endif
    if hasfont!=0
        sd height
        set height p_font_height#
        mult height 20
        call swf_mem_add(#height,2)
    endif
    if hastextcolor!=0
        setcall p_rgba# dword_swap(p_rgba#)
        call swf_mem_add(p_rgba,4)
    endif
    if hasmaxlength!=0
        call swf_mem_add(p_maxlength,2)
    endif
    if haslayout!=0
        data layout_align#1
        data layout_leftmargin#1
        data layout_rightmargin#1
        data layout_indent#1
        data layout_leading#1
        call memcpy(#layout_align,p_layout,(5*DWORD))
        mult layout_leftmargin 20
        mult layout_rightmargin 20
        mult layout_indent 20
        mult layout_leading 20
        chars l_align#1
        chars l_leftmargin#2
        chars l_rightmargin#2
        chars l_indent#2
        chars l_leading#2
        set l_align layout_align
        call dword_to_word_arg(layout_leftmargin,#l_leftmargin)
        call dword_to_word_arg(layout_rightmargin,#l_rightmargin)
        call dword_to_word_arg(layout_indent,#l_indent)
        call dword_to_word_arg(layout_leading,#l_leading)
        call swf_mem_add(#l_align,layout_size)
    endif
    call swf_mem_add(variablename,vlen)
    if hastext!=0
        call swf_mem_add(initialtext,initialtextsize)
    endif
    return id
endfunction

import "shape_records_add" shape_records_add
#id
functionX swf_shape(sd width,sd height,sd args)
#sd width
#sd height
#sd args        see swf_shape_basic or swf_image(last part) for example, or see shape_records_add and it's sub-functions to see how the swf SHAPERECORD is added
    if width==0
        call error("shape width 0 not allowed")
    elseif height==0
        call error("shape height 0 not allowed")
    endelseif
    sd fillstyle
    sd fillarg
    sd linewidth
    sd linecolor

    setcall fillstyle args_advance(#args)
    if fillstyle!=(no_fill)
        setcall fillarg args_advance(#args)
    endif
    setcall linewidth args_advance(#args)
    if linewidth!=0
        setcall linecolor args_advance(#args)
    endif
    ########
    sd shape_size

    #id
    sd shape_id
    setcall shape_id identifiers_get()
    set shape_size (WORD)

    #rect
    sd rect
    sd rect_size
    call rect_prepare(#rect,#rect_size,width,height)
    add shape_size rect_size

    #SHAPEWITHSTYLE
    chars FillStyleCount#1
        chars FillStyleType#1
    #
        data data#3
    vdata fillstyles^FillStyleCount
    set FillStyleCount 0
    sd fillstyles_size=1
    if fillstyle!=(no_fill)
        set FillStyleCount 1
        set FillStyleType fillstyle
        add fillstyles_size 1
        if fillstyle==(solid_fill)
            setcall data dword_swap(fillarg)
            add fillstyles_size (DWORD)
        else
        #if fillstyle==(repeating_bitmap_fill)
        #clipped bitmap fill,non-smoothed repeating bitmap or non-smoothed clipped bitmap
            call dword_to_word_arg(fillarg,#data)
            sd fill_pointer^data
            add fill_pointer (WORD)
            #matrix,scaleX=20,scaleY=20,translateX=0,translateY=0
            #first bit: scaleX 0 and Y 0;or 1;=>0;else is 1
            #const FIXEDBITS=16
            #x and y=floor(scaleX*(1<<FIXEDBITS))=0x00140000
            #Nbits is 0x15 + 1(sign)
            const predef_nbits=0x16
            const predef_XYscale=0x00140000
            #rotate is 0
            #translate nbits is 0
            call bits_packs(fill_pointer,6,1,1,(predef_nbits),(NBits_size),(predef_XYscale),(predef_nbits),(predef_XYscale),(predef_nbits),0,1,0,(NBits_size))
            #chars ref_id#2
            #chars matrix#7
            add fillstyles_size (2+7)
        endelse
    endif
    add shape_size fillstyles_size
    #
    chars LineStyleCount#1
    chars line_points#2
    data color#1
    vdata linestyles^LineStyleCount
    sd linestyles_size=1
    set LineStyleCount 0
    if linewidth!=0
        set LineStyleCount 1
        mult linewidth 20
        call dword_to_word_arg(linewidth,#line_points)
        setcall color dword_swap(linecolor)
        add linestyles_size (WORD+DWORD)
    endif
    add shape_size linestyles_size
    #NumFillBits/NumLineBits
    call NFill_NLin(0,FillStyleCount,LineStyleCount)
    sd NumFill_NumLin;setcall NumFill_NumLin NFill_NLin(1,(TRUE));mult NumFill_NumLin 0x10;orcall NumFill_NumLin NFill_NLin(1,(FALSE))
    inc shape_size
    #shaperecord[n]
    sd shapewithstyle_record_start
    setcall shapewithstyle_record_start shapewithstyle_records()
    value pointer#1;data pos#1
    set pos 0x80
    set pointer shapewithstyle_record_start
    sd p_dest_pos^pointer
    while args#!=-1
        call shape_records_add(p_dest_pos,#args)
    endwhile
    data end={0,0}
    sd end_record^end
    call shape_records_add(p_dest_pos,#end_record)
    if pos!=0x80
        inc pointer
    endif
    sd records_sz
    set records_sz pointer
    sub records_sz shapewithstyle_record_start
    add shape_size records_sz

    call swf_tag_recordheader_entry((DefineShape3),shape_size)
    call swf_mem_add(#shape_id,2)
    call swf_mem_add(rect,rect_size)
    call swf_mem_add(fillstyles,fillstyles_size)
    call swf_mem_add(linestyles,linestyles_size)
    call swf_mem_add(#NumFill_NumLin,1)
    call swf_mem_add(shapewithstyle_record_start,records_sz)

    return shape_id
endfunction

#id
functionX swf_shape_basic(sd width,sd height,sd fillcolor,sd linecolor)
#sd width
#sd height
#sd fillcolor       RGBA color to fill the shape
#sd linecolor       RGBA line color around the shape
    sd xcurve_value;set xcurve_value width;div xcurve_value 6
    sd ycurve_value;set ycurve_value height;div ycurve_value 6
    sd lineheight;set lineheight width;if lineheight>height;set lineheight height;endif;div lineheight 20
    #xc width/6;yc..hg..;lh (min(w,h))/20
    sd id
    setcall id swf_shape_simple(width,height,fillcolor,lineheight,linecolor,xcurve_value,ycurve_value)
    return id
endfunction

#id
functionX swf_shape_bitmap(sd bitmapId,sd width,sd height)
#sd bitmapId    id, e.g.: from swf_dbl
    sd shape_id
    sd width_variable
    set width_variable width
    sd height_variable
    set height_variable height
    data struct=repeating_bitmap_fill
        data refid#1
        set refid bitmapId
    data *=0
    data *={0,StateFillStyle0}
    data *={1,1}
        data w1#1;data *=0
        set w1 width_variable
    data *={1,1}
        data *=0;data h1#1
        set h1 height_variable
    data *={1,1}
        data w2#1;data *=0
        mult width_variable -1
        set w2 width_variable
    data *={1,1}
        data *=0;data h2#1
        mult height_variable -1
        set h2 height_variable
    data *=-1
    setcall shape_id swf_shape(width,height,#struct)
    return shape_id
endfunction
#id
functionX swf_shape_border(sd width,sd height,sd linesize,sd linecolor)
#sd width      border width
#sd height     border height
#sd linesize  line size
#sd linecolor  0xRGBA color
    sd shape
    sd neg_w=-1
    sd neg_h=-1
    mult neg_w width
    mult neg_h height
    #
    if linesize==0;call error("is useless to call shape_border with linesize=0");endif
    data border=no_fill
    data l_w#1
        set l_w linesize
    data color#1;#linesize!=0
        set color linecolor
    #
    data *={0,StateLineStyle}
    data *={1,1}
    data est#1;data *=0
        set est width
    data *={1,1}
    data *=0;data sud#1
        set sud height
    data *={1,1}
    data west#1;data *=0
        set west neg_w
    data *={1,1}
    data *=0;data nord#1
        set nord neg_h
    data *=-1
    setcall shape swf_shape(width,height,#border)
    return shape
endfunction

#id
functionX swf_image(ss imagepath)
#ss imagepath = path name for the dbl image
    data width#1;data *height#1
    sd shape_id;setcall shape_id swf_image_ex(imagepath,#width)
    return shape_id
endfunction
#id
functionX swf_image_ex(ss imagepath,sd p_wh)
#ss imagepath = path name for the dbl image
#sd p_wh      = pointer width height
    sd dbl_id
    setcall dbl_id swf_dbl_ex(imagepath,p_wh)
    #add dbl to a shape
    sd shape_id
    sd width;set width p_wh#;add p_wh (DWORD)
    setcall shape_id swf_shape_bitmap(dbl_id,width,p_wh#)
    return shape_id
endfunction

######################dbl
#id
functionX swf_dbl(ss imagepath)
#ss imagepath = path name for the dbl image
    sd id
    setcall id swf_dbl_ex(imagepath,0)
    return id
endfunction
import "file_get_content" file_get_content
#id
functionX swf_dbl_ex(ss imagepath,sd p_wh)
#ss imagepath = path name for the dbl image
#sd p_wh = pointer width a dword and height next dword
    sd id
    sd mem
    sd size
    sd cursor
    setcall mem file_get_content(imagepath,#size)
    if size<8
        call error("missing image header")
    endif
    chars hd_magic1={D,B,l,1};vdata magic1^hd_magic1
    chars hd_magic2={D,B,l,2};vdata magic2^hd_magic2
    if mem#!=magic1#
    if mem#!=magic2#
        call printEr("expecting dbl(define bits lossless 1 or 2)header; filepath: ")
        call error(imagepath)
    endif;endif
    sd header=DefineBitsLossless2
    if mem#==magic1#
        set header (DefineBitsLossless)
    endif
    set cursor mem
    add cursor (DWORD)

    sd image_size
    setcall image_size dword_swap(cursor#)
    add cursor (DWORD)
    sub size (2*DWORD)
    if image_size>size
        call error("size error at dbl")
    endif
    #add the define bits lossless file to mem
    add size (WORD)
    import "swf_tag_recordheader_long_entry" swf_tag_recordheader_long_entry
    call swf_tag_recordheader_long_entry(header,size)
    setcall id identifiers_get()
    call swf_mem_add(#id,(WORD))
    if p_wh!=0
        #get width and height;BitmapFormat UI8,BitmapWidth UI16,BitmapHeight UI16
        if image_size<(2*WORD+BYTE)
            call error("size error at dbl when looking for width/height")
        endif
        sd pointer
        set pointer cursor
        add pointer (BYTE)
        setcall p_wh# word_arg_to_dword(pointer)
        add pointer (WORD)
        add p_wh (DWORD)
        setcall p_wh# word_arg_to_dword(pointer)
    endif
    call swf_mem_add(cursor,image_size)
    call file_get_content__resources_free()
    return id
endfunction
import "file_open" file_open
import "file_seek" file_seek
import "file_read" file_read
import "filesize" filesize

#width
functionX swf_dbl_width(ss imagepath)
#ss imagepath = path name for the dbl image
    sd file
    setcall file file_open(imagepath,(_open_read))
    call file_resources_set(file)
    sd size
    setcall size filesize(file)
    if size<(4+4+1+2)
        call error("invalid dbl file")
    endif
    call file_seek(file,(4+4+1),(SEEK_SET))
    sd width=0
    call file_read(file,#width,2)
    call file_resources_free()
    return width
endfunction
#height
functionX swf_dbl_height(ss imagepath)
#ss imagepath = path name for the dbl image
    sd file
    setcall file file_open(imagepath,(_open_read))
    call file_resources_set(file)
    sd size
    setcall size filesize(file)
    if size<(4+4+1+2+2)
        call error("invalid dbl file")
    endif
    call file_seek(file,(4+4+1+2),(SEEK_SET))
    sd height=0
    call file_read(file,#height,2)
    call file_resources_free()
    return height
endfunction

##############
import "exportsId_get" exportsId_get
functionX swf_done()
    call swf_exports_done();#remaining exports?
    call swf_actionblock((mem_exp_part_done));#in case there are remaining actions
#the swf is done and the total length is wrote and the memory is freed
    call swf_mem((mem_exp_done))
    call freereset()
endfunction

functionX swf_new(ss path,sd width,sd height,sd backgroundcolor,sd fps)
#ss path             file out pathname
#sd width
#sd height
#sd backgroundcolor  0xRRGGBB  value
#sd fps              swf frames per second

    #F=uncompressed, C=ZLib
const hd_start=!
    chars *=F
    chars *={W,S}
    chars *version=8
const file_sz_off=!
    data *FileLength#1
data size=!-hd_start
vdata hd_pack%hd_start
    #rect
const hd2=!
    chars *FrameRate=0
        chars FrameRate#1
    chars *FrameCount={1,0}
data size2=!-hd2
vdata hd_pack2%hd2

    #
    call swf_mem((mem_exp_init),path,(file_sz_off-hd_start))
    #identifiers for swf
    call identifiers_set(1);#font with id 0 isn't visible in the placements

    call swf_mem_add(hd_pack,size)
    call rect_add(width,height)
    #x.x format
    set FrameRate fps
    call swf_mem_add(hd_pack2,size2)
    #

    chars setbackgroundtag#2
    chars red#1
    chars green#1
    chars blue#1

    set blue backgroundcolor
    sd g_color=0xff00;and g_color backgroundcolor;div g_color 0x100;set green g_color
    sd r_color=0xff0000;and r_color backgroundcolor;div r_color (0x100*0x100);set red r_color
    call swf_tag(#setbackgroundtag,(SetBackGroundColor),3)
endfunction

functionX swf_placeobject(sd refid,sd depth)
#sd refid    the id
#sd depth    depth value
     call swf_placeobject_coords(refid,depth,0,0)
endfunction
functionX swf_placeobject_coords(sd refid,sd depth,sd x,sd y)
#sd refid
#sd depth
#sd x         x coordinate
#sd y         y coordinate
#const PlaceFlagHasClipActions=0x80
#const PlaceFlagHasClipDepth=0x40
#const PlaceFlagHasName=0x20
#const PlaceFlagHasRatio=0x10
#const PlaceFlagHasColorTransform=0x8
const PlaceFlagHasMatrix=0x4
const PlaceFlagHasCharacter=0x2
#const PlaceFlagMove=0x1
    sd flags=PlaceFlagHasMatrix|PlaceFlagHasCharacter
    sd matrix
    sd maxtrixsz
    call matrix_translate(#matrix,#maxtrixsz,x,y)

    sd size=5
    add size maxtrixsz
    call swf_tag_recordheader_entry((PlaceObject2),size)
    call swf_mem_add(#flags,1)
    call swf_mem_add(#depth,2)
    #character id
    call swf_mem_add(#refid,2)
    #matrix
    call swf_mem_add(matrix,maxtrixsz)
endfunction
functionX swf_removeobject(sd depth)
#sd depth        depth for the removeobject2 tag
    call swf_tag_recordheader_entry((RemoveObject2),2)
    #depth
    call swf_mem_add(#depth,2)
endfunction

functionX swf_showframe()
#showframe tag
    call swf_actionblock((mem_exp_part_done))
    call swf_tag_recordheader_entry((ShowFrame),0)
endfunction

######################

#sprite

#id
functionX swf_sprite_done(sd spriteid)
#sd spriteid        pre-id created with swf_sprite_new
    call swf_mem((mem_exp_change),spriteid)
    call swf_actionblock((mem_exp_change),spriteid)
    call swf_actionblock((mem_exp_part_done));#in case there are remaining actions
    call swf_actionblock((mem_exp_change_back))
    import "swf_tag_end" swf_tag_end
    call swf_tag_end()
    call swf_mem((mem_exp_change_back))

    sd sprite
    setcall sprite struct_ids((ids_get),spriteid)
    sd mem
    setcall mem block_get_mem(sprite)
    sd size
    setcall size block_get_size(sprite)
    #
    call swf_tag_recordheader_entry((DefineSprite),size)
    sd id
    setcall id identifiers_get()
    call dword_to_word_arg(id,mem)
    #

    call swf_mem_add(mem,size)

    call free_sprite_id(spriteid)

    return id
endfunction
import "new_sprite_id" new_sprite_id
#pre-id
functionX swf_sprite_new()
#a pre-id to be used
    sd id
    setcall id new_sprite_id()
    call swf_mem((mem_exp_change),id)
    sd reserve;#set later
    call swf_mem_add(#reserve,2)
    sd frames=0
    call swf_mem_add(#frames,2)
    call swf_mem((mem_exp_change_back))
    return id
endfunction
functionX swf_sprite_placeobject(sd spriteid,sd object,sd depth)
#sd spriteid          pre-id
#sd object,sd depth   same as swf_placeobject
    call swf_mem((mem_exp_change),spriteid)
    call swf_placeobject(object,depth)
    call swf_mem((mem_exp_change_back))
endfunction
functionX swf_sprite_placeobject_coords(sd spriteid,sd object,sd depth,sd x,sd y)
#sd spriteid                   pre-id
#sd object,sd depth,sd x,sd y  same as swf_placeobject_coords
    call swf_mem((mem_exp_change),spriteid)
    call swf_placeobject_coords(object,depth,x,y)
    call swf_mem((mem_exp_change_back))
endfunction
functionX swf_sprite_removeobject(sd spriteid,sd depth)
#sd spriteid   pre-id
#sd depth      same as swf_removeobject
    call swf_mem((mem_exp_change),spriteid)
    call swf_removeobject(depth)
    call swf_mem((mem_exp_change_back))
endfunction
functionX swf_sprite_showframe(sd spriteid)
#sd spriteid   pre-id
    call swf_mem((mem_exp_change),spriteid)
    #
    sd sprite
    setcall sprite struct_ids((ids_get),spriteid)
    sd mem
    setcall mem block_get_mem(sprite)
    add mem (WORD)
    sd frames
    setcall frames word_arg_to_dword(mem)
    inc frames
    call dword_to_word_arg(frames,mem)
    #
    call swf_actionblock((mem_exp_change),spriteid)
    call swf_showframe()
    call swf_actionblock((mem_exp_change_back))
    call swf_mem((mem_exp_change_back))
endfunction

######################

#exports

functionX swf_exports_add(sd id,ss name)
#sd id
#ss name       name to be used at the actionscript
    sd exports
    setcall exports exportsId_get()
    #
    call swf_mem((mem_exp_change),exports)
    #
    sd block
    setcall block struct_ids((ids_get),exports)
    sd size
    setcall size block_get_size(block)
    sd counter
    if size==0
        set counter 1
        call swf_mem_add(#counter,(WORD))
    else
        sd mem
        setcall mem block_get_mem(block)
        setcall counter word_arg_to_dword(mem)
        inc counter
        call dword_to_word_arg(counter,mem)
    endelse
    #
    call swf_mem_add(#id,(WORD))
    sd len
    setcall len strlen(name)
    inc len
    call swf_mem_add(name,len)
    #
    call swf_mem((mem_exp_change_back))
endfunction
functionX swf_exports_done()
#write all the exports to the swf
    sd exports
    setcall exports exportsId_get()
    sd block
    setcall block struct_ids((ids_get),exports)
    sd size
    setcall size block_get_size(block)
    if size!=0
        #
        call swf_tag_recordheader_entry((ExportAssets),size)
        #
        sd exp
        setcall exp block_get_mem(block)
        call swf_mem_add(exp,size)
        call block_reset_size(block)
    endif
endfunction
