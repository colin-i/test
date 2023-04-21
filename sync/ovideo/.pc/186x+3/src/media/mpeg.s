
format elfobj


#MPEG-4 encoder

include "../_include/include.h"

import "shl" shl
import "shr" shr

const ARG_SLICES=1
const ARG_BQRATIO=150
const ARG_BQOFFSET=100
const ARG_MAXBFRAMES=2
const ARG_MAXKEYINTERVAL=300

const value_rgbtoyuv=value_custom
const value_endinterval=value_custom


##init

#bool
function mpeg_init(sd file,sd pixbufSample,sd totalframes)
    import "macro_blocks" macro_blocks

    data filemem#1
    set filemem 0
    data inputmem#1
    set inputmem 0
    data macroblocks#1
    set macroblocks 0

    call mpeg_start(file,pixbufSample)
    call mpeg_lastframe((value_set),totalframes)

    sd bool
    setcall bool mpeg_file_mem((value_set))
    if bool==1
        set filemem 1
        setcall bool mpeg_input_mem((value_set))
        if bool==1
            set inputmem 1
            setcall bool macro_blocks((value_set))
            if bool==1
                return 1
            endif
        endif
    endif

    if filemem==0
        return 0
    endif
    call mpeg_file_mem((value_unset))
    if inputmem==0
        return 0
    endif
    call mpeg_input_mem((value_unset))
    if macroblocks==0
        return 0
    endif
    call macro_blocks((value_unset))
    return 0
endfunction

#bool
function mpeg_encode(sd pixbuf,sd position,sd p_is_key_frame)
    data b#1
    data p_b^b
    sd bool
    setcall bool mpeg_write_frame(p_b,pixbuf,position,p_is_key_frame)
    return bool
endfunction

function mpeg_release()
    call mpeg_file_mem((value_unset))
    call mpeg_input_mem((value_unset))
    call macro_blocks((value_unset))
endfunction


function mpeg_lastframe(sd action,sd value)
    data lastframe#1
    if action==(value_set)
        dec value
        set lastframe value
    else
        return lastframe
    endelse
endfunction
function mpeg_start(sd file,sd pixbufSample)
    #store output file
    call mpeg_write_file((value_set),file)
    #store sizes
    sd w
    sd h
    sd wh^w
    import "pixbuf_get_wh" pixbuf_get_wh
    call pixbuf_get_wh(pixbufSample,wh)
    import "yuv_get_size" yuv_get_size
    sd size
    setcall size yuv_get_size(w,h)
        #get yuv size based on pixbuf and alloc the mpeg4 buffer, mult with 2 for safety
    mult size 2
    call mpeg_buffer_size((value_set),size,w,h)
    #init vlc tables
    import "mpeg_init_vlc" mpeg_init_vlc
    call mpeg_init_vlc()
    #init time
    call mpeg_time((value_set),0)
endfunction

const value_is_key=value_custom
function mpeg_ptr_is_keyframe(sd action,sd value)
    data ptr_is_keyframe#1
    if action==(value_set)
        set ptr_is_keyframe value
        set ptr_is_keyframe# 0
    else
        #if action==(value_is_key)
        set ptr_is_keyframe# 1
    endelse
endfunction

