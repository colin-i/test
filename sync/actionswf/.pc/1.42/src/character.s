Format ElfObj64

importx "swf_text" swf_text
importx "swf_shape" swf_shape
#
importx "action_sprite" action_sprite

importaftercall ebool
include "../include/prog.h"


#shape

import "identifiers_get" identifiers_get
import "dword_to_word_arg" dword_to_word_arg
#value
function args_advance(sv p_args)
    sd value
    set value p_args#
    add p_args# (DWORD)
    return value#
endfunction
const max_chars_records=256
function shapewithstyle_records()
    chars shapewithstyle_record#max_chars_records
    return #shapewithstyle_record
endfunction
import "error" error
function shape_records_bits(sd value,sd size,sv p_dest_pos)
    #why was this here? data start#1
    #and this, this is called through shape_records_add    if p_dest_pos==0
    #	set start value
    #	return (void)
    #endif
    sd pointer
    set pointer p_dest_pos#
    subcall pointer shapewithstyle_records()
    if pointer==(max_chars_records)
    #was >=
        call error("too many arguments at shape")
    endif
    import "bits_bigendian" bits_bigendian
    sd p_pos
    set p_pos p_dest_pos
    add p_pos :
    call bits_bigendian(value,size,p_dest_pos,p_pos)
endfunction
function shape_records_add(sd p_dest_pos,sd p_args)
    sd edge
    setcall edge args_advance(p_args)
    call shape_records_bits(edge,1,p_dest_pos)
    if edge==0
    #StyleChangeRecord,#EndShapeRecord
        sd flags
        setcall flags args_advance(p_args)
        call shape_records_bits(flags,5,p_dest_pos)
        if flags==0
        #EndShapeRecord
            return (void)
        endif
        #StateMoveTo
        call shape_records_add_moveto(p_dest_pos,flags,p_args)
        #
        sd f_l_bits
        sd fill
        #StateFillStyle0
        set fill flags;and fill (StateFillStyle0)
        if fill!=0
            setcall f_l_bits NumFill_NumLin(1,(TRUE));call shape_records_bits(1,f_l_bits,p_dest_pos)
        endif
        #StateFillStyle1
        set fill flags;and fill (StateFillStyle1)
        if fill!=0
            setcall f_l_bits NumFill_NumLin(1,(TRUE));call shape_records_bits(1,f_l_bits,p_dest_pos)
        endif
        #StateLineStyle
        and flags (StateLineStyle)
        if flags!=0
            setcall f_l_bits NumFill_NumLin(1,(FALSE))
            call shape_records_bits(1,f_l_bits,p_dest_pos)
        endif
        return (void)
    endif
    call shape_records_add_edge(p_dest_pos,p_args)
endfunction
function shape_records_add_moveto(sd p_dest_pos,sd flags,sd p_args)
    and flags (StateMoveTo)
    if flags==0
        return (void)
    endif
    sd x
    setcall x args_advance(p_args)
    sd y
    setcall y args_advance(p_args)
    import "numbitsMax" numbitsMax
    sd numbits
    mult x 20
    mult y 20
    setcall numbits numbitsMax(x,y)
    call shape_records_bits(numbits,(NBits_size),p_dest_pos)
    call shape_records_bits(x,numbits,p_dest_pos)
    call shape_records_bits(y,numbits,p_dest_pos)
endfunction
function shape_records_add_edge(sd p_dest_pos,sd p_args)
    sd straight_edge
    setcall straight_edge args_advance(p_args)
    call shape_records_bits(straight_edge,1,p_dest_pos)
    if straight_edge==1
        call shape_records_add_edge_straight(p_dest_pos,p_args)
    else
        call shape_records_add_edge_curved(p_dest_pos,p_args)
    endelse
