format elfobj

include "../_include/include.h"

const zig_zag=0
const horizontal=1
#const vertical=2

#cbp
function mpeg_mb_prediction(sd x,sd y,sd mb_width,sd qcoeff,sd acpred_direction)
    sd s=0
    chars predictors_data#6*8*int16
    data predictors^predictors_data

    #sd scaler=default_scaler

    sd qcoeff_cursor
    set qcoeff_cursor qcoeff
    sd predictors_cursor
    set predictors_cursor predictors

    sd mbpos
    set mbpos y
    mult mbpos mb_width
    add mbpos x

    sd j=0
    while j<6
        call mpeg_predict_acdc(x,mb_width,mbpos,j,predictors_cursor,acpred_direction)

        #XVID_VOP_HQACPRED
        addcall s calc_acdc_bits(acpred_direction,mbpos,j,qcoeff_cursor,predictors_cursor)

        add qcoeff_cursor (64*int16)
        add predictors_cursor (8*int16)
        inc j
    endwhile

    set j 0
    sd ac_pred_dir
    set ac_pred_dir acpred_direction
    if s<=0
        #don't predict
        while j<6
            set ac_pred_dir# 0
            add ac_pred_dir 4
            inc j
        endwhile
    else
    #apply acdc
        set qcoeff_cursor qcoeff
        set predictors_cursor predictors
        while j<6
            call mpeg_apply_acdc(qcoeff_cursor,predictors_cursor,ac_pred_dir)

            add qcoeff_cursor (64*int16)
            add predictors_cursor (8*int16)
            add ac_pred_dir 4
            inc j
        endwhile
    endelse

    sd cbp
    setcall cbp mpeg_calc_cbp(qcoeff)
    return cbp
endfunction

const mb_pred_values=0
const mb_mode=1

const MBPRED_SIZE=15
const mbpred_block_size=MBPRED_SIZE*int16
const pred_values_size=6*mbpred_block_size
function macro_blocks_core(sd action,sd mbpos,sd sector,sd item)
    data mem#1

    data mb_width#1
    data mb_height#1

    data pred_values_size#1
    data modes_size#1

    import "memalloc" memalloc
    importx "_free" free
    import "mpeg_image_w" mpeg_image_w
    import "mpeg_image_h" mpeg_image_h
    import "multiple_of_nr" multiple_of_nr

    if action==(value_set)
    #bool
        setcall mb_width mpeg_image_w()
        setcall mb_height mpeg_image_h()
        setcall mb_width multiple_of_nr(mb_width,16)
        setcall mb_height multiple_of_nr(mb_height,16)
        div mb_width 16
        div mb_height 16

        sd size
        sd blocks
        set blocks mb_width
        mult blocks mb_height

        #pred values
        set pred_values_size (pred_values_size)
        mult pred_values_size blocks

        #modes
        set modes_size 4
        mult modes_size blocks

        set size pred_values_size
        add size modes_size

        setcall mem memalloc(size)
        if mem==0
            return 0
        endif
        return 1
    elseif action==(value_unset)
        call free(mem)
    else
    #if action==(value_get)
    #pointer
        #go to item
        sd block
        set block mem
        if item>(mb_pred_values)
            add block pred_values_size
        endif

        #set mbpos and sector
        if item==(mb_pred_values)
            mult mbpos (pred_values_size)
            mult sector (mbpred_block_size)
        elseif item==(mb_mode)
            mult mbpos 4
        endelseif

        #get pointer
        add block mbpos
        add block sector
        return block
    endelse
endfunction

function macro_blocks(sd action,sd mbpos,sd sector)
    sd value
    setcall value macro_blocks_core(action,mbpos,sector,(mb_pred_values))
    return value
endfunction

function macro_blocks_mode(sd action,sd mbpos,sd value)
    sd mode
    setcall mode macro_blocks_core((value_get),mbpos,0,(mb_mode))
    if action==(value_set)
        set mode# value
    else
        return mode#
    endelse
endfunction

