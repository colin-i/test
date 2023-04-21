

format elfobj

include "../_include/include.h"

const luma_count=16
#const chroma_count=8

#CQM_4IY = 0,
#CQM_4IC = 2,

function avc_block(sd Y,sd U,sd V,sd x,sd y)
    #encode luma
    import "avc_residual_ac" avc_residual_ac
    sd residual_ac
    setcall residual_ac avc_residual_ac((value_get))
    import "avc_residual_luma" avc_residual_luma
    sd residual_luma_dc
    setcall residual_luma_dc avc_residual_luma()
    call avc_enc_16x16(Y,residual_ac,residual_luma_dc)
    #encode chroma
    import "avc_residual_ac_ch" avc_residual_ac_ch
    import "avc_residual_ac_u" avc_residual_ac_u
    import "avc_residual_ac_v" avc_residual_ac_v
    sd residual_ac_ch
    sd residual_ac_u
    sd residual_ac_v
    setcall residual_ac_ch avc_residual_ac_ch()
    setcall residual_ac_u avc_residual_ac_u()
    setcall residual_ac_v avc_residual_ac_v()
    import "avc_chroma_dc_u" avc_chroma_dc_u
    import "avc_chroma_dc_v" avc_chroma_dc_v
    sd chroma_dc_u
    sd chroma_dc_v
    setcall chroma_dc_u avc_chroma_dc_u()
    setcall chroma_dc_v avc_chroma_dc_v()
    call avc_enc_8x8_chroma(U,V,residual_ac_u,residual_ac_v,chroma_dc_u,chroma_dc_v)
    #
    import "avc_scan8" avc_scan8
    sd i
    sd value
    #calculate luma
    import "avc_mb_non_zero" avc_mb_non_zero
    set i 0
    sd nz
    sd cbp_luma=0
    while i!=16
        setcall nz avc_array_non_zero_count(residual_ac,15)
        if nz>0
            set cbp_luma 0x0f
        endif
        setcall value avc_scan8(i)
        call avc_mb_non_zero((value_set),value,nz)
        add residual_ac (15*DWORD)
        inc i
    endwhile
    import "avc_cbp_luma" avc_cbp_luma
    call avc_cbp_luma((value_set),cbp_luma)
    #calculate chroma
    sd cbp_chroma=0
    set i 0
    while i!=8
        setcall nz avc_array_non_zero_count(residual_ac_ch,15)
        if nz>0
            set cbp_chroma 0x02
        endif
        set value i
        add value 16
        setcall value avc_scan8(value)
        call avc_mb_non_zero((value_set),value,nz)
        add residual_ac_ch (15*DWORD)
        inc i
    endwhile
    if cbp_chroma==0
        setcall value avc_array_non_zero_count(chroma_dc_u,4)
        addcall value avc_array_non_zero_count(chroma_dc_v,4)
        if value>0
            set cbp_chroma 1
        endif
    endif
    import "avc_cbp_chroma" avc_cbp_chroma
    call avc_cbp_chroma((value_set),cbp_chroma)
        #for cbp
    sd cbp_dc
    setcall value avc_array_non_zero_count(residual_luma_dc,16)
    if value>0
        set cbp_dc 0x01
    else
        set cbp_dc 0x00
    endelse
    setcall value avc_array_non_zero_count(chroma_dc_u,4)
    if value>0
        or cbp_dc 0x02
    endif
    setcall value avc_array_non_zero_count(chroma_dc_v,4)
    if value>0
        or cbp_dc 0x04
    endif
    #store cbp
    import "avc_mb_data" avc_mb_data
    import "shl" shl
    sd cbp
    set cbp cbp_luma
    orcall cbp shl(cbp_chroma,4)
    orcall cbp shl(cbp_dc,8)
    call avc_mb_data((value_write),(avc_mb_cbp_offset),x,y,cbp)
endfunction

import "avc_width" avc_width

function avc_enc_16x16(sd Y,sd residual_ac,sd residual_luma)
    chars dct_data#16*4*4*WORD
    data d_dct^dct_data
    chars dct_luma_data#4*4*WORD
    data d_dct_luma^dct_luma_data
    sd stride
    setcall stride avc_width((value_get))

    #ac
    call avc_enc_block(Y,residual_ac,d_dct,8,d_dct_luma,16,stride)
    #dc
    call avc_dct4x4dc(d_dct_luma)
    call avc_quant(d_dct_luma,4,(TRUE))
    call avc_scan_zigzag_4x4full(d_dct_luma,residual_luma)
    #
    call avc_idct_dc(d_dct_luma)
    call avc_dequant_dc(d_dct_luma)
    call avc_dc_coeff_inv(d_dct_luma,d_dct,16,4)

    sd dct_ix
    sd p_dct^dct_ix
    set dct_ix d_dct
    sd index=0
    sd p_index^index
    sd Y_deq
    setcall Y_deq avc_input_dequant_move(Y)
    call avc_dct_add(p_dct,Y_deq,8,stride,p_index)