endfunction
function shape_records_add_edge_straight(sd p_dest_pos,sd p_args)
    sd width=20;multCall width args_advance(p_args)
    sd height=20;multCall height args_advance(p_args)
    sd counter;setcall counter numbitsMax(width,height)
    #NumBits(UB[4])
    sd NumBits;setcall NumBits shape_records_NumBits(#counter)
    call shape_records_bits(NumBits,4,p_dest_pos)
    #GeneralLineFlag
    sd GeneralLineFlag=0
    if width!=0;if height!=0;set GeneralLineFlag 1;endif;endif
    call shape_records_bits(GeneralLineFlag,1,p_dest_pos)
    #Vert(1)/Horz(0)
    if GeneralLineFlag==0
        sd vertical=1;if width!=0;set vertical 0;endif
        call shape_records_bits(vertical,1,p_dest_pos)
    endif
    #DeltaX SB[NumBits+2]
    sd DeltaX=TRUE;if GeneralLineFlag==0;if vertical==1;set DeltaX (FALSE);endif;endif
    if DeltaX==(TRUE);call shape_records_bits(width,counter,p_dest_pos);endif
    #DeltaY SB[NumBits+2]
    sd DeltaY=TRUE;if GeneralLineFlag==0;if vertical==0;set DeltaY (FALSE);endif;endif
    if DeltaY==(TRUE);call shape_records_bits(height,counter,p_dest_pos);endif
endfunction
function shape_records_add_edge_curved(sd p_dest_pos,sd p_args)
    sd control_x
    setcall control_x args_advance(p_args)
    sd control_y
    setcall control_y args_advance(p_args)
    sd anchor_x
    setcall anchor_x args_advance(p_args)
    sd anchor_y
    setcall anchor_y args_advance(p_args)
    mult control_x 20
    mult control_y 20
    mult anchor_x 20
    mult anchor_y 20
    sd numbits
    sd numbits2
    setcall numbits numbitsMax(control_x,control_y)
    setcall numbits2 numbitsMax(anchor_x,anchor_y)
    if numbits2>numbits
        set numbits numbits2
    endif
    #NumBits(UB[4])
    sd Num_Bits;setcall Num_Bits shape_records_NumBits(#numbits)
    call shape_records_bits(Num_Bits,4,p_dest_pos)
    #SB[NumBits+2]
    call shape_records_bits(control_x,numbits,p_dest_pos)
    call shape_records_bits(control_y,numbits,p_dest_pos)
    call shape_records_bits(anchor_x,numbits,p_dest_pos)
    call shape_records_bits(anchor_y,numbits,p_dest_pos)
endfunction
#n
function shape_records_NumBits(sd p_val)
    sd val=-2;add val p_val#
    if val<0
        mult val -1;add p_val# val
        return 0
    endif
    return val
endfunction
#get:fill/lin
function NumFill_NumLin(sd set_get,sd fill,sd lin)
    data NFill_NLin#1
    if set_get==0
        set NFill_NLin lin;mult fill 0x10;or NFill_NLin fill
    else
        if fill==(FALSE);set lin NFill_NLin;and lin 0x0F;return lin
        else;set fill NFill_NLin;div fill 0x10;return fill;endelse
    endelse
endfunction
#id
function swf_shape_simple(sd width,sd height,sd fillcolor,sd lineheight,sd linecolor,sd xcurve,sd ycurve)
    sd wd;set wd width;sub wd lineheight
    sd hg;set hg height;sub hg lineheight
    sd test
    set test lineheight;mult test 2;if test>width;call error("lineheight value against width is too high for shape");endif
    set test lineheight;mult test 2;if test>height;call error("lineheight value against height is too high for shape");endif
    set test wd;div test 2;if xcurve>wd;call error("xcurve value is too high for shape");endif
    set test hg;div test 2;if ycurve>hg;call error("ycurve value is too high for shape");endif
    sd lineheight_hf;set lineheight_hf lineheight;div lineheight_hf 2

    sd width_variable
    sd height_variable
    set width_variable wd
    set height_variable hg
    sub width_variable xcurve
    sub width_variable xcurve
    sub height_variable ycurve
    sub height_variable ycurve

    data header#4
    sd struct^header;if lineheight==0;add struct (DWORD);endif
    sd cursor;set cursor struct
    set cursor# (solid_fill)
    add cursor (DWORD);set cursor# fillcolor
    add cursor (DWORD);set cursor# lineheight
    if lineheight!=0;add cursor (DWORD);set cursor# linecolor;endif
    #the header is connected with the part below
    data *=0
    data styles#1;set styles (StateFillStyle0|StateMoveTo);if lineheight!=0;or styles (StateLineStyle);endif
        data x_move#1;set x_move lineheight_hf;add x_move xcurve
        data y_move#1;set y_move lineheight_hf

    data *={1,1}
        data w1#1;data *=0
        set w1 width_variable
    data *={1,0}
        data xNE#1
        set xNE xcurve
        data *={0,0}
        data yNE#1
        set yNE ycurve
    data *={1,1}
        data *=0;data h1#1
        set h1 height_variable
    data *={1,0}
        data *=0
        data ySE#1
        set ySE ycurve
        data xSE#1
        mult xcurve -1
        set xSE xcurve
        data *=0
    data *={1,1}
        data w2#1;data *=0
        mult width_variable -1
        set w2 width_variable
    data *={1,0}
        data xSV#1
        set xSV xcurve
        data *={0,0}
        mult ycurve -1
        data ySV#1
        set ySV ycurve
    data *={1,1}
        data *=0;data h2#1
        mult height_variable -1
        set h2 height_variable
    data *={1,0}
        data *=0
        data yNV#1
        set yNV ycurve
        data xNV#1
        mult xcurve -1
        set xNV xcurve
        data *=0
    data *=-1
    sd id
    setcall id swf_shape(width,height,struct)
    return id
endfunction

#edittext

const sim64pointerSize=:-DWORD
#struct
function edittext_struct()
    data fontid#1
    data *font_height#1
    str *fontclassname#1;chars *sim64pointer#sim64pointerSize
    data *rgba#1
    data *maxlength#1
    str *initialtext#1;chars *sim64pointer#sim64pointerSize
    data *layout_align#1
    data *layout_leftmargin#1
    data *layout_rightmargin#1
    data *layout_indent#1
    data *layout_leading#1
    return #fontid
endfunction
function edittext_font(sd fontid,sd fontheight)
    sd s
    setcall s edittext_struct()
    set s# fontid
    add s (DWORD)
    set s# fontheight
endfunction
function edittext_rgba(sd val)
    sd ed_str
    setcall ed_str edittext_struct()
    add ed_str (3*DWORD+sim64pointerSize);set ed_str# val
endfunction
function edittext_layout(sd in_args)
    sd s
    setcall s edittext_struct()
    add s (6*DWORD+sim64pointerSize+sim64pointerSize)
    set s# in_args#
    add s (DWORD);add in_args (DWORD);set s# in_args#
    add s (DWORD);add in_args (DWORD);set s# in_args#
    add s (DWORD);add in_args (DWORD);set s# in_args#
    add s (DWORD);add in_args (DWORD);set s# in_args#
endfunction
function edittext_text(ss text)
    sd s
    setcall s edittext_struct()
    add s (5*DWORD+sim64pointerSize)
    set s# text
endfunction

#id
function swf_text_initial_font_centered(sd width,sd height,ss text,sd font_id,sd font_height,sd font_color)
    call edittext_font(font_id,font_height)
    call edittext_rgba(font_color)
    data layout={layout_align_center,0,0,0,0}
    call edittext_layout(#layout)
    call edittext_text(text)
    sd e_struct
    setcall e_struct edittext_struct()
    sd text_id
    setcall text_id swf_text(width,height,"",(HasFont|HasText|HasTextColor|HasLayout|ReadOnly|NoSelect),e_struct)
    return text_id
endfunction

#button

function button_mem()
    data up#1
    data *over#1
	data *hit#1

    data *width#1
    data *height#1

    data *no_text#1
    data *font_id#1
    data *font_height#1
    data *y#1
    data *font_color#1

    return #up
endfunction
import "swf_tag_recordheader_entry" swf_tag_recordheader_entry
import "swf_mem_add" swf_mem_add
#id
function swf_button_base(sd state_def_id,sd state_over_id,sd state_down_id,sd noText,sd text_id,sd y,ss actions)
    sd size=2+1+2;#ButtonId,TrackAsMenu,ActionOffset

    sd Characters_CharacterEndFlag_size
    setcall Characters_CharacterEndFlag_size buttonrecord(0,0,0)
    mult Characters_CharacterEndFlag_size 3
    if noText==(FALSE)
        addcall Characters_CharacterEndFlag_size buttonrecord(0,0,y)
    endif
    inc Characters_CharacterEndFlag_size

    add size Characters_CharacterEndFlag_size

    chars BUTTONCONDACTION={0,0};#CondActionSize
    chars *={8,0};#CondOverDownToOverUp
    const BUTTONCONDACTION_header_size=2+2
    #is action,pool and sprite, it's more code to get action,pool only
    import "new_sprite_id" new_sprite_id
    sd id
    setcall id new_sprite_id()
    call action_sprite(id,actions)

    add size (BUTTONCONDACTION_header_size)
    import "action_size" action_size
    addcall size action_size(id)

    call swf_tag_recordheader_entry((DefineButton2),size)
    sd ButtonId
    setcall ButtonId identifiers_get()
    call swf_mem_add(#ButtonId,2)
    chars TrackAsMenu=0
    call swf_mem_add(#TrackAsMenu,(BYTE))
    sd ActionOffset=2;add ActionOffset Characters_CharacterEndFlag_size
    call swf_mem_add(#ActionOffset,(WORD))
    call buttonrecord(1,0,0,(ButtonStateUp),state_def_id,1)
    call buttonrecord(1,0,0,(ButtonStateOver),state_over_id,2)
	call buttonrecord(1,0,0,(ButtonStateDown|ButtonStateHitTest),state_down_id,3)
    if noText==(FALSE)
        call buttonrecord(1,0,y,(ButtonStateUp|ButtonStateOver|ButtonStateDown|ButtonStateHitTest),text_id,4)
    endif
    chars CharacterEndFlag=0
    call swf_mem_add(#CharacterEndFlag,1)
    import "write_action" write_action
    call swf_mem_add(#BUTTONCONDACTION,(BUTTONCONDACTION_header_size))
    call write_action(id)

    import "free_sprite_id" free_sprite_id
    call free_sprite_id(id)
    return ButtonId
endfunction

import "matrix_translate" matrix_translate

#size/void
function buttonrecord(sd writeflag,sd x,sd y,sd states,sd id,sd depth)
    #ButtonReserved[2]=0,ButtonHasBlendMode[1]=0,ButtonHasFilterList[1]=0
    #states[4]
    chars bits#1
    chars CharacterID#2
    chars PlaceDepth#2

    sd size=1+2+2

    if writeflag==1
        set bits states
        call dword_to_word_arg(id,#CharacterID)
        call dword_to_word_arg(depth,#PlaceDepth)
        call swf_mem_add(#bits,size)
    endif

    #PlaceMatrix
    sd matrix
    sd maxtrixsz
    call matrix_translate(#matrix,#maxtrixsz,x,y)
    if writeflag==1
        call swf_mem_add(matrix,maxtrixsz)
    else
        add size maxtrixsz
    endelse

    chars CXFORMWITHALPHA=0
    if writeflag==1
        call swf_mem_add(#CXFORMWITHALPHA,(BYTE))
    else
        add size (BYTE)
    endelse

    if writeflag==0
        return size
    endif
endfunction
