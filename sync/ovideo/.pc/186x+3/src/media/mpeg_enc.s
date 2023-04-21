
format elfobj

include "../_include/include.h"

#bool
function mpeg_frame_block(sd max_y,sd max_x,sd type)
    chars dct_codes#6*64*int16
    chars qcoeff#6*64*int16

    data p_dct_codes^dct_codes
    data p_qcoeff^qcoeff

    data acpred_direction_data#6
    data acpred_direction^acpred_direction_data

    sd bool
    import "mpeg_mem_bit" mpeg_mem_bit

    sd y=0
    while y!=max_y
        sd x=0
        while x!=max_x
            sd mode=INTRA
            if type==(P_VOP)
                import "mpeg_compare_block" mpeg_compare_block
                setcall mode mpeg_compare_block(x,y)
            endif
            import "macro_blocks_mode" macro_blocks_mode
            sd mbpos
            set mbpos y
            mult mbpos max_x
            add mbpos x
            call macro_blocks_mode((value_set),mbpos,mode)
            if mode==(INTRA)
                call mpeg_mb_trans_quant(x,y,p_dct_codes,p_qcoeff)

                import "mpeg_mb_prediction" mpeg_mb_prediction
                sd cbp
                setcall cbp mpeg_mb_prediction(x,y,max_x,p_qcoeff,acpred_direction)

                import "mpeg_mb_code" mpeg_mb_code
                setcall bool mpeg_mb_code(cbp,acpred_direction,p_qcoeff,type)
                if bool!=1
                    return 0
                endif
            else
                #skip
                setcall bool mpeg_mem_bit(1)
                if bool!=1
                    return 0
                endif
            endelse

            inc x
        endwhile
        inc y
    endwhile

    import "mpeg_mem_pad" mpeg_mem_pad
    setcall bool mpeg_mem_pad((always))
    if bool!=1
        return 0
    endif

    return 1
endfunction

function mpeg_mb_trans_quant(sd x,sd y,sd p_dct_codes,sd p_qcoeff)
    #Transfer data 8 to 16
    data t8to16^mb_trans_8to16
    call mpeg_mb_trans(x,y,p_dct_codes,t8to16)
    #DCT and field decision
    call mpeg_mb_dct(p_dct_codes)
    #Quantize the block
    call mpeg_mb_quant(p_dct_codes,p_qcoeff)
    #DeQuantize the block
    #call mpeg_mb_dequant(p_dct_codes,p_qcoeff)
    #Inverse DCT
    #call mpeg_mb_inv_dct(p_dct_codes)
    #Transfer data 16 to 8
    #data t16to8^mb_trans_16to8
    #call mpeg_mb_trans(x,y,p_dct_codes,t16to8)
endfunction

import "mpeg_input_y" mpeg_input_y
import "mpeg_input_u" mpeg_input_u
import "mpeg_input_v" mpeg_input_v
import "mpeg_input_lumstride" mpeg_input_lumstride
import "mpeg_input_cromstride" mpeg_input_cromstride

#########trans 8 to 16 for dct
function mpeg_mb_trans(sd x,sd y,sd p_dct_codes,sd function)
    sd Y
    sd U
    sd V
    setcall Y mpeg_input_y((value_get))
    setcall U mpeg_input_u((value_get))
    setcall V mpeg_input_v((value_get))
    sd lumstride
    setcall lumstride mpeg_input_lumstride((value_get))
    sd cromstride
    setcall cromstride mpeg_input_cromstride((value_get))

    #get plane,plane+8,plane+stride,plane+stride+8
    sd i
    sd ptr_dct_codes^p_dct_codes
    sd cursor
    set cursor y
    mult cursor 16
    mult cursor lumstride
    set i x
    mult i 16
    add cursor i
    add cursor Y
    call function(cursor,ptr_dct_codes,lumstride)

    add cursor 8
    call function(cursor,ptr_dct_codes,lumstride)

    sub cursor 8
    sd lum_add
    set lum_add lumstride
    mult lum_add 8
    add cursor lum_add
    call function(cursor,ptr_dct_codes,lumstride)

    add cursor 8
    call function(cursor,ptr_dct_codes,lumstride)

    set cursor y
    mult cursor 8
    mult cursor cromstride
    set i x
    mult i 8
    add cursor i
    add U cursor
    call function(U,ptr_dct_codes,cromstride)

    add V cursor
    call function(V,ptr_dct_codes,cromstride)