endfunction

function avc_enc_block(sd plane,sd residual,sd dct,sd coef,sd dct_lum_ch,sd mb_count,sd stride)
    #coef: rounding down to pieces at sub
    #      =2*arraysize for avc_dc_coeff; [0][0]
    #      =block_size/2
    sd block_size
    set block_size coef
    mult block_size 2
    sd dct_ix
    sd p_dct^dct_ix
    set dct_ix dct
    call avc_dct_pred((value_set),plane,stride,block_size)
    call avc_dct_sub(p_dct,plane,coef,stride)

    sd array_size
    set array_size coef
    div array_size 2
    sd i=0
    while i!=mb_count
        call avc_dc_coeff(dct_lum_ch,dct,i,array_size)
        call avc_quant(dct,4,(FALSE))
        call avc_scan_zigzag_4x4(dct,residual)
        call avc_dequant(dct)
        add residual (15*DWORD)
        add dct (4*4*WORD)
        inc i
    endwhile
endfunction

import "avc_dct_sub_pred_index" avc_dct_sub_pred_index

function avc_dct_sub(sd p_dct,ss plane,sd coef,sd stride)
    if coef!=2
        call avc_dct_sub_row(p_dct,plane,coef,stride)
        sd second_part
        set second_part stride
        mult second_part coef
        add plane second_part
        call avc_dct_sub_row(p_dct,plane,coef,stride)
    else
        sd value
        chars d_data#4*4*WORD
        chars tmp_data#4*4*WORD
        data d^d_data
        data tmp^tmp_data
        import "sar32" sar
        ss dif
        set dif d
        sd y=0
        sd tempPlane
        set tempPlane plane
        while y!=4
            sd x=0
            while x!=4
                set value plane#
                subcall value avc_dct_pred((value_get))
                set dif# value
                setcall value sar(value,8)
                inc dif
                set dif# value
                inc dif
                inc plane
                inc x
            endwhile
            add tempPlane stride
            set plane tempPlane
            inc y
        endwhile

        sd pos
        sd i=0
        import "array_get_int16" array_get_int16
        import "array_set_word_bi" array_set_word_bi
        import "array_bi_index" array_bi_index
        while i!=4
            sd s03
            sd s12
            sd d03
            sd d12

            setcall pos array_bi_index(i,4,0)
            setcall s03 array_get_int16(d,pos)
            setcall pos array_bi_index(i,4,3)
            addcall s03 array_get_int16(d,pos)

            setcall pos array_bi_index(i,4,1)
            setcall s12 array_get_int16(d,pos)
            setcall pos array_bi_index(i,4,2)
            addcall s12 array_get_int16(d,pos)

            setcall pos array_bi_index(i,4,0)
            setcall d03 array_get_int16(d,pos)
            setcall pos array_bi_index(i,4,3)
            subcall d03 array_get_int16(d,pos)

            setcall pos array_bi_index(i,4,1)
            setcall d12 array_get_int16(d,pos)
            setcall pos array_bi_index(i,4,2)
            subcall d12 array_get_int16(d,pos)

            set value s03
            add value s12
            call array_set_word_bi(tmp,0,4,i,value)

            set value d03
            mult value 2
            add value d12
            call array_set_word_bi(tmp,1,4,i,value)

            set value s03
            sub value s12
            call array_set_word_bi(tmp,2,4,i,value)

            set value d12
            mult value -2
            add value d03
            call array_set_word_bi(tmp,3,4,i,value)

            inc i
        endwhile
        import "array_get_int16_bi" array_get_int16_bi
        sd dct
        set dct p_dct#
        set i 0
        while i!=4
            setcall s03 array_get_int16_bi(tmp,i,4,0)
            addcall s03 array_get_int16_bi(tmp,i,4,3)
            setcall s12 array_get_int16_bi(tmp,i,4,1)
            addcall s12 array_get_int16_bi(tmp,i,4,2)
            setcall d03 array_get_int16_bi(tmp,i,4,0)
            subcall d03 array_get_int16_bi(tmp,i,4,3)
            setcall d12 array_get_int16_bi(tmp,i,4,1)
            subcall d12 array_get_int16_bi(tmp,i,4,2)

            set value s03
            add value s12
            call array_set_word_bi(dct,0,4,i,value)
            set value d03
            mult value 2
            add value d12
            call array_set_word_bi(dct,1,4,i,value)
            set value s03
            sub value s12
            call array_set_word_bi(dct,2,4,i,value)
            set value d12
            mult value -2
            add value d03
            call array_set_word_bi(dct,3,4,i,value)

            inc i
        endwhile
        add p_dct# (4*4*WORD)
    endelse
    setcall value avc_dct_sub_pred_index((value_get))
    #using just: 0,1,2,3
    if value<3
        inc value
        call avc_dct_sub_pred_index((value_set),value)
    endif