function mpeg_predict_acdc(sd x,sd mb_width,sd mbpos,sd block,sd predictors,sd acpred_direction)
    #sd left_quant=DEFAULT_QUANT
    #sd top_quant=DEFAULT_QUANT

    #int16
    chars default_acdc_values={1024,1024/0x100}
    chars *={0,0, 0,0, 0,0, 0,0, 0,0, 0,0, 0,0}
    chars *={0,0, 0,0, 0,0, 0,0, 0,0, 0,0, 0,0}

    sd p_left^default_acdc_values
    sd p_top^default_acdc_values
    sd p_diag^default_acdc_values

    sd index
    #set index mbpos

    #data acpred_directions_data#6
    #sd acpred_directions^acpred_directions_data
    #sd value
    #set value block
    #mult value 4
    #add acpred_directions value

    sd left=0
    sd top=0
    sd diag=0

    import "array_get_int16" array_get_int16

    sd mode

    sd condition=0
    #left,top and diag macroblocks
    #left
    if x!=0
        if mbpos>=1
            set condition 1
        endif
    endif
    if condition==1
        set index mbpos
        dec index
        setcall mode macro_blocks_mode((value_get),index)
        if mode==(INTRA)
            setcall left macro_blocks((value_get),index,0)
        endif
    endif
    #top
    if mbpos>=mb_width
        set index mbpos
        sub index mb_width
        setcall mode macro_blocks_mode((value_get),index)
        if mode==(INTRA)
            setcall top macro_blocks((value_get),index,0)
        endif
    endif
    #diag
    set condition 0
    if x!=0
        set index mb_width
        inc index
        if mbpos>=index
            set condition 1
        endif
    endif
    if condition==1
        set index mbpos
        sub index mb_width
        dec index
        setcall mode macro_blocks_mode((value_get),index)
        if mode==(INTRA)
            setcall diag macro_blocks((value_get),index,0)
        endif
    endif

    #pLeft, pTop, pDiag blocks
    sd current
    setcall current macro_blocks((value_get),mbpos,0)
    if block==0
        if left!=0
            set p_left left
            add p_left (mbpred_block_size)
        endif
        if top!=0
            set p_top top
            add p_top (mbpred_block_size*2)
        endif
        if diag!=0
            set p_diag diag
            add p_diag (mbpred_block_size*3)
        endif
    elseif block==1
        set p_left current
        #set left_quant
        if top!=0
            set p_top top
            add p_top (mbpred_block_size*3)
            set p_diag top
            add p_diag (mbpred_block_size*2)
        endif
    elseif block==2
        if left!=0
            set p_left left
            add p_left (mbpred_block_size*3)
            set p_diag left
            add p_diag (mbpred_block_size)
        endif
        set p_top current
    elseif block==3
        set p_left current
        add p_left (mbpred_block_size*2)
        set p_top current
        add p_top (mbpred_block_size)
        set p_diag current
    elseif block==4
        if left!=0
            set p_left left
            add p_left (mbpred_block_size*4)
        endif
        if top!=0
            set p_top top
            add p_top (mbpred_block_size*4)
        endif
        if diag!=0
            set p_diag diag
            add p_diag (mbpred_block_size*4)
        endif
    elseif block==5
        if left!=0
            set p_left left
            add p_left (mbpred_block_size*5)
        endif
        if top!=0
            set p_top top
            add p_top (mbpred_block_size*5)
        endif
        if diag!=0
            set p_diag diag
            add p_diag (mbpred_block_size*5)
        endif
    endelseif
    #determine ac prediction direction & ac/dc predictor place rescaled ac/dc
    #predictions into predictors[] for later use
    import "mb_div" mb_div
    import "array_set_word_off" array_set_word_off
    import "array_set_int" array_set_int
    sd value
    sd i=1
    sd condition1
    setcall condition1 array_get_int16(p_left,0)
    subcall condition1 array_get_int16(p_diag,0)
    if condition1<0
        mult condition1 -1
    endif
    sd condition2
    setcall condition2 array_get_int16(p_diag,0)
    subcall condition2 array_get_int16(p_top,0)
    if condition2<0
        mult condition2 -1
    endif
    if condition1<condition2
        #vertical
        call array_set_int(acpred_direction,block,1)
        setcall value array_get_int16(p_top,0)
        setcall value mb_div(value,(default_scaler))
        call array_set_word_off(predictors,value,0)
        while i<8
            setcall value array_get_int16(p_top,i)
            setcall value mb_rescale(value)
            call array_set_word_off(predictors,value,i)
            inc i
        endwhile
    else
        #horizontal
        call array_set_int(acpred_direction,block,2)
        setcall value array_get_int16(p_left,0)
        setcall value mb_div(value,(default_scaler))
        call array_set_word_off(predictors,value,0)
        while i<8
            set value i
            add value 7
            setcall value array_get_int16(p_left,value)
            setcall value mb_rescale(value)
            call array_set_word_off(predictors,value,i)
            inc i
        endwhile
    endelse