#bool
function mpeg_write_frame(sd p_bframes,sd argument,sd frameindex,sd p_is_key_frame)
    sd ind
    sd bool
    data sec#1
    data p_sec^sec
    data nth_sec#1
    data p_nth_sec^nth_sec
    data ivop_comeback#1
    data ivop_frameindex#1
    data ivop_pixbuf#1
    data ivop_wait_bframes#1

    ##bframes store data
    data bframes_counter#1
    const bframes_data_mix_size=3
    #seconds and nth_of_sec and pixbuf
    data bframes_store_data#ARG_MAXBFRAMES*bframes_data_mix_size
    data bframes_store^bframes_store_data

    ##set last frame
    sd framelast
    setcall framelast mpeg_lastframe((value_get))

    ##reset keyflag
    call mpeg_ptr_is_keyframe((value_set),p_is_key_frame)

    ##flush bframes
    if p_bframes==0
        set p_bframes argument

        if ivop_comeback==1
            if ivop_wait_bframes==0
                ##add passed frames
                call mpeg_time((value_append),ivop_frameindex)
                ##get new time
                setcall nth_sec mpeg_time((value_get),p_sec)
                ##write frame
                setcall bool mpeg_frame_object((I_VOP),sec,nth_sec,ivop_pixbuf,0)
                if bool!=1
                    return 0
                endif
                set p_bframes# 0
                return 1
            endif
        endif

        data flush_counter#1

        if bframes_counter!=0
        #bframe
            sd pbuf
            setcall pbuf mpeg_bframe_values(p_sec,p_nth_sec,bframes_store,flush_counter)
            setcall bool mpeg_frame((B_VOP),sec,nth_sec,pbuf,1)
            if bool!=1
                return 0
            endif
        else
        ##empty marker for divx5 decoder compatibility
            setcall bool mpeg_vop_header((P_VOP),0,0,0)
            if bool!=1
                return 0
            endif
            setcall bool mpeg_mem_pad((if_needed))
            if bool!=1
                return 0
            endif
        endelse

        #mpeg_file_mem((value_filewrite))

        if bframes_counter!=0
            dec bframes_counter
        else
            #flag to stop the container loop
            if ivop_comeback==1
                set ivop_wait_bframes 0
            else
                set p_bframes# 0
            endelse
        endelse

        return 1
    endif

    data key_interval#1

    ##set first frame inits
    set p_bframes# 0
    if frameindex==0
        set bframes_counter 0
        set key_interval 0
    endif

    ##input rgb check
    sd pixbuf
    set pixbuf argument

    sd width
    setcall width mpeg_image_w((value_get))
    sd height
    setcall height mpeg_image_h((value_get))
    import "rgb_sizes_test" rgb_sizes_test
    setcall bool rgb_sizes_test(width,height,pixbuf)
    if bool!=1
        return 0
    endif

    ##frame type and key_interval
    sd type=I_VOP
    if frameindex==0
    #first frame is intra
    elseif frameindex==framelast
    #last frame is prediction
        set type (P_VOP)
    elseif key_interval==(ARG_MAXKEYINTERVAL)
    #intra frame
    else
        import "me_analyze" me_analyze
        setcall type me_analyze()
        if type==(B_VOP)
            if bframes_counter==(ARG_MAXBFRAMES)
                #maximum bframes encounter
                set type (P_VOP)
            else
                #add passed frames and increment
                call mpeg_time((value_append),frameindex)
                #bframe
                sd bf_tm
                set ind bframes_counter
                mult ind (bframes_data_mix_size*int32)
                set bf_tm bframes_store
                add bf_tm ind
                sd sec_ptr
                set sec_ptr bf_tm
                add bf_tm (int32)
                setcall bf_tm# mpeg_time((value_get),sec_ptr)
                add bf_tm (int32)
                set bf_tm# pixbuf

                inc bframes_counter
            endelse
        endif
    endelse

    if type==(I_VOP)
        set key_interval 0
    endif
    inc key_interval
    if type==(B_VOP)
        return 1
    endif

    ##there are bframes to flush
    set ivop_comeback 0
    if bframes_counter!=0
        set p_bframes# 1
        set flush_counter 0
        if type==(I_VOP)
            #keep the values for when the i vop turn comes
            set ivop_frameindex frameindex
            set ivop_pixbuf pixbuf
            #get the last sec, nthsec and pixbuf from bframes
            sd last_b
            set last_b bframes_counter
            dec last_b
            setcall pixbuf mpeg_bframe_values(p_sec,p_nth_sec,bframes_store,last_b)
            set ivop_comeback 1
            dec bframes_counter
            set ivop_wait_bframes bframes_counter
            #last bframe becomes prediction
            set type (P_VOP)
        endif
    endif

    if ivop_comeback==0
        ##add passed frames
        call mpeg_time((value_append),frameindex)
        ##get new time
        setcall nth_sec mpeg_time((value_get),p_sec)
    endif

    ##write frame
    setcall bool mpeg_frame_object(type,sec,nth_sec,pixbuf,bframes_counter)
    if bool!=1
        return 0
    endif

    if bframes_counter!=0
    ##link the P_VOP with the first B_VOP
        setcall bool mpeg_write_frame(0,p_bframes)
        if bool!=1
            return 0
        endif
    endif

    return 1
endfunction

#pbuf
function mpeg_bframe_values(sd p_sec,sd p_nth_sec,sd bframes_store,sd flush_counter)
    import "array_get_int" array_get_int
    sd pbuf
    sd ind

    set ind flush_counter
    inc flush_counter
    mult ind (bframes_data_mix_size)

    setcall p_sec# array_get_int(bframes_store,ind)
    inc ind
    setcall p_nth_sec# array_get_int(bframes_store,ind)
    inc ind
    setcall pbuf array_get_int(bframes_store,ind)

    return pbuf
endfunction