endfunction
function avc_dct_sub_row(sd p_dct,sd plane,sd coef,sd stride)
    sd ix
    set ix coef
    div coef 2
    call avc_dct_sub(p_dct,plane,coef,stride)
    add plane ix
    call avc_dct_sub(p_dct,plane,coef,stride)
endfunction

import "avc_input" avc_input
import "avc_input_dequant" avc_input_dequant

function avc_dct_pred(sd way,sd plane,sd stride,sd count)
    import "array_get_byte" array_get_byte
    sd value
    data pred_data#4
    data preds_init^pred_data
    sd preds
    set preds preds_init
    if way==(value_set)
        call avc_dct_sub_pred_index((value_set),0)
        import "avc_mb_nr_left" avc_mb_nr_left
        import "avc_mb_nr_top" avc_mb_nr_top
        sd left_nr
        sd top_nr
        setcall left_nr avc_mb_nr_left((value_get))
        setcall top_nr avc_mb_nr_top((value_get))
        sd n
        #for quant/dequant on mem imput
            #change to input dequant
        setcall plane avc_input_dequant_move(plane)
        #
        #dc0    dc1
        #dc2    dc3
        sd dc0=0
        sd dc1=0
        sd dc2
        sd dc3
        #first
        if left_nr==0
            if top_nr==0
                set dc0 0x80
                set dc1 0x80
                set dc2 0x80
                set dc3 0x80
            endif
        endif
        if count==(luma_count)
        #luma
            #left
            if left_nr!=0
                set n 0
                while n!=16
                    set value n
                    mult value stride
                    dec value
                    addcall dc0 array_get_byte(plane,value)
                    inc n
                endwhile
                if top_nr==0
                #nothing at top, left done
                    add dc0 8
                    setcall dc0 sar(dc0,4)
                    set dc1 dc0
                    set dc2 dc0
                    set dc3 dc0
                endif
            endif
            #top, leftTop
            if top_nr!=0
                set n 0
                while n!=16
                    set value n
                    sub value stride
                    addcall dc1 array_get_byte(plane,value)
                    inc n
                endwhile
                if left_nr==0
                #nothing at left, top done
                    add dc1 8
                    setcall dc1 sar(dc1,4)
                    set dc0 dc1
                    set dc2 dc1
                    set dc3 dc1
                else
                #left top
                    add dc0 dc1
                    add dc0 16
                    setcall dc0 sar(dc0,5)
                    set dc1 dc0
                    set dc2 dc0
                    set dc3 dc0
                endelse
            endif
        else
        #chroma
        #   s0    s1
        #s2
        #s3
            sd s0=0
            sd s1=0
            sd s2=0
            sd s3=0
            #left
            if left_nr!=0
                set n 0
                while n!=4
                    set value n
                    mult value stride
                    dec value
                    addcall s2 array_get_byte(plane,value)
                    set value n
                    add value 4
                    mult value stride
                    dec value
                    addcall s3 array_get_byte(plane,value)
                    inc n
                endwhile
                if top_nr==0
                #nothing at top, left done
                    set dc0 s2
                    add dc0 2
                    setcall dc0 sar(dc0,2)
                    set dc2 s3
                    add dc2 2
                    setcall dc2 sar(dc2,2)
                    set dc1 dc0
                    set dc3 dc2
                endif
            endif
            #top, leftTop
            if top_nr!=0
                set n 0
                while n!=4
                    set value n
                    sub value stride
                    addcall s0 array_get_byte(plane,value)
                    set value n
                    add value 4
                    sub value stride
                    addcall s1 array_get_byte(plane,value)
                    inc n
                endwhile
                if left_nr==0
                #nothing at left, top done
                    set dc0 s0
                    add dc0 2
                    setcall dc0 sar(dc0,2)
                    set dc1 s1
                    add dc1 2
                    setcall dc1 sar(dc1,2)
                    set dc2 dc0
                    set dc3 dc1
                else
                #left top
                    set dc0 s0
                    add dc0 s2
                    add dc0 4
                    setcall dc0 sar(dc0,3)
                    set dc1 s1
                    add dc1 2
                    setcall dc1 sar(dc1,2)
                    set dc2 s3
                    add dc2 2
                    setcall dc2 sar(dc2,2)
                    set dc3 s1
                    add dc3 s3
                    add dc3 4
                    setcall dc3 sar(dc3,3)
                endelse
            endif
        endelse

        set preds# dc0
        add preds (DWORD)
        set preds# dc1
        add preds (DWORD)
        set preds# dc2
        add preds (DWORD)
        set preds# dc3
        add preds (DWORD)
        #set for next macroblocks
        ss mem_deq_left
        set mem_deq_left plane
        add mem_deq_left count
        dec mem_deq_left
        ss mem_deq_top
        set mem_deq_top plane
        #from 1 to let at the last row
        set n 1
        while n!=count
            add mem_deq_top stride
            inc n
        endwhile
        #left is from top-right to bottom-right; top is from bottom-left to bottom-right
        set n 0
        sd m
        set m count
        div m 2
        while n!=m
            set mem_deq_left# dc1
            add mem_deq_left stride
            set mem_deq_top# dc2
            inc mem_deq_top
            inc n
        endwhile
        set n 0
        while n!=m
            set mem_deq_left# dc3
            add mem_deq_left stride
            set mem_deq_top# dc3
            inc mem_deq_top
            inc n
        endwhile
        #
    else
        #value
        setcall value avc_dct_sub_pred_index((value_get))
        mult value 4
        add preds value
        return preds#
    endelse
