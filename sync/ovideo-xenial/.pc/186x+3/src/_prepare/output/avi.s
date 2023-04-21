


format elfobj
include "../../_include/include.h"


Const AVIF_HASINDEX=0x00000010
#Const AVIF_MUSTUSEINDEX=0x00000020
Const AVIF_ISINTERLEAVED=0x00000100

Const AVIIF_KEYFRAME=0x00000010

const WAVE_FORMAT_PCM=1

import "av_dialog_run" av_dialog_run
import "av_dialog_close" av_dialog_close
import "av_dialog_stop" av_dialog_stop

import "stage_sound_sizedone" stage_sound_sizedone
import "stage_sound_alloc_getremainingsize" stage_sound_alloc_getremainingsize

#w_r, writeseek; means a function used at write and at read, at read it seeks instead of writes

import "av_readwrite_value" av_readwrite_value

#write

import "stage_file_get_avi_encoder" stage_file_get_avi_encoder

import "cmpmem" cmpmem

#bool
function is_local_avi()
    import "stage_file_get_format" stage_file_get_format
    sd format
    setcall format stage_file_get_format()
    str avi="avi"
    sd cmp
    setcall cmp cmpmem(format,avi,3)
    if cmp==(equalCompare)
        sd encoder
        setcall encoder stage_file_get_avi_encoder()
        if encoder!=(format_avi_raw)
            return 1
        endif
    endif
    return 0
endfunction
importx "_free" free
#location
function aviwrite(sd combo_flag,sd data)
    #get file path
    import "combo_location" combo_location
    sd location
    setcall location combo_location(combo_flag,data)

    call avi_write_fname(location,(avi_new))

    return location
endfunction

function avi_write_fname(ss location,sd expand)
    #new file or expand file
    call avi_expandvalue((value_set),expand)
    sd method
    if expand==(avi_new)
        str w="w+b"
        set method w
    else
        str rw="r+b"
        set method rw
    endelse

    #init readwrite value
    call av_readwrite_value((value_set),(write_file))
    #init frames
    import "av_frames" av_frames
    call av_frames((value_set),0)

    #inits
    sd bool
    setcall bool avi_index_mem((value_set))
    if bool==0
        return 0
    endif

    #open file and continue at forward
    import "file_forward" file_forward
    sd forward^avidialog
    sd err
    setcall err file_forward(location,method,forward)

    #frees
    call avi_index_mem((value_unset))

    #
    if err==(noerror)
        import "save_inform_saved" save_inform_saved
        call save_inform_saved(location)
    endif
endfunction

#read

import "stage_read_values" stage_read_values

function aviread(ss filepath)
    #write_read flag
    call av_readwrite_value((value_set),(read_file))

    #values init
    sd bool
    setcall bool stage_read_values((value_set))
    if bool!=1
        return 0
    endif

    import "file_forward_read" file_forward_read
    data f^avidialog
    call file_forward_read(filepath,f)

    #values write and free
    call stage_read_values((value_write))
    call stage_read_values((value_unset))
endfunction

#

#expand

function avi_expandvalue(sd action,sd value)
    data expandvalue#1
    if action==(value_set)
        set expandvalue value
    else
        return expandvalue
    endelse
endfunction

#

import "riff_chunk_w_r" riff_chunk_w_r
import "riff_w_r_name" riff_w_r_name

##read/write start

#er
function avidialog(sd file)
    #encoder inits
    sd bool
    data f^avicontent
    setcall bool av_dialog_run(f,file)
    if bool!=1
        return (error)
    endif
    return (noerror)
endfunction



#bool
function avicontent(sd file)
    ss riff="RIFF"
    data f^aviriff
    sd bool
    setcall bool riff_chunk_w_r(file,f,riff)
    call av_dialog_close()
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function aviriff(sd file)
    ss avi="AVI "
    sd bool
    setcall bool riff_w_r_name(file,avi)
    if bool!=1
        return 0
    endif
    #

    #header list
    ss list="LIST"
    data f^avi_hdrl
    setcall bool riff_chunk_w_r(file,f,list)
    if bool!=1
        return 0
    endif

    sd io
    sd encoder
    setcall io av_readwrite_value((value_get))
    if io==(write_file)
        setcall encoder stage_write_avi_encoder((value_get))
        if encoder==(format_avi_xvid)
            import "stage_mpeg_init" stage_mpeg_init
            setcall bool stage_mpeg_init(file)
            if bool!=1
                return (error)
            endif
        endif
    endif
    setcall bool avi_movi_index(file)
    if io==(write_file)
        if encoder==(format_avi_xvid)
            import "mpeg_release" mpeg_release
            call mpeg_release()
        endif
    endif
    return bool
