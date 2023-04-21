

format elfobj

include "../_include/include.h"

const NAL_SLICE=1
const NAL_SLICE_IDR=5
const NAL_SEI=6
const NAL_SPS=7
const NAL_PPS=8

#const NAL_PRIORITY_DISPOSABLE=0
#const NAL_PRIORITY_LOW=1
const NAL_PRIORITY_HIGH=2
const NAL_PRIORITY_HIGHEST=3

const X264_TYPE_AUTO=0x0000
#const X264_TYPE_IDR=0x0001
const X264_TYPE_I=0x0002
#const X264_TYPE_P=0x0003

import "avc_output" avc_output
import "avc_output_size" avc_output_size
import "avc_output_pos" avc_output_pos
import "avc_nal_output" avc_nal_output

import "avc_bs_write_ue" avc_bs_write_ue
import "avc_bs_align_byte" avc_bs_align_byte

#bool
function avc_encode(sd file,sd settype,sd pixbuf)
    call avc_output_size((value_set),0)
    call avc_output_pos((value_set),8)

    if settype==(avc_sequence_param)
        call avc_sequenceParameterSet()
    elseif settype==(avc_picture_param)
        call avc_pictureParameterSet()
    elseif settype==(avc_frame0_headers)
        call avc_ini_headers()
    else
        call avc_enc_frame(pixbuf)
    endelse

    sd bool
    setcall bool avc_write(file)
    return bool
endfunction

#bool
function avc_write(sd file)
    import "file_write" file_write
    ss mem
    sd size
    setcall mem avc_output((value_get))
    setcall size avc_output_size((value_get))

    import "avc_allsize" avc_allsize
    ss nal_mem
    setcall nal_mem avc_nal_output((value_get))
    sd nal_size=0
    sd allsize
    setcall allsize avc_allsize((value_get))
    sd count=-1
    #-1 at count will ignore the header
    while size!=0
        if nal_size!=allsize
            sd src_byte
            set src_byte mem#
            if count==2
                if src_byte<=0x3
                    set nal_mem# 0x3
                    set count 0
                    inc nal_mem
                    inc nal_size
                endif
            endif
            if src_byte==0
                inc count
            else
                set count 0
            endelse
            set nal_mem# src_byte
            inc nal_mem
            inc nal_size
        endif
        inc mem
        dec size
    endwhile
    setcall nal_mem avc_nal_output((value_get))

    sd er
    setcall er file_write(nal_mem,nal_size,file)
    if er!=(noerror)
        return 0
    endif
    return 1
endfunction

import "shl" shl
import "avc_bs_write" avc_bs_write
import "avc_bs_write_byte" avc_bs_write_byte
import "avc_bs_trailing" avc_bs_trailing
import "avc_bs_write_data" avc_bs_write_data

function avc_ini_headers()
    call avc_bs_write_byte((NAL_SEI))
    #payload_type = user_data_unregistered
    call avc_bs_write_byte(0x5)

    import "slen" slen
    sd length=16
    sd ver_len
    #
    #importx "_sprintf" sprintf
    #chars version_data#256
    #str version^version_data
    #str format="x264 - core %d%s - H.264/MPEG-4 AVC codec - Copyleft 2005 - http://www.videolan.org/x264.html"
    #sd X264_BUILD=34
    #str X264_VERSION=""
    #call sprintf(version,format,X264_BUILD,X264_VERSION)
    str version="OApplications"

    setcall ver_len slen(version)
    inc ver_len
    add length ver_len

    call avc_bs_write_byte(length)

    chars id_data={0xdc,0x45,0xe9,0xbd,0xe6,0xd9,0x48,0xb7}
    chars *      ={0x96,0x2c,0xd8,0x20,0xd9,0x23,0xee,0xef}
    data id^id_data

    call avc_bs_write_data(id,16)
    call avc_bs_write_data(version,ver_len)

    call avc_bs_trailing()
endfunction