#bool
function mpeg_frame_object(sd type,sd sec,sd nth_sec,sd pixbuf)
    sd bool
    ##set rounding type
    call mpeg_rounding_type((value_set),type)

    ##write frame
    setcall bool mpeg_frame(type,sec,nth_sec,pixbuf,1)
    if bool!=1
        return 0
    endif
    #mpeg_file_mem((value_filewrite))

    ##reset time interval
    call mpeg_time((value_endinterval))

    return 1
endfunction

#bool
function mpeg_frame(sd type,sd sec,sd nth_sec,sd pixbuf,sd vop_coded)
    sd bool

    ##headers
    if type==(I_VOP)
        #vol header
        setcall bool mpeg_vol_header()
        if bool!=1
            return 0
        endif

        setcall bool mpeg_mem_pad((if_needed))
        if bool!=1
            return 0
        endif

        #set the key frame flag for container
        call mpeg_ptr_is_keyframe((value_is_key))
    endif

    #vop header
    setcall bool mpeg_vop_header(type,vop_coded,sec,nth_sec)
    if bool!=1
        return 0
    endif

    ##
    ##frame blocks

    #rgb to rounded yuv
    importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
    sd bytes
    setcall bytes gdk_pixbuf_get_pixels(pixbuf)
    call mpeg_input_mem((value_rgbtoyuv),bytes)

    #(num_slices*1024 / num_threads)
    sd slices=ARG_SLICES*1024/1
    #((slices_per_thread + 512) >> 10)
    #sd start_y=ARG_SLICES-1/ARG_SLICES
    sd stop_y

    sd add
    set add slices
    add add 512
    setcall add shr(add,10)

    #bound=0
    #stop_y=(((bound+add) * mb_height + (num_slices-1)) / num_slices)
    sd mb_height
    setcall mb_height mpeg_image_h((value_get))
    add mb_height 15
    div mb_height 16
    set stop_y add
    mult stop_y mb_height
    add stop_y (ARG_SLICES-1)
    div stop_y (ARG_SLICES)

    sd mb_width
    setcall mb_width mpeg_image_w((value_get))
    add mb_width 15
    div mb_width 16

    #frame
    import "mpeg_frame_block" mpeg_frame_block
    setcall bool mpeg_frame_block(stop_y,mb_width,type)
    if bool!=1
        return 0
    endif

    return 1
endfunction


    const VIDOBJ_START_CODE=0x00000100
    const VIDOBJLAY_START_CODE=0x00000120
    const VISOBJSEQ_START_CODE=0x000001b0
    const USERDATA_START_CODE=0x000001b2
    const VISOBJ_START_CODE=0x000001b5
    const VOP_START_CODE=0x000001b6

#################################values functions

function mpeg_buffer_size(sd action,sd size,sd w,sd h)
    data buffer_size#1
    if action==(value_set)
        set buffer_size size
        call mpeg_image_w((value_set),w)
        call mpeg_image_h((value_set),h)
    else
        return buffer_size
    endelse
endfunction
function mpeg_image_w(sd action,sd w)
    data width#1
    if action==(value_set)
        set width w
    else
        return width
    endelse
endfunction
function mpeg_image_h(sd action,sd h)
    data height#1
    if action==(value_set)
        set height h
    else
        return height
    endelse
endfunction

import "memalloc" memalloc
importx "_free" free

##input

function mpeg_input_mem(sd action,ss rgb)
    data mem#1
    data temp_y#1
    data temp_u#1
    data temp_v#1
    data Y#1
    data U#1
    data V#1
    data width#1
    data height#1
    data rounded_width#1
    data rounded_height#1

    data memory#1
    data distance#1

    if action==(value_set)
    #bool
        sd size
        import "yuv_get_all_sizes" yuv_get_all_sizes
        setcall width mpeg_image_w((value_get))
        setcall height mpeg_image_h((value_get))
        sd p_temp_u^temp_u
        sd p_temp_v^temp_v
        setcall size yuv_get_all_sizes(width,height,p_temp_u,p_temp_v)

