

format elfobj

include "../_include/include.h"

import "stage_sound_alloc_getremainingsize" stage_sound_alloc_getremainingsize
import "stage_sound_sizedone" stage_sound_sizedone
import "stage_sound_alloc_getbytes" stage_sound_alloc_getbytes

const HAN_SIZE=512
const han_bytes_size=HAN_SIZE*DWORD
#get pcm

function mp3_get_pcm(sd buffer)
    #get the remaining size
    sd remainingsize
    setcall remainingsize stage_sound_alloc_getremainingsize()
    #frame size all the raw size of a channel(samp_per_frame*mp3_bytespersample)
    sd frame_ch_size
    setcall frame_ch_size mp3_frame_ch_size()
    #get size is all the raw size to read
    sd get_size
    set get_size frame_ch_size
    mult get_size (mp3_channels)
    #can be less remaining size than a frame
    if get_size>remainingsize
        set get_size remainingsize
    endif
    #get the bytes and add the sizedone
    sd sizedone
    sd bytes
    setcall bytes stage_sound_alloc_getbytes()
    setcall sizedone stage_sound_sizedone((value_get))
    add bytes sizedone
    add sizedone get_size
    call stage_sound_sizedone((value_set),sizedone)
    #
    sd get_ch_size
    set get_ch_size get_size
    div get_ch_size (mp3_channels)
    #raw data to buffer
    import "cpymem" cpymem
    sd cursor
    sd next_channel
    sd i=0
    sd cursor_size
    sd buffer_cursor
    sd sizeadd
    while i!=(mp3_channels)
        set cursor bytes
        set next_channel i
        mult next_channel (mp3_bytespersample)
        add cursor next_channel
        #
        set buffer_cursor buffer
        set sizeadd (buffer_channel_size)
        mult sizeadd i
        add buffer_cursor sizeadd
        #
        set cursor_size 0
        while cursor_size!=get_ch_size
            call cpymem(buffer_cursor,cursor,(mp3_bytespersample))
            add cursor (mp3_bytespersample*mp3_channels)
            add buffer_cursor (WORD)
            add cursor_size (mp3_bytespersample)
        endwhile
        inc i
    endwhile
    #actions if less than a frame readed
    #if get_ch_size!=frame_ch_size
    #    set i 0
    #    while i!=(mp3_channels)
    #        set buffer_cursor buffer
    #        set sizeadd (buffer_channel_size)
    #        mult sizeadd i
    #        add buffer_cursor sizeadd
    #        add buffer_cursor get_ch_size
            #
    #        set cursor_size get_ch_size
    #        while cursor_size!=frame_ch_size
    #            data silent_data=0
    #            data p_silent_data^silent_data
    #            call cpymem(buffer_cursor,p_silent_data,(mp3_bytespersample))
    #            add buffer_cursor (WORD)
    #            add cursor_size (mp3_bytespersample)
    #        endwhile
    #        inc i
    #    endwhile
    #endif
endfunction

#bool
function mp3_encode_test()
    sd sz
    setcall sz stage_sound_alloc_getremainingsize()
    sd frame_ch_size
    setcall frame_ch_size mp3_frame_ch_size()
    sub sz frame_ch_size
    if sz<0
        return 0
    endif
    return 1
endfunction

#frame_ch_size
function mp3_frame_ch_size()
    sd frame_ch_size=samp_per_frame
    mult frame_ch_size (mp3_bytespersample)
    return frame_ch_size
endfunction

#subband

const l3_sb_fl_units=SBLIMIT*64
const l3_sb_fl_size=l3_sb_fl_units*DWORD
function l3_subband_init()
    call l3_sb_off_set(0,0)
    call l3_sb_off_set(1,0)
    #
    sd x
    setcall x l3_sb_x()
    sd i=0
    sd j
    while i!=2
        set j 0
        while j!=(HAN_SIZE)
            set x# 0
            add x (DWORD)
            inc j
        endwhile
        inc i
    endwhile
    #
    import "str_to_double" str_to_double
    import "double_mult" double_mult
    data double_low#1
    data double_high#1
    data double^double_low
    data PI64_low#1
    data *PI64_high#1
    data PI64^PI64_low
    str PI64_str="0.049087385212"
    call str_to_double(PI64_str,PI64)
    data const1_low#1
    data *const1_high#1
    data const1^const1_low
    str const1_str="1e9"
    call str_to_double(const1_str,const1)
    data const2_low#1
    data *const2_high#1
    data const2^const2_low
    str const2_str="0.5"
    call str_to_double(const2_str,const2)
    data const3_low#1
    data *const3_high#1
    data const3^const3_low
    str const3_str="1e-9"
    call str_to_double(const3_str,const3)
    data const4_low#1
    data *const4_high#1
    data const4^const4_low
    str const4_str="0"
    call str_to_double(const4_str,const4)
    #
    call double_mult(const4,const3)
    import "fld_quad" fld_quad
    import "fild_value" fild_value
    import "fmul_quad" fmul_quad
    import "fstp_quad" fstp_quad
    import "fcom_quad_greater_or_equal" fcom_quad_greater_or_equal
    import "fsub_quad" fsub_quad
    import "fadd_quad" fadd_quad
    import "double_to_int" double_to_int
    importx "_cos" cos
    importx "_modf" modf
    sd value
    sd value_2
    sd fl
    setcall fl l3_sb_fl()
    add fl (l3_sb_fl_size)
    set i (SBLIMIT)
    while i!=0
        dec i
        set j 64
        while j!=0
            dec j
            sub fl (DWORD)
            #
            set value i
            mult value 2
            inc value
            set value_2 16
            sub value_2 j
            mult value value_2
            call fild_value(value)
            call fmul_quad(PI64)
            call fstp_quad(double)
            call cos(double_low,double_high)
            call fmul_quad(const1)
            sd bool
            setcall bool fcom_quad_greater_or_equal(const4)
            if bool==1
                call fadd_quad(const2)
            else
                call fsub_quad(const2)
            endelse
            call fstp_quad(double)
            call modf(double_low,double_high,double)
            call fild_value(0x7fFFffFF)
            call fmul_quad(const3)
            call fmul_quad(double)
            #call fistp(fl)
            call fstp_quad(double)
            setcall fl# double_to_int(double)
            #pop the modf result to clean the fpu stack
            call fstp_quad(double)
        endwhile
    endwhile
    #
    import "mp3_tables_enwindow" mp3_tables_enwindow
    import "slen" slen
    sd enwindow
    setcall enwindow mp3_tables_enwindow()
    sd ew
    setcall ew l3_sb_ew()
    set i 0
    while i<(HAN_SIZE)
        call str_to_double(enwindow,double)
        call fld_quad(double)
        call fild_value(0x7fffffff)
        call fstp_quad(double)
        call fmul_quad(double)
        call fstp_quad(double)
        setcall ew# double_to_int(double)
        #
        inc i
        add ew (DWORD)
        addcall enwindow slen(enwindow)
        inc enwindow
    endwhile