import "avc_bs_write_bit" avc_bs_write_bit

function avc_sequenceParameterSet()
    sd nal_header
    setcall nal_header shl((NAL_PRIORITY_HIGHEST),5)
    or nal_header (NAL_SPS)
    call avc_bs_write_byte(nal_header)

    import "avc_ProfileIndication" avc_ProfileIndication
    import "avc_profile_compatibility" avc_profile_compatibility
    import "avc_LevelIndication" avc_LevelIndication

    sd ProfileIndication
    setcall ProfileIndication avc_ProfileIndication((value_get))
    call avc_bs_write_byte(ProfileIndication)
    sd profile_compatibility
    setcall profile_compatibility avc_profile_compatibility((value_get))
    call avc_bs_write_byte(profile_compatibility)
    sd LevelIndication
    setcall LevelIndication avc_LevelIndication((value_get))
    call avc_bs_write_byte(LevelIndication)

    #id=0
    call avc_bs_write_ue(0)
    #i_log2_max_frame_num
    sd i_log2_max_frame_num=4
    sd loop=1
    while loop==1
        sd nr
        setcall nr shl(1,i_log2_max_frame_num)
        if nr<=(avc_keyint_max)
            inc i_log2_max_frame_num
        else
            set loop 0
        endelse
    endwhile
        #just in case
    inc i_log2_max_frame_num
        #
    sd log
    set log i_log2_max_frame_num
    sub log 4
    call avc_bs_write_ue(log)
    import "avc_log2_max_frame_num" avc_log2_max_frame_num
    call avc_log2_max_frame_num((value_set),i_log2_max_frame_num)
    #i_poc_type=0
    call avc_bs_write_ue(0)
    #
    import "avc_log2_max_poc_lsb" avc_log2_max_poc_lsb
    sd i_log2_max_poc_lsb=1
    add i_log2_max_poc_lsb i_log2_max_frame_num
    set log i_log2_max_poc_lsb
    sub log 4
    call avc_bs_write_ue(log)
    call avc_log2_max_poc_lsb((value_set),i_log2_max_poc_lsb)
    #i_num_reorder_frames = b_bframe_pyramid ? 2 : i_bframe ? 1 : 0;
    #i_frame_reference=1
    #i_num_ref_frames = X264_MIN(16, i_frame_reference + i_num_reorder_frames);
    call avc_bs_write_ue(1)
    #b_gaps_in_frame_num_value_allowed
    call avc_bs_write(0,1)
    import "avc_mb_width" avc_mb_width
    import "avc_mb_height" avc_mb_height
    sd w
    sd h
    setcall w avc_mb_width((value_get))
    setcall h avc_mb_height((value_get))
    dec w
    dec h
    call avc_bs_write_ue(w)
    call avc_bs_write_ue(h)
    #b_frame_mbs_only=1
    call avc_bs_write(1,1)
    #analyse.inter = X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8 | X264_ANALYSE_PSUB16x16 | X264_ANALYSE_BSUB16x16
    #0x113
    #b_transform_8x8=0
    #!b_transform_8x8
    #          analyse.inter &= ~X264_ANALYSE_I8x8
    #0x111
    #if !(analyse.inter & X264_ANALYSE_PSUB8x8) )
    #b_direct8x8_inference=1
    call avc_bs_write(1,1)

    #b_crop
    import "avc_width" avc_width
    import "avc_height" avc_height
    sd width
    sd height
    setcall width avc_width((value_get))
    setcall height avc_height((value_get))
    import "rest" rest
    sd w_rem
    sd h_rem
    setcall w_rem rest(width,16)
    setcall h_rem rest(height,16)
    sd b_crop=0
    if w_rem!=0
        set b_crop 1
    elseif h_rem!=0
        set b_crop 1
    endelseif
    call avc_bs_write(b_crop,1)
    if b_crop==1
        #left
        call avc_bs_write_ue(0)
        #right
        sd crop_right=16
        sub crop_right w_rem
        div crop_right 2
        call avc_bs_write_ue(crop_right)
        #top
        call avc_bs_write_ue(0)
        #bottom
        sd crop_bottom=16
        sub crop_bottom h_rem
        div crop_bottom 2
        call avc_bs_write_ue(crop_bottom)
    endif
    #b_vui
    #i_fps_den=1000
    #i_fps_num = (int)(fps * 1000 + .5);
    #if i_fps_num>0 && i_fps_den>0
    #          b_timing_info_present = 1
    #          i_num_units_in_tick = i_fps_den
    #          i_time_scale = i_fps_num
    #          b_fixed_frame_rate = 1
    sd b_timing_info_present=1
    sd i_num_units_in_tick=1000

    import "stage_file_options_fps" stage_file_options_fps
    sd i_time_scale
    setcall i_time_scale stage_file_options_fps()
    mult i_time_scale 1000

    sd b_fixed_frame_rate=1
    #b_vui|=b_timing_info_present
    call avc_bs_write(1,1)

    #b_aspect_ratio_info_present=0
    #i_sar_width>0 && i_sar_height>0 then b_aspect_ratio_info_present is 0
    call avc_bs_write_bit(0)
    #overscan_info_present_flag
    call avc_bs_write_bit(0)
    #video_signal_type_present_flag
    call avc_bs_write_bit(0)
    #chroma_loc_info_present_flag
    call avc_bs_write_bit(0)

    #b_timing_info_present
    call avc_bs_write_bit(b_timing_info_present)
    #i_num_units_in_tick
    call avc_bs_write(i_num_units_in_tick,32)
    #i_time_scale
    call avc_bs_write(i_time_scale,32)
    #b_fixed_frame_rate
    call avc_bs_write_bit(b_fixed_frame_rate)

    #nal_hrd_parameters_present_flag
    call avc_bs_write_bit(0)
    #vcl_hrd_parameters_present_flag
    call avc_bs_write_bit(0)
    #pic_struct_present_flag
    call avc_bs_write_bit(0)
    #b_bitstream_restriction
    call avc_bs_write_bit(0)

    call avc_bs_trailing()