endfunction
function mb_trans_8to16(ss src,sd p_dest,sd stride)
    ss dest
    set dest p_dest#

    ss sign
    set sign src
    sd j=0
    while j!=8
        set src sign
        sd i=0
        while i!=8
            set dest# src#
            inc src

            inc dest
            set dest# 0
            inc dest

            inc i
        endwhile
        add sign stride
        inc j
    endwhile

    set p_dest# dest
endfunction

const FIX=16
const FPASS=2

const ROT6_C=35468
const ROT6_SmC=50159
const ROT6_SpC=121095

const ROT17_C=77062
const ROT17_SpC=128553
const ROT17_SmC=25571

const ROT37_C=58981
const ROT37_SmC=98391
const ROT37_SpC=19571

const ROT13_C=167963
const ROT13_SmC=134553
const ROT13_SpC=201373

const pow_a=FIX-FPASS-1
const pow_b=FIX+FPASS+3-1
const pow_c=FPASS+3-1

############dct
function mpeg_mb_dct(sd dct_codes)
    sd i=0
    while i!=6
        call mpeg_mb_dct_block(dct_codes)
        add dct_codes (64*int16)
        inc i
    endwhile
endfunction

function mpeg_mb_dct_block(sd dct_codes)
#perform dct on a 8x8 block
    sd m0
    sd m1
    sd m2
    sd m3
    sd m4
    sd m5
    sd m6
    sd m7
    sd p_m1^m1
    sd p_m2^m2
    sd p_m3^m3
    sd p_m4^m4
    sd p_m5^m5
    sd p_m6^m6
    sd p_m7^m7

    import "array_set_word_off" array_set_word_off
    import "shl" shl
    import "sar32" sar
    sd i=8
    sd dct_cursor
    set dct_cursor dct_codes
    while i>0
    #even
        #m1 m6
        setcall m1 dct_op(p_m6,1,6,dct_cursor)
        #m2 m5
        setcall m2 dct_op(p_m5,2,5,dct_cursor)
        #m3 m4
        setcall m3 dct_op(p_m4,3,4,dct_cursor)
        #m0 m7
        setcall m0 dct_op(p_m7,0,7,dct_cursor)

        #m1 m2
        setcall m1 dct_calc(m1,p_m2)
        #m0 m3
        setcall m0 dct_calc(m0,p_m3)

        #m3 m2 rotate
        setcall m3 dct_rotate(m3,p_m2,(ROT6_C),(ROT6_SmC),(-1*ROT6_SpC),(FIX-FPASS),(2$pow_a))
        #m2
        call array_set_word_off(dct_cursor,m3,2)
        #m3
        call array_set_word_off(dct_cursor,m2,6)

        #m0 m1
        setcall m0 dct_calc(m0,p_m1)
        #m0
        setcall m0 shl(m0,(FPASS))
        call array_set_word_off(dct_cursor,m0,0)
        #m1
        setcall m1 shl(m1,(FPASS))
        call array_set_word_off(dct_cursor,m1,4)
    #odd
        #m3
        set m3 m5
        add m3 m7
        #m2
        set m2 m4
        add m2 m6
        #m2 m3 rotate
        setcall m2 dct_rotate(m2,p_m3,(ROT17_C),(-1*ROT17_SpC),(-1*ROT17_SmC),(FIX-FPASS),(2$pow_a))
        #m4 m7
        setcall m4 dct_rotate(m4,p_m7,(-1*ROT37_C),(ROT37_SpC),(ROT37_SmC),(FIX-FPASS),(2$pow_a))
        #m7
        add m7 m3
        call array_set_word_off(dct_cursor,m7,1)

        #m4
        add m4 m2
        call array_set_word_off(dct_cursor,m4,7)

        #m5 m6
        setcall m5 dct_rotate(m5,p_m6,(-1*ROT13_C),(ROT13_SmC),(ROT13_SpC),(FIX-FPASS),(2$pow_a))
        #m5
        add m5 m3
        call array_set_word_off(dct_cursor,m5,5)
        #m6
        add m6 m2
        call array_set_word_off(dct_cursor,m6,3)

        add dct_cursor (8*2)
        dec i
    endwhile
    set i 8
    set dct_cursor dct_codes
    while i>0
    #even
        #m1 m2
        setcall m1 dct_op(p_m6,(1*8),(6*8),dct_cursor)
        setcall m2 dct_op(p_m5,(2*8),(5*8),dct_cursor)
        setcall m1 dct_calc(m1,p_m2)

        #m3 m4
        setcall m3 dct_op(p_m4,(3*8),(4*8),dct_cursor)
        #m0 m7
        setcall m0 dct_op(p_m7,(0*8),(7*8),dct_cursor)
        setcall m0 dct_calc(m0,p_m3)

        #m3 m2
        setcall m3 dct_rotate(m3,p_m2,(ROT6_C),(ROT6_SmC),(-1*ROT6_SpC),0,(2$pow_b))
        #m3
        setcall m3 sar(m3,(FIX+FPASS+3))
        call array_set_word_off(dct_cursor,m3,(2*8))
        #m2
        setcall m2 sar(m2,(FIX+FPASS+3))
        call array_set_word_off(dct_cursor,m2,(6*8))

        #m0 m1
        add m0 (2$pow_c-1)
        setcall m0 dct_calc(m0,p_m1)
        #m0
        setcall m0 sar(m0,(FPASS+3))
        call array_set_word_off(dct_cursor,m0,(0*8))
        #m1
        setcall m1 sar(m1,(FPASS+3))
        call array_set_word_off(dct_cursor,m1,(4*8))
    #odd
        #m3
        set m3 m5
        add m3 m7
        #m2
        set m2 m4
        add m2 m6

        #m2 m3
        setcall m2 dct_rotate(m2,p_m3,(ROT17_C),(-1*ROT17_SpC),(-1*ROT17_SmC),0,(2$pow_b))
        #m4 m7
        setcall m4 dct_rotate_simple(m4,p_m7,(-1*ROT37_C),(ROT37_SpC),(ROT37_SmC))
        #m7
        add m7 m3
        setcall m7 sar(m7,(FIX+FPASS+3))
        call array_set_word_off(dct_cursor,m7,(1*8))
        #m4
        add m4 m2
        setcall m4 sar(m4,(FIX+FPASS+3))
        call array_set_word_off(dct_cursor,m4,(7*8))

        #m5 m6
        setcall m5 dct_rotate_simple(m5,p_m6,(-1*ROT13_C),(ROT13_SmC),(ROT13_SpC))
        add m5 m3
        add m6 m2
        setcall m5 sar(m5,(FIX+FPASS+3))
        setcall m6 sar(m6,(FIX+FPASS+3))
        call array_set_word_off(dct_cursor,m5,(5*8))
        call array_set_word_off(dct_cursor,m6,(3*8))

        add dct_cursor (1*2)
        dec i
    endwhile