endfunction

function avc_input_dequant_move(sd plane)
    #input deq start
    ss mem_deq
    setcall mem_deq avc_input_dequant((value_get))
    #input start
    ss mem_in
    setcall mem_in avc_input((value_get))
    #from plane to dequant
    sd dif
    set dif plane
    sub dif mem_in
    add mem_deq dif
    return mem_deq
endfunction

function avc_quant_mf_set()
    #[4][4]
    data d_def_quant4#4*4
    data def_quant4^d_def_quant4
    #
    data d_def_dequant4#4*4
    data def_dequant4^d_def_dequant4

    sd def_quant
    sd def_dequant
    set def_quant def_quant4
    set def_dequant def_dequant4
    sd i=0
    sd value
    while i!=16
        sd j
        set j i
        and j 1
        setcall value sar(i,2)
        and value 1
        add j value
        setcall def_quant# avc_quant4_scale(j)
        setcall def_dequant# avc_dequant4_scale(j)
        add def_quant 4
        add def_dequant 4
        inc i
    endwhile
    set i 0
    set def_quant def_quant4
    set def_dequant def_dequant4
    sd quant_mf_set
    sd dequant_mf_set
    setcall quant_mf_set avc_quant_mf_array()
    setcall dequant_mf_set avc_dequant_mf_array()
    while i!=16
        set value def_quant#
        mult value 16
        div value 0x10
        set quant_mf_set# value

        set value def_dequant#
        mult value 0x10
        set dequant_mf_set# value

        add quant_mf_set 4
        add def_quant 4
        add dequant_mf_set 4
        add def_dequant 4
        inc i
    endwhile
endfunction

function avc_quant_mf_array()
    data d_quant_mf#4*4
    data d^d_quant_mf
    return d
endfunction

function avc_dequant_mf_array()
    data d_dequant_mf#4*4
    data d^d_dequant_mf
    return d
endfunction

function avc_quant4_scale(sd x)
    #[6][3]
    #        { 13107, 8066, 5243 },
    #    { 11916, 7490, 4660 },
    #    { 10082, 6554, 4194 },
    #    {  9362, 5825, 3647 },
    #    {  8192, 5243, 3355 },
    data q={7282, 4559, 2893}
    sd quant4_scale^q
    mult x 4
    add quant4_scale x
    return quant4_scale#
endfunction

function avc_dequant4_scale(sd x)
    #[6][3]
    #{ 10, 13, 16 },
    #{ 11, 14, 18 },
    #{ 13, 16, 20 },
    #{ 14, 18, 23 },
    #{ 16, 20, 25 },
    data dequant={18, 23, 29}
    sd deq^dequant
    mult x 4
    add deq x
    return deq#
endfunction

import "short_get_to_int" short_get_to_int

function avc_quant(sd dct,sd upper_limit,sd dc_bool)
    import "avc_qp_I" avc_qp_I
    sd qbits
    sd qscale
    setcall qscale avc_qp_I()
    set qbits qscale
    div qbits 6
    add qbits 15
    sd f
    sd i_qmf
    sd quant_mf
    sd shift_value
    setcall quant_mf avc_quant_mf_array()
    if dc_bool==0
        setcall f shl(1,qbits)
        set shift_value qbits
    else
        setcall f shl(2,qbits)
        set i_qmf quant_mf#
        set shift_value qbits
        inc shift_value
    endelse
    #/ b_intra ? 3 : 6
    div f 3

    sd x
    sd y=0
    while y!=upper_limit
        set x 0
        while x!=upper_limit
            sd value
            setcall value short_get_to_int(dct)
            if value>0
                if dc_bool==0
                    mult value quant_mf#
                else
                    mult value i_qmf
                endelse
                add value f
                setcall value sar(value,shift_value)
            else
                if dc_bool==0
                    mult value quant_mf#
                else
                    mult value i_qmf
                endelse
                mult value -1
                add value f
                setcall value sar(value,shift_value)
                mult value -1
            endelse
            import "int_into_short" int_into_short
            call int_into_short(value,dct)
            add quant_mf 4
            add dct 2
            inc x
        endwhile
        inc y
    endwhile