endfunction

import "avc_bs_write_se" avc_bs_write_se

function avc_pictureParameterSet()
    sd nal_header
    setcall nal_header shl((NAL_PRIORITY_HIGHEST),5)
    or nal_header (NAL_PPS)
    call avc_bs_write_byte(nal_header)

    sd value

    #id=0
    call avc_bs_write_ue(0)
    #sps_id=id
    call avc_bs_write_ue(0)

    #b_cabac=1
    call avc_bs_write(1,1)
    #b_pic_order=0
    call avc_bs_write(0,1)
    #i_num_slice_groups=1
    sd s_groups=1
    set value s_groups
    dec value
    call avc_bs_write_ue(value)
    #i_num_ref_idx_l0_active=1;write num-1
    call avc_bs_write_ue(0)
    #i_num_ref_idx_l1_active=1;write num-1
    call avc_bs_write_ue(0)
    #b_weighted_pred=0
    call avc_bs_write(0,1)
    #b_weighted_bipred=0
    call avc_bs_write(0,2)

    #i_pic_init_qp
    sd pic_init_qp=avc_pic_init_qp
    set value pic_init_qp
    sub value 26
    call avc_bs_write_se(value)
    #i_pic_init_qs
    sd pic_init_qs=26
    set value pic_init_qs
    sub value 26
    call avc_bs_write_se(value)
    #i_chroma_qp_index_offset=i_chroma_qp_offset=0
    call avc_bs_write_se(0)

    #b_deblocking_filter_control=1
    call avc_bs_write(1,1)
    #b_constrained_intra_pred
    call avc_bs_write(0,1)
    #b_redundant_pic_cnt
    call avc_bs_write(0,1)

    call avc_bs_trailing()
endfunction

import "avc_slice_type" avc_slice_type
import "avc_pre_input" avc_pre_input
import "avc_input" avc_input

