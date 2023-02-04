


format elfobj

include "../../_include/include.h"

import "dword_reverse" dword_reverse

const mkv_write=0
const mkv_read=1
import "file_seek_cursor" file_seek_cursor
import "file_get_dword_reverse" file_get_dword_reverse
import "file_seek_cursor_get_dword_reverse" file_seek_cursor_get_dword_reverse
import "memoryrealloc" memoryrealloc
import "rgb_get_all_sizes" rgb_get_all_sizes

import "pixbuf_from_pixbuf_reverse" pixbuf_from_pixbuf_reverse

const mkv_yuv_init=0
const mkv_yuv_p_bytes=1
const mkv_yuv_set_size=2
const mkv_yuv_get_size=3
const mkv_yuv_get_bytes=4
const mkv_yuv_free=5
const mkv_rgb_get_p_bytes=6
const mkv_rgb_set_size=7
const mkv_rgb_get_size=8

import "av_dialog_run" av_dialog_run
import "av_dialog_close" av_dialog_close
import "av_dialog_stop" av_dialog_stop

import "stage_file_get_mkv_encoder" stage_file_get_mkv_encoder

#write/capture node

function mkvfile(sd capture_flag,sd file_number)
    call mkv_capture((value_set),capture_flag)
    data f^mkvfile_fn
    call av_dialog_run(f,file_number)
endfunction

import "capture_obtain_screenshot" capture_obtain_screenshot

function mkvfile_fn(sd data)
    call mkv_write_read_set((mkv_write))

    data location#1
    const ptr_location^location
    sd capture
    setcall capture mkv_capture((value_get))

    import "combo_location" combo_location
    setcall location combo_location(capture,data)

    import "file_write_forward" file_write_forward
    data f^mkvfile_encoders
    call file_write_forward(location,f)

    call av_dialog_close()
endfunction

function mkvfile_encoders(sd file)
    sd bool
    sd encoder
    setcall encoder stage_file_get_mkv_encoder()
    if encoder==(format_mkv_xvid)
        import "av_frames" av_frames
        call av_frames((value_set),0)
        import "stage_mpeg_init" stage_mpeg_init
        setcall bool stage_mpeg_init(file)
        if bool!=1
            return 0
        endif
    endif

    call mkvfile_headers(file)

    if encoder==(format_mkv_xvid)
        import "mpeg_release" mpeg_release
        call mpeg_release()
    endif
endfunction

function mkv_capture(sd action,sd value)
    data capture#1
    #bool value, true for capture, or false
    if action==(value_set)
        set capture value
    else
        return capture
    endelse
endfunction

#

##headers

function mkvfile_headers(sd file)
    #Extensible Binary Meta Language
    #EBML Header, level 0
    chars EBML={0x1A,0x45,0xDF,0xA3}
    chars EBML_size#1
    chars EBMLVersion={0x42,0x86}
    chars *EBMLVersion_size=0x81
    chars *EBMLVersion_value=1
    chars *EBMLReadVersion={0x42,0xF7}
    chars *EBMLReadVersion_size=0x81
    chars *EBMLReadVersion_value=1
    chars *EBMLMaxIDLength={0x42,0xF2}
    chars *EBMLMaxIDLength_size=0x81
    chars *EBMLMaxIDLength_value=4
    chars *EBMLMaxSizeLength={0x42,0xF3}
    chars *EBMLMaxSizeLength_size=0x81
    chars *EBMLMaxSizeLength_value=8
    chars *DocType={0x42,0x82}
    chars *DocType_size=0x80|8
    chars *DocType_value={m,a,t,r,o,s,k,a}
    chars *DocTypeVersion={0x42,0x87}
    chars *DocTypeVersion_size=0x81
    chars *DocTypeVersion_value=2
    chars *DocTypeReadVersion={0x42,0x85}
    chars *DocTypeReadVersion_size=0x81
    chars DocTypeReadVersion_value=2

    #segment, level 0
    chars *SegmentElement={0x18,0x53,0x80,0x67}

    data f^mkv_segment

    const _EBMLVersion^EBMLVersion
    const DocTypeReadVersion_value_^DocTypeReadVersion_value
    sd EBML_sz=DocTypeReadVersion_value_-_EBMLVersion+1|0x80
    set EBML_size EBML_sz

    data start^EBML
    data end^f
    call mkv_size_pass(file,f,start,end)
endfunction

import "file_set_dword" file_set_dword
import "file_length" file_length
import "file_write" file_write

function mkv_segment(sd file,sd read_size,sd file_pos)
    sd io
    setcall io mkv_write_read_get()
    #get the offset for seek head positions at write
    if io==(mkv_write)
        data segment_base#1
        const ptr_segment_base^segment_base
        data ptr_segment_base^segment_base
        sd err
        setcall err file_length(file,ptr_segment_base)
        if err!=(noerror)
            return 0
        endif
    endif

    #seek head
    #level 1
    chars SeekHead={0x11,0x4D,0x9B,0x74}

    data f^mkv_seekhead

    data start1^SeekHead
    data end1^f

    sd bool
    setcall bool mkv_size_pass(file,f,start1,end1)
    if bool==0
        return 0
    endif

    if io==(mkv_write)
        #info
        #set the information at seek head for Info
        setcall bool mkv_seekhead_fn(1,file)
        if bool==0
            return 0
        endif
    endif

    #level 1
    chars Info={0x15,0x49,0xA9,0x66}

    data fn^mkv_info

    data start2^Info
    data end2^fn
    setcall bool mkv_size_pass(file,fn,start2,end2)
    if bool==0
        return 0
    endif

    #tracks
    if io==(mkv_write)
        #reset frames index; init here for calling at tracks, get width/height based on first frame
        call mkv_frames(0)
        #set the information at seek head for Tracks
        setcall bool mkv_seekhead_fn(2,file)
        if bool==0
            return 0
        endif
    endif

    #level 1
    chars Tracks={0x16,0x54,0xAE,0x6B}

    data fnc^mkv_track

    data start_data^Tracks
    data end_data^fnc
    setcall bool mkv_size_pass(file,fnc,start_data,end_data)
    if bool==0
        return 0
    endif

    #clusters
    chars Cluster={0x1F,0x43,0xB6,0x75}
    data p_fn^mkv_cluster
    data p_start^Cluster
    data p_end^p_fn

    call mkv_fr_set(0)

    data no_more_frames#1
    data p_nomoreframes^no_more_frames
    const ptr_nomoreframes^no_more_frames
    set no_more_frames 0

    sd loop
    set loop 1
    while loop==1
        setcall loop mkv_size_pass(file,p_fn,p_start,p_end)
        #stop if error or no more frames
        if loop==1
            if io==(mkv_read)
                setcall err mkv_read_cluster_verify_end(file,read_size,file_pos,p_nomoreframes)
                if err!=(noerror)
                    return 0
                endif
                if no_more_frames==1
                    set loop 0
                endif
            endif
        endif
    endwhile
    sd allframes
    setcall allframes mkv_fr_get()

    if io==(mkv_write)
        sd fileduration
        setcall fileduration mkv_timecodes(allframes)
        call mkv_set_duration(file,fileduration)
    else
        sd newframes_read
        sd p_newframes_read^newframes_read
        sd duration
        setcall duration mkv_read_get_duration()
        call mkv_readentry(allframes,duration,p_newframes_read)
    endelse
