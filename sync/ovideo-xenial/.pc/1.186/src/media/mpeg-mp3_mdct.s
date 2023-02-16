

format elfobj

include "../_include/include.h"

const cos_l_units=18*36
const cos_l_size=cos_l_units*DWORD
const ca_cs_units=8
const ca_cs_size=ca_cs_units*DWORD

import "mult64" mult64

function mp3_mdct(sd l3_sb_sample,sd mdct_freq)
    sd l3_sb_gr
    sd l3_sb_gr_1
    sd sizeadd
    sd mdct_enc
    sd l3_sb_cursor
    sd m
    sd value
    sd p_value^value
    sd l3_sb_cursor_1
    sd granule=0
    while granule<2
        set mdct_enc mdct_freq
        set sizeadd (mdct_freq_granule_size)
        mult sizeadd granule
        add mdct_enc sizeadd
        add mdct_enc (mdct_freq_granule_size)
        #
        set l3_sb_gr l3_sb_sample
        set sizeadd granule
        mult sizeadd (l3_sb_sample_granule_size)
        add l3_sb_gr sizeadd
        set l3_sb_gr_1 l3_sb_gr
        add l3_sb_gr_1 (l3_sb_sample_granule_size)
        #
        add l3_sb_gr (l3_sb_sample_size)
        add l3_sb_gr_1 (l3_sb_sample_size)
        #
        sd channel=mp3_channels
        while channel>0
            dec channel
            sub l3_sb_gr (l3_sb_sample_channel_size)
            sub l3_sb_gr_1 (l3_sb_sample_channel_size)
            #
            sub mdct_enc (mdct_freq_channel_size)
            #Compensate for inversion in the analysis filter
            #(every odd index of band AND k)
            sd band=1
            while band<32
                set l3_sb_cursor l3_sb_gr_1
                set sizeadd band
                mult sizeadd (DWORD)
                add l3_sb_cursor sizeadd
                sd k=1
                add l3_sb_cursor (l3_sb_sample_band_size)
                while k<18
                    mult l3_sb_cursor# -1
                    add l3_sb_cursor (l3_sb_sample_band_size)
                    add l3_sb_cursor (l3_sb_sample_band_size)
                    add k 2
                endwhile
                add band 2
            endwhile
            #Perform imdct of 18 previous subband samples + 18 current subband samples
            data mdct_in_data#36
            data mdct_in^mdct_in_data
            const mdct_in_size=36*DWORD
            sd mdct_in_cursor
            sd mdct_in_cursor_18
            set band 32
            while band!=0
                dec band
                set l3_sb_cursor l3_sb_gr
                set l3_sb_cursor_1 l3_sb_gr_1
                set sizeadd band
                mult sizeadd (DWORD)
                add l3_sb_cursor sizeadd
                add l3_sb_cursor_1 sizeadd
                #
                set k 18
                set sizeadd k
                mult sizeadd (l3_sb_sample_band_size)
                add l3_sb_cursor sizeadd
                add l3_sb_cursor_1 sizeadd
                set mdct_in_cursor mdct_in
                set mdct_in_cursor_18 mdct_in
                add mdct_in_cursor (mdct_in_size/2)
                add mdct_in_cursor_18 (mdct_in_size)
                while k!=0
                    dec k
                    sub l3_sb_cursor (l3_sb_sample_band_size)
                    sub l3_sb_cursor_1 (l3_sb_sample_band_size)
                    sub mdct_in_cursor (DWORD)
                    sub mdct_in_cursor_18 (DWORD)
                    #
                    set mdct_in_cursor# l3_sb_cursor#
                    set mdct_in_cursor_18# l3_sb_cursor_1#
                endwhile
                #Calculation of the MDCT,mdct_enc: [576] to [32][18]
                const mdct_band_size=18*DWORD
                sd cos_l
                setcall cos_l l3_cos_l()
                add cos_l (cos_l_size)
                set k 18
                set m mdct_enc
                set sizeadd band
                mult sizeadd (mdct_band_size)
                add m sizeadd
                add m (mdct_band_size)
                while k!=0
                    dec k
                    sub m (DWORD)
                    #
                    set mdct_in_cursor mdct_in
                    add mdct_in_cursor (mdct_in_size)
                    sd j=36
                    set m# 0
                    while j!=0
                        dec j
                        sub mdct_in_cursor (DWORD)
                        sub cos_l (DWORD)
                        #
                        call mult64(mdct_in_cursor#,cos_l#,p_value)
                        add m# value
                    endwhile
                endwhile
            endwhile
            #Perform aliasing reduction butterfly
            sd bu
            sd bd
            sd m_1
            sd m_2
            sd m_value_1
            sd m_value_2
            set band 31
            while band!=0
                dec band
                #
                set m_1 band
                mult m_1 (mdct_band_size)
                add m_1 mdct_enc
                set m_2 m_1
                add m_2 (mdct_band_size)
                #
                sd ca
                sd cs
                sd ca_value
                sd cs_value
                setcall ca l3_ca()
                setcall cs l3_cs()
                add ca (ca_cs_size)
                add cs (ca_cs_size)
                set k 8
                set sizeadd 17
                sub sizeadd k
                mult sizeadd (DWORD)
                add m_1 sizeadd
                set sizeadd k
                mult sizeadd (DWORD)
                add m_2 sizeadd
                while k!=0
                    dec k
                    add m_1 (DWORD)
                    sub m_2 (DWORD)
                    sub ca (DWORD)
                    sub cs (DWORD)
                    #must left justify result of multiplication here because the centre
                    # two values in each block are not touched.
                    set m_value_1 m_1#
                    set m_value_2 m_2#
                    set ca_value ca#
                    set cs_value cs#
                    call mult64(m_value_1,cs_value,p_value)
                    set bu value
                    call mult64(m_value_2,ca_value,p_value)
                    add bu value
                    call mult64(m_value_2,cs_value,p_value)
                    set bd value
                    call mult64(m_value_1,ca_value,p_value)
                    sub bd value
                    set m_1# bu
                    set m_2# bd
                endwhile
            endwhile
        endwhile
        inc granule
    endwhile
    #Save latest granule's subband samples to be used in the next mdct call
    import "cpymem" cpymem
    sd from
    sd to
    set channel 0
    while channel!=(mp3_channels)
        set from channel
        mult from (l3_sb_sample_channel_size)
        set to from
        add from (l3_sb_sample_granule_size)
        add from (l3_sb_sample_granule_size)
        add from l3_sb_sample
        add to l3_sb_sample
        call cpymem(to,from,(l3_sb_sample_granule_size))
        inc channel
    endwhile
endfunction

import "str_to_double" str_to_double
import "fld_quad" fld_quad
import "fmul_quad" fmul_quad
import "fstp_quad" fstp_quad
import "fadd_quad" fadd_quad
import "fdiv_quad" fdiv_quad
import "fild_value" fild_value
import "double_to_int" double_to_int
importx "_sqrt" sqrt
importx "_sin" sin
importx "_cos" cos
import "slen" slen

function l3_mdct_init()
    data double_low#1
    data double_high#1
    data double^double_low
    data double_2_low#1
    data *double_2_high#1
    data double_2^double_2_low
    data double_3_low#1
    data *double_3_high#1
    data double_3^double_3_low
    ##prepare the aliasing reduction butterflies
    chars c_data="-0.6"
    chars *="-0.535"
    chars *="-0.33"
    chars *="-0.185"
    chars *="-0.095"
    chars *="-0.041"
    chars *="-0.0142"
    chars *="-0.0037"
    sd c^c_data
    sd ca
    sd cs
    setcall ca l3_ca()
    setcall cs l3_cs()
    call fild_value(0x7fffffff)
    call fstp_quad(double_3)
    sd i=0
    while i!=8
        call str_to_double(c,double_2)
        call fld_quad(double_2)
        call fmul_quad(double_2)
        call fild_value(1)
        call fstp_quad(double)
        call fadd_quad(double)
        call fstp_quad(double)
        call sqrt(double_low,double_high)
        call fstp_quad(double)
        #
        call fld_quad(double_2)
        call fdiv_quad(double)
        call fmul_quad(double_3)
        #call fistp(ca)
        call fstp_quad(double_2)
        setcall ca# double_to_int(double_2)
        #
        call fild_value(1)
        call fdiv_quad(double)
        call fmul_quad(double_3)
        #call fistp(cs)
        call fstp_quad(double)
        setcall cs# double_to_int(double)
        #
        add ca (DWORD)
        add cs (DWORD)
        addcall c slen(c)
        inc c
        inc i
    endwhile
    ##prepare the mdct coefficients
    data const1_low#1
    data *const1_high#1
    data const1^const1_low
    str const1_str="0.5"
    call str_to_double(const1_str,const1)
    #PI 36
    data const2_low#1
    data *const2_high#1
    data const2^const2_low
    str const2_str="0.087266462599717"
    call str_to_double(const2_str,const2)
    #PI
    data const3_low#1
    data *const3_high#1
    data const3^const3_low
    str const3_str="3.14159265358979"
    call str_to_double(const3_str,const3)
    #
    sd cos_l
    setcall cos_l l3_cos_l()
    add cos_l (cos_l_size)
    sd k
    sd value
    sd value_2
    sd m=18
    while m!=0
        dec m
        set k 36
        while k!=0
            #combine window and mdct coefficients into a single table
            #scale and convert to fixed point before storing
            dec k
            sub cos_l (DWORD)
            #
            call fild_value(k)
            call fadd_quad(const1)
            call fmul_quad(const2)
            call fstp_quad(double)
            call sin(double_low,double_high)
            #
            set value m
            mult value 2
            inc value
            set value_2 k
            mult value_2 2
            add value_2 19
            mult value value_2
            call fild_value(72)
            call fstp_quad(double)
            call fld_quad(const3)
            call fdiv_quad(double)
            call fstp_quad(double)
            call fild_value(value)
            call fmul_quad(double)
            call fstp_quad(double)
            call cos(double_low,double_high)
            call fstp_quad(double)
            call fmul_quad(double)
            #
            call fild_value(0x7fffffff)
            call fstp_quad(double)
            call fmul_quad(double)
            #call fistp(cos_l)
            call fstp_quad(double)
            setcall cos_l# double_to_int(double)
        endwhile
    endwhile
endfunction

function l3_ca()
    data cs#ca_cs_units
    data p^cs
    return p
endfunction
function l3_cs()
    data cs#ca_cs_units
    data p^cs
    return p
endfunction

function l3_cos_l()
    data cos_l#cos_l_units
    data p^cos_l
    return p
endfunction