endfunction


function avc_scan_zigzag_4x4(sd dct,sd residual_ac)
    call avc_zig(residual_ac,0,dct,0,1)
    call avc_zig(residual_ac,1,dct,1,0)
    call avc_zig(residual_ac,2,dct,2,0)
    call avc_zig(residual_ac,3,dct,1,1)
    call avc_zig(residual_ac,4,dct,0,2)
    call avc_zig(residual_ac,5,dct,0,3)
    call avc_zig(residual_ac,6,dct,1,2)
    call avc_zig(residual_ac,7,dct,2,1)
    call avc_zig(residual_ac,8,dct,3,0)
    call avc_zig(residual_ac,9,dct,3,1)
    call avc_zig(residual_ac,10,dct,2,2)
    call avc_zig(residual_ac,11,dct,1,3)
    call avc_zig(residual_ac,12,dct,2,3)
    call avc_zig(residual_ac,13,dct,3,2)
    call avc_zig(residual_ac,14,dct,3,3)
endfunction
function avc_scan_zigzag_2x2_dc(sd dct,sd residual)
    call avc_zig2x2(residual,0,dct,0,0)
    call avc_zig2x2(residual,1,dct,0,1)
    call avc_zig2x2(residual,2,dct,1,0)
    call avc_zig2x2(residual,3,dct,1,1)
endfunction
function avc_scan_zigzag_4x4full(sd dct,sd residual)
    call avc_zig(residual,0,dct,0,0)
    call avc_zig(residual,1,dct,0,1)
    call avc_zig(residual,2,dct,1,0)
    call avc_zig(residual,3,dct,2,0)
    call avc_zig(residual,4,dct,1,1)
    call avc_zig(residual,5,dct,0,2)
    call avc_zig(residual,6,dct,0,3)
    call avc_zig(residual,7,dct,1,2)
    call avc_zig(residual,8,dct,2,1)
    call avc_zig(residual,9,dct,3,0)
    call avc_zig(residual,10,dct,3,1)
    call avc_zig(residual,11,dct,2,2)
    call avc_zig(residual,12,dct,1,3)
    call avc_zig(residual,13,dct,2,3)
    call avc_zig(residual,14,dct,3,2)
    call avc_zig(residual,15,dct,3,3)
endfunction

function avc_zig(sd residual,sd i,sd dct,sd y,sd x)
    mult i (DWORD)
    add residual i
    mult y (4*WORD)
    add dct y
    mult x (WORD)
    add dct x
    setcall residual# short_get_to_int(dct)
endfunction
function avc_zig2x2(sd residual,sd i,sd dct,sd y,sd x)
    mult i (DWORD)
    add residual i
    mult y (2*WORD)
    add dct y
    mult x (WORD)
    add dct x
    setcall residual# short_get_to_int(dct)
endfunction

function avc_array_non_zero_count(sd array,sd count)
    sd i=0
    sd nz=0
    while i<count
        if array#!=0
            inc nz
        endif
        add array (DWORD)
        inc i
    endwhile
    return nz
endfunction


##chroma

function avc_enc_8x8_chroma(sd U,sd V,sd residual_ac_u,sd residual_ac_v,sd chroma_dc_u,sd chroma_dc_v)
    #U
    call avc_enc_chroma_block(U,residual_ac_u,chroma_dc_u)
    #V
    call avc_enc_chroma_block(V,residual_ac_v,chroma_dc_v)
endfunction
function avc_enc_chroma_block(sd plane,sd residual_ac,sd residual_dc)
    chars dct_data#4*4*4*WORD
    data d_dct^dct_data
    chars dct2x2_data#2*2*WORD
    data dct2x2^dct2x2_data
    sd stride
    setcall stride avc_width((value_get))
    div stride 2
    #ac
    call avc_enc_block(plane,residual_ac,d_dct,4,dct2x2,4,stride)
    #dc
    call avc_dct2x2dc(dct2x2)
    call avc_quant(dct2x2,2,(TRUE))
    call avc_scan_zigzag_2x2_dc(dct2x2,residual_dc)
    #
    call avc_idct_dc_2x2(dct2x2)
    call avc_dequant_dc_2x2(dct2x2)
    call avc_dc_coeff_inv(dct2x2,d_dct,4,2)

    sd dct_ix
    sd p_dct^dct_ix
    set dct_ix d_dct
    sd index=16
    sd p_index^index
    sd plane_deq
    setcall plane_deq avc_input_dequant_move(plane)
    call avc_dct_add(p_dct,plane_deq,4,stride,p_index)
endfunction