endfunction

function dct_op(sd p_b,sd xa,sd xb,sd codes)
    import "array_get_int16" array_get_int16
    sd a
    setcall a array_get_int16(codes,xa)
    addcall a array_get_int16(codes,xb)
    setcall p_b# array_get_int16(codes,xa)
    subcall p_b# array_get_int16(codes,xb)
    return a
endfunction

#temp=a+b;b=a-b;a=tmp
#return a
function dct_calc(sd a,sd p_b)
    sd temp
    set temp a
    add temp p_b#

    sd b
    set b a
    sub b p_b#
    set p_b# b

    return temp
endfunction

#return m1
function dct_rotate(sd m1,sd p_m2,sd c,sd k1,sd k2,sd fix,sd rnd)
    sd m2
    set m2 p_m2#
#define ROTATE(m1,m2,c,k1,k2,Fix,Rnd)
    #(temp) = ( (m1) + (m2) )*(c)
    sd temp
    set temp m1
    add temp m2
    mult temp c
    #(m1) *= k1
    mult m1 k1
    #(m2) *= k2
    mult m2 k2
    #(temp) += (Rnd)
    add temp rnd
    #(m1) = ((m1)+(temp))>>(Fix)
    add m1 temp
    setcall m1 sar(m1,fix)
    #(m2) = ((m2)+(temp))>>(Fix)
    add m2 temp
    setcall m2 sar(m2,fix)

    set p_m2# m2
    return m1