endfunction

#bool
function avi_movi_index(sd file)
    sd bool

    #movi list
    ss list="LIST"
    sd io
    setcall io av_readwrite_value((value_get))
    call avi_movi_flag((value_set),io)
    if io==(write_file)
        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_expand)
            call av_readwrite_value((value_set),(read_file))
        endif
    endif
    data m_f^avi_movi
    setcall bool riff_chunk_w_r(file,m_f,list)
    if bool!=1
        return 0
    endif

    #index
    ss index="idx1"
    data ind_f^avi_index
    setcall bool riff_chunk_w_r(file,ind_f,index)
    if bool!=1
        return 0
    endif
    return 1
endfunction

##
#bool
function avi_hdrl(sd file)
    sd bool

    ss hdrl="hdrl"
    setcall bool riff_w_r_name(file,hdrl)
    if bool==0
        return 0
    endif
    #

    #avi header
    ss avih="avih"
    data h_f^avi_avih
    setcall bool riff_chunk_w_r(file,h_f,avih)
    if bool==0
        return 0
    endif

    #video stream
    ss list="LIST"
    data strl_f^avi_streamlist
    setcall bool riff_chunk_w_r(file,strl_f,list)
    if bool==0
        return 0
    endif

    #audio stream
    sd audio=0
    sd is_from_read=1
    sd w_r
    setcall w_r av_readwrite_value((value_get))
    if w_r==(write_file)
        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_new)
            sd sz
            setcall sz stage_sound_alloc_getremainingsize()
            if sz!=0
                set audio 1
            endif
            set is_from_read 0
        endif
    endif
    if is_from_read==1
        sd streams
        setcall streams avi_read_streams((value_get))
        if streams==2
            set audio 1
        endif
    endif
    if audio==1
        data f_audio^avi_strl_audio
        setcall bool riff_chunk_w_r(file,f_audio,list)
        if bool!=1
            return 0
        endif
    endif

    #odml header
    data odml_f^avi_odml
    setcall bool riff_chunk_w_r(file,odml_f,list)
    if bool==0
        return 0
    endif

    return 1
endfunction

import "av_frames_mainpixbuf_sizes" av_frames_mainpixbuf_sizes
import "stage_file_options_fps" stage_file_options_fps
import "stage_frame_time_numbers" stage_frame_time_numbers
import "file_write" file_write
import "file_read" file_read
import "file_read_and_back_with_intervening_call" file_read_and_back_with_intervening_call

#AVIMAINHEADER