endfunction

#bool
function mkv_seekhead_fn(sd action,sd file)
    if action==0
        #seek entry KaxInfo
        data info#1
        data ptr_info^info
        chars KaxInfo={0x15,0x49,0xA9,0x66}
        sd todata^KaxInfo

        sd bool
        setcall bool seek_entry(todata#,file,ptr_info)
        if bool==0
            return 0
        endif

        #seek entry KaxTracks
        data tracks#1
        data ptr_tracks^tracks
        chars KaxTracks={0x16,0x54,0xAE,0x6B}
        sd dodata^KaxTracks

        setcall bool seek_entry(dodata#,file,ptr_tracks)
        return bool
    else
        sd seg_base%ptr_segment_base
        sd position_value
        sd ptr_position_value^position_value
        sd err
        setcall err file_length(file,ptr_position_value)
        if err!=(noerror)
            return 0
        endif
        sub position_value seg_base#
        setcall position_value dword_reverse(position_value)
        sd pos
        if action==1
            set pos info
        else
            set pos tracks
        endelse
        setcall err file_set_dword(file,pos,ptr_position_value)
        if err!=(noerror)
            return 0
        endif
        return 1
    endelse
endfunction

#bool
function mkv_seekhead(sd file)
    sd bool
    setcall bool mkv_seekhead_fn(0,file)
    return bool
endfunction

#bool
function seek_entry(sd value,sd file,sd ptr_pointer)
    chars Seek={0x4D,0xBB}
    chars *Seek_size=0x80+2+1+4+2+1+4
    chars *SeekID={0x53,0xAB}
    chars *SeekID_size=0x84
    data SeekID_value#1
    chars *SeekPosition={0x53,0xAC}
    chars *SeekPosition_size=0x84
    chars SeekPosition_value#4

    set SeekID_value value

    const _Seek^Seek
    const SeekPosition_value_^SeekPosition_value
    data sz=SeekPosition_value_-_Seek+4
    data wr^Seek

    #write/pass the seek entry
    sd bool
    setcall bool mkv_write_seek(wr,sz,file)
    if bool==0
        return 0
    endif

    sd io
    setcall io mkv_write_read_get()
    #set the pointer entry if write
    if io==(mkv_write)
        sd err
        setcall err file_length(file,ptr_pointer)
        if err!=(noerror)
            return 0
        endif
        sub ptr_pointer# 4
    endif

    return 1
endfunction

#bool
function mkv_info(sd file)
    sd io
    setcall io mkv_write_read_get()

    if io==(mkv_write)
        sd err
        #get the offset for Duration
        data offset#1
        data ptr_offset^offset
        const ptr_offset^offset
        setcall err file_length(file,ptr_offset)
        if err!=(noerror)
            return 0
        endif
    endif

    chars SegmentUID={0x73,0xA4}
    chars *SegmentUID_size=0x80|16
    data SegmentUID_value#4
    chars *TimecodeScale={0x2A,0xD7,0xB1}
    chars *TimecodeScale_size=0x84
    data TimecodeScale_value#1
    chars *Duration={0x44,0x89}
    #unsigned integer
    chars *Duration_size=0x84
    data Duration_value#1
    chars *DateUTC={0x44,0x61}
    chars *DateUTC_size=0x80|8
    data DateUTC_value_high#1
    data DateUTC_value_low#1
    chars *MuxingApp={0x4D,0x80}
    chars MuxingApp_size#1
    chars MuxingApp_value={O,A,p,p,l,i,c,a,t,i,o,n,s}
    chars WritingApp={0x57,0x41}
    chars WritingApp_size#1
    chars WritingApp_value={O,A,p,p,l,i,c,a,t,i,o,n,s}

    const _MuxingApp^MuxingApp_value
    const MuxingApp_^WritingApp
    const App=MuxingApp_-_MuxingApp
    const _SegmentUID^SegmentUID
    const WritingApp_value_^WritingApp_value
    data info_sz=WritingApp_value_-_SegmentUID+App
    data ptr_seg^SegmentUID

    #the muxer timecode
    const ptr_Duration^Duration_value
    const Duration_offset=ptr_Duration-_SegmentUID
    data Dur_offset=Duration_offset

    if io==(mkv_write)
        #1 000 000 nanoseconds=1 millisecond
        setcall TimecodeScale_value dword_reverse((1000*1000))

        #set app name size
        data MuxingApp_sz=App|0x80
        set MuxingApp_size MuxingApp_sz
        set WritingApp_size MuxingApp_sz

        #set unique ID
        data p_SegmentUID_value^SegmentUID_value
        sd pointer
        set pointer p_SegmentUID_value
        import "timeNode" time
        sd currenttime
        setcall currenttime time(0)
        sd getAtime
        set getAtime currenttime
        mult getAtime (3*7)
        set pointer# getAtime
        add pointer 4
        mult getAtime 11
        set pointer# getAtime
        add pointer 4
        mult getAtime 13
        set pointer# getAtime
        add pointer 4
        mult getAtime 17
        set pointer# getAtime

        #set the date
        #the number is seconds sub: 1 jan 2001 - 1 jan 1970
        sub currenttime 978307200
        data ptr_DateUTC_value_high^DateUTC_value_high
        import "mult64" mult64
        setcall DateUTC_value_low mult64(currenttime,1000000000,ptr_DateUTC_value_high)
        setcall DateUTC_value_high dword_reverse(DateUTC_value_high)
        setcall DateUTC_value_low dword_reverse(DateUTC_value_low)

        setcall err file_write(ptr_seg,info_sz,file)
        if err!=(noerror)
            return 0
        endif

        #add for duration write
        add offset Dur_offset
    else
        #get the duration for the last frame
        data ptr_Duration^Duration_value
        setcall err file_seek_cursor_get_dword_reverse(file,Dur_offset,ptr_Duration)
        if err!=(noerror)
            return 0
        endif
        #seek to the end of info
        sd sz
        set sz info_sz
        sub sz 4
        sub sz Dur_offset
        setcall err file_seek_cursor(file,sz)
        if err!=(noerror)
            return 0
        endif
    endelse
    return 1
endfunction

#write duration to file
function mkv_set_duration(sd file,sd duration)
    data p_dr%ptr_Duration
    data p_of%ptr_offset
    setcall p_dr# dword_reverse(duration)
    call file_set_dword(file,p_of#,p_dr)
endfunction

import "stage_sound_sizedone" stage_sound_sizedone
import "stage_sound_alloc_getremainingsize" stage_sound_alloc_getremainingsize

import "file_seek_offset_plus_size" file_seek_offset_plus_size
import "file_sizeofseek_offset_plus_size" file_sizeofseek_offset_plus_size

function mkv_track(sd file,sd size,sd filepos)
    #level 2
    chars TrackEntry=0xAE

    data f^mkv_track_entry
    data start^TrackEntry
    data end^f
    sd bool
    setcall bool mkv_size_pass(file,f,start,end)
    if bool==0
        return 0
    endif

    #verify for sound
    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        #at write check the sound memory
        #set remaining size to 0
        call stage_sound_sizedone((value_set),0)
        #get the size
        sd sz
        setcall sz stage_sound_alloc_getremainingsize()
        if sz==0
            return 1
        endif
    else
        #at read check if space is available
        #get size of seek
        sd sizeofseek
        sd p_sizeofseek^sizeofseek
        sd err
        setcall err file_sizeofseek_offset_plus_size(file,size,filepos,p_sizeofseek)
        if err!=(noerror)
            return 0
        endif
        if sizeofseek==0
            return 1
        endif
    endelse

    data sound_f^mkv_sound
    setcall bool mkv_size_pass(file,sound_f,start,end)
    return bool
endfunction

importx "_gdk_pixbuf_get_pixels" gdk_pixbuf_get_pixels
importx "_gdk_pixbuf_get_width" gdk_pixbuf_get_width
importx "_gdk_pixbuf_get_height" gdk_pixbuf_get_height

import "stage_file_options_fps" stage_file_options_fps

const TrackNumber_video=1
const TrackNumber_audio=2

const bitmapInfoHeader_size=40

function mkv_track_entry(sd file,sd *size,sd *filepos)
    chars CodecID=0x86
    data f^mkv_codecid

    data start^CodecID
    data end^f

    sd bool

    setcall bool mkv_size_pass(file,f,start,end)
    if bool==0
        return 0
    endif

##############
    chars TrackNumber=0xD7
    chars *TrackNumber_size=0x81
    chars *TrackNumber_value=TrackNumber_video
    chars *TrackUID={0x73,0xC5}
    chars *TrackUID_size=0x81
    chars *TrackUID_value=TrackNumber_video
    chars *TrackType=0x83
    chars *TrackType_size=0x81
    chars *TrackType_value=1
    #video type=1
    chars *FlagLacing=0x9C
    chars *FlagLacing_size=0x81
    chars *FlagLacing_value=0
    #no lacing used
    chars *Name={0x53,0x6E}
    chars *Name_size=0x85
    chars Name_value={V,i,d,e,o}

    chars *CodecPrivate={0x63,0xA2}
    chars *CodecPrivate_size=0x80+bitmapInfoHeader_size
    data *biSize=bitmapInfoHeader_size
    data biWidth#1
    data biHeight#1
    chars *biPlanes={1,0}
    chars *biBitCount={24,0}
    data *biCompression=BI_RGB
    data biSizeImage#1
    data *biXPelsPerMeter=0
    data *biClrUsed=0
    data *biClrImportant=0
##############

    const _track^TrackNumber
    const track_last_^Name_value
    const track_=track_last_+5
    data track_data^TrackNumber
    data track_sz_init=track_-_track
    data track_sz#1
    sd rgb_privdata_size=2+1+bitmapInfoHeader_size

    set track_sz track_sz_init

    sd encoder
    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        setcall encoder stage_file_get_mkv_encoder()
        if encoder==(format_mkv_rgb24)
            sd p_wh^biWidth
            call mkv_get_video_width_height(p_wh)
            #add here the bmp header
            import "rgb_get_size" rgb_get_size
            setcall biSizeImage rgb_get_size(biWidth,biHeight)
            call mkv_rgb_yuv_functions((mkv_rgb_set_size),biSizeImage)
        endif
    else
        setcall encoder mkv_read_encoder((value_get))
    endelse
    if encoder==(format_mkv_rgb24)
        add track_sz rgb_privdata_size
    endif

    setcall bool mkv_write_seek(track_data,track_sz,file)
    if bool!=1
        return 0
    endif

    #add the video track
    chars Video=0xE0
    data f_vd^mkv_track_video_entry
    data start_vd^Video
    data end_vd^f_vd
    setcall bool mkv_size_pass(file,f_vd,start_vd,end_vd)
    if bool==0
        return 0
    endif
    return 1
endfunction

function mkv_track_video_entry(sd file,sd *size,sd *filepos)
    #level 3
    chars PixelWidth=0xB0
    chars *PixelWidth_size=0x84
    data PixelWidth_value#1
    chars PixelHeight=0xBA
    chars *PixelHeight_size=0x84
    data PixelHeight_value#1
    chars DisplayWidth={0x54,0xB0}
    chars *DisplayWidth_size=0x84
    data DisplayWidth_value#1
    chars *DisplayHeight={0x54,0xBA}
    chars *DisplayHeight_size=0x84
    data DisplayHeight_value#1
    chars *FrameRate={0x23,0x83,0xE3}
    chars *FrameRate_size=0x84
    data FrameRate_value#1

    chars *ColourSpace={0x2E,0xB5,0x24}
    chars *ColourSpace_size=0x84
    chars *ColourSpace_value={I,_4,_2,_0}

    sd err
    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        const _video_track^PixelWidth
        const video_track_last_^FrameRate_value
        const video_track_=video_track_last_+4
        data video_track^PixelWidth
        data video_track_sz_init=video_track_-_video_track
        data video_track_sz#1
        set video_track_sz video_track_sz_init

        sd encoder
        setcall encoder stage_file_get_mkv_encoder()
        if encoder==(format_mkv_i420)
            const color_size=3+1+4
            add video_track_sz (color_size)
        endif

        #set width, height
        sd w
        sd h
        sd p_wh^w
        call mkv_get_video_width_height(p_wh)
        set PixelWidth_value w
        set PixelHeight_value h

        #to big endian and to display
        setcall PixelWidth_value dword_reverse(PixelWidth_value)
        setcall PixelHeight_value dword_reverse(PixelHeight_value)
        set DisplayWidth_value PixelWidth_value
        set DisplayHeight_value PixelHeight_value
        #set frame rate
        import "int_to_float" int_to_float
        setcall FrameRate_value stage_file_options_fps()
        setcall FrameRate_value int_to_float(FrameRate_value)
        setcall FrameRate_value dword_reverse(FrameRate_value)

        setcall err file_write(video_track,video_track_sz,file)
        if err!=(noerror)
            return 0
        endif
    else
        #get the width
        const ptr_PixelWidth_value^PixelWidth_value
        data off_PixelWidth_value=ptr_PixelWidth_value-_video_track
        data ptr_PixelWidth_value^PixelWidth_value
        setcall err file_seek_cursor_get_dword_reverse(file,off_PixelWidth_value,ptr_PixelWidth_value)
        if err!=(noerror)
            return 0
        endif
        #get the height
        const ptr_PixelHeight^PixelHeight
        const ptr_PixelHeight_value^PixelHeight_value
        data off_to_PixelHeight=ptr_PixelHeight_value-ptr_PixelHeight
        data ptr_PixelHeight_value^PixelHeight_value
        setcall err file_seek_cursor_get_dword_reverse(file,off_to_PixelHeight,ptr_PixelHeight_value)
        if err!=(noerror)
            return 0
        endif
        #get file fps
        const ptr_DisplayWidth^DisplayWidth
        const ptr_FrameRate_value^FrameRate_value
        data off_to_FrameRate_value=ptr_FrameRate_value-ptr_DisplayWidth
        data ptr_FrameRate_value^FrameRate_value
        setcall err file_seek_cursor_get_dword_reverse(file,off_to_FrameRate_value,ptr_FrameRate_value)
        if err!=(noerror)
            return 0
        endif
        import "float_to_int" float_to_int
        setcall FrameRate_value float_to_int(FrameRate_value)
            #correct fps if it's 0
        import "av_good_fps" av_good_fps
        call av_good_fps(ptr_FrameRate_value)
            #
        call mkv_read_fps((value_set),FrameRate_value)

        sd sz

        #set the size and the bytes for yuv
        import "yuv_get_size" yuv_get_size
        setcall sz yuv_get_size(PixelWidth_value,PixelHeight_value)
        sd p_yuv
        setcall p_yuv mkv_rgb_yuv_functions((mkv_yuv_p_bytes))
        setcall err memoryrealloc(p_yuv,sz)
        if err!=(noerror)
            return 0
        endif
        call mkv_rgb_yuv_functions((mkv_yuv_set_size),sz)
        #set the bytes for rgb
        setcall sz rgb_get_size(PixelWidth_value,PixelHeight_value)
        call mkv_rgb_yuv_functions((mkv_rgb_set_size),sz)
        sd p_rgb
        setcall p_rgb mkv_rgb_yuv_functions((mkv_rgb_get_p_bytes))
        setcall err memoryrealloc(p_rgb,sz)
        if err!=(noerror)
            return 0
        endif
    endelse
    return 1
endfunction

import "file_get_size_forward" file_get_size_forward

function mkv_codecid(sd file,sd size,sd *filepos)
    sd err
    sd bool
    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        setcall bool mkv_codecid_data(io,file)
        return bool
    else
        data f^mkv_codecid_read
        setcall err file_get_size_forward(file,size,f)
        if err!=(noerror)
            return 0
        endif
    endelse
    return 1
endfunction

function mkv_cluster(sd file,sd read_size,sd file_pos)
    chars Timecode=0xE7
    chars *Timecode_size=0x84
    data Timecode_value#1

    #data p_nomoreframes%ptr_nomoreframes
    data timecode_max#1
    data p_timecodemax^timecode_max
    const ptr_timecodemax^timecode_max

    set timecode_max 0

    sd io
    sd bool
    sd err
    setcall io mkv_write_read_get()

    #duration time
    sd allframes
    setcall allframes mkv_fr_get()

    if io==(mkv_write)
        setcall Timecode_value mkv_timecodes(allframes)
        setcall Timecode_value dword_reverse(Timecode_value)

        data ptr_tm^Timecode
        setcall err file_write(ptr_tm,(1+1+4),file)
        if err!=(noerror)
            return 0
        endif
    else
        #get cluster timecode
        data p_Timecode_value^Timecode_value
        setcall err file_seek_cursor_get_dword_reverse(file,(1+1),p_Timecode_value)
        if err!=(noerror)
            return 0
        endif
        #finalize the previous frame
        sd newframes_read
        sd p_newframes_read^newframes_read
        setcall bool mkv_readentry(allframes,Timecode_value,p_newframes_read)
        if bool==0
            return 0
        endif
        #set the elapsed frames
        call mkv_fr_set(newframes_read)
    endelse

    call mkv_cluster_fr_set(0)
    #

    sd stop
    sd loop
    set loop 1
    while loop==1
        #aborted?
        setcall stop av_dialog_stop((value_get))
        if stop==1
            #this is the point where user abort is checked
            #direct capture required only: verify to not be the first frame to not let an empty cluster
            sd s
            setcall s mkv_cluster_fr_get()
            if s!=0
                set loop 0
            endif
        else
            chars SimpleBlock=0xA3
            data f^mkv_simpleblock

            data start^SimpleBlock
            data end^f
            setcall loop mkv_size_pass(file,f,start,end)

            #stop if error or no more frames or cluster time exceeded
            if io==(mkv_read)
                if loop==1
                    setcall err mkv_read_cluster_verify_end(file,read_size,file_pos,p_timecodemax)
                    if err!=(noerror)
                        return 0
                    endif
                    if timecode_max==1
                        set loop 0
                    endif
                endif
            endif
        endelse
    endwhile

    #cluster time
    sd newframes
    setcall newframes mkv_cluster_fr_get()
    addcall newframes mkv_fr_get()
    call mkv_fr_set(newframes)
    #

    if timecode_max==1
        return 1
    else
        #p_nomoreframes#==1 or an error or abort
        return 0
    endelse
endfunction

#returns the timecode
function mkv_timecodes(sd frames)
    data returnduration#1
    sd fps
    setcall fps stage_file_options_fps()
    sd value
    #truncate frames
    set value frames
    div value fps
    #truncation to milliseconds
    set returnduration value
    mult returnduration 1000

    #look at the last milliseconds
    mult value fps
    sub frames value
    #x      1000
    #frames  fps
    sd msec
    set msec 1000
    mult msec frames
    div msec fps

    add returnduration msec
    return returnduration
endfunction
function mkv_fr_get()
    data all_frames#1
    const ptr_all_frames^all_frames
    return all_frames
endfunction
function mkv_fr_set(sd value)
    data p%ptr_all_frames
    set p# value
endfunction
function mkv_cluster_fr_get()
    data cluster_frames#1
    const ptr_cluster_frames^cluster_frames
    return cluster_frames
endfunction
function mkv_cluster_fr_set(sd value)
    data p%ptr_cluster_frames
    set p# value
endfunction

import "stage_nthwidgetFromcontainer" stage_nthwidgetFromcontainer
import "object_get_dword_name" object_get_dword_name

const value_frame_nr=value_custom

#bool, simpleblock is in loop
function mkv_simpleblock(sd file,sd size,sd filepos)
    sd err
    sd io
    setcall io mkv_write_read_get()

    const SimpleBlock_Flags_Keyframe=0x80

    chars Track_Number#1
    chars Timecode_high#1
    chars Timecode_low#1
    #cluster relative, signed int16
    chars Flags#1

    #cluster time
    sd frames
    setcall frames mkv_cluster_fr_get()
    sd bool

    sd encoder
    if io==(mkv_write)
        setcall encoder stage_file_get_mkv_encoder()

        set Track_Number 0x80

        sd timecode
        setcall timecode mkv_timecodes(frames)

        set Timecode_low timecode
        div timecode 0x100
        set Timecode_high timecode

        data ptr_smp^Track_Number
        data smp_size=1+2+1

        set Flags (SimpleBlock_Flags_Keyframe)

        sd sz
        setcall sz stage_sound_alloc_getremainingsize()
        if sz!=0
            #audio
            or Track_Number (TrackNumber_audio)

            setcall err file_write(ptr_smp,smp_size,file)
            if err!=(noerror)
                return 0
            endif

            import "stage_sound_alloc_getbytes" stage_sound_alloc_getbytes
            sd bytes
            setcall bytes stage_sound_alloc_getbytes()
            setcall err file_write(bytes,sz,file)
            if err!=(noerror)
                return 0
            endif
            call stage_sound_sizedone((value_set),sz)
            return 1
        endif

        #video
        sd currentframe
        sd pixbuf
        setcall currentframe mkv_frames((value_frame_nr))

        or Track_Number (TrackNumber_video)

        setcall pixbuf mkv_frames(1,1)

        if encoder==(format_mkv_xvid)
            import "stage_mpeg_encode" stage_mpeg_encode
            data is_keyframe#1
            data p_is_keyframe^is_keyframe
            setcall bool stage_mpeg_encode(pixbuf,currentframe,p_is_keyframe)
            if bool!=1
                return 0
            endif
            if is_keyframe==(FALSE)
                set Flags 0
            endif
        endif

        setcall err file_write(ptr_smp,smp_size,file)
        if err!=(noerror)
            return 0
        endif

		#import "rgb_test" rgb_test
		#setcall bool rgb_test(pixbuf)
		#if bool==0
		#    return 0
		#else
		#info prepare
		import "av_display_info" av_display_info
		call av_display_info((value_get),file)
		if encoder==(format_mkv_i420)
		    sd pixels
		    sd width
		    sd height
		    setcall pixels gdk_pixbuf_get_pixels(pixbuf)
		    setcall width gdk_pixbuf_get_width(pixbuf)
		    setcall height gdk_pixbuf_get_height(pixbuf)

		    import "rgb_to_yuvi420_write" rgb_to_yuvi420_write
		    setcall err rgb_to_yuvi420_write(pixels,width,height,file)
		    if err!=(noerror)
		        return 0
		    endif
		elseif encoder==(format_mkv_mjpg)
		    import "stage_jpeg_write" stage_jpeg_write
		    setcall bool stage_jpeg_write(file,pixbuf)
		    if bool!=1
		        return 0
		    endif
		elseif encoder==(format_mkv_xvid)
		    import "mpeg_file_mem" mpeg_file_mem
		    setcall bool mpeg_file_mem((value_filewrite))
		    if bool!=1
		        return 0
		    endif
		else
		#if encoder==(format_avi_rgb24)
		    import "pixbuf_get_wh" pixbuf_get_wh
		    sd rgb_pixels
		    sd rgb_sz
		    setcall rgb_pixels gdk_pixbuf_get_pixels(pixbuf)
		    sd rgb_width
		    sd rgb_height
		    sd rgb_dim^rgb_width
		    call pixbuf_get_wh(pixbuf,rgb_dim)
		    setcall rgb_sz rgb_get_size(rgb_width,rgb_height)

		    sd capture_flag
		    setcall capture_flag mkv_capture((value_get))
		    if capture_flag==0
		        sd reverse_pixbuf
		        setcall reverse_pixbuf pixbuf_from_pixbuf_reverse(pixbuf)
		        setcall rgb_pixels gdk_pixbuf_get_pixels(reverse_pixbuf)
		    endif
		    #
		    setcall err file_write(rgb_pixels,rgb_sz,file)
		    #
		    if capture_flag==0
		        importx "_g_object_unref" g_object_unref
		        call g_object_unref(reverse_pixbuf)
		    endif

		    if err!=(noerror)
		        return 0
		    endif
		endelse
		#info display
		call av_display_info((value_write),file,currentframe)
		#endelse

        setcall pixbuf mkv_frames(1,0,file)

        if pixbuf==0
        #no more frames
            data p%ptr_nomoreframes
            set p# 1
            data fl%ptr_location
            import "save_inform_saved" save_inform_saved
            call save_inform_saved(fl#)
            return 0
        endif
        data time_max%ptr_timecodemax
        if time_max#==1
        #cluster is full
            return 0
        endif
    else
        setcall encoder mkv_read_encoder((value_get))

        import "file_get_dword" file_get_dword
        sd harvest_blocktime#1
        sd p_harvest_blocktime^harvest_blocktime
        setcall err file_get_dword(file,p_harvest_blocktime)
        if err!=(noerror)
            return err
        endif

        set Track_Number harvest_blocktime
        and Track_Number 0x7f
        #add if it is audio to the prepared music
        if Track_Number==(TrackNumber_audio)
            sd audioframesize
            sd p_audioframesize^audioframesize
            setcall err file_sizeofseek_offset_plus_size(file,size,filepos,p_audioframesize)
            if err!=(noerror)
                return 0
            endif

            data f^mkv_read_sound
            setcall err file_get_size_forward(file,audioframesize,f)
            if err!=(noerror)
                return 0
            endif
            return 1
        endif

        setcall harvest_blocktime dword_reverse(harvest_blocktime)

        sd newframes_read
        sd p_newframes_read^newframes_read

        and harvest_blocktime 0xffFFff
        div harvest_blocktime 0x100
        setcall bool mkv_readentry(frames,harvest_blocktime,p_newframes_read)
        if bool==0
            return 0
        endif
        call mkv_cluster_fr_set(newframes_read)

        if encoder==(format_mkv_i420)
            sd yuv
            setcall yuv mkv_rgb_yuv_functions((mkv_yuv_get_bytes))
            sd sizeofyuv
            setcall sizeofyuv mkv_rgb_yuv_functions((mkv_yuv_get_size))
            import "file_read" file_read
            setcall err file_read(yuv,sizeofyuv,file)
            if err!=(noerror)
                return 0
            endif
        elseif encoder==(format_mkv_mjpg)
            import "read_jpeg" read_jpeg
            data f_readjpeg^mkv_read_mjpeg

            setcall bool read_jpeg(file,f_readjpeg)
            if bool==0
                return 0
            endif
            #the read function let the cursor somewhere after the frame size
            setcall err file_seek_offset_plus_size(file,size,filepos)
            if err!=(noerror)
                return 0
            endif
        else
            sd p_rgb
            setcall p_rgb mkv_rgb_yuv_functions((mkv_rgb_get_p_bytes))
            sd rgb_size
            setcall rgb_size mkv_rgb_yuv_functions((mkv_rgb_get_size))
            setcall err file_read(p_rgb#,rgb_size,file)
            if err!=(noerror)
                return 0
            endif
        endelse
        #info display
        call av_display_info((value_write),file,-1,size)
    endelse
    return 1
endfunction

function mkv_get_video_width_height(sd p_wh)
    sd capture_flag
    setcall capture_flag mkv_capture((value_get))
    if capture_flag==0
        sd pixbuf
        setcall pixbuf mkv_frames(1,0)
        setcall p_wh# gdk_pixbuf_get_width(pixbuf)
        add p_wh 4
        setcall p_wh# gdk_pixbuf_get_height(pixbuf)
    else
        import "capture_get_width_height" capture_get_width_height
        call capture_get_width_height(p_wh)
    endelse
endfunction

function mkv_frames(sd action,sd addatframes,sd file)
    data image_nr#1
    if action==0
        #0
        set image_nr 0
    elseif action==1
    #0 is no more frames or error
        #1
        sd capture
        sd temp_flag
        sd pix
        setcall capture mkv_capture((value_get))
        if capture==0
            #save the stage
            sd eventbox
            setcall eventbox stage_nthwidgetFromcontainer(image_nr)
            if eventbox==0
                return 0
            endif
            setcall pix object_get_dword_name(eventbox)
        else
            #capture file
            import "capture_temp_flag" capture_temp_flag
            setcall temp_flag capture_temp_flag((value_get))
            if addatframes==0
                #test for end of frames/last frame
                import "capture_split" capture_split
                if temp_flag==0
                    #test for split max size(end of frames)
                    setcall pix capture_split((value_get),file)
                else
                    #test for end of frames/last frame
                    import "capture_direct_frames" capture_direct_frames
                    sd temp_frames
                    setcall temp_frames capture_direct_frames((value_get))
                    if temp_frames==image_nr
                        #last frame
                        set pix 0
                    else
                        #test for split max size(end of frames)
                        setcall pix capture_split((value_get),file)
                        if pix==0
                        #substract for next file
                            sub temp_frames image_nr
                            call capture_direct_frames((value_set),temp_frames)
                        endif
                    endelse
                endelse
            else
            #get a frame
                setcall pix capture_obtain_screenshot()
            endelse
        endelse

        if addatframes!=0
            #increment image_nr
            add image_nr addatframes

            #display position
            import "av_display_progress" av_display_progress
            call av_display_progress(image_nr,capture)

            #frames number is rising
            sd frames_rise
            #the frame length
            if capture==0
                import "stage_get_fr_length" stage_get_fr_length
                setcall frames_rise stage_get_fr_length(eventbox)
            else
                if temp_flag==0
                    import "capture_time" capture_time
                    setcall frames_rise capture_time((value_get))
                else
                    import "capture_temp_file" capture_temp_file
                    sd temp_file
                    setcall temp_file capture_temp_file((value_get))
                    sd p_frames_rise^frames_rise
                    call file_read(p_frames_rise,4,temp_file)
                endelse
            endelse
            #
            addcall frames_rise mkv_cluster_fr_get()
            call mkv_cluster_fr_set(frames_rise)

            sd maxtimecheck
            data stop%ptr_timecodemax
            setcall maxtimecheck mkv_timecodes(frames_rise)
            if maxtimecheck>0x7fFF
                set stop# 1
            endif
        endif

        return pix
    else
        #2
        #value_frame_nr
        return image_nr
    endelse
endfunction

import "file_tell" file_tell

#bool
function mkv_size_pass(sd file,sd forward,sd start,sd end)
    sd size
    set size end
    sub size start

    sd bool
    sd err
    sd io
    setcall io mkv_write_read_get()

    #write the start/pass the start
    setcall bool mkv_write_seek(start,size,file)
    if bool==0
        return 0
    endif

    if io==(mkv_write)
        #write the size
        sd ebmlsize_high
        sd *ebmlsize_low
        setcall ebmlsize_high dword_reverse(0x01000000)
        sd ptr_ebmlsize_high^ebmlsize_high

        setcall err file_write(ptr_ebmlsize_high,8,file)
        if err!=(noerror)
            return 0
        endif
    else
        #get the size
        setcall err file_seek_cursor(file,4)
        if err!=(noerror)
            return 0
        endif
        sd ebmlblocksize
        sd p_ebmlblocksize^ebmlblocksize
        setcall err file_get_dword_reverse(file,p_ebmlblocksize)
        if err!=(noerror)
            return 0
        endif
    endelse

    #get the point for write/read calculations
    sd file_pos
    sd ptr_file_pos^file_pos
    setcall err file_tell(file,ptr_file_pos)
    if err!=(noerror)
        return 0
    endif
    if io==(mkv_write)
        sd writepoint
        set writepoint file_pos
        sub writepoint 4
    endif

    setcall bool forward(file,ebmlblocksize,file_pos)

    #set the size at write
    if io==(mkv_write)
        sd seg_size_after
        sd ptr_seg_size_after^seg_size_after
        setcall err file_length(file,ptr_seg_size_after)
        if err!=(noerror)
            return 0
        endif
        sub seg_size_after file_pos

        setcall seg_size_after dword_reverse(seg_size_after)

        setcall err file_set_dword(file,writepoint,ptr_seg_size_after)
        if err!=(noerror)
            return 0
        endif
    else
    #seek remaining at read
        import "file_seek" file_seek
        sd seek_remaining
        set seek_remaining file_pos
        add seek_remaining ebmlblocksize
        setcall err file_seek(file,seek_remaining,(SEEK_SET))
        if err!=(noerror)
            return 0
        endif
    endelse

    return bool
endfunction





#mkv write/seek
#bool
function mkv_write_seek(sd mem,sd size,sd file)
    sd err
    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        setcall err file_write(mem,size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor(file,size)
        if err!=(noerror)
            return 0
        endif
    endelse
    return 1
endfunction













importx "_free" free

#

function stage_mkv_read(ss filename)
    #color space init
    sd err
    setcall err mkv_rgb_yuv_functions((mkv_yuv_init))
    if err!=(noerror)
        return 0
    endif

    import "file_forward_read" file_forward_read
    data f^stage_mkv_read_gotfile
    call file_forward_read(filename,f)

    #color space free
    call mkv_rgb_yuv_functions((mkv_yuv_free))
endfunction

import "stage_read_values" stage_read_values

function stage_mkv_read_gotfile(sd file)
    #values init
    sd bool
    setcall bool stage_read_values((value_set))
    if bool!=1
        return 0
    endif

    data f^stage_mkv_read_fn
    call av_dialog_run(f,file)

    #values write and free
    call stage_read_values((value_write))
    call stage_read_values((value_unset))
endfunction

function stage_mkv_read_fn(sd file)
    call mkv_write_read_set((mkv_read))

    call mkvfile_headers(file)

    call av_dialog_close()
endfunction

function mkv_rgb_yuv_functions(sd method,sd sz)
    data yuv#1
    data p_yuv^yuv
    data size#1

    data rgb#1
    data rgb_size#1
    data p_rgb^rgb

    if method==(mkv_yuv_init)
        set yuv 0
        set rgb 0

        sd err
        setcall err memoryrealloc(p_yuv,0)
        if err!=(noerror)
            return err
        endif

        setcall err memoryrealloc(p_rgb,0)
        if err!=(noerror)
            call mkv_rgb_yuv_functions((mkv_yuv_free))
            return err
        endif

        return (noerror)
    elseif method==(mkv_yuv_p_bytes)
        return p_yuv
    elseif method==(mkv_yuv_set_size)
        set size sz
    elseif method==(mkv_yuv_get_size)
        return size
    elseif method==(mkv_yuv_get_bytes)
        return yuv
    elseif method==(mkv_yuv_free)
        call free(yuv)
        if rgb!=0
            call free(rgb)
        endif
    elseif method==(mkv_rgb_get_p_bytes)
        return p_rgb
    elseif method==(mkv_rgb_set_size)
        set rgb_size sz
    else
    #if method==(mkv_rgb_get_size)
        return rgb_size
    endelse
    return 1
endfunction

function mkv_write_read_set(sd value)
    data write_or_read#1
    set write_or_read value
    const p_write_or_read^write_or_read
endfunction
function mkv_write_read_get()
    data p%p_write_or_read
    return p#
endfunction

#err
function mkv_read_cluster_verify_end(sd file,sd sz,sd pos,sd p_bool)
    sd position
    sd p_position^position
    sd err
    setcall err file_tell(file,p_position)
    if err!=(noerror)
        return err
    endif
    sub position pos
    if position>sz
        import "texter" texter
        str er="Wrong mkv segment sizes."
        call texter(er)
        return er
    endif
    if position<sz
        set p_bool# 0
        return (noerror)
    endif
    #size end
    set p_bool# 1
    return (noerror)
endfunction

function mkv_read_get_duration()
    data p%ptr_Duration
    return p#
endfunction

#bool
function mkv_readentry(sd frames,sd newtime,sd p_resultedframes)
    sd px
    sd nt_frames

    sd fps
    setcall fps mkv_read_fps((value_get))

    #<fps
    sd msec
    #x fps
    #msec 1000
    import "rest" rest
    setcall msec rest(newtime,1000)
    #round msec, not working at 1000 fps
    inc msec
    import "rule3" rule3
    setcall nt_frames rule3(msec,1000,fps)

    #seconds*fps
    div newtime 1000
    mult newtime fps
    add nt_frames newtime

    set p_resultedframes# nt_frames
    sub nt_frames frames
    if nt_frames==0
        return 1
    elseif nt_frames<0
        str timeerr="Wrong timecodes."
        call texter(timeerr)
        return 0
    endelseif

    sd p_rgb
    setcall p_rgb mkv_rgb_yuv_functions((mkv_rgb_get_p_bytes))
    sd p_wd%ptr_PixelWidth_value
    sd p_hg%ptr_PixelHeight_value
    sd w
    sd h
    set w p_wd#
    set h p_hg#

    sd encoder
    setcall encoder mkv_read_encoder((value_get))
    if encoder==(format_mkv_i420)
        #convert yuv to rgb
        sd yuv
        setcall yuv mkv_rgb_yuv_functions((mkv_yuv_get_bytes))
        import "yuvi420_to_rgb" yuvi420_to_rgb
        call yuvi420_to_rgb(yuv,p_rgb#,w,h)
    endif

    #add make pixbuf from data
    importx "_gdk_pixbuf_new_from_data" gdk_pixbuf_new_from_data
    sd rowstride
    sd p_rowstride^rowstride
    call rgb_get_all_sizes(w,h,p_rowstride)
    sd pixbuf
    setcall pixbuf gdk_pixbuf_new_from_data(p_rgb#,(GDK_COLORSPACE_RGB),(FALSE),8,w,h,rowstride,(NULL),0)

    #keep the pixbuf
    import "pixbuf_copy" pixbuf_copy
    setcall px pixbuf_copy(pixbuf)
    if px==0
        return 0
    endif
    if encoder==(format_mkv_rgb24)
        #bitmap is right to left from file
        import "rgb_color_swap" rgb_color_swap
        sd newbytes
        setcall newbytes gdk_pixbuf_get_pixels(px)
        call rgb_color_swap(newbytes,w,h)
    endif
    call g_object_unref(pixbuf)

    #add to stage
    sd bool
    sd entry^px
    setcall bool stage_read_values((value_append),entry,8)
    return bool
endfunction










function mkv_codecid_data(sd io,sd arg,sd size)
    if io==(mkv_write)
        sd file
        set file arg
    #bool
        sd codec_ptr
        sd codec_sz

        sd encoder
        setcall encoder stage_file_get_mkv_encoder()
        if encoder==(format_mkv_i420)
                const codecid_i420_sz=1+1+1+1+1+1+1+1+1+1+1+1+1+1
            chars CodecID_i420_value={V,_,U,N,C,O,M,P,R,E,S,S,E,D}
            data p_uncomp^CodecID_i420_value

            set codec_ptr p_uncomp
            set codec_sz (codecid_i420_sz)
        elseif encoder==(format_mkv_mjpg)
                const codecid_mjpg_sz=1+1+1+1+1+1+1
            chars CodecID_mjpg_value={V,_,M,J,P,E,G}
            data p_mjpg^CodecID_mjpg_value

            set codec_ptr p_mjpg
            set codec_sz (codecid_mjpg_sz)
        elseif encoder==(format_mkv_xvid)
                const codecid_xvid_sz=1+1+1+1+1+1+ 1+1+    1+1+1+1+    1+1+1
            chars CodecID_xvid_value={V,_,M,P,E,G,_4,Slash,I,S,O,Slash,A,S,P}
            data p_xvid^CodecID_xvid_value

            set codec_ptr p_xvid
            set codec_sz (codecid_xvid_sz)
        else
        #if encoder==(format_mkv_rgb24)
                const codecid_rgb24_sz=1+1+1+1+1+    1+1+1+1+    1+1+1+1+1+1
            chars CodecID_rgb24_value={V,_,M,S,Slash,V,F,W,Slash,F,O,U,R,C,C}
            data p_rgb24^CodecID_rgb24_value

            set codec_ptr p_rgb24
            set codec_sz (codecid_rgb24_sz)
        endelse

        sd err
        setcall err file_write(codec_ptr,codec_sz,file)
        if err!=(noerror)
            return 0
        endif
        return 1
    else
    #void
        sd mem
        set mem arg

        import "cmpmem_s" cmpmem_s
        sd compare

        setcall compare cmpmem_s(mem,size,p_uncomp,(codecid_i420_sz))
        if compare==(equalCompare)
            call mkv_read_encoder(0,(format_mkv_i420))
            return (void)
        endif
        setcall compare cmpmem_s(mem,size,p_mjpg,(codecid_mjpg_sz))
        if compare==(equalCompare)
            call mkv_read_encoder(0,(format_mkv_mjpg))
            return (void)
        endif
        call mkv_read_encoder(0,(format_mkv_rgb24))
    endelse
endfunction


#void
function mkv_codecid_read(sd mem,sd size)
    call mkv_codecid_data((mkv_read),mem,size)
endfunction


function mkv_read_encoder(sd action,sd value)
    data encoder#1
    if action==(value_set)
    #void
        set encoder value
    else
        return encoder
    endelse
endfunction

function mkv_read_fps(sd action,sd value)
    data fps#1
    if action==(value_set)
        set fps value
    else
        return fps
    endelse
endfunction

#bool
function mkv_read_mjpeg(sd bytes,sd filerowstride,sd j)
    sd p_rgb
    setcall p_rgb mkv_rgb_yuv_functions((mkv_rgb_get_p_bytes))
    sd rgb
    set rgb p_rgb#
    sd p_wd%ptr_PixelWidth_value
    sd p_hg%ptr_PixelHeight_value
    sd w
    sd h
    set w p_wd#
    set h p_hg#
    import "rgb_get_rowstride" rgb_get_rowstride
    sd rowstride
    setcall rowstride rgb_get_rowstride(w)

    if filerowstride>rowstride
        ss rstr="Rowstride too large"
        call texter(rstr)
        return 0
    elseif j>=h
        ss herr="Height too big"
        call texter(herr)
        return 0
    endelseif

    mult rowstride j
    add rgb rowstride

    import "cpymem" cpymem
    call cpymem(rgb,bytes,filerowstride)

    return 1
endfunction


#sound entry
#bool
function mkv_sound(sd file,sd *size,sd *filepos)
    chars CodecID=0x86
 chars *CodecID_size=0x80+1+1+1+1+1+1+    1+1+1+1+    1+1+1
    chars *CodecID_value={A,_,P,C,M,Slash,I,N,T,Slash,L,I,T}
    chars *TrackNumber=0xD7
    chars *TrackNumber_size=0x81
    chars *TrackNumber_value=TrackNumber_audio
    chars *TrackUID={0x73,0xC5}
    chars *TrackUID_size=0x81
    chars *TrackUID_value=TrackNumber_audio
    chars *TrackType=0x83
    chars *TrackType_size=0x81
    chars *TrackType_value=2
    #audio type=2
    chars *FlagLacing=0x9C
    chars *FlagLacing_size=0x81
    chars *FlagLacing_value=0
    #no lacing used
    chars *Name={0x53,0x6E}
    chars *Name_size=0x85
    chars *Name_value={A,u,d,i,o}

    chars *Audio={0xE1}
    chars Audio_size=0x80
    chars SamplingFrequency=0xB5
    chars *SamplingFrequency_size=0x84
    data SamplingFrequency_value#1
    chars *Channels=0x9F
    chars *Channels_size=0x84
    data Channels_value#1
    chars *BitDepth={0x62,0x64}
    chars *BitDepth_size=0x84
    data BitDepth_value#1

    sd io
    setcall io mkv_write_read_get()
    if io==(mkv_write)
        const _audiospec^SamplingFrequency
        const audiospec_^BitDepth_value
        const audiospec_@=audiospec_+4
        const audiospec_size=audiospec_@-_audiospec
        or Audio_size (audiospec_size)

        import "stage_sound_rate" stage_sound_rate
        data freq#1
        setcall freq stage_sound_rate((value_get))
        setcall SamplingFrequency_value int_to_float(freq)
        setcall SamplingFrequency_value dword_reverse(SamplingFrequency_value)

        import "stage_sound_channels" stage_sound_channels
        setcall Channels_value stage_sound_channels((value_get))
        import "stage_sound_bps" stage_sound_bps
        setcall BitDepth_value stage_sound_bps((value_get))
        setcall Channels_value dword_reverse(Channels_value)
        setcall BitDepth_value dword_reverse(BitDepth_value)
    endif

    const _audio^CodecID
    const audio_size=audiospec_@-_audio
    data audio^CodecID

    sd bool
    setcall bool mkv_write_seek(audio,(audio_size),file)
    return bool
endfunction

function mkv_read_sound(sd mem,sd size)
    import "stage_sound_alloc_expand" stage_sound_alloc_expand
    call stage_sound_alloc_expand(mem,size)
endfunction