endfunction

function mb_rescale(sd coef)
    sd x
    if coef!=0
        mult coef (DEFAULT_QUANT)
        setcall x mb_div(coef,(DEFAULT_QUANT))
        return x
    else
        return 0
    endelse
endfunction

#################calc_acdc_bits
#return S
function calc_acdc_bits(sd acpred_direction,sd mbpos,sd sector,sd qcoeff,sd predictors)
    import "array_get_int" array_get_int
    sd direction
    setcall direction array_get_int(acpred_direction,sector)
    sd pred_values
    setcall pred_values macro_blocks((value_get),mbpos,sector)
    #store current coeffs to pred_values[] for future prediction
    sd value
    setcall value array_get_int16(qcoeff,0)
    mult value (default_scaler)
    setcall value clip_value(value,-2048,2047)
    call array_set_word_off(pred_values,value,0)
    sd ind
    sd i=1
    while i<8
        setcall value array_get_int16(qcoeff,i)
        call array_set_word_off(pred_values,value,i)
        #
        set value i
        mult value 8
        setcall value array_get_int16(qcoeff,value)
        set ind i
        add ind 7
        call array_set_word_off(pred_values,value,ind)
        inc i
    endwhile
    #dc prediction
    setcall value array_get_int16(qcoeff,0)
    subcall value array_get_int16(predictors,0)
    call array_set_word_off(qcoeff,value,0)
    #calc cost before ac prediction

    sd z2
    setcall z2 coef_intra_calc(qcoeff,(zig_zag))

    chars tmp#8*int16
    data temp^tmp
    set i 1
    #apply ac prediction & calc cost
    if direction==1
        while i<8
            setcall value array_get_int16(qcoeff,i)
            call array_set_word_off(temp,value,i)

            setcall value array_get_int16(qcoeff,i)
            subcall value array_get_int16(predictors,i)
            call array_set_word_off(qcoeff,value,i)

            setcall value array_get_int16(qcoeff,i)
            call array_set_word_off(predictors,value,i)

            inc i
        endwhile
    else
    #acpred_direction == 2
        while i<8
            set value i
            mult value 8
            setcall value array_get_int16(qcoeff,value)
            call array_set_word_off(temp,value,i)

            set ind i
            mult ind 8

            setcall value array_get_int16(qcoeff,ind)
            subcall value array_get_int16(predictors,i)
            call array_set_word_off(qcoeff,value,ind)

            setcall value array_get_int16(qcoeff,ind)
            call array_set_word_off(predictors,value,i)

            inc i
        endwhile
    endelse

    sd z1
    setcall z1 coef_intra_calc(qcoeff,direction)

    set i 1
    #undo prediction
    if direction==1
        while i<8
            setcall value array_get_int16(temp,i)
            call array_set_word_off(qcoeff,value,i)
            inc i
        endwhile
    else
    #acpred_direction == 2
        while i<8
            setcall value array_get_int16(temp,i)
            set ind i
            mult ind 8
            call array_set_word_off(qcoeff,value,ind)
            inc i
        endwhile
    endelse

    sub z2 z1
    return z2
endfunction

function clip_value(sd value,sd min,sd max)
    if value<min
        return min
    elseif value>max
        return max
    endelseif
    return value
endfunction