function avc_dc_coeff(sd dct_chroma,ss dct,sd i,sd array_size)
    sd x
    sd y
    setcall x avc_block_idx_x(i)
    setcall y avc_block_idx_y(i)
    sd value
    setcall value short_get_to_int(dct)
    call array_set_word_bi(dct_chroma,y,array_size,x,value)
endfunction


function avc_dct2x2dc(sd dct)
    sd a00
    sd a10
    sd a01
    sd a11

    setcall a00 array_get_int16_bi(dct,0,2,0)
    addcall a00 array_get_int16_bi(dct,0,2,1)
    setcall a10 array_get_int16_bi(dct,0,2,0)
    subcall a10 array_get_int16_bi(dct,0,2,1)
    setcall a01 array_get_int16_bi(dct,1,2,0)
    addcall a01 array_get_int16_bi(dct,1,2,1)
    setcall a11 array_get_int16_bi(dct,1,2,0)
    subcall a11 array_get_int16_bi(dct,1,2,1)

    sd value
    set value a00
    add value a01
    call array_set_word_bi(dct,0,2,0,value)
    set value a10
    add value a11
    call array_set_word_bi(dct,0,2,1,value)
    set value a00
    sub value a01
    call array_set_word_bi(dct,1,2,0,value)
    set value a10
    sub value a11
    call array_set_word_bi(dct,1,2,1,value)
endfunction
function avc_dct4x4dc(sd dct)
    chars tmp_data#4*4*WORD
    data tmp^tmp_data
    sd s01
    sd s23
    sd d01
    sd d23
    sd value
    sd i=0
    while i!=4
        setcall s01 array_get_int16_bi(dct,i,4,0)
        addcall s01 array_get_int16_bi(dct,i,4,1)
        setcall d01 array_get_int16_bi(dct,i,4,0)
        subcall d01 array_get_int16_bi(dct,i,4,1)
        setcall s23 array_get_int16_bi(dct,i,4,2)
        addcall s23 array_get_int16_bi(dct,i,4,3)
        setcall d23 array_get_int16_bi(dct,i,4,2)
        subcall d23 array_get_int16_bi(dct,i,4,3)

        set value s01
        add value s23
        call array_set_word_bi(tmp,0,4,i,value)
        set value s01
        sub value s23
        call array_set_word_bi(tmp,1,4,i,value)
        set value d01
        sub value d23
        call array_set_word_bi(tmp,2,4,i,value)
        set value d01
        add value d23
        call array_set_word_bi(tmp,3,4,i,value)

        inc i
    endwhile
    set i 0
    while i!=4
        setcall s01 array_get_int16_bi(tmp,i,4,0)
        addcall s01 array_get_int16_bi(tmp,i,4,1)
        setcall d01 array_get_int16_bi(tmp,i,4,0)
        subcall d01 array_get_int16_bi(tmp,i,4,1)
        setcall s23 array_get_int16_bi(tmp,i,4,2)
        addcall s23 array_get_int16_bi(tmp,i,4,3)
        setcall d23 array_get_int16_bi(tmp,i,4,2)
        subcall d23 array_get_int16_bi(tmp,i,4,3)

        set value s01
        add value s23
        inc value
        setcall value sar(value,1)
        call array_set_word_bi(dct,0,4,i,value)
        set value s01
        sub value s23
        inc value
        setcall value sar(value,1)
        call array_set_word_bi(dct,1,4,i,value)
        set value d01
        sub value d23
        inc value
        setcall value sar(value,1)
        call array_set_word_bi(dct,2,4,i,value)
        set value d01
        add value d23
        inc value
        setcall value sar(value,1)
        call array_set_word_bi(dct,3,4,i,value)

        inc i
    endwhile
endfunction



function avc_block_idx_x(sd x)
    data idx_x={0, 1, 0, 1, 2, 3, 2, 3, 0, 1, 0, 1, 2, 3, 2, 3}
    sd idx^idx_x
    mult x 4
    add idx x
    return idx#
endfunction
function avc_block_idx_y(sd y)
    data idx_y={0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 3, 3, 2, 2, 3, 3}
    sd idx^idx_y
    mult y 4
    add idx y
    return idx#
endfunction
function avc_block_idx_xy(sd x,sd y)
    #idx[x][y]
    data idx_xy={0, 2, 8,  10}
    data *     ={1, 3, 9,  11}
    data *     ={4, 6, 12, 14}
    data *     ={5, 7, 13, 15}
    sd index^idx_xy
    mult x (4*DWORD)
    add index x
    mult y (DWORD)
    add index y
    return index#
endfunction



#dequant