#bool
function avi_avih(sd file)
    data dwMicroSecPerFrame#1
    #max(sum of file bytes/sec)
    data dwMaxBytesPerSec#1
    #entries pad=0
    data dwPaddingGranularity#1
    data dwFlags#1
    data dwTotalFrames#1
    #initial frames=0
    data dwInitialFrames#1
    data dwStreams#1
    #playback buffer size
    data dwSuggestedBufferSize#1
    data dwWidth#1
    data dwHeight#1
    data *dwReserved#4

    data AVIMAINHEADER^dwMicroSecPerFrame

    const _AVIMAINHEADER^dwMicroSecPerFrame
    const AVIMAINHEADER_^AVIMAINHEADER
    data size=AVIMAINHEADER_-_AVIMAINHEADER

    sd w_r
    sd err
    setcall w_r av_readwrite_value((value_get))

    if w_r==(write_file)
        #sound init
        call stage_sound_sizedone((value_set),0)

        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_new)
            set dwPaddingGranularity 0
            set dwInitialFrames 0

            sd wh^dwWidth

            set dwMicroSecPerFrame (1000*1000)
            sd fps
            setcall fps stage_file_options_fps()
            div dwMicroSecPerFrame fps

            setcall dwMaxBytesPerSec av_frames_mainpixbuf_sizes(wh)
            mult dwMaxBytesPerSec 2
            set dwSuggestedBufferSize dwMaxBytesPerSec

            set dwFlags (AVIF_HASINDEX)

            #dwTotalFrames: new 0+frames
            set dwTotalFrames 0

            set dwStreams 1
            #sound write verification
            #get the size
            sd sound_size
            setcall sound_size stage_sound_alloc_getremainingsize()
            if sound_size!=0
                inc dwStreams
            endif
        else
            #avi_expand
            setcall err file_read_and_back_with_intervening_call(AVIMAINHEADER,size,file)
            if err!=(noerror)
                return 0
            endif
            #flags
            if dwStreams==2
                or dwFlags (AVIF_ISINTERLEAVED)
            endif
            #set the number of streams
            call avi_read_streams((value_set),dwStreams)
        endelse
        #add the frames
        addcall dwTotalFrames stage_frame_time_numbers((stage_frame_time_total_sum))
        #write to file
        setcall err file_write(AVIMAINHEADER,size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_read(AVIMAINHEADER,size,file)
        if err!=(noerror)
            return 0
        endif
        call avi_read_width((value_set),dwWidth)
        call avi_read_height((value_set),dwHeight)
        call avi_read_streams((value_set),dwStreams)
    endelse

    return 1
endfunction


function avi_streamlist(sd file)
    sd bool

    ss strl="strl"
    setcall bool riff_w_r_name(file,strl)
    if bool==0
        return 0
    endif
    #
    ss strh="strh"
    data strh_f^avi_streamheader
    setcall bool riff_chunk_w_r(file,strh_f,strh)
    if bool==0
        return 0
    endif

    ss strf="strf"
    data strf_f^avi_streamformat
    setcall bool riff_chunk_w_r(file,strf_f,strf)
    if bool==0
        return 0
    endif

    return 1
endfunction

import "cpymem" cpymem

#AVISTREAMHEADER

#bool
function avi_streamheader(sd file)
    data fccType#1
    data fccHandler#1
    data dwFlags#1
    data wPriority_wLanguage#1
    data dwInitialFrames#1
    data dwScale#1
    #dwRate/dwScale=fps
    data dwRate#1
    data dwStart#1
    data dwLength#1
    data dwSuggestedBufferSize#1
    data dwQuality#1
    data dwSampleSize#1
    data left_top#1
    data right_bottom#1

    data AVISTREAMHEADER^fccType

    const _AVISTREAMHEADER^fccType
    const AVISTREAMHEADER_^AVISTREAMHEADER
    data size=AVISTREAMHEADER_-_AVISTREAMHEADER

    str fcc^fccHandler

    sd err
    sd enc

    sd w_r
    setcall w_r av_readwrite_value((value_get))

    if w_r==(write_file)
        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_new)
            str vds="vids"
            call cpymem(AVISTREAMHEADER,vds,4)

            set dwFlags 0
            set wPriority_wLanguage 0
            set dwInitialFrames 0
            set dwScale 1
            set dwStart 0
            set dwQuality -1
            set dwSampleSize 0
            set left_top 0

            setcall dwRate stage_file_options_fps()
            set dwLength 0

            sd w
            sd h
            sd wh^w

            setcall dwSuggestedBufferSize av_frames_mainpixbuf_sizes(wh)
            set right_bottom w
            mult h 0x10000
            or right_bottom h

            setcall enc stage_file_get_avi_encoder()
        else
            setcall err file_read_and_back_with_intervening_call(AVISTREAMHEADER,size,file)
            if err!=(noerror)
                return 0
            endif

            setcall enc avi_video_fcc((value_get),fcc)
        endelse
        call stage_write_avi_encoder((value_set),enc)
        if expand==(avi_new)
            call avi_video_fcc((value_set),fcc)
        endif

        addcall dwLength stage_frame_time_numbers((stage_frame_time_total_sum))

        setcall err file_write(AVISTREAMHEADER,size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_read(AVISTREAMHEADER,size,file)
        if err!=(noerror)
            return 0
        endif

        import "av_good_fps" av_good_fps
        data p_dwRate^dwRate
        call av_good_fps(p_dwRate)
        call avi_read_fps((value_set),dwRate)

        setcall enc avi_video_fcc((value_get),fcc)
        call avi_read_encoder((value_set),enc)
    endelse
    return 1
endfunction

function avi_video_fcc(sd action,ss fcc)
    if action==(value_set)
        str i420="I420"
        str jpg="MJPG"
        str xvid="XVID"

        sd encoder

        setcall encoder stage_write_avi_encoder((value_get))
        if encoder==(format_avi_i420)
            call cpymem(fcc,i420,4)
        elseif encoder==(format_avi_mjpg)
            call cpymem(fcc,jpg,4)
        else
        #if encoder==(format_avi_xvid)
            call cpymem(fcc,xvid,4)
        endelse
    else
        sd compare

        setcall compare cmpmem(fcc,i420,4)
        if compare==(equalCompare)
            return (format_avi_i420)
        endif
        setcall compare cmpmem(fcc,jpg,4)
        if compare==(equalCompare)
            return (format_avi_mjpg)
        endif
        return (format_avi_xvid)
    endelse
endfunction

#bool
function avi_streamformat(sd file)
    data biSize=40
    data biWidth#1
    data biHeight#1
    chars *biPlanes={1,0}
    chars biBitCount={24,0}
    chars biCompression#4
    data biSizeImage#1
    data *biXPelsPerMeter=0
    data *biYPelsPerMeter=0
    data *biClrUsed=0
    data *biClrImportant=0

    data BITMAPINFOHEADER^biSize

    const _BITMAPINFOHEADER^biSize
    const BITMAPINFOHEADER_^BITMAPINFOHEADER
    data size=BITMAPINFOHEADER_-_BITMAPINFOHEADER

    sd w_r
    setcall w_r av_readwrite_value((value_get))

    if w_r==(write_file)
        data fcc^biCompression
        call avi_video_fcc((value_set),fcc)

        sd wh^biWidth
        setcall biSizeImage av_frames_mainpixbuf_sizes(wh)

        sd encoder
        setcall encoder stage_write_avi_encoder((value_get))
        if encoder==(format_avi_i420)
            set biBitCount 12
            import "yuv_get_size" yuv_get_size
            setcall biSizeImage yuv_get_size(biWidth,biHeight)
        else
            set biBitCount 24
        endelse

        sd err
        setcall err file_write(BITMAPINFOHEADER,size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function avi_strl_audio(sd file)
    sd bool

    ss strl="strl"
    setcall bool riff_w_r_name(file,strl)
    if bool!=1
        return 0
    endif
    #
    ss strh="strh"
    data strh_f^avi_streamheader_audio
    setcall bool riff_chunk_w_r(file,strh_f,strh)
    if bool==0
        return 0
    endif

    ss strf="strf"
    data strf_f^avi_streamformat_audio
    setcall bool riff_chunk_w_r(file,strf_f,strf)
    if bool==0
        return 0
    endif

    return 1
endfunction

#bool
function avi_streamheader_audio(sd file)
    chars fccType={a,u,d,s}
    data *fccHandler=0
    data *dwFlags=0
    chars *wPriority={0,0}
    chars *wLanguage={0,0}
    data *dwInitialFrames=0
    #blockalign
    data dwScale#1
    #avgbytes_per_sec
    data dwRate#1
    data *dwStart=0
    data dwLength#1
    data dwSuggestedBufferSize#1
    data *dwQuality=-1
    data dwSampleSize#1
    data *left_top=0
    data *right_bottom=0

    data AVISTREAMHEADER_audio^fccType
    const _AVISTREAMHEADER_audio^fccType
    const AVISTREAMHEADER__audio^AVISTREAMHEADER_audio
    data size=AVISTREAMHEADER__audio-_AVISTREAMHEADER_audio

    sd w_r
    setcall w_r av_readwrite_value((value_get))

    if w_r==(write_file)
        import "stage_sound_blockalign" stage_sound_blockalign
        setcall dwScale stage_sound_blockalign()
        set dwSampleSize dwScale
        import "stage_sound_avgbytespersec" stage_sound_avgbytespersec
        setcall dwRate stage_sound_avgbytespersec()

        sd err
        #suggested size and length
        sd suggestedsize
        sd length
        setcall suggestedsize stage_sound_alloc_getremainingsize()
        set length suggestedsize
        div length dwSampleSize
        #add new expand bytes
        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_expand)
            setcall err file_read_and_back_with_intervening_call(AVISTREAMHEADER_audio,size,file)
            if err!=(noerror)
                return 0
            endif
            import "get_higher" get_higher
            setcall suggestedsize get_higher(suggestedsize,dwSuggestedBufferSize)
            add length dwLength
        endif
        #set
        set dwSuggestedBufferSize suggestedsize
        set dwLength length
        #write all
        setcall err file_write(AVISTREAMHEADER_audio,size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

function avi_streamformat_audio(sd file)
    #WAVEFORMATEX
    chars wFormatTag={WAVE_FORMAT_PCM,0}
    chars nChannels={1,0}
    data nSamplesPerSec#1
    data nAvgBytesPerSec#1
    chars nBlockAlign={2,0}
    chars wBitsPerSample={16,0}
    #EX
    #no extra data, simple PCM-format used
    chars *cbSize={0,0}

    data WAVEFORMATEX^wFormatTag

    const _WAVEFORMATEX^wFormatTag
    const WAVEFORMATEX_^WAVEFORMATEX
    data size=WAVEFORMATEX_-_WAVEFORMATEX

    sd w_r
    setcall w_r av_readwrite_value((value_get))

    if w_r==(write_file)
        import "stage_sound_channels" stage_sound_channels
        import "stage_sound_rate" stage_sound_rate
        import "stage_sound_bps" stage_sound_bps
        setcall nChannels stage_sound_channels((value_get))
        setcall nSamplesPerSec stage_sound_rate((value_get))
        setcall wBitsPerSample stage_sound_bps((value_get))
        setcall nBlockAlign stage_sound_blockalign()
        setcall nAvgBytesPerSec stage_sound_avgbytespersec()

        sd err
        setcall err file_write(WAVEFORMATEX,size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function avi_odml(sd file)
    ss odml="odml"
    sd bool
    setcall bool riff_w_r_name(file,odml)
    if bool!=1
        return 0
    endif

    chars dmlh={d,m,l,h}
    data *size=4
    data value#1

    data DMLH^dmlh
    data odml_sz=3*4

    sd w_r
    setcall w_r av_readwrite_value((value_get))
    if w_r==(write_file)
        sd err
        set value 0
        sd expand
        setcall expand avi_expandvalue((value_get))
        if expand==(avi_expand)
            setcall err file_read_and_back_with_intervening_call(DMLH,odml_sz,file)
            if err!=(noerror)
                return 0
            endif
        endif
        addcall value stage_frame_time_numbers((stage_frame_time_total_sum))
        setcall err file_write(DMLH,odml_sz,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function avi_movi(sd file,sd offset,ss *name,sd size)
    sd prev_io
    setcall prev_io avi_movi_flag((value_get))
    call av_readwrite_value((value_set),prev_io)

    sd bool

    sd expand=avi_new
    sd w_r
    setcall w_r av_readwrite_value((value_get))
    if w_r==(write_file)
        setcall expand avi_expandvalue((value_get))
        #here, if it is expanding, jump over the current data, get the previous index, and continue
        if expand==(avi_expand)
            setcall bool avi_expanding(file,size,offset)
            if bool!=1
                return 0
            endif
        endif
    endif
    if expand==(avi_new)
        ss mv="movi"
        setcall bool riff_w_r_name(file,mv)
        if bool!=1
            return 0
        endif
    endif

    if w_r==(write_file)
        sd audio_sz
        setcall audio_sz stage_sound_alloc_getremainingsize()
        if audio_sz!=0
            data forward_write_audio^avi_write_frame_audio
            str audio_id="01wb"
            setcall bool avi_index_mem((value_append),file,offset,0,audio_id,forward_write_audio,(AVIIF_KEYFRAME))
            if bool!=1
                return 0
            endif
        endif
        sd encoder
        setcall encoder stage_write_avi_encoder((value_get))
    endif

    sd loop=1
    while loop==1
        sd stop
        setcall stop av_dialog_stop((value_get))
        if stop==1
            set loop 0
        else
            if w_r==(write_file)
                #verify for last frame
                sd pixbuf
                setcall pixbuf av_frames((get_buffer))
                if pixbuf==0
                    return 1
                endif
                #get the frame length
                sd framelength
                sd currentframe
                setcall currentframe av_frames((value_get))
                setcall framelength stage_frame_time_numbers((stage_frame_time_get_at_index),currentframe)
                #loop the frame length
                sd i=0
                while i!=framelength
                    data forward_write_video^avi_write_frame
                    str video_id_key="00db"
                    str video_id_p="00dc"
                    ss video_id
                    sd flags
                    if i==0
                        set flags (AVIIF_KEYFRAME)
                        if encoder==(format_avi_xvid)
                            import "stage_mpeg_encode" stage_mpeg_encode
                            data is_keyframe#1
                            data p_is_keyframe^is_keyframe
                            setcall bool stage_mpeg_encode(pixbuf,currentframe,p_is_keyframe)
                            if bool!=1
                                return 0
                            endif
                            if is_keyframe==(FALSE)
                                set flags 0
                            endif
                        endif
                    else
                        set flags 0
                    endelse
                    if flags==(AVIIF_KEYFRAME)
                        set video_id video_id_key
                    else
                        set video_id video_id_p
                    endelse
                    setcall loop avi_index_mem((value_append),file,offset,i,video_id,forward_write_video,flags)
                    if loop==0
                        return 0
                    endif
                    #increment iter
                    inc i
                endwhile
                #increment current frame and print info
                inc currentframe
                call av_frames((value_set),currentframe)
                import "av_display_progress" av_display_progress
                call av_display_progress(currentframe,(capture_flag_off))
            else
                if size==0
                    set loop 0
                else
                    data f_video^avi_read_entries
                    setcall loop riff_chunk_w_r(file,f_video,0)
                    if loop==1
                        import "file_tell" file_tell

                        sd off
                        sd p_off^off
                        sd err
                        setcall err file_tell(file,p_off)
                        if err!=(noerror)
                            return 0
                        endif
                        sub off offset
                        if off==size
                            set loop 0
                        endif
                    endif
                endelse
            endelse
        endelse
    endwhile
    return 1
endfunction


#bool
function avi_index(sd file)
    sd bool
    setcall bool avi_index_mem((value_filewrite),file)
    if bool!=1
        return 0
    endif
    return 1
endfunction
















import "alloc_block" alloc_block

const value_expand=value_custom

function avi_index_mem(sd action,sd file,sd offset,sd i,ss identifier,sd forward,sd flags)
    data index_mem#1
    data size#1

    data p_size^size

    if action==(value_set)
    #bool
        set size 0
        setcall index_mem alloc_block((value_set))
        if index_mem==0
            return 0
        endif
        return 1
    elseif action==(value_unset)
        call alloc_block((value_unset),index_mem)
    elseif action==(value_append)
    #bool
        const avi_index_entry_size=0x10

        data avi_oldindex_dwChunkId#1
        data avi_oldindex_dwFlags#1
        data avi_oldindex_dwOffset#1
        data avi_oldindex_dwSize#1

        data avi_oldindex^avi_oldindex_dwChunkId

        data seek_off#1
        data p_seek_off^seek_off

        sd err
        sd bool

        #write identifier
        call cpymem(avi_oldindex,identifier,4)

        #get the file offset
        setcall err file_tell(file,p_seek_off)
        if err!=(noerror)
            return 0
        endif
        set avi_oldindex_dwOffset seek_off
        sub avi_oldindex_dwOffset offset

        if i==0
            #write the frame
            setcall bool riff_chunk_w_r(file,forward,avi_oldindex)
            if bool!=1
                return 0
            endif
        else
            #write empty frame
            setcall err file_write(avi_oldindex,4,file)
            if err!=(noerror)
                return 0
            endif
            data null=0
            data p_null^null
            setcall err file_write(p_null,4,file)
            if err!=(noerror)
                return 0
            endif
        endelse

        #get the frame size and write the value at index
        #bool
        import "file_seek_set" file_seek_set
        add seek_off 4
        setcall err file_seek_set(file,seek_off)
        if err!=(noerror)
            return 0
        endif
        import "file_get_dword" file_get_dword
        sd p_sz^avi_oldindex_dwSize
        setcall err file_get_dword(file,p_sz)
        if err!=(noerror)
            return 0
        endif
        import "file_seek_end" file_seek_end
        call file_seek_end(file)

        #avi index add
        #write the index flags
        set avi_oldindex_dwFlags flags
        #add to mem
        setcall index_mem alloc_block((value_append),index_mem,size,avi_oldindex,(avi_index_entry_size))
        if index_mem==0
            return 0
        endif
        add size (avi_index_entry_size)
        return 1
    elseif action==(value_expand)
    #bool
        import "file_seek_cursor" file_seek_cursor
        setcall err file_seek_cursor(file,4)
        if err!=(noerror)
            return 0
        endif

        setcall err file_read(p_size,4,file)
        if err!=(noerror)
            return 0
        endif

        setcall index_mem alloc_block((value_append),index_mem,0,0,size)
        if index_mem==0
            return 0
        endif

        setcall err file_read(index_mem,size,file)
        if err!=(noerror)
            return 0
        endif
        return 1
    else
    #bool
        #value_filewrite
        setcall err file_write(index_mem,size,file)
        if err!=(noerror)
            return 0
        endif
        return 1
    endelse
endfunction

function avi_write_frame(sd file)
    #get the pixbuf
    sd pixbuf
    setcall pixbuf av_frames((get_buffer))
    if pixbuf==0
        return 0
    endif

    #info prepare
    import "av_display_info" av_display_info
    call av_display_info((value_get),file)

    #encode the frame or only write
    sd encoder
    sd bool
    setcall encoder stage_write_avi_encoder((value_get))
    if encoder==(format_avi_i420)
        importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
        import "pixbuf_get_wh" pixbuf_get_wh
        sd width
        sd height
        sd width_height^width
        sd pixels
        call pixbuf_get_wh(pixbuf,width_height)
        setcall pixels gdk_pixbuf_get_pixels(pixbuf)

        import "rgb_to_yuvi420_write" rgb_to_yuvi420_write
        sd err
        setcall err rgb_to_yuvi420_write(pixels,width,height,file)
        if err!=(noerror)
            return 0
        endif
    elseif encoder==(format_avi_mjpg)
        import "stage_jpeg_write" stage_jpeg_write
        setcall bool stage_jpeg_write(file,pixbuf)
        if bool!=1
            return 0
        endif
    else
    #if encoder==(format_avi_xvid)
        import "mpeg_file_mem" mpeg_file_mem
        setcall bool mpeg_file_mem((value_filewrite))
        if bool!=1
            return 0
        endif
    endelse

    #info display
    sd currentframe
    setcall currentframe av_frames((value_get))
    call av_display_info((value_write),file,currentframe)

    return 1
endfunction

function avi_write_frame_audio(sd file)
    sd audio_sz
    setcall audio_sz stage_sound_alloc_getremainingsize()

    import "stage_sound_alloc_getbytes" stage_sound_alloc_getbytes
    sd bytes
    setcall bytes stage_sound_alloc_getbytes()
    sd err
    setcall err file_write(bytes,audio_sz,file)
    if err!=(noerror)
        return 0
    endif

    call stage_sound_sizedone((value_set),audio_sz)

    return 1
endfunction

#

function avi_read_fps(sd action,sd value)
    data read_fps#1
    if action==(value_set)
        set read_fps value
    else
        return read_fps
    endelse
endfunction
function avi_read_width(sd action,sd value)
    data read_width#1
    if action==(value_set)
        set read_width value
    else
        return read_width
    endelse
endfunction
function avi_read_height(sd action,sd value)
    data read_height#1
    if action==(value_set)
        set read_height value
    else
        return read_height
    endelse
endfunction
function avi_read_streams(sd action,sd value)
    data read_streams#1
    if action==(value_set)
        set read_streams value
    else
        return read_streams
    endelse
endfunction
function avi_read_buffer(sd action,sd value)
    data read_buffer#1
    if action==(value_set)
        set read_buffer value
    else
        return read_buffer
    endelse
endfunction
function avi_read_encoder(sd action,sd value)
    data read_encoder#1
    if action==(value_set)
        set read_encoder value
    else
        return read_encoder
    endelse
endfunction

#bool
function avi_read_entries(sd file,sd *file_pos,ss chunk_id,sd chunk_size)
    sd bool
    sd is_video=0
    ss video_iframe="00db"
    sd compare
    setcall compare cmpmem(chunk_id,video_iframe,4)
    if compare==(equalCompare)
        set is_video 1
    endif
    ss video_pframe="00dc"
    setcall compare cmpmem(chunk_id,video_pframe,4)
    if compare==(equalCompare)
        set is_video 1
    endif

    if is_video==1
        if chunk_size==0
        #extend previous frame length
            setcall bool stage_read_values((value_custom))
            if bool!=1
                return 0
            endif
            return 1
        endif

        #get width and height
        import "memalloc" memalloc
        import "rgb_get_size" rgb_get_size
        sd width
        sd height
        setcall width avi_read_width((value_get))
        setcall height avi_read_height((value_get))
        #get image size
        sd size
        setcall size rgb_get_size(width,height)
        #alloc buffer
        sd rgbbuffer
        setcall rgbbuffer memalloc(size)
        if rgbbuffer==0
            return 0
        endif
        call avi_read_buffer((value_set),rgbbuffer)
        #read
        sd encoder
        setcall encoder avi_read_encoder((value_get))
        if encoder==(format_avi_i420)
            #read yuv
            import "yuv_to_rgb_from_file" yuv_to_rgb_from_file
            sd yuvbuffer
            sd yuvsize
            setcall yuvsize yuv_get_size(width,height)
            setcall yuvbuffer memalloc(yuvsize)
            if yuvbuffer==0
                return 0
            endif
            setcall bool yuv_to_rgb_from_file(file,yuvbuffer,rgbbuffer,width,height)
            call free(yuvbuffer)
            if bool!=1
                return 0
            endif
        else
            #read jpeg
            import "read_jpeg" read_jpeg
            data f^avi_read_video
            setcall bool read_jpeg(file,f)
            if bool!=1
                return 0
            endif
        endelse

        #info display
        call av_display_info((value_write),file,-1,chunk_size)

        #make pixbuf
        importx "_gdk_pixbuf_new_from_data" gdk_pixbuf_new_from_data
        import "rgb_get_rowstride" rgb_get_rowstride
        data free_pixbuf^free
        sd rowstride
        setcall rowstride rgb_get_rowstride(width)
        sd pixbuf
        sd *length=1
        setcall pixbuf gdk_pixbuf_new_from_data(rgbbuffer,(GDK_COLORSPACE_RGB),(FALSE),8,width,height,rowstride,free_pixbuf,rgbbuffer)

        #add to stage buffer
        sd entry^pixbuf
        setcall bool stage_read_values((value_append),entry,8)
        if bool!=1
            return 0
        endif
        return 1
    else
    #is audio
        #01wb
        import "file_get_size_forward" file_get_size_forward
        data f_audio^avi_read_sound
        sd err
        setcall err file_get_size_forward(file,chunk_size,f_audio)
        if err!=(noerror)
            return 0
        endif
        return 1
    endelse
endfunction

#bool
function avi_read_video(sd bytes,sd rowstride,sd rowindex)
    sd width
    sd height
    setcall width avi_read_width((value_get))
    setcall height avi_read_height((value_get))
    sd buffer
    setcall buffer avi_read_buffer((value_get))

    import "av_read_row" av_read_row
    sd bool
    setcall bool av_read_row(width,height,buffer,bytes,rowstride,rowindex)
    return bool
endfunction

function avi_read_sound(sd mem,sd size)
    import "stage_sound_alloc_expand" stage_sound_alloc_expand
    call stage_sound_alloc_expand(mem,size)
endfunction



##expanding

function avi_movi_flag(sd action,sd value)
    data movi_flag#1
    if action==(value_set)
        set movi_flag value
    else
        return movi_flag
    endelse
endfunction

#bool
function avi_expanding(sd file,sd size,sd offset)
    sd err

    #jump over the current data
    setcall err file_seek_cursor(file,size)
    if err!=(noerror)
        return 0
    endif

    sd bool
    setcall bool avi_index_mem((value_expand),file)

    #seek back to add more frames
    add offset size
    setcall err file_seek_set(file,offset)
    if err!=(noerror)
        return 0
    endif

    return 1
endfunction



function stage_write_avi_encoder(sd action,sd value)
    data enc#1
    if action==(value_set)
        set enc value
    else
        return enc
    endelse
endfunction
