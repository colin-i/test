


format elfobj

include "../_include/include.h"

import "mp3_output_size" mp3_output_size
import "mp3_output_pos" mp3_output_pos

#define         MPG_MD_STEREO           0
const MPG_MD_DUAL_CHANNEL=2
#define         MPG_MD_MONO             3

const MPG_MD_LR_LR=0
#define         MPG_MD_LR_I              1
#define         MPG_MD_MS_LR             2
#define         MPG_MD_MS_I              3

#bool
function mp3_encode(sd file)
    call mp3_output_size((value_set),0)
    call mp3_output_pos((value_set),8)

    call mp3_encode_frame()

    import "file_write" file_write
    import "mp3_output" mp3_output
    ss mem
    sd size
    setcall mem mp3_output((value_get))
    setcall size mp3_output_size((value_get))
    sd er
    setcall er file_write(mem,size,file)
    if er!=(noerror)
        return 0
    endif
    return 1
endfunction

import "fild_value" fild_value
import "fstp_quad" fstp_quad
import "fdiv_quad" fdiv_quad
import "fmul_quad" fmul_quad
import "double_to_int" double_to_int
import "sar32" sar

import "mp3_mean_bits" mp3_mean_bits
import "mp3_l3_sb_sample" mp3_l3_sb_sample

function mp3_encode_init()
    #sd avg_slots_per_frame
    #(
    #    (double)config->mpeg.samples_per_frame /
    #    (
    #        (double)config->wave.samplerate/1000
    #    )
    #)*(
    #    (double)config->mpeg.bitr /
    #    (double)config->mpeg.bits_per_slot
    #);
    sd samp_per_frame=samp_per_frame
    sd samplerate=mp3_samplerate
    sd bits_per_slot=8
    sd bitrate
    setcall bitrate mp3_bitrate()
    data double_low#1
    data *double_high#1
    data double^double_low

    call fild_value(samp_per_frame)
    call fild_value(samplerate)
    call fild_value(1000)
    call fstp_quad(double)
    call fdiv_quad(double)
    call fstp_quad(double)
    call fdiv_quad(double)
    call fild_value(bitrate)
    call fild_value(bits_per_slot)
    call fstp_quad(double)
    call fdiv_quad(double)
    call fstp_quad(double)
    call fmul_quad(double)
    data whole_slots_per_frame#1
    data p_whole_slots_per_frame^whole_slots_per_frame
    call fstp_quad(double)
    setcall p_whole_slots_per_frame# double_to_int(double)
    #call fistp(p_whole_slots_per_frame)

    sd bits_per_frame
    set bits_per_frame whole_slots_per_frame
    mult bits_per_frame 8

    sd sideinfo_len
    if (mp3_channels)==1
        set sideinfo_len 168
    else
        set sideinfo_len 288
    endelse

    sd mean_bits
    set mean_bits bits_per_frame
    sub mean_bits sideinfo_len
    setcall mean_bits sar(mean_bits,1)

    sd p_mean_bits
    setcall p_mean_bits mp3_mean_bits()
    set p_mean_bits# mean_bits

    import "setmemzero" setmemzero
    sd l3_sb_sample
    setcall l3_sb_sample mp3_l3_sb_sample()
    call setmemzero(l3_sb_sample,(l3_sb_sample_size))
endfunction