#######align at 16 bytes
        import "multiple_of_nr" multiple_of_nr
        setcall rounded_width multiple_of_nr(width,16)
        setcall rounded_height multiple_of_nr(height,16)
        sd p_U^U
        sd p_V^V
        sd roundedsize
        setcall roundedsize yuv_get_all_sizes(rounded_width,rounded_height,p_U,p_V)

        set Y size
        add U size
        add V size

        add size roundedsize

        #for reference image for inter frames comparisons
        set distance size
        mult size 2

        setcall mem memalloc(size)
        if mem==0
            return 0
        endif

        #memory is for freeing regardless the reference
        set memory mem

        set temp_y mem
        add temp_u mem
        add temp_v mem

        add Y mem
        add U mem
        add V mem

        return 1
    elseif action==(value_rgbtoyuv)
        #place the cursor on one of the two images
        add mem distance
        add temp_y distance
        add temp_u distance
        add temp_v distance
        add Y distance
        add U distance
        add V distance

        mult distance -1

        call mpeg_input_y((value_set),Y,distance)
        call mpeg_input_u((value_set),U,distance)
        call mpeg_input_v((value_set),V,distance)

        sd temp_width_crom
        sd temp_height_crom
        sd width_crom
        sd height_crom

        set temp_width_crom width
        div temp_width_crom 2
        set temp_height_crom height
        div temp_height_crom 2
        set width_crom rounded_width
        div width_crom 2
        set height_crom rounded_height
        div height_crom 2

        import "rgb_to_yuvi420" rgb_to_yuvi420
        call rgb_to_yuvi420(rgb,mem,width,height)

        call yuv_rounding(temp_y,Y,width,height,rounded_width,rounded_height)
        call yuv_rounding(temp_u,U,temp_width_crom,temp_height_crom,width_crom,height_crom)
        call yuv_rounding(temp_v,V,temp_width_crom,temp_height_crom,width_crom,height_crom)

        call mpeg_input_lumstride((value_set),rounded_width)
        call mpeg_input_cromstride((value_set),width_crom)
    else
    #if action==(value_unset)
        call free(memory)
    endelse
endfunction
function mpeg_input_y(sd action,sd value,sd distance)
    data y#1
    data y_ref#1
    if action==(value_set)
        set y value
        set y_ref y
        add y_ref distance
    elseif action==(value_get)
        return y
    else
    #if action==(value_get_prev)
        return y_ref
    endelse
endfunction
function mpeg_input_u(sd action,sd value,sd distance)
    data u#1
    data u_ref#1
    if action==(value_set)
        set u value
        set u_ref u
        add u_ref distance
    elseif action==(value_get)
        return u
    else
    #if action==(value_get_prev)
        return u_ref
    endelse
endfunction
function mpeg_input_v(sd action,sd value,sd distance)
    data v#1
    data v_ref#1
    if action==(value_set)
        set v value
        set v_ref v
        add v_ref distance
    elseif action==(value_get)
        return v
    else
    #if action==(value_get_prev)
        return v_ref
    endelse
endfunction
function mpeg_input_lumstride(sd action,sd value)
    data lumstride#1
    if action==(value_set)
        set lumstride value
    else
        return lumstride
    endelse
endfunction
function mpeg_input_cromstride(sd action,sd value)
    data cromstride#1
    if action==(value_set)
        set cromstride value
    else
        return cromstride
    endelse
endfunction
function yuv_rounding(ss src_plane,ss dest_plane,sd src_w,sd src_h,sd dest_w,sd dest_h)
    sd j=0
    sd last_i
    sd src_cursor
    while j!=dest_h
        if j<src_h
            set src_cursor src_plane
        else
            set src_plane src_cursor
        endelse
        sd i=0
        while i!=dest_w
            if i<src_w
                set last_i src_plane#
                inc src_plane
            endif
            set dest_plane# last_i
            inc dest_plane
            inc i
        endwhile
        inc j
    endwhile
endfunction

##write

function mpeg_write_file(sd action,sd value)
    data file#1
    if action==(value_set)
        set file value
    else
        return file
    endelse
endfunction

import "file_write" file_write