function coef_intra_calc(sd qcoeff,sd index)
    sd scan_table
    setcall scan_table mpeg_scan_tables(index)
    sd bits=0
    sd i=1
    sd run=0
    sd level=0
    while level==0
        setcall level array_get_int(scan_table,i)
        inc i
        setcall level array_get_int16(qcoeff,level)
        if level==0
            if i==64
                #empty block
                return 0
            endif
            inc run
        endif
    endwhile
    sd prev_level
    set prev_level level
    sd prev_run
    set prev_run run
    set run 0
    sd abs_level
    ss p_len
    sd len
    while i<64
        setcall level array_get_int(scan_table,i)
        inc i
        setcall level array_get_int16(qcoeff,level)
        if level!=0
            set abs_level prev_level
            if abs_level<0
                mult abs_level -1
            endif
            if abs_level>=64
                set abs_level 0
            endif
            import "vlc_tables_intra" vlc_tables_intra
            setcall p_len vlc_tables_intra((value_get),(VLC_len),0,abs_level,prev_run)
            set len p_len#
            if len!=128
                add bits len
            else
                add bits 30
            endelse
            set prev_level level
            set prev_run run
            set run 0
        else
            inc run
        endelse
    endwhile

    set abs_level prev_level
    if abs_level<0
        mult abs_level -1
    endif
    if abs_level>=64
        set abs_level 0
    endif
    setcall p_len vlc_tables_intra((value_get),(VLC_len),1,abs_level,prev_run)
    set len p_len#
    if len!=128
        add bits len
    else
        add bits 30
    endelse
    return bits
endfunction

function mpeg_scan_tables(sd table)
    #uint16
    data zig_zag_data={0,   1,  8, 16,  9,  2,  3, 10}
    data *           ={17, 24, 32, 25, 18, 11,  4,  5}
    data *           ={12, 19, 26, 33, 40, 48, 41, 34}
    data *           ={27, 20, 13,  6,  7, 14, 21, 28}
    data *           ={35, 42, 49, 56, 57, 50, 43, 36}
    data *           ={29, 22, 15, 23, 30, 37, 44, 51}
    data *           ={58, 59, 52, 45, 38, 31, 39, 46}
    data *           ={53, 60, 61, 54, 47, 55, 62, 63}

    data horizontal_data={0,   1,  2,  3,  8,  9, 16, 17}
    data *              ={10, 11,  4,  5,  6,  7, 15, 14}
    data *              ={13, 12, 19, 18, 24, 25, 32, 33}
    data *              ={26, 27, 20, 21, 22, 23, 28, 29}
    data *              ={30, 31, 34, 35, 40, 41, 48, 49}
    data *              ={42, 43, 36, 37, 38, 39, 44, 45}
    data *              ={46, 47, 50, 51, 56, 57, 58, 59}
    data *              ={52, 53, 54, 55, 60, 61, 62, 63}

    data   vertical_data={0,   8, 16, 24,  1,  9,  2, 10}
    data *              ={17, 25, 32, 40, 48, 56, 57, 49}
    data *              ={41, 33, 26, 18,  3, 11,  4, 12}
    data *              ={19, 27, 34, 42, 50, 58, 35, 43}
    data *              ={51, 59, 20, 28,  5, 13,  6, 14}
    data *              ={21, 29, 36, 44, 52, 60, 37, 45}
    data *              ={53, 61, 22, 30,  7, 15, 23, 31}
    data *              ={38, 46, 54, 62, 39, 47, 55, 63}

    data zig_zag^zig_zag_data
    data horizontal^horizontal_data
    data vertical^vertical_data
    if table==(zig_zag)
        return zig_zag
    elseif table==(horizontal)
        return horizontal
    else
        #vertical
        return vertical
    endelse
endfunction

######
function mpeg_apply_acdc(sd qcoeff,sd predictors,sd direction)
    sd i=1
    sd value
    if direction#==1
        while i<8
            setcall value array_get_int16(predictors,i)
            call array_set_word_off(qcoeff,value,i)
            inc i
        endwhile
    else
        while i<8
            setcall value array_get_int16(predictors,i)
            sd ind
            set ind i
            mult ind 8
            call array_set_word_off(qcoeff,value,ind)
            inc i
        endwhile
    endelse
endfunction

###
#cbp
function mpeg_calc_cbp(sd qcoeff)
    sd cbp=0
    sd i=0
    while i<6
        add cbp cbp

        sd value
        setcall value array_get_int16(qcoeff,1)
        if value!=0
            inc cbp
        else
            sd qcoeff_cursor
            set qcoeff_cursor qcoeff
            sd iter=64/2-1
            while iter!=0
                add qcoeff_cursor 4
                dec iter

                if qcoeff_cursor#!=0
                    inc cbp
                    set iter 0
                endif
            endwhile
        endelse

        add qcoeff (64*int16)
        inc i
    endwhile
    return cbp
endfunction