function mp3_encode_frame()
    sd mean_bits
    setcall mean_bits mp3_mean_bits()
    set mean_bits mean_bits#
    #
    chars buffer_data#buffer_size
    data buffer^buffer_data
    #
    sd l3_sb_sample
    setcall l3_sb_sample mp3_l3_sb_sample()
    #
    const mdct_freq_size=2*mdct_freq_granule_size
    data mdct_freq_data#mdct_freq_size
    data mdct_freq^mdct_freq_data
    #call setmemzero(mdct_freq,(mdct_freq_size))

    #get from input
    import "mp3_get_pcm" mp3_get_pcm
    call mp3_get_pcm(buffer)
    #polyphase filtering
    sd buf
    sd l3_sb
    import "l3_window_filter_subband" l3_window_filter_subband
    sd granule=0
    const buffer_granule_size=buffer_channel_size/2
    const buffer_band_size=buffer_granule_size/18
    sd sizeadd
    set buf buffer
    set l3_sb l3_sb_sample
    add l3_sb (l3_sb_sample_granule_size)
    while granule!=2
        set sizeadd granule
        mult sizeadd (buffer_granule_size)
        add sizeadd (buffer_size)
        add buf sizeadd
        #
        set sizeadd granule
        mult sizeadd (l3_sb_sample_granule_size)
        add sizeadd (l3_sb_sample_size)
        add l3_sb sizeadd
        #
        sd channel=mp3_channels
        while channel!=0
            dec channel
            sub buf (buffer_channel_size)
            sub l3_sb (l3_sb_sample_channel_size)
            #
            sd i=0
            while i<18
                call l3_window_filter_subband(buf,l3_sb,channel)
                add buf (buffer_band_size)
                add l3_sb (l3_sb_sample_band_size)
                inc i
            endwhile
            sub buf (buffer_granule_size)
            sub l3_sb (l3_sb_sample_granule_size)
        endwhile
        inc granule
    endwhile
    #apply mdct to the polyphase output
    import "mp3_mdct" mp3_mdct
    call mp3_mdct(l3_sb_sample,mdct_freq)
    #bit and noise allocation
    import "mp3_iteration" mp3_iteration
    call mp3_iteration(mdct_freq,mean_bits)
    #write the frame to the bitstream
    call mp3_format_bitstream(mdct_freq)
endfunction

function mp3_bitrate()
    data bitrate=128
    return bitrate
endfunction

import "l3_enc" l3_enc

function mp3_format_bitstream(sd mdct_freq)
    #from mdct to l3_enc sign is lost, change back
    sd l3enc_tt
    setcall l3enc_tt l3_enc(0,0)
    sd granule=0
    while granule<2
        sd channel=0
        while channel<(mp3_channels)
            sd i=0
            while i<(samp_per_frame2)
                if mdct_freq#<0
                    #if l3enc_tt#>0
                    mult l3enc_tt# -1
                    #endif
                endif
                add mdct_freq (DWORD)
                add l3enc_tt (DWORD)
                inc i
            endwhile
            inc channel
        endwhile
        inc granule
    endwhile
    #
    call mp3_side_info()
    call mp3_main_data()
endfunction

function mp3_side_info()
    call mp3_header()
    call mp3_frameSI()
endfunction

import "int_in_set" int_in_set

function mp3_header()
    import "mp3_bs_write" mp3_bs_write
    #sync
    call mp3_bs_write(0xfff,12)
    #version name, 0="MPEG-2 LSF", 1="MPEG-1"
    call mp3_bs_write(1,1)
    #layer; (4-layer), 3="III"
    call mp3_bs_write(1,2)
    #error_protection=0,(!error_protection)
    call mp3_bs_write((0+1),1)
    #biterate index
    sd biterate_index
    sd btrt
    setcall btrt mp3_bitrate()
    data bitratex_data={0,32,40,48,56,64,80,96,112,128,160,192,224,256,320}
    data bitratex^bitratex_data
    setcall biterate_index int_in_set(btrt,bitratex,15)
    call mp3_bs_write(biterate_index,4)
    #samplerate index
    sd samplerate_index
    data samplerateex_data={44100, 48000, 32000}
    data samplerateex^samplerateex_data
    setcall samplerate_index int_in_set(48000,samplerateex,3)
    call mp3_bs_write(samplerate_index,2)
    #padding
    call mp3_bs_write(0,1)
    #extension
    call mp3_bs_write(0,1)
    #mode
    call mp3_bs_write((MPG_MD_DUAL_CHANNEL),2)
    #mode_ext
    call mp3_bs_write((MPG_MD_LR_LR),2)
    #copyright
    call mp3_bs_write(0,1)
    #wantedOriginal = TRUE
    call mp3_bs_write((TRUE),1)
    #emphasis
    call mp3_bs_write(0,2)
endfunction

import "mp3_gr_info" mp3_gr_info
import "mp3_gr_info_itemGet" mp3_gr_info_itemGet