#bool
function mpeg_write(sd buffer,sd size)
    sd file
    setcall file mpeg_write_file((value_get))
    sd err
    setcall err file_write(buffer,size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

function mpeg_file_mem_append(sd append,sd append_bits)
    sd bool
    setcall bool mpeg_file_mem((value_append),append,append_bits)
    return bool
endfunction

####output memory

function mpeg_file_mem(sd action,sd append,sd append_bits)
    data mem#1
    data size#1
    data all_size#1

    data bits#1
    data bits_pos#1

    data p_size^size
    sd bool

    if action==(value_set)
    #bool
        set size 0
        set bits 0
        set bits_pos 0

        setcall all_size mpeg_buffer_size((value_get))
        setcall mem memalloc(all_size)
        if mem==0
            return 0
        endif
        return 1
    elseif action==(value_get)
        return bits_pos
    elseif action==(value_unset)
        call free(mem)
    elseif action==(value_append)
    #bool
        import "neg" neg

        sd dif
        sd bits_count

        sd loop=1
        while loop==1
            #32-bitsPos-appendBits
            sd shift
            set shift 32
            sub shift bits_pos
            sub shift append_bits
            #
            if shift>=0
                orCall bits shl(append,shift)
                set bits_count append_bits
            else
                setcall dif neg(shift)
                orCall bits shr(append,dif)
                set bits_count append_bits
                sub bits_count dif
            endelse

            add bits_pos bits_count
            sub append_bits bits_count

            if bits_pos==32
                setcall bool mpeg_outbuffer_add(p_size,all_size,bits,mem,4)
                if bool!=1
                    return 0
                endif
                set bits 0
                set bits_pos 0
            endif
            if append_bits==0
                set loop 0
            endif
        endwhile
        return 1
    else
    #if action==(value_filewrite)
    #bool
        if bits_pos!=0
            sd bytes_add
            set bytes_add bits_pos
            add bytes_add 7
            div bytes_add 8
            setcall bool mpeg_outbuffer_add(p_size,all_size,bits,mem,bytes_add)
            if bool!=1
                return 0
            endif
        endif
        setcall bool mpeg_write(mem,size)

        #reset the counters and the bits store for other frames
        set size 0
        set bits 0
        set bits_pos 0

        return bool
    endelse
endfunction

#bool
function mpeg_outbuffer_add(sd p_size,sd all_size,sd bits,sd buffer,sd add_size)
    sd size
    set size p_size#
    add size add_size
    if size>all_size
        str sizerr="Size error"
        import "texter" texter
        call texter(sizerr)
        return 0
    endif

    #transform to big endian
    import "dword_reverse" dword_reverse
    setcall bits dword_reverse(bits)
    add buffer p_size#
    set buffer# bits

    set p_size# size

    return 1
endfunction


#bool
function mpeg_mem_pad(sd mode)
    sd bits_pos
    setcall bits_pos mpeg_file_mem((value_get))
    sd pad
    sd pad_rest
    import "rest" rest
    setcall pad_rest rest(bits_pos,8)
    set pad 8
    sub pad pad_rest

    if mode==(if_needed)
        if pad==8
            return 1
        endif
    endif
    data stuff={0,1,3,7,0xf,0x1f,0x3f,0x7f}
    sd value
    set value pad
    dec value
    mult value 4
    sd p_stuff^stuff
    add p_stuff value

    sd bool
    setcall bool mpeg_file_mem_append(p_stuff#,pad)
    return bool
endfunction

#bool
function mpeg_mem_bit(sd value)
    sd bool
    setcall bool mpeg_file_mem_append(value,1)
    return bool
endfunction

#bool
function mpeg_mem_marker()
    sd bool
    setcall bool mpeg_file_mem_append(1,1)
    return bool
endfunction

#bool
function mpeg_mem_userdata(ss string)
    sd bool
    setcall bool mpeg_mem_pad((if_needed))
    if bool!=1
        return 0
    endif
    setcall bool mpeg_file_mem_append((USERDATA_START_CODE),32)
    if bool!=1
        return 0
    endif
    import "slen" slen
    sd len
    setcall len slen(string)
    while len!=0
        setcall bool mpeg_file_mem_append(string#,8)
        if bool!=1
            return 0
        endif
        inc string
        dec len
    endwhile
    return 1
endfunction

##time

import "stage_file_options_fps" stage_file_options_fps

function mpeg_time(sd action,sd arg)
    #store the frames interval and process the time
    data begin#1
    data end#1
    if action==(value_set)
        set begin 0
        set end 0
    elseif action==(value_get)
    #nth_of_sec return
        sd p_sec
        set p_sec arg
        #
        sd framesstack
        set framesstack end
        sub framesstack begin
        sd fps
        setcall fps stage_file_options_fps()
        sd sec
        set sec framesstack
        div sec fps
        set p_sec# sec
        mult sec fps
        sd nth_of_sec
        set nth_of_sec framesstack
        sub nth_of_sec sec
        return nth_of_sec
    elseif action==(value_append)
        set end arg
    else
    #if action==(value_endinterval)
    #set the new start for the new interval
        set begin end
    endelse
endfunction

function mpeg_get_quant(sd type)
    sd quant
    set quant (DEFAULT_QUANT)
    if type==(B_VOP)
        add quant (DEFAULT_QUANT)
        mult quant (ARG_BQRATIO)
        div quant 2
        add quant (ARG_BQOFFSET)
        div quant 100
    endif
    return quant
endfunction

function mpeg_fixcode(sd mv)
    sd fcode=1
    while 1==1
        sd value
        setcall value shl(16,fcode)
        if value>mv
            return fcode
        endif
        inc fcode
    endwhile
    return fcode
endfunction

##rounding
function mpeg_rounding_type(sd action,sd type)
    data rounding#1
    if action==(value_set)
        if type==(I_VOP)
            set rounding 1
        else
        #P_VOP
            sd value
            set value rounding
            set rounding 1
            sub rounding value
        endelse
    else
        return rounding
    endelse
endfunction

##################misc funcs
function log2bin(sd value)
    chars log2={0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4}
    sd n=0
    sd x
    set x value
    and x 0xffff0000
    if x!=0
        setcall value shr(value,16)
        add n 16
    endif
    set x value
    and x 0xff00
    if x!=0
        setcall value shr(value,8)
        add n 8
    endif
    set x value
    and x 0xf0
    if x!=0
        setcall value shr(value,4)
        add n 4
    endif
    ss log^log2
    add log value
    add n log#
    return n
endfunction

function log2_resolution()
    sd bits

    sd fps
    setcall fps stage_file_options_fps()
    dec fps

    setcall bits log2bin(fps)

    import "get_higher" get_higher
    setcall bits get_higher(bits,1)
    return bits
endfunction

###########################################VOL header

#bool
function mpeg_vol_header()
    const VISOBJ_TYPE_VIDEO=1
    #const VIDOBJLAY_TYPE_SIMPLE=1
    const VIDOBJLAY_TYPE_ASP=17

    const Profile_Unrestricted=0xf5
    const vo_id=0
    const vol_id=0
    #const vol_ver_id=1
    #1:1 vga (square), default if supplied PAR is not a valid value
    const XVID_PAR_11_VGA=1

    sd bool

    #VOS header
    setcall bool mpeg_file_mem_append((VISOBJSEQ_START_CODE),32)
    if bool!=1
        return 0
    endif
    chars vol_profile=Profile_Unrestricted
    setcall bool mpeg_file_mem_append(vol_profile,8)
    if bool!=1
        return 0
    endif
    #byte padded

    #Visual Object start code
    setcall bool mpeg_mem_pad((if_needed))
    if bool!=1
        return 0
    endif
    setcall bool mpeg_file_mem_append((VISOBJ_START_CODE),32)
    if bool!=1
        return 0
    endif
    #visual_object_identifier=0
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif

    #Video type
    setcall bool mpeg_file_mem_append((VISOBJ_TYPE_VIDEO),4)
    if bool!=1
        return 0
    endif
    #video_signal_type
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif

    #video object start code & vo_id
    setcall bool mpeg_mem_pad((always))
    if bool!=1
        return 0
    endif
    setcall bool mpeg_file_mem_append((vo_id&0x5|VIDOBJ_START_CODE),32)
    if bool!=1
        return 0
    endif

    #video_object_layer_start_code & vol_id
    setcall bool mpeg_mem_pad((if_needed))
    if bool!=1
        return 0
    endif
    setcall bool mpeg_file_mem_append((vol_id&0x4|VIDOBJLAY_START_CODE),32)
    if bool!=1
        return 0
    endif

        #random_accessible_vol
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif
        #video_object_type_indication
    setcall bool mpeg_file_mem_append((VIDOBJLAY_TYPE_ASP),8)
    if bool!=1
        return 0
    endif

        #if vol_ver_id=1
        #is_object_layer_identified (0=not given)
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif

    #aspect ratio
    setcall bool mpeg_file_mem_append((XVID_PAR_11_VGA),4)
    if bool!=1
        return 0
    endif

    #vol_control_parameters
    setcall bool mpeg_file_mem_append(1,1)
    if bool!=1
        return 0
    endif

    #chroma_format 1="4:2:0"
    setcall bool mpeg_file_mem_append(1,2)
    if bool!=1
        return 0
    endif

    #low_delay
    #if max_bframes > 0,ARG_MAXBFRAMES=2
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif

    #vbv_parameters (0=not given)
    setcall bool mpeg_file_mem_append(0,1)
    if bool!=1
        return 0
    endif

    #video_object_layer_shape (0=rectangular)
    setcall bool mpeg_file_mem_append(0,2)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif

    #time_inc_resolution

    #framerate
    #ARG_DWRATE
    sd fps
    setcall fps stage_file_options_fps()
    setcall bool mpeg_file_mem_append(fps,16)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif

    #frame inc
    #ARG_DWSCALE=1

    #fixed_vop_rate = 1
    setcall bool mpeg_mem_bit(1)
    if bool!=1
        return 0
    endif

    #fixed_vop_time_increment
    sd bits
    setcall bits log2_resolution()
    setcall bool mpeg_file_mem_append(1,bits)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif
    #width
    sd w
    setcall w mpeg_image_w((value_get))
    setcall bool mpeg_file_mem_append(w,13)
    if bool!=1
        return 0
    endif
    #
    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif
    #height
    sd h
    setcall h mpeg_image_h((value_get))
    setcall bool mpeg_file_mem_append(h,13)
    if bool!=1
        return 0
    endif
    #
    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif

    #interlace
    #const XVID_VOL_INTERLACING=(1<<5)
    #vol_flags=0
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif
    #obmc_disable (overlapped block motion compensation)
    setcall bool mpeg_mem_bit(1)
    if bool!=1
        return 0
    endif

    #sprite_enable==off
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    #not_8_bit
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    #quant_type   0=h.263  1=mpeg4(quantizer tables)
    #XVID_VOL_MPEGQUANT=(1<<0),vol_flags=0
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    #complexity_estimation_disable
    setcall bool mpeg_mem_bit(1)
    if bool!=1
        return 0
    endif

    #resync_marker_disabled
    setcall bool mpeg_mem_bit((ARG_SLICES))
    if bool!=1
        return 0
    endif

    #data_partitioned
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    #scalability
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_pad((always))
    if bool!=1
        return 0
    endif

    #packed bitstream
    const XVID_GLOBAL_PACKED=2$0
    #closed_gop:	was DX50BVOP dx50 bvop compatibility
    const XVID_GLOBAL_CLOSED_GOP=2$1
    #write divx5 userdata string,this is implied if XVID_GLOBAL_PACKED is set
    const XVID_GLOBAL_DIVX5_USERDATA=2$5
    sd global_flags=XVID_GLOBAL_PACKED|XVID_GLOBAL_CLOSED_GOP|XVID_GLOBAL_DIVX5_USERDATA
    sd flags
    set flags global_flags
    and flags (XVID_GLOBAL_DIVX5_USERDATA)
    if flags!=0
        str sign="OApplications"
        #str divx="DivX503b1393"
        setcall bool mpeg_mem_userdata(sign)
        if bool!=1
            return 0
        endif
        #if max_bframes > 0,ARG_MAXBFRAMES=2
        chars p="p"
        set flags global_flags
        and flags (XVID_GLOBAL_PACKED)
        if flags!=0
            setcall bool mpeg_file_mem_append(p,8)
            if bool!=1
                return 0
            endif
        endif
    endif

    #"VOP" flags
#define XVID_VOP_DEBUG                (1<< 0) /* print debug messages in frames */
    #use halfpel interpolation
    #const XVID_VOP_HALFPEL=2$1
    #use 4 motion vectors per MB
    #const XVID_VOP_INTER4V=2$2
    #use trellis based R-D "optimal" quantization
    #const XVID_VOP_TRELLISQUANT=2$3
#define XVID_VOP_CHROMAOPT            (1<< 4) /* enable chroma optimization pre-filter */
#define XVID_VOP_CARTOON              (1<< 5) /* use 'cartoon mode' */
#define XVID_VOP_GREYSCALE            (1<< 6) /* enable greyscale only mode (even for  color input material chroma is ignored) */
    #high quality ac prediction
    #const XVID_VOP_HQACPRED=2$7
    #enable DCT-ME and use it for mode decision
    #const XVID_VOP_MODEDECISION_RD=2$8
#define XVID_VOP_FAST_MODEDECISION_RD (1<<12) /* use simplified R-D mode decision */
#define XVID_VOP_RD_BVOP              (1<<13) /* enable rate-distortion mode decision in b-frames */
#define XVID_VOP_RD_PSNRHVSM          (1<<14) /* use PSNR-HVS-M as metric for rate-distortion optimizations */
    #sd vop_flags=XVID_VOP_HALFPEL|XVID_VOP_INTER4V|XVID_VOP_TRELLISQUANT|XVID_VOP_HQACPRED|XVID_VOP_MODEDECISION_RD

    #str xvid="XviD0064"
    str signature="OApplications"
    setcall bool mpeg_mem_userdata(signature)
    if bool!=1
        return 0
    endif

    return 1
endfunction


############vop header
#bool
function mpeg_vop_header(sd type,sd vop_coded,sd seconds,sd nth_of_sec)
    sd bool
    setcall bool mpeg_file_mem_append((VOP_START_CODE),32)
    if bool!=1
        return 0
    endif

#intra,prediction,backward
#define I_VOP	0
#define P_VOP	1
#define B_VOP	2
    setcall bool mpeg_file_mem_append(type,2)
    if bool!=1
        return 0
    endif

    #time
    #frame seconds
    sd i=0
    while i<seconds
        setcall bool mpeg_mem_bit(1)
        if bool!=1
            return 0
        endif
        inc i
    endwhile
        #termination
    setcall bool mpeg_mem_bit(0)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif

    #nth of sec(of fps)
    sd bits
    setcall bits log2_resolution()
    setcall bool mpeg_file_mem_append(nth_of_sec,bits)
    if bool!=1
        return 0
    endif

    setcall bool mpeg_mem_marker()
    if bool!=1
        return 0
    endif

    #not vop_coded
    if vop_coded==0
        setcall bool mpeg_mem_bit(0)
        if bool!=1
            return 0
        endif
        return 1
    endif

    #vop_coded
    setcall bool mpeg_mem_bit(1)
    if bool!=1
        return 0
    endif

    #(frame->coding_type == P_VOP) || (frame->coding_type == S_VOP)
    if type==(P_VOP)
        #rounding_type
        sd rounding
        setcall rounding mpeg_rounding_type((value_get))
        setcall bool mpeg_mem_bit(rounding)
        if bool!=1
            return 0
        endif
    endif

    #intra_dc_vlc_threshold
    setcall bool mpeg_file_mem_append(0,3)
    if bool!=1
        return 0
    endif

    #frame->vol_flags & XVID_VOL_INTERLACING

    #frame->coding_type == S_VOP

    #quantizer
    sd quant
    setcall quant mpeg_get_quant(type)
    setcall bool mpeg_file_mem_append(quant,5)
    if bool!=1
        return 0
    endif

    if type!=(I_VOP)
    #forward_fixed_code
        sd fcode
        setcall fcode mpeg_fixcode(0)
        setcall bool mpeg_file_mem_append(fcode,3)
        if bool!=1
            return 0
        endif

        if type==(B_VOP)
    #backward_fixed_code
            sd bcode
            setcall bcode mpeg_fixcode(0)
            setcall bool mpeg_file_mem_append(bcode,3)
            if bool!=1
                return 0
            endif
        endif
    endif

    return 1
endfunction




##########options
function mpeg_options(sd mem,sd *size)
    sd value
    sd p_value^value
    sd mem_sz^mem
    import "get_mem_int_advance" get_mem_int_advance
    sd err

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call mpeg_single_tolerance((value_set),value)

    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call mpeg_group_tolerance((value_set),value)
endfunction

function mpeg_single_tolerance(sd action,sd value)
    data single_tolerance#1
    if action==(value_set)
        set single_tolerance value
    else
        return single_tolerance
    endelse
endfunction
function mpeg_group_tolerance(sd action,sd value)
    data group_tolerance#1
    if action==(value_set)
        set group_tolerance value
    else
        return group_tolerance
    endelse
endfunction

function mpeg_settings_init(sd vbox,sd *dialog)
    import "hscalefield" hscalefield
    sd scale
    sd value
    import "hboxfield_cnt" hboxfield_cnt
    sd hbox
    import "labelfield_left_default" labelfield_left_default

    str s="Single Tolerance: "
    setcall hbox hboxfield_cnt(vbox)
    call labelfield_left_default(s,hbox)
    setcall value mpeg_single_tolerance((value_get))
    setcall scale hscalefield(hbox,0,255,1,value)
    call mpeg_single_scale((value_set),scale)

    str g="Group Tolerance: "
    setcall hbox hboxfield_cnt(vbox)
    call labelfield_left_default(g,hbox)
    setcall value mpeg_group_tolerance((value_get))
    setcall scale hscalefield(hbox,0,256,1,value)
    call mpeg_group_scale((value_set),scale)
endfunction
function mpeg_settings_set()
    import "file_write_forward_sys_folder_enter_leave" file_write_forward_sys_folder_enter_leave
    data forw_mpeg^mpeg_settings_set_write
    import "mpeg_file" mpeg_file
    ss mpeg_fl_str
    setcall mpeg_fl_str mpeg_file()
    call file_write_forward_sys_folder_enter_leave(mpeg_fl_str,forw_mpeg)
endfunction

function mpeg_settings_set_write(sd mpeg_fl)
    import "hscale_get" hscale_get
    sd value
    sd scale
    sd p_value^value

    setcall scale mpeg_single_scale((value_get))
    setcall value hscale_get(scale)
    call mpeg_single_tolerance((value_set),value)

    call file_write(p_value,4,mpeg_fl)

    setcall scale mpeg_group_scale((value_get))
    setcall value hscale_get(scale)
    call mpeg_group_tolerance((value_set),value)

    call file_write(p_value,4,mpeg_fl)
endfunction

function mpeg_single_scale(sd action,sd value)
    data single_scale#1
    if action==(value_set)
        set single_scale value
    else
        return single_scale
    endelse
endfunction
function mpeg_group_scale(sd action,sd value)
    data group_scale#1
    if action==(value_set)
        set group_scale value
    else
        return group_scale
    endelse
endfunction