function avc_enc_frame(sd pixbuf)
    #get pixbuf to input i420
    sd input
    setcall input avc_pre_input((value_get))
    importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
    sd bytes
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)
    import "rgb_to_yuvi420" rgb_to_yuvi420
    sd w
    sd h
    setcall w avc_width((value_get))
    setcall h avc_height((value_get))
    call rgb_to_yuvi420(bytes,input,w,h)

    #write header
    call avc_enc_frame_header()
    #align
    call avc_bs_align_byte()
    #encode
    call avc_enc_frame_content()
endfunction
function avc_enc_frame_header()
    sd nal_slice_type
    sd nal_priority
    sd type=X264_TYPE_I
    import "avc_frame_num" avc_frame_num
    sd frame_num
    setcall frame_num avc_frame_num((value_get))
    import "avc_idr_pic_id" avc_idr_pic_id
    #-1 if nal_type != 5
    sd idr_pic_id
    setcall idr_pic_id avc_idr_pic_id((value_get))
    if frame_num==(avc_keyint_max)
        set nal_slice_type (NAL_SLICE_IDR)
        set nal_priority (NAL_PRIORITY_HIGHEST)
        set type (X264_TYPE_I)

        set frame_num 0
        inc idr_pic_id
        call avc_idr_pic_id((value_set),idr_pic_id)
        setcall idr_pic_id rest(idr_pic_id,65536)
        call avc_slice_type((value_set),(SLICE_TYPE_I))
    else
        set nal_slice_type (NAL_SLICE)
        set type (X264_TYPE_AUTO)
        set nal_priority (NAL_PRIORITY_HIGH)

        inc frame_num
        set idr_pic_id -1
        call avc_slice_type((value_set),(SLICE_TYPE_P))
    endelse
    call avc_frame_num((value_set),frame_num)

    #header
    sd value

    sd nal_header
    setcall nal_header shl(nal_priority,5)
    or nal_header nal_slice_type
    call avc_bs_write(nal_header,8)

    #i_first_mb
    call avc_bs_write_ue(0)
    #i_type
    set value type
    add value 5
    call avc_bs_write_ue(value)
    #i_pps_id=0
    call avc_bs_write_ue(0)
    #frame_num
    sd log2_max_frame_num
    setcall log2_max_frame_num avc_log2_max_frame_num((value_get))
    call avc_bs_write(frame_num,log2_max_frame_num)
    #idr_pic_id
    if idr_pic_id>=0
        call avc_bs_write_ue(idr_pic_id)
    endif
    #if poc_type==0

    sd i_poc
    sd log2_max_poc_lsb
    sd i_poc_lsb
    set i_poc frame_num
    mult i_poc 2
    setcall log2_max_poc_lsb avc_log2_max_poc_lsb((value_get))
    setcall i_poc_lsb shl(1,log2_max_poc_lsb)
    dec i_poc_lsb
    and i_poc_lsb i_poc
    call avc_bs_write(i_poc_lsb,log2_max_poc_lsb)

    if type!=(X264_TYPE_I)
        sd b_num_ref_idx_override=1
        call avc_bs_write_bit(b_num_ref_idx_override)
        sd i_num_ref_idx_l0_active=1
        set value i_num_ref_idx_l0_active
        dec value
        call avc_bs_write_ue(value)

        sd b_ref_pic_list_reordering_l0=0
        call avc_bs_write_bit(b_ref_pic_list_reordering_l0)
    endif

    #NAL_PRIORITY_DISPOSABLE at B frames
    #i_nal_ref_idc!=NAL_PRIORITY_DISPOSABLE
    if idr_pic_id>=0
        #no output of prior pics flag
        call avc_bs_write_bit(0)
        #long term reference flag
        call avc_bs_write_bit(0)
    else
        #adaptive_ref_pic_marking_mode_flag
        call avc_bs_write_bit(0)
    endelse

    #b_cabac && sh->i_type != SLICE_TYPE_I
    if type!=(X264_TYPE_I)
        sd i_cabac_init_idc=0
        call avc_bs_write_ue(i_cabac_init_idc)
    endif

    #slice qp delta
    import "avc_qp_I" avc_qp_I
    sd qp_delta
    setcall qp_delta avc_qp_I()
    sub qp_delta (avc_pic_init_qp)
    call avc_bs_write_se(qp_delta)

    #if b_deblocking_filter_control
        #qp_delta
            #i_disable_deblocking_filter_idc=1
    call avc_bs_write_ue(1)
            #i_disable_deblocking_filter_idc!=1
                #i_alpha_c0_offset
    #call avc_bs_write_se(0)
                #i_beta_offset
    #call avc_bs_write_se(0)