function mp3_frameSI()
    #main_data_begin
    call mp3_bs_write(0,9)
    #private_bits
    #if config->wave.channels == 2
    call mp3_bs_write(0,3)
    #scalefactor select information
    sd i=0
    while i<(mp3_channels)
        sd scfsi_band=0
        while scfsi_band<4
            call mp3_bs_write(0,1)
            inc scfsi_band
        endwhile
        inc i
    endwhile
    sd value
    sd granule=0
    while granule<2
        sd channel=0
        while channel<(mp3_channels)
            sd gr_info
            setcall gr_info mp3_gr_info(granule,channel)
            #
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_part2_3_length))
            call mp3_bs_write(value,12)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_big_values))
            call mp3_bs_write(value,9)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_global_gain))
            call mp3_bs_write(value,8)
            #scalefac_compress
            call mp3_bs_write(0,4)
            call mp3_bs_write(0,1)
            #
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_table_select_0))
            call mp3_bs_write(value,5)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_table_select_1))
            call mp3_bs_write(value,5)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_table_select_2))
            call mp3_bs_write(value,5)
            #
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_region0_count))
            call mp3_bs_write(value,4)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_region1_count))
            call mp3_bs_write(value,3)
            #
            #preflag
            call mp3_bs_write(0,1)
            #scalefac_scale
            call mp3_bs_write(0,1)
            setcall value mp3_gr_info_itemGet(gr_info,(gr_info_count1table_select))
            call mp3_bs_write(value,1)
            #
            inc channel
        endwhile
        inc granule
    endwhile
endfunction

#main data

function mp3_main_data()
    sd granule=0
    while granule<2
        sd channel=0
        while channel<(mp3_channels)
            sd gr_info
            setcall gr_info mp3_gr_info(granule,channel)
            sd l3enc_tt
            setcall l3enc_tt l3_enc(granule,channel)
            #
            call mp3_Huffmancodebits(gr_info,l3enc_tt)
            inc channel
        endwhile
        inc granule
    endwhile
endfunction

import "l3_enc_sample_get" l3_enc_sample_get
import "scalefac_band_long_get" scalefac_band_long_get

function mp3_Huffmancodebits(sd gr_info,sd l3enc)
    data code#1
    data p_code^code
    data bisize#1
    data p_bisize^bisize
    data ext#1
    data p_ext^ext
    data ext_bisize#1
    data p_ext_bisize^ext_bisize
    sd index
    sd tableindex
    sd bigvalues
    setcall bigvalues mp3_gr_info_itemGet(gr_info,(gr_info_big_values))
    mult bigvalues 2
    #1: Write the bigvalues
    sd scalefac_index
    sd region1Start
    setcall scalefac_index mp3_gr_info_itemGet(gr_info,(gr_info_region0_count))
    inc scalefac_index
    setcall region1Start scalefac_band_long_get(scalefac_index)
    sd region2Start
    addcall scalefac_index mp3_gr_info_itemGet(gr_info,(gr_info_region1_count))
    inc scalefac_index
    setcall region2Start scalefac_band_long_get(scalefac_index)
    sd v
    sd w
    sd x
    sd y
    sd bitsWritten=0
    sd i=0
    while i<bigvalues
        #get table pointer
        if i<region1Start
            setcall tableindex mp3_gr_info_itemGet(gr_info,(gr_info_table_select_0))
        elseif i<region2Start
            setcall tableindex mp3_gr_info_itemGet(gr_info,(gr_info_table_select_1))
        else
            setcall tableindex mp3_gr_info_itemGet(gr_info,(gr_info_table_select_2))
        endelse
        if tableindex!=0
            set index i
            setcall x l3_enc_sample_get(l3enc,index)
            inc index
            setcall y l3_enc_sample_get(l3enc,index)
            addcall bitsWritten mp3_HuffmanCode(tableindex,x,y,p_code,p_bisize,p_ext,p_ext_bisize)
            call mp3_bs_write(code,bisize)
            call mp3_bs_write(ext,ext_bisize)
        endif
        #
        add i 2
    endwhile
    #2: Write count1 area
    setcall tableindex mp3_gr_info_itemGet(gr_info,(gr_info_count1table_select))
    add tableindex 32
    sd count1End
    setcall count1End mp3_gr_info_itemGet(gr_info,(gr_info_count1))
    mult count1End 4
    add count1End bigvalues
    set i bigvalues
    while i!=count1End
        set index i
        setcall v l3_enc_sample_get(l3enc,index)
        inc index
        setcall w l3_enc_sample_get(l3enc,index)
        inc index
        setcall x l3_enc_sample_get(l3enc,index)
        inc index
        setcall y l3_enc_sample_get(l3enc,index)
        addcall bitsWritten l3_huffman_coder_count1(tableindex,v,w,x,y)
        add i 4
    endwhile
    import "rest" rest
    sd stuffingBits
    setcall stuffingBits mp3_gr_info_itemGet(gr_info,(gr_info_part2_3_length))
    sub stuffingBits bitsWritten
    if stuffingBits!=0
        #Due to the nature of the Huffman code tables, we will pad with ones
        sd stuffingWords
        set stuffingWords stuffingBits
        div stuffingWords 32
        sd remainingBits
        setcall remainingBits rest(stuffingBits,32)
        while stuffingWords!=0
            dec stuffingWords
            call mp3_bs_write(-1,32)
        endwhile
        if remainingBits!=0
            call mp3_bs_write(-1,remainingBits)
        endif
    endif