endfunction

#return m1
function dct_rotate_simple(sd m1,sd p_m2,sd c,sd k1,sd k2)
    sd m2
    set m2 p_m2#
#define ROTATE(m1,m2,c,k1,k2)
    #(temp) = ( (m1) + (m2) )*(c)
    sd temp
    set temp m1
    add temp m2
    mult temp c
    #(m1) *= k1
    mult m1 k1
    #(m2) *= k2
    mult m2 k2
    #(m1) = ((m1)+(temp))
    add m1 temp
    #(m2) = ((m2)+(temp))
    add m2 temp

    set p_m2# m2
    return m1
endfunction

############Quantize

function mpeg_mb_quant(sd dct_codes,sd qcoeff)
    sd scaler_lum=default_scaler
    sd scaler_crom=default_scaler
    sd i=0
    while i!=6
        sd scaler
        if i<4
            set scaler scaler_lum
        else
            set scaler scaler_crom
        endelse
        call mpeg_mb_quant_block(dct_codes,qcoeff,scaler)
        add dct_codes (64*int16)
        add qcoeff (64*int16)
        inc i
    endwhile
endfunction

import "neg" neg
function mpeg_mb_quant_block(sd dct_codes,sd qcoeff,sd scaler)
    const SCALEBITS=16
#define FIX(X)		((1L << SCALEBITS) / (X) + 1)
    data m_data={0,               2$SCALEBITS/2+1, 2$SCALEBITS/4+1, 2$SCALEBITS/6+1}
    data      *={2$SCALEBITS/8+1, 2$SCALEBITS/10+1,2$SCALEBITS/12+1,2$SCALEBITS/14+1}
    data      *={2$SCALEBITS/16+1,2$SCALEBITS/18+1,2$SCALEBITS/20+1,2$SCALEBITS/22+1}
    data      *={2$SCALEBITS/24+1,2$SCALEBITS/26+1,2$SCALEBITS/28+1,2$SCALEBITS/30+1}
    data      *={2$SCALEBITS/32+1,2$SCALEBITS/34+1,2$SCALEBITS/36+1,2$SCALEBITS/38+1}
    data      *={2$SCALEBITS/40+1,2$SCALEBITS/42+1,2$SCALEBITS/44+1,2$SCALEBITS/46+1}
    data      *={2$SCALEBITS/48+1,2$SCALEBITS/50+1,2$SCALEBITS/52+1,2$SCALEBITS/54+1}
    data      *={2$SCALEBITS/56+1,2$SCALEBITS/58+1,2$SCALEBITS/60+1,2$SCALEBITS/62+1}
    data multipliers^m_data
    import "array_get_int" array_get_int
    sd multp
    setcall multp array_get_int(multipliers,(DEFAULT_QUANT))

    sd quant_m_2=DEFAULT_QUANT*2
    #sd quant_d_2=DEFAULT_QUANT/2
    #sd sum=0

    sd codes0
    setcall codes0 array_get_int16(dct_codes,0)
    sd value
    setcall value mb_div(codes0,scaler)
    call array_set_word_off(qcoeff,value,0)

    sd i=1
    while i<64
        sd acLevel
        setcall acLevel array_get_int16(dct_codes,i)
        if acLevel<0
            setcall acLevel neg(acLevel)
            if acLevel<quant_m_2
                call array_set_word_off(qcoeff,0,i)
            else
                mult acLevel multp
                div acLevel (2$SCALEBITS)
                #sum += acLevel
                setcall acLevel neg(acLevel)
                call array_set_word_off(qcoeff,acLevel,i)
            endelse
        else
            if acLevel<quant_m_2
                call array_set_word_off(qcoeff,0,i)
            else
                mult acLevel multp
                div acLevel (2$SCALEBITS)
                #sum += acLevel
                call array_set_word_off(qcoeff,acLevel,i)
            endelse
        endelse
        inc i
    endwhile
endfunction

function mb_div(sd a,sd b)
    sd temp
    set temp b
    div temp 2
    if a>0
    #((a)+((b)>>1))/(b)
        add a temp
    else
    #((a)-((b)>>1))/(b))
        sub a temp
    endelse
    div a b
    return a
endfunction