endfunction

import "avc_mb_nr_left" avc_mb_nr_left
import "avc_mb_nr_top" avc_mb_nr_top

import "sar32" sar

function avc_enc_frame_content()
    import "avc_cabac_context_init" avc_cabac_context_init
    call avc_cabac_context_init()
    import "avc_cabac_range" avc_cabac_range
    call avc_cabac_range((value_set),0x1fe)
    import "avc_cabac_low" avc_cabac_low
    call avc_cabac_low((value_set),0)
    import "avc_cabac_sym_cnt" avc_cabac_sym_cnt
    call avc_cabac_sym_cnt((value_set),0)
    import "avc_cabac_bits_outstanding" avc_cabac_bits_outstanding
    call avc_cabac_bits_outstanding((value_set),0)
    import "avc_cabac_first_bit" avc_cabac_first_bit
    call avc_cabac_first_bit((value_set),1)

    sd mb_width
    sd mb_height
    setcall mb_width avc_mb_width((value_get))
    setcall mb_height avc_mb_height((value_get))
    sd pre_input
    setcall pre_input avc_pre_input((value_get))
    sd input
    setcall input avc_input((value_get))
    import "yuv_get_all_sizes" yuv_get_all_sizes
    sd Y_area_pre
    sd U_area_pre
    sd V_area_pre
    sd Y_area
    sd U_area
    sd V_area
    sd planeY
    sd planeU
    sd planeV
    sd planeY_pre
    sd planeU_pre
    sd planeV_pre
    sd p_planeU^planeU
    sd p_planeV^planeV
    sd width
    sd height
    setcall width avc_width((value_get))
    setcall height avc_height((value_get))
    call yuv_get_all_sizes(width,height,p_planeU,p_planeV)
    set planeU_pre planeU
    set planeV_pre planeV
    set planeY_pre pre_input
    add planeU_pre pre_input
    add planeV_pre pre_input
    set Y_area_pre planeY_pre
    set U_area_pre planeU_pre
    set V_area_pre planeV_pre
    set planeY input
    add planeU input
    add planeV input
    set Y_area planeY
    set U_area planeU
    set V_area planeV
    sd strideY
    sd strideUV
    set strideY width
    set strideUV width
    div strideUV 2

    sd y=0
    while y!=mb_height
        call avc_mb_nr_top((value_set),y)
        sd x=0
        while x!=mb_width
            call avc_mb_nr_left((value_set),x)
            #skip or code
            sd mb_type=avc_I_16x16
            sd slice_type
            setcall slice_type avc_slice_type((value_get))
            if slice_type!=(SLICE_TYPE_I)
                import "mpeg_block_iteration_compare" mpeg_block_iteration_compare
                sd mode
                setcall mode mpeg_block_iteration_compare(Y_area,Y_area_pre,U_area,U_area_pre,V_area,V_area_pre,strideY,strideUV,x,y)
                if mode==(SKIP)
                    set mb_type (avc_P_SKIP)
                endif
            endif
            if mb_type==(avc_I_16x16)
                #get the block bytes on the current input
                import "mpeg_block_iteration_copy" mpeg_block_iteration_copy
                call mpeg_block_iteration_copy(Y_area,Y_area_pre,U_area,U_area_pre,V_area,V_area_pre,strideY,strideUV,x,y)
            endif

            #init cache
            import "avc_mb_cache_init" avc_mb_cache_init
            call avc_mb_cache_init(x,y,mb_type)

            sd call_terminal=1
            if y==0
                if x==0
                    set call_terminal 0
                endif
            endif
            if call_terminal==1
                import "avc_cabac_terminal" avc_cabac_terminal
                call avc_cabac_terminal(0)
            endif
            if mb_type==(avc_P_SKIP)
                call avc_cabac_skip(1,x,y)
            else
                import "avc_block" avc_block
                call avc_block(planeY,planeU,planeV,x,y)
                if slice_type!=(SLICE_TYPE_I)
                    call avc_cabac_skip(0,x,y)
                endif
                import "avc_mb_write_cabac" avc_mb_write_cabac
                call avc_mb_write_cabac(slice_type)
            endelse
            import "avc_mb_cache_save" avc_mb_cache_save
            call avc_mb_cache_save(x,y)

            add planeY_pre 16
            add planeU_pre 8
            add planeV_pre 8
            add planeY 16
            add planeU 8
            add planeV 8
            inc x
        endwhile
        #add 16-1 rows at luma input and 8-1 rows at chroma
        sd alpha=0
        while alpha!=15
            add planeY_pre strideY
            add planeY strideY
            inc alpha
        endwhile
        set alpha 0
        while alpha!=7
            add planeU_pre strideUV
            add planeV_pre strideUV
            add planeU strideUV
            add planeV strideUV
            inc alpha
        endwhile
        inc y
    endwhile
    call avc_cabac_terminal(1)
    call avc_cabac_flush()
    #i_cabac_word =
    #(
    #    (
    #        (
    #            3 * h->cabac.i_sym_cnt - 3 * 96 * h->sps->i_mb_width * h->sps->i_mb_height
    #        )
    #        /32
    #    )
    #    - bs_pos( &h->out.bs)/8
    #)
    #/3
    sd cabac_word
    sd value
    setcall cabac_word avc_cabac_sym_cnt((value_get))
    mult cabac_word 3
    set value (3*96)
    mult value mb_width
    mult value mb_height
    sub cabac_word value
    div cabac_word 32

    #8 * ( s->p - s->p_start ) + 8 - s->i_left
    setcall value avc_output_size((value_get))

    #div value 8
    sub cabac_word value
    div cabac_word 3
    while cabac_word>0
        call avc_bs_write(0x0000,16)
        dec cabac_word
    endwhile