function avc_dequant(sd dct)
    #const int i_mf = i_qscale%6;

    sd qbits
    setcall qbits avc_qp_I()
    div qbits 6
    sub qbits 4

    #qbits is negative, need positive
    mult qbits -1
    sd f
    set f qbits
    dec f
    setcall f shl(1,f)

    sd dequant_mf
    setcall dequant_mf avc_dequant_mf_array()
    sd value
    sd n=0
    while n!=4
        sd m=0
        while m!=4
            setcall value short_get_to_int(dct)
            mult value dequant_mf#
            add value f
            setcall value sar(value,qbits)
            call int_into_short(value,dct)

            add dct (WORD)
            add dequant_mf (DWORD)
            inc m
        endwhile
        inc n
    endwhile
endfunction

function avc_idct_dc(sd dct)
    chars tmp_data#4*4*WORD
    data tmp^tmp_data
    sd s01
    sd s23
    sd d01
    sd d23
    sd i
    sd value

    set i 0
    while i!=4
        setcall s01 array_get_int16_bi(dct,0,4,i)
        addcall s01 array_get_int16_bi(dct,1,4,i)
        setcall d01 array_get_int16_bi(dct,0,4,i)
        subcall d01 array_get_int16_bi(dct,1,4,i)
        setcall s23 array_get_int16_bi(dct,2,4,i)
        addcall s23 array_get_int16_bi(dct,3,4,i)
        setcall d23 array_get_int16_bi(dct,2,4,i)
        subcall d23 array_get_int16_bi(dct,3,4,i)
        set value s01
        add value s23
        call array_set_word_bi(tmp,0,4,i,value)
        set value s01
        sub value s23
        call array_set_word_bi(tmp,1,4,i,value)
        set value d01
        sub value d23
        call array_set_word_bi(tmp,2,4,i,value)
        set value d01
        add value d23
        call array_set_word_bi(tmp,3,4,i,value)
        inc i
    endwhile
    set i 0
    while i!=4
        setcall value array_get_int16_bi(tmp,i,4,0)
        setcall d01 array_get_int16_bi(tmp,i,4,1)
        set s01 value
        add s01 d01
        mult d01 -1
        add d01 value
        setcall value array_get_int16_bi(tmp,i,4,2)
        setcall d23 array_get_int16_bi(tmp,i,4,3)
        set s23 value
        add s23 d23
        mult d23 -1
        add d23 value
        #
        set value s01
        add value s23
        call int_into_short(value,dct)
        add dct (WORD)
        sub s01 s23
        call int_into_short(s01,dct)
        add dct (WORD)
        set value d01
        sub value d23
        call int_into_short(value,dct)
        add dct (WORD)
        add d01 d23
        call int_into_short(d01,dct)
        add dct (WORD)
        inc i
    endwhile
endfunction

function avc_dequant_dc(sd dct)
    sd qbits
    setcall qbits avc_qp_I()
    div qbits 6
    sub qbits 6
    sd dequant_mf
    sd dmf
    sd f
    setcall dequant_mf avc_dequant_mf_array()
    set dmf dequant_mf#
    mult qbits -1
    set f qbits
    dec f
    setcall f shl(1,f)
    sd value
    sd i=0
    while i!=4
        sd j=0
        while j!=4
            setcall value short_get_to_int(dct)
            mult value dmf
            add value f
            setcall value sar(value,qbits)
            call int_into_short(value,dct)
            add dct (WORD)
            inc j
        endwhile
        inc i
    endwhile
endfunction

function avc_dc_coeff_inv(sd dct_lum_ch,sd dct,sd count,sd size)
    sd i=0
    sd y
    sd x
    sd value
    while i!=count
        setcall y avc_block_idx_y(i)
        setcall x avc_block_idx_x(i)
        setcall value array_get_int16_bi(dct_lum_ch,y,size,x)
        call int_into_short(value,dct)
        add dct (4*4*WORD)
        inc i
    endwhile
endfunction