endfunction

import "huffman_tabs" huffman_tabs
import "huffman_table" huffman_table
import "huffman_hlen" huffman_hlen

#bits
function mp3_HuffmanCode(sd tableindex,sd x,sd y,sd p_code,sd p_bisize,sd p_ext,sd p_ext_bisize)
    sd linbits
    sd linbitsx=0
    sd linbitsy=0
    sd ylen
    setcall ylen huffman_tabs(tableindex,(huffman_ylen))
    setcall linbits huffman_tabs(tableindex,(huffman_linbits))
    sd signx=0
    if x<0
        mult x -1
        set signx 1
    endif
    sd signy=0
    if y<0
        mult y -1
        set signy 1
    endif
    import "shl" shl
    sd code
    sd bisize
    sd ext=0
    sd ext_bisize=0
    sd idx
    if tableindex>15
        #ESC-table is used
        if x>14
            set linbitsx x
            sub linbitsx 15
            set x 15
        endif
        if y>14
            set linbitsy y
            sub linbitsy 15
            set y 15
        endif
        set idx ylen
        mult idx x
        add idx y
        setcall code huffman_table(tableindex,idx)
        setcall bisize huffman_hlen(tableindex,idx)
        if x>14
            or ext linbitsx
            add ext_bisize linbits
        endif
        if x!=0
            mult ext 2
            or ext signx
            add ext_bisize 1
        endif
        if y>14
            setcall ext shl(ext,linbits)
            or ext linbitsy
            add ext_bisize linbits
        endif
        if y!=0
            mult ext 2
            or ext signy
            add ext_bisize 1
        endif
    else
        #No ESC-words
        set idx ylen
        mult idx x
        add idx y
        setcall code huffman_table(tableindex,idx)
        setcall bisize huffman_hlen(tableindex,idx)
        if x!=0
            mult code 2
            or code signx
            inc bisize
        endif
        if y!=0
            mult code 2
            or code signy
            inc bisize
        endif
    endelse
    set p_code# code
    set p_bisize# bisize
    set p_ext# ext
    set p_ext_bisize# ext_bisize
    add bisize ext_bisize
    return bisize
endfunction

#bits
function l3_huffman_coder_count1(sd tableindex,sd v,sd w,sd x,sd y)
    sd totalBits=0
    sd signv=0
    if v<0
        mult v -1
        set signv 1
    endif
    sd signw=0
    if w<0
        mult w -1
        set signw 1
    endif
    sd signx=0
    if x<0
        mult x -1
        set signx 1
    endif
    sd signy=0
    if y<0
        mult y -1
        set signy 1
    endif
    sd p
    set p v
    addcall p shl(w,1)
    addcall p shl(x,2)
    addcall p shl(y,3)
    sd code
    setcall code huffman_table(tableindex,p)
    sd len
    setcall len huffman_hlen(tableindex,p)
    call mp3_bs_write(code,len)
    add totalBits len
    if v!=0
        call mp3_bs_write(signv,1)
        inc totalBits
    endif
    if w!=0
        call mp3_bs_write(signw,1)
        inc totalBits
    endif
    if x!=0
        call mp3_bs_write(signx,1)
        inc totalBits
    endif
    if y!=0
        call mp3_bs_write(signy,1)
        inc totalBits
    endif
    return totalBits
endfunction