endfunction

function avc_cabac_flush()
    import "avc_cabac_putbit" avc_cabac_putbit
    sd value
    setcall value avc_cabac_low((value_get))
    setcall value sar(value,9)
    and value 1
    call avc_cabac_putbit(value)
    setcall value avc_cabac_low((value_get))
    setcall value sar(value,8)
    and value 1
    call avc_bs_write_bit(value)
    call avc_bs_write_bit(1)
    import "avc_bs_align_byte_with_0" avc_bs_align_byte_with_0
    call avc_bs_align_byte_with_0()
endfunction

import "avc_cabac_decision" avc_cabac_decision

function avc_cabac_skip(sd b_skip,sd x,sd y)
    sd ctx=0
    sd left
    sd top
    import "avc_mb_data" avc_mb_data
    if x>0
        sd left_type
        set left x
        dec left
        setcall left_type avc_mb_data((value_item),(avc_mb_type_offset),left,y)
        if left_type!=(avc_P_SKIP)
            inc ctx
        endif
    endif
    if y>0
        sd top_type
        set top y
        dec top
        setcall top_type avc_mb_data((value_item),(avc_mb_type_offset),x,top)
        if top_type!=(avc_P_SKIP)
            inc ctx
        endif
    endif

    add ctx 11
    call avc_cabac_decision(ctx,b_skip)
endfunction