function avc_dct_add(sd p_dct,ss plane,sd coef,sd stride,sd p_index)
    if coef!=2
        call avc_dct_add_row(p_dct,plane,coef,stride,p_index)
        sd second_part
        set second_part stride
        mult second_part coef
        add plane second_part
        call avc_dct_add_row(p_dct,plane,coef,stride,p_index)
    else
        sd index
        set index p_index#
        data numbers_data={0,1,2,3, 4,-1,6,-1, 8,9,-2,-2, 12,-1,-2,-3,0,-1,-2,-3}
        #0  1  4  L   0 L
        #2  3  5  L   T C
        #6  7  10 L
        #T  T  T  C
        sd numbers^numbers_data
        mult index (DWORD)
        add numbers index
        sd nr
        set nr numbers#
        if nr<0
            chars d_data#4*4*WORD
            data d^d_data
            chars tmp_data#4*4*WORD
            data tmp^tmp_data
            sd cursor
            sd s02
            sd d02
            sd s13
            sd d13
            sd value
            sd dct
            set dct p_dct#
            set cursor tmp
            sd i=0
            while i!=4
                setcall s02 array_get_int16_bi(dct,i,4,0)
                setcall value array_get_int16_bi(dct,i,4,2)
                set d02 value
                mult d02 -1
                add d02 s02
                add s02 value
                setcall s13 array_get_int16_bi(dct,i,4,1)
                setcall value array_get_int16_bi(dct,i,4,3)
                set d13 value
                mult d13 -1
                addcall d13 sar(s13,1)
                addcall s13 sar(value,1)

                set value s02
                add value s13
                call int_into_short(value,cursor)
                add cursor (WORD)
                set value d02
                add value d13
                call int_into_short(value,cursor)
                add cursor (WORD)
                set value d02
                sub value d13
                call int_into_short(value,cursor)
                add cursor (WORD)
                set value s02
                sub value s13
                call int_into_short(value,cursor)
                add cursor (WORD)
                inc i
            endwhile
            set i 0
            while i!=4
                setcall s02 array_get_int16_bi(tmp,0,4,i)
                setcall value array_get_int16_bi(tmp,2,4,i)
                set d02 value
                mult d02 -1
                add d02 s02
                add s02 value
                setcall s13 array_get_int16_bi(tmp,1,4,i)
                setcall value array_get_int16_bi(tmp,3,4,i)
                set d13 value
                mult d13 -1
                addcall d13 sar(s13,1)
                addcall s13 sar(value,1)

                set value s02
                add value s13
                add value 32
                setcall value sar(value,6)
                call array_set_word_bi(d,0,4,i,value)
                set value d02
                add value d13
                add value 32
                setcall value sar(value,6)
                call array_set_word_bi(d,1,4,i,value)
                set value d02
                sub value d13
                add value 32
                setcall value sar(value,6)
                call array_set_word_bi(d,2,4,i,value)
                set value s02
                sub value s13
                add value 32
                setcall value sar(value,6)
                call array_set_word_bi(d,3,4,i,value)
                inc i
            endwhile
            ss block
            if nr!=-2
            #resolve left; top bottom
                set block plane
                add block 3
                set i 0
                while i!=3
                    set value block#
                    addcall value array_get_int16_bi(d,i,4,3)
                    setcall block# avc_clip_uint8(value)
                    add block stride
                    inc i
                endwhile
            endif
            if nr<-1
            #resolve top; left right
                set block plane
                set i 0
                while i!=3
                    add block stride
                    inc i
                endwhile
                set i 0
                while i!=3
                    set value block#
                    addcall value array_get_int16_bi(d,3,4,i)
                    setcall block# avc_clip_uint8(value)
                    inc block
                    inc i
                endwhile
            endif
            #set last value once
            set value block#
            addcall value array_get_int16_bi(d,3,4,3)
            setcall block# avc_clip_uint8(value)
        endif
        inc p_index#
        add p_dct# (4*4*WORD)
    endelse
endfunction
function avc_dct_add_row(sd p_dct,sd plane,sd coef,sd stride,sd p_index)
    sd ix
    set ix coef
    div coef 2
    call avc_dct_add(p_dct,plane,coef,stride,p_index)
    add plane ix
    call avc_dct_add(p_dct,plane,coef,stride,p_index)
endfunction


function avc_clip_uint8(sd a)
    sd value
    set value a
    and value 0xffFFff00
    if value!=0
        mult a -1
        setcall a sar(a,31)
        return a
    endif
    return a
endfunction

#

function avc_idct_dc_2x2(sd dct)
    sd t00
    sd t10
    sd t01
    sd t11
    sd value

    setcall t00 short_get_to_int(dct)
    add dct (WORD)
    setcall value short_get_to_int(dct)
    add dct (WORD)
    set t10 value
    mult t10 -1
    add t10 t00
    add t00 value
    setcall t01 short_get_to_int(dct)
    add dct (WORD)
    setcall value short_get_to_int(dct)
    set t11 value
    mult t11 -1
    add t11 t01
    add t01 value

    set value t10
    sub value t11
    call int_into_short(value,dct)
    sub dct (WORD)
    set value t00
    sub value t01
    call int_into_short(value,dct)
    sub dct (WORD)
    set value t10
    add value t11
    call int_into_short(value,dct)
    sub dct (WORD)
    set value t00
    add value t01
    call int_into_short(value,dct)
endfunction

function avc_dequant_dc_2x2(sd dct)
    sd qbits
    setcall qbits avc_qp_I()
    div qbits 6
    sub qbits 5

    sd dequant_mf
    sd dmf

    setcall dequant_mf avc_dequant_mf_array()
    set dmf dequant_mf#

    #qbits is negative
    mult qbits -1

    sd value
    sd i=0
    while i!=4
        setcall value short_get_to_int(dct)
        mult value dmf
        setcall value sar(value,qbits)
        call int_into_short(value,dct)
        add dct (WORD)
        inc i
    endwhile
endfunction