endfunction

function l3_sb_off()
    data off#2
    data p^off
    return p
endfunction
function l3_sb_off_get(sd index)
    sd off
    setcall off l3_sb_off()
    mult index (DWORD)
    add off index
    return off#
endfunction
function l3_sb_off_set(sd index,sd value)
    sd off
    setcall off l3_sb_off()
    mult index (DWORD)
    add off index
    set off# value
endfunction
#
function l3_sb_x()
    data x#2*HAN_SIZE
    data p_x^x
    return p_x
endfunction
function l3_sb_x_set(sd channel,sd index,sd value)
    sd x
    setcall x l3_sb_x()
    mult channel (han_bytes_size)
    add x channel
    mult index (DWORD)
    add x index
    set x# value
endfunction
function l3_sb_x_get(sd channel,sd index)
    sd x
    setcall x l3_sb_x()
    mult channel (han_bytes_size)
    add x channel
    mult index (DWORD)
    add x index
    return x#
endfunction
#
function l3_sb_z()
    data z#2*HAN_SIZE
    data p_z^z
    return p_z
endfunction
function l3_sb_z_get(sd channel,sd index)
    sd z
    setcall z l3_sb_z()
    mult channel (han_bytes_size)
    add z channel
    mult index (DWORD)
    add z index
    return z#
endfunction
#
function l3_sb_ew()
    data ew#HAN_SIZE
    data p^ew
    return p
endfunction
function l3_sb_ew_get(sd index)
    sd ew
    setcall ew l3_sb_ew()
    mult index (DWORD)
    add ew index
    return ew#
endfunction
#
function l3_sb_fl()
    data fl#l3_sb_fl_units
    data p^fl
    return p
endfunction
#

import "short_get_to_int" short_get_to_int
import "shl" shl
import "mult64" mult64
function l3_window_filter_subband(sd buf,sd l3_sb,sd channel)
    sd index
    sd value
    sd p_value^value
    sd off
    setcall off l3_sb_off_get(channel)
    #replace 32 oldest samples with 32 new samples
    sd i=31
    while i>=0
        setcall value short_get_to_int(buf)
        add buf (WORD)
        setcall value shl(value,16)
        set index i
        add index off
        call l3_sb_x_set(channel,index,value)
        dec i
    endwhile
    #shift samples into proper window positions
    set i (HAN_SIZE)
    sd z
    set z channel
    inc z
    mult z (han_bytes_size)
    addcall z l3_sb_z()
    while i!=0
        dec i
        sub z (DWORD)
        #
        set index i
        add index off
        and index (HAN_SIZE-1)
        setcall value l3_sb_x_get(channel,index)
        sd ew
        setcall ew l3_sb_ew_get(i)
        call mult64(value,ew,z)
    endwhile
    #offset is modulo (HAN_SIZE)
    add off 480
    and off (HAN_SIZE-1)
    call l3_sb_off_set(channel,off)
    #
    data y_data#64
    data y_data_set^y_data
    sd y^y_data
    sd j
    add y (64*DWORD)
    set i 64
    while i!=0
        dec i
        sub y (DWORD)
        #
        set y# 0
        set j 8
        while j!=0
            dec j
            set index i
            addcall index shl(j,6)
            addcall y# l3_sb_z_get(channel,index)
        endwhile
    endwhile
    #
    sd fl
    setcall fl l3_sb_fl()
    add fl (l3_sb_fl_size)
    set i (SBLIMIT)
    add l3_sb (SBLIMIT*DWORD)
    while i!=0
        dec i
        sub l3_sb (DWORD)
        #
        set l3_sb# 0
        set j 64
        set y y_data_set
        add y (64*DWORD)
        while j!=0
            dec j
            sub y (DWORD)
            sub fl (DWORD)
            #
            call mult64(fl#,y#,p_value)
            add l3_sb# value
        endwhile
    endwhile
endfunction
