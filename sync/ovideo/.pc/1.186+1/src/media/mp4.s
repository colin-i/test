
format elfobj

include "../_include/include.h"

import "mp4_sizes" mp4_sizes
import "mp4_times" mp4_times
import "mp4_tscale" mp4_tscale
import "mp4_duration" mp4_duration
import "mp4_timescale" mp4_timescale
import "mp4_duration_1000" mp4_duration_1000
import "mp4_SampleCount" mp4_SampleCount

import "avc_init" avc_init
import "avc_free" avc_free
import "avc_ProfileIndication" avc_ProfileIndication
import "avc_profile_compatibility" avc_profile_compatibility
import "avc_LevelIndication" avc_LevelIndication
import "avc_encode" avc_encode

import "mp4_write_expand_set" mp4_write_expand_set
import "mp4_write_expand_get" mp4_write_expand_get
#0 is write
const mp4_write=0
#1 is expand
const mp4_expand=1
import "mp4_sound_presence" mp4_sound_presence
import "mp4_sound_presence_get" mp4_sound_presence_get
import "mp4_audio_samples_set" mp4_audio_samples_set
import "mp4_audio_samples_get" mp4_audio_samples_get
import "mp4_info_set" mp4_info_set
import "mp4_info_get" mp4_info_get

import "dialog_modal_texter_draw" dialog_modal_texter_draw
const videoId=1
const soundId=2
const emptyId=3

const enable_flag=1
const sample_delta=1000

import "stage_nthwidgetFromcontainer" stage_nthwidgetFromcontainer
import "file_write" file_write

import "av_dialog_run" av_dialog_run
import "av_dialog_close" av_dialog_close
import "av_dialog_stop" av_dialog_stop



#importx "_fread" fread
#importx "_fwrite" fwrite
#function extragere(ss location)
#	data extragere_off1#1
#	const extr_1^extragere_off1
#	data extragere_off2#1
#	const extr_2^extragere_off2
#	sd file
#	call openfile(#file,location,"rb")
#	sd mp3_file
#	call openfile(#mp3_file,"captures/file.mp3","wb")
#	sd mp3_sz;set mp3_sz extragere_off2;sub mp3_sz extragere_off1
#	call file_seek_set(file,extragere_off1)
#	sd mp3Mem;setcall mp3Mem memalloc(mp3_sz)
#	Call fread(mp3Mem,1,mp3_sz,file)
#	Call fwrite(mp3Mem,1,mp3_sz,mp3_file)
#	call fclose(mp3_file)
#	call fclose(file)
#endfunction




function mp4_write()
    call mp4_write_expand_set((mp4_write))
    ss location
    import "stage_get_output_container" stage_get_output_container
    setcall location stage_get_output_container()
    call av_dialog_run(mp4_dialog,location)

#call extragere(location)

endfunction
#
function mp4_filewrite(sd file)
    sd ebox
    setcall ebox stage_nthwidgetFromcontainer(0)
    import "object_get_dword_name" object_get_dword_name
    sd pixbuf
    setcall pixbuf object_get_dword_name(ebox)
    call mp4_container(file,pixbuf)
endfunction

import "mp3_init" mp3_init
import "mp3_free" mp3_free

function mp4_container(sd file,sd pixbuf)
    sd bool
    setcall bool avc_init(pixbuf)
    if bool!=1
        return 0
    endif
    setcall bool mp3_init()
    if bool==1
        call mp4_file(file,pixbuf)
        call mp3_free()
    endif
    call avc_free()
endfunction

import "mp4_longest_duration" mp4_longest_duration
import "mp4_next_track" mp4_next_track
import "mp4_next_track_set" mp4_next_track_set
import "mp4_audio_profile" mp4_audio_profile
import "mp4_audio_profile_set" mp4_audio_profile_set

import "stage_sound_alloc_getremainingsize" stage_sound_alloc_getremainingsize
import "mp4_all_samples" mp4_all_samples
import "mp4_sound_duration" mp4_sound_duration
import "mp4_sample_count" mp4_sample_count
import "mp4_entrysize_offset" mp4_entrysize_offset
import "mp4_chunkoff" mp4_chunkoff

function mp4_file(sd file,sd pixbuf)
    call mp4_SampleCount((value_set))
    call mp4_sizes((value_set),pixbuf)
    call mp4_timescale((value_set))
    call mp4_duration((value_set))
    call mp4_duration_1000((value_set))
    sd duration
    setcall duration mp4_duration((value_get))
    sd l_duration
    setcall l_duration mp4_longest_duration()
    set l_duration# duration
    call mp4_next_track_set((soundId))
        #No audio capability required
    call mp4_audio_profile_set(0xff)
    sd bool
    #sound
    import "stage_sound_sizedone" stage_sound_sizedone
    call stage_sound_sizedone((value_set),0)
    sd is_sound_or_is_not
    setcall is_sound_or_is_not mp4_sound_presence_get()
    if is_sound_or_is_not==0
        setcall is_sound_or_is_not stage_sound_alloc_getremainingsize()
    endif
    if is_sound_or_is_not!=0
        sd sz
        setcall sz stage_sound_alloc_getremainingsize()
        addcall sz mp4_audio_samples_get()
        setcall bool mp4_sound_init(sz)
        if bool!=1
            return (void)
        endif
    endif
    #
    setcall bool mp4_start(file)
    if bool==(TRUE)
        call mp4_info_set(1)
    endif
endfunction
#bool
function mp4_start(sd file)
    sd bool
    str type="ftyp"
    data type_fwd^mp4_ftyp
    setcall bool mp4_piece(file,type,type_fwd)
    if bool!=1
        return (FALSE)
    endif
    str mov="moov"
    data mov_fwd^mp4_moov
    setcall bool mp4_piece(file,mov,mov_fwd)
    if bool!=1
        return (FALSE)
    endif
    #
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_expand)
        #at read for expand stop here
        return (TRUE)
    endif
    #
    str md="mdat"
    data md_fwd^mp4_mdat
    setcall bool mp4_piece(file,md,md_fwd)
    if bool!=1
        return (FALSE)
    endif
    return (TRUE)
endfunction

#bool
function mp4_piece(sd file,sd name,sd forward)
    sd bool
    setcall bool mp4_content(file,name,forward,0,4,0)
    return bool
endfunction

#bool
function mp4_content(sd file,sd name,sd forward,sd f_data,sd sizefield_bytes,sd substract)
    sd bool
    setcall bool mp4_wrap(file,name,forward,f_data,sizefield_bytes,substract,0)
    return bool
endfunction
import "file_read" file_read
#bool
function mp4_wrap(sd file,sd name,sd forward,sd f_data,sd sizefield_bytes,sd substract,sd p_SizeOfSample)
    import "file_tell" file_tell
    sd err
    #get the point for calculations
    sd file_pos_in
    sd ptr_file_pos_in^file_pos_in
    setcall err file_tell(file,ptr_file_pos_in)
    if err!=(noerror)
        return 0
    endif
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd dummy_size
        sd dummy^dummy_size
        setcall err file_write(dummy,sizefield_bytes,file)
        if err!=(noerror)
            return 0
        endif
    else
        sd read_size
        setcall err file_read(#read_size,sizefield_bytes,file)
        if err!=(noerror)
            return 0
        endif
    endelse
    sd bool
    if name!=0
        setcall bool mp4_write_seek(name,4,file)
        if bool!=(TRUE)
            return (FALSE)
        endif
    endif

    setcall bool forward(file,f_data)
    if bool!=1
        return 0
    endif

    sd arrange_size=1
    sd count
    set count sizefield_bytes
    while count!=4
        mult arrange_size 0x100
        inc count
    endwhile

    if procedure==(mp4_write)
        sd file_pos_out
        sd ptr_file_pos_out^file_pos_out
        setcall err file_tell(file,ptr_file_pos_out)
        if err!=(noerror)
            return 0
        endif
        import "file_seek_set" file_seek_set
        import "dword_reverse" dword_reverse
        sd size
        sd p_size^size
        set size file_pos_out

        sub size file_pos_in
        sub size substract
        mult size arrange_size

        if p_SizeOfSample!=0
            set p_SizeOfSample# size
        endif
        setcall size dword_reverse(size)
        setcall err file_seek_set(file,file_pos_in)
        if err!=(noerror)
            return 0
        endif
        setcall err file_write(p_size,sizefield_bytes,file)
        if err!=(noerror)
            return 0
        endif
        setcall err file_seek_set(file,file_pos_out)
        if err!=(noerror)
            return 0
        endif
    else
        setcall read_size dword_reverse(read_size)
        div read_size arrange_size
        add read_size substract
        add read_size file_pos_in
        setcall err file_seek_set(file,read_size)
        if err!=(noerror)
            return 0
        endif
    endelse

    return 1
endfunction

#bool
function mp4_ftyp(sd file)
const ftyp_start=!
    char GF_ISOM_BRAND_ISOM={i,s,o,m}
    char *minorVersion={0,0,0,1}
    char *brand={i,s,o,m}
    char *brand_1={a,v,c,_1}
const ftyp_size=!-ftyp_start
    data ftyp^GF_ISOM_BRAND_ISOM
    data ftyp_size=ftyp_size

    sd err
    setcall err mp4_write_or_no(ftyp,ftyp_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_moov(sd file)
    call mp4_times((value_set))

    str hd="mvhd"
    data hd_fwd^mp4_mvhd
    sd bool
    setcall bool mp4_piece(file,hd,hd_fwd)
    if bool!=1
        return 0
    endif
    str iod="iods"
    data iod_fwd^mp4_iods
    setcall bool mp4_piece(file,iod,iod_fwd)
    if bool!=1
        return 0
    endif
    str trk="trak"
    data trk_fwd^mp4_trak
    setcall bool mp4_piece(file,trk,trk_fwd)
    if bool!=1
        return 0
    endif

    #sound
    sd is_sound_or_is_not
    setcall is_sound_or_is_not mp4_sound_presence_get()
    if is_sound_or_is_not!=0
        str soundtrk="trak"
        data soundtrk_fwd^mp4_soundtrak
        setcall bool mp4_piece(file,soundtrk,soundtrk_fwd)
        if bool!=1
            return 0
        endif
    endif
    #

    return 1
endfunction

import "file_seek_cursor" file_seek_cursor
import "word_reverse" word_reverse
import "file_get_dword" file_get_dword

#bool
function mp4_mvhd(sd file)
const mvhd_start=!
    #movie header
    char version_u8={0}
    char *flags_u24={0,0,0}
    data creationTime#1
    data *modificationTime#1
    data timeScale#1
    data duration#1
    data preferredRate#1
    char preferredVolume#2
    char *reserved={0,0,0,0,0,0,0,0,0,0}
    data matrixA#1
    data *matrixB=0
    data *matrixU=0
    data *matrixC=0
    data matrixD#1
    data *matrixV=0
    data *matrixX=0
    data *matrixY=0
    data matrixW#1
    data *previewTime=0
    data *previewDuration=0
    data *posterTime=0
    data *selectionTime=0
    data *selectionDuration=0
    data *currentTime=0
const off_to_nexttrack=!-mvhd_start
    data nextTrackID#1
const mvhd_size=!-mvhd_start
    data mvhd^version_u8
    data mvhd_size=mvhd_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        data times^creationTime
        call mp4_times((value_get),times)
        setcall timeScale mp4_tscale((value_get))
        setcall timeScale dword_reverse(timeScale)
        #
        setcall duration mp4_longest_duration()
        setcall duration dword_reverse(duration#)
        #
        setcall preferredRate dword_reverse((2$16))
        ss vol^preferredVolume
        call word_reverse((2$8),vol)
        setcall matrixA dword_reverse((2$16))
        setcall matrixD dword_reverse((2$16))
        setcall matrixW dword_reverse((2$30))
        #
        sd nexttrack
        setcall nexttrack mp4_next_track()
        setcall nextTrackID dword_reverse(nexttrack#)

        sd err
        setcall err file_write(mvhd,mvhd_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor(file,(off_to_nexttrack))
        if err!=(noerror)
            return 0
        endif
        setcall err file_get_dword(file,#nextTrackID)
        if err!=(noerror)
            return 0
        endif
    endelse
    #back to little endian
    setcall nextTrackID dword_reverse(nextTrackID)
    if nextTrackID>(soundId)
        #incrementation because one or two calls means sound and zero means no sound
        sd presence
        setcall presence mp4_sound_presence()
        inc presence#
    endif

    return 1
endfunction

#bool
function mp4_iods(sd file)
    #InitialObjectDescriptor
    const GF_ODF_ISOM_IOD_TAG=0x10
    const iod_objectDescriptorId=1
    const iod_URLFlag=0
    const iod_inlineProfileFlag=0
    const iod_reserved=0xf

    char version=0
    char *flags={0,0,0}

    char *tag=GF_ODF_ISOM_IOD_TAG
    char *tag_size=7
    char iod_attr_data#2
    char *OD_profileAndLevel=0xff
    char *scene_profileAndLevel=0xff
    char audio_profileAndLevel#1
    #AVC/H264 Profile
    char *visual_profileAndLevel=0x15
    char *graphics_profileAndLevel=0xff

    data iod^version
    data _iod^iod
    data iod_size#1

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        set iod_size _iod
        sub iod_size iod

        sd data=iod_reserved
        sd mover=0x10
        sd concat

        set concat (iod_inlineProfileFlag)
        mult concat mover
        or data concat
        mult mover 2

        set concat (iod_URLFlag)
        mult concat mover
        or data concat
        mult mover 2

        set concat (iod_objectDescriptorId)
        mult concat mover
        or data concat

        str iod_attr^iod_attr_data
        call word_reverse(data,iod_attr)

        ss profile
        setcall profile mp4_audio_profile()
        set audio_profileAndLevel profile#

        sd err
        setcall err file_write(iod,iod_size,file)
        if err!=(noerror)
            return 0
        endif
    endif

    return 1
endfunction

#bool
function mp4_trak(sd file)
    sd bool

    str tkh="tkhd"
    data tkh_fwd^mp4_tkhd
    setcall bool mp4_piece(file,tkh,tkh_fwd)
    if bool!=1
        return 0
    endif
    str md="mdia"
    data md_fwd^mp4_mdia
    setcall bool mp4_piece(file,md,md_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_tkhd(sd file)
    char version_u8={0}
    char *flags_u24={0,0,enable_flag}
    data creationTime#1
    data *modificationTime#1
    char *trackID={0,0,0,videoId}
    data *reserved1=0
    data duration#1
    data *reserved2={0,0}
    char *layer={0,0}
    char *alternate_group={0,0}
    char *volume={0,0}
    char *reserved3={0,0}
    char *matrix0={0,1,0,0}
    data *matrix1=0
    data *matrix2=0
    data *matrix3=0
    char *matrix4={0,1,0,0}
    data *matrix5=0
    data *matrix6=0
    data *matrix7=0
    char *matrix8={0x40,0,0,0}
    data width#1
    data height#1

    data tkhd^version_u8
    data _tkhd^tkhd
    data tkhd_size#1

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        set tkhd_size _tkhd
        sub tkhd_size tkhd

        data tm^creationTime
        call mp4_times((value_get),tm)
        setcall duration mp4_duration((value_get))
        setcall duration dword_reverse(duration)
        sd wh^width
        call mp4_sizes((value_get),wh)
        mult width 0x10000
        mult height 0x10000
        setcall width dword_reverse(width)
        setcall height dword_reverse(height)

        sd err
        setcall err file_write(tkhd,tkhd_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_mdia(sd file)
    sd bool

    str mhd="mdhd"
    data mhd_fwd^mp4_mdhd
    setcall bool mp4_piece(file,mhd,mhd_fwd)
    if bool!=1
        return 0
    endif
    str hdl="hdlr"
    data hdl_fwd^mp4_hdlr
    setcall bool mp4_piece(file,hdl,hdl_fwd)
    if bool!=1
        return 0
    endif
    str mi="minf"
    data mi_fwd^mp4_minf
    setcall bool mp4_piece(file,mi,mi_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_mdhd(sd file)
    char version_u8={0}
    char *flags_u24={0,0,0}
    data creationTime#1
    data *modificationTime#1
    data timeScale#1
    data duration#1
    char language#2
    char *reserved={0,0}

    data mdhd^version_u8
    data _mdhd^mdhd
    data mdhd_size#1

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        set mdhd_size _mdhd
        sub mdhd_size mdhd

        sd times^creationTime
        call mp4_times((value_get),times)

        setcall timeScale mp4_timescale((value_get))
        setcall timeScale dword_reverse(timeScale)
        setcall duration mp4_duration_1000((value_get))
        setcall duration dword_reverse(duration)

        data lang_str^language
        call mp4_set_language(lang_str)

        sd err
        setcall err file_write(mdhd,mdhd_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

function mp4_set_language(sd pword)
    sd word=0
    sd aux
    ss lang="und"
    sd mover=0x8000
    #SPECS: BIT(1) of padding

    set aux lang#
    sub aux 0x60
    div mover (2$5)
    mult aux mover
    or word aux

    inc lang
    set aux lang#
    sub aux 0x60
    div mover (2$5)
    mult aux mover
    or word aux

    inc lang
    set aux lang#
    sub aux 0x60
    div mover (2$5)
    mult aux mover
    or word aux

    call word_reverse(word,pword)
endfunction

#bool
function mp4_hdlr(sd file)
const hdlr_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    data *reserved1=0
    char *handlerType={v,i,d,e}
    char *reserved2={0,0,0,0,0,0,0,0,0,0,0,0}
    #is null terminated
    #char *nameUTF8="GPAC ISO Video Handler"
    char *nameUTF8="OApplications Video"
const hdlr_size=!-hdlr_start
    data hdlr^version_u8
    data hdlr_size=hdlr_size

    sd err
    setcall err mp4_write_or_no(hdlr,hdlr_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_minf(sd file)
    sd bool

    str vhd="vmhd"
    data vhd_fwd^mp4_vmhd
    setcall bool mp4_piece(file,vhd,vhd_fwd)
    if bool!=1
        return 0
    endif
    #data info
    str di="dinf"
    data di_fwd^mp4_dinf
    setcall bool mp4_piece(file,di,di_fwd)
    if bool!=1
        return 0
    endif
    #sample table
    str stb="stbl"
    data stb_fwd^mp4_stbl
    setcall bool mp4_piece(file,stb,stb_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_vmhd(sd file)
    char version_u8={0}
    char *flags_u24={0,0,enable_flag}
    char *reserved={0,0,0,0,0,0,0,0}

    data vmhd^version_u8
    data _vmhd^vmhd
    data vmhd_size#1

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        set vmhd_size _vmhd
        sub vmhd_size vmhd

        sd err
        setcall err file_write(vmhd,vmhd_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_dinf(sd file)
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd bool
        str drf="dref"
        data drf_fwd^mp4_dref
        setcall bool mp4_piece(file,drf,drf_fwd)
        if bool!=1
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_dref(sd file)
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *count={0,0,0,1}

    data dref^version_u8
    data _dref^dref
    data dref_size#1
    set dref_size _dref
    sub dref_size dref

    sd err
    setcall err file_write(dref,dref_size,file)
    if err!=(noerror)
        return 0
    endif

    sd bool
    str url="url "
    data url_fwd^mp4_url
    setcall bool mp4_piece(file,url,url_fwd)
    if bool!=1
        return 0
    endif

    return 1
endfunction

#bool
function mp4_url(sd file)
    char version_u8={0}
    char *flags_u24={0,0,enable_flag}

    data url^version_u8
    data _url^url
    data url_size#1
    set url_size _url
    sub url_size url

    sd err
    setcall err file_write(url,url_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_stbl(sd file)
    sd bool
    #sample description
    str sd="stsd"
    data sd_fwd^mp4_stsd
    setcall bool mp4_piece(file,sd,sd_fwd)
    if bool!=1
        return 0
    endif
    #time scale
    str ts="stts"
    data ts_fwd^mp4_stts
    setcall bool mp4_piece(file,ts,ts_fwd)
    if bool!=1
        return 0
    endif
    #sync sample
    str ss="stss"
    data ss_fwd^mp4_stss
    setcall bool mp4_piece(file,ss,ss_fwd)
    if bool!=1
        return 0
    endif
    #sample to chunk
    str sc="stsc"
    data sc_fwd^mp4_stsc
    setcall bool mp4_piece(file,sc,sc_fwd)
    if bool!=1
        return 0
    endif
    #sample size
    str sz="stsz"
    data sz_fwd^mp4_stsz
    setcall bool mp4_piece(file,sz,sz_fwd)
    if bool!=1
        return 0
    endif
    #chunk offset
    str co="stco"
    data co_fwd^mp4_stco
    setcall bool mp4_piece(file,co,co_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_stsd(sd file)
const stsd_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *entryCount={0,0,0,1}
const stsd_size=!-stsd_start
    data stsd^version_u8
    data stsd_size=stsd_size

    sd bool
    setcall bool mp4_write_seek(stsd,stsd_size,file)
    if bool!=1
        return 0
    endif

    str avc="avc1"
    data avc_fwd^mp4_avc1
    setcall bool mp4_piece(file,avc,avc_fwd)
    if bool!=1
        return 0
    endif

    return 1
endfunction

#bool
function mp4_avc1(sd file)
const avc1_start=!
    char reserved={0,0,0,0,0,0}
    char *dataReferenceIndex={0,videoId}
    char *version={0,0}
    char *revision={0,0}
    data *vendor=0
    data *temporal_quality=0
    data *spacial_quality=0
    char Width#2
    char Height#2
    char *horiz_res={0,0x48,0,0}
    char *vert_res={0,0x48,0,0}
    data *entry_data_size=0
    char *frames_per_sample={0,1}
    char *compressor_name={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    char *bit_depth={0,0x18}
    char color_table_index#2
const avc1_size=!-avc1_start
    data avc1^reserved
    data avc1_size=avc1_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd w
        sd h
        sd wh^w
        call mp4_sizes((value_get),wh)
        sd W^Width
        sd H^Height
        call word_reverse(w,W)
        call word_reverse(h,H)
        sd cti^color_table_index
        call word_reverse(-1,cti)
    endif

    sd bool
    setcall bool mp4_write_seek(avc1,avc1_size,file)
    if bool!=1
        return 0
    endif

    #avc_config
    str avC="avcC"
    data avC_fwd^mp4_avcC
    setcall bool mp4_piece(file,avC,avC_fwd)
    if bool!=1
        return 0
    endif
    #bitrate
    str br="btrt"
    data br_fwd^mp4_btrt
    setcall bool mp4_piece(file,br,br_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_avcC(sd file)
const avcC_start=!
    char configurationVersion=1
    char AVCProfileIndication#1
    char profile_compatibility#1
    char AVCLevelIndication#1
    char cfg_data#2
const avcC_size=!-avcC_start
    data avcfg_main^configurationVersion
    data avcfg_main_size=avcC_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        setcall AVCProfileIndication avc_ProfileIndication((value_get))
        setcall profile_compatibility avc_profile_compatibility((value_get))
        setcall AVCLevelIndication avc_LevelIndication((value_get))

        sd word=0
        sd aux
        sd mover=0x10000

        set aux 0x3f
        div mover (2$6)
        mult aux mover
        or word aux

        sd nal_unit_size=4
        sub nal_unit_size 1
        div mover (2$2)
        mult nal_unit_size mover
        or word nal_unit_size

        set aux 0x7
        div mover (2$3)
        mult aux mover
        or word aux

        sd list_count=1
        or word list_count

        sd cfg_d^cfg_data
        call word_reverse(word,cfg_d)

        sd err
        sd bool
        #
        setcall err file_write(avcfg_main,avcfg_main_size,file)
        if err!=(noerror)
            return 0
        endif
        #
        data avc_fn^avc_encode
        setcall bool mp4_content(file,0,avc_fn,(avc_sequence_param),2,2)
        if bool!=1
            return 0
        endif
        #
        char count=1
        sd p_count^count
        setcall err file_write(p_count,1,file)
        if err!=(noerror)
            return 0
        endif
        #
        setcall bool mp4_content(file,0,avc_fn,(avc_picture_param),2,2)
        if bool!=1
            return 0
        endif
    endif
    return 1
endfunction

import "mp4_bufferSzOffset" mp4_bufferSzOffset
import "mp4_avgbitrateOffset" mp4_avgbitrateOffset

import "mp4_video_bufferSz_set" mp4_video_bufferSz_set
import "mp4_video_bufferSz_get" mp4_video_bufferSz_get

#bool
function mp4_btrt(sd file)
const btrt_start=!
    data bufferSizeDB#1
    data *maxBitrate=0
    data *avgBitrate#1
const btrt_size=!-btrt_start
    data btrt^bufferSizeDB
    data btrt_size=btrt_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd file_pos
        sd ptr_file_pos^file_pos
        sd err
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        call mp4_bufferSzOffset((value_set),file_pos)
        add file_pos 8
        call mp4_avgbitrateOffset((value_set),file_pos)

        setcall err file_write(btrt,btrt_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_get_dword(file,#bufferSizeDB)
        if err!=(noerror)
            return 0
        endif
        setcall bufferSizeDB dword_reverse(bufferSizeDB)
        call mp4_video_bufferSz_set(bufferSizeDB)
    endelse
    return 1
endfunction

import "mp4_video_samples_set" mp4_video_samples_set
import "mp4_video_samples_get" mp4_video_samples_get
import "file_seek_cursor_get_dword_reverse" file_seek_cursor_get_dword_reverse

#bool
function mp4_stts(sd file)
const mp4_stts_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *list_count={0,0,0,1}
const mp4_stts_sampleCount_offset=!-mp4_stts_start
    data sampleCount#1
    data sampleDelta#1
const mp4_stts_size=!-mp4_stts_start

    data stts^version_u8
    data stts_size=mp4_stts_size

    sd err
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        setcall sampleCount mp4_SampleCount((value_get))
        setcall sampleCount dword_reverse(sampleCount)
        setcall sampleDelta dword_reverse((sample_delta))

        setcall err file_write(stts,stts_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor_get_dword_reverse(file,(mp4_stts_sampleCount_offset),#sampleCount)
        if err!=(noerror)
            return 0
        endif
        call mp4_video_samples_set(sampleCount)
    endelse

    return 1
endfunction

#bool
function mp4_stss(sd file)
const stss_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *entryCount={0,0,0,1}
    char *sampleNumber={0,0,0,1}
const stss_size=!-stss_start
    data stss^version_u8
    data stss_size=stss_size

    sd err
    setcall err mp4_write_or_no(stss,stss_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_stsc(sd file)
const stsc_start=!
    char version={0}
    char *flags={0,0,0}
    char *list_count={0,0,0,1}
    char *firstChunk={0,0,0,1}
    data samplesPerChunk#1
    char *sampleDescriptionIndex={0,0,0,1}
const stsc_size=!-stsc_start
    data stsc^version
    data stsc_size=stsc_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        setcall samplesPerChunk mp4_SampleCount((value_get))
        setcall samplesPerChunk dword_reverse(samplesPerChunk)

        sd err
        setcall err file_write(stsc,stsc_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_stsz(sd file)
const stsz_start=!
    char version={0}
    char *flags={0,0,0}
    data *sampleSize=0
    data sampleCount#1
const stsz_size=!-stsz_start
    data stsz^version
    data stsz_size=stsz_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd NrOfSamples
        setcall NrOfSamples mp4_SampleCount((value_write))
        setcall sampleCount dword_reverse(NrOfSamples)

        sd err
        setcall err file_write(stsz,stsz_size,file)
        if err!=(noerror)
            return 0
        endif

        import "mp4_samplesOffset" mp4_samplesOffset
        sd file_pos
        sd ptr_file_pos^file_pos
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        call mp4_samplesOffset((value_set),file_pos)
        sd dummy_data
        sd dummy^dummy_data
        while NrOfSamples!=0
            setcall err file_write(dummy,4,file)
            if err!=(noerror)
                return 0
            endif
            dec NrOfSamples
        endwhile
    endif
    return 1
endfunction
import "mp4_video_offset_set" mp4_video_offset_set
import "mp4_video_offset_get" mp4_video_offset_get
#bool
function mp4_stco(sd file)
const stco_start=!
    char version={0}
    char *flags={0,0,0}
    char *entries={0,0,0,1}
const stco_offset_pos=!-stco_start
    data offset#1
const stco_size=!-stco_start
    data stco^version
    data stco_size=stco_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        import "mp4_chunksOffset" mp4_chunksOffset
        sd file_pos
        sd ptr_file_pos^file_pos
        sd err
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        add file_pos 8
        call mp4_chunksOffset((value_set),file_pos)

        setcall err file_write(stco,stco_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor_get_dword_reverse(file,(stco_offset_pos),#offset)
        if err!=(noerror)
            return 0
        endif
        call mp4_video_offset_set(offset)
    endelse
    return 1
endfunction

import "memalloc" memalloc
importx "_free" free
import "texter" texter

import "mp4_expand_startfile_set" mp4_expand_startfile_set
import "mp4_expand_startfile_get" mp4_expand_startfile_get

import "file_seekSet_setDwRev_goEnd" file_seekSet_setDwRev_goEnd

#bool
function mp4_mdat(sd file)

#data off1%extr_1
#call file_tell(file,off1)

    sd bool
    setcall bool mp4_mdat_sound(file)
    if bool!=1
        return 0
    endif

    #get chunk offset
    sd ch_off
    setcall ch_off mp4_chunksOffset((value_get))
    sd file_pos
    sd ptr_file_pos^file_pos
    sd err
    setcall err file_tell(file,ptr_file_pos)
    if err!=(noerror)
        return 0
    endif
    setcall bool file_seekSet_setDwRev_goEnd(file,ch_off,file_pos)
    if bool!=(TRUE)
        return (FALSE)
    endif

#data off2%extr_2
#set off2# file_pos

    #
    sd all_size_of_sample
    sd p_all_size_of_sample^all_size_of_sample
    #
    sd sz_off
    setcall sz_off mp4_samplesOffset((value_get))
    #
    sd size_of_sample
    sd p_size_of_sample^size_of_sample
    #
    sd max_size
    setcall max_size mp4_video_bufferSz_get()
    #
    sd all_size=0

    const chunk_size_sz=4

    data avc_fn^avc_encode
    setcall bool mp4_wrap(file,0,avc_fn,(avc_frame0_headers),(chunk_size_sz),(chunk_size_sz),p_all_size_of_sample)
    if bool!=1
        return 0
    endif
    add all_size_of_sample (chunk_size_sz)

    sd force_start_encode=30

    #can be expand
    sd off_v
    setcall off_v mp4_video_offset_get()
    if off_v!=0
        sd ex_file
        setcall ex_file mp4_expand_startfile_get()
        setcall err file_seek_set(ex_file,off_v)
        if err!=(noerror)
            return 0
        endif
        #skip header
        import "file_get_dword_reverse" file_get_dword_reverse
        setcall err file_get_dword_reverse(ex_file,p_size_of_sample)
        if err!=(noerror)
            return 0
        endif
        setcall err file_seek_cursor(ex_file,size_of_sample)
        if err!=(noerror)
            return 0
        endif
        #
        sd mem
        setcall mem memalloc(max_size)
        if mem==0
            return 0
        endif
        sd ex_samples
        setcall ex_samples mp4_video_samples_get()
        while ex_samples!=0
            #
            setcall err file_get_dword_reverse(ex_file,p_size_of_sample)
            if err!=(noerror)
                call free(mem)
                return 0
            endif
            sd sz
            setcall sz dword_reverse(size_of_sample)
            setcall err file_write(#sz,(chunk_size_sz),file)
            if err!=(noerror)
                call free(mem)
                return 0
            endif
            if max_size<size_of_sample
                call texter("error at expand video")
                call free(mem)
                return 0
            endif
            setcall err file_read(mem,size_of_sample,ex_file)
            if err!=(noerror)
                call free(mem)
                return 0
            endif
            setcall err file_write(mem,size_of_sample,file)
            if err!=(noerror)
                call free(mem)
                return 0
            endif
            #
            add size_of_sample (chunk_size_sz)
            setcall bool mp4_avc_loop_sizes(file,size_of_sample,p_all_size_of_sample,#sz_off,#max_size,#all_size)
            if bool!=1
                call free(mem)
                return 0
            endif
            dec ex_samples
        endwhile
        call free(mem)
        set force_start_encode 0
    endif

    #
    import "stage_get_frames" stage_get_frames
    sd current_frame=0
    sd f_size=-1
    sd number_of_slices
    setcall number_of_slices stage_get_frames()
    sd current_slice=0
    while current_slice!=number_of_slices
        sd encode_slice
        if f_size<0
            set encode_slice current_slice
        elseif current_frame>force_start_encode
            set encode_slice -1
        else
        #at fixed frame rate we use zero length frames at this version
        #some players may skip the start frame (frames?), encode at the beginning as p_skip
            set encode_slice current_slice
        endelse
        data fn^mp4_avc
        setcall bool mp4_wrap(file,0,fn,encode_slice,(chunk_size_sz),(chunk_size_sz),p_size_of_sample)
        if bool!=1
            return 0
        endif
        add size_of_sample (chunk_size_sz)
        setcall bool mp4_avc_loop_sizes(file,size_of_sample,p_all_size_of_sample,#sz_off,#max_size,#all_size)
        if bool!=1
            return 0
        endif
        if f_size<0
            import "stage_frame_time_numbers" stage_frame_time_numbers
            setcall f_size stage_frame_time_numbers((stage_frame_time_get_at_index),encode_slice)
        endif
        dec f_size
        if f_size==0
            set f_size -1
            inc current_slice
        endif
        inc current_frame
    endwhile

    #max buffer
    sd bf_offset
    setcall bf_offset mp4_bufferSzOffset((value_get))
    setcall bool file_seekSet_setDwRev_goEnd(file,bf_offset,max_size)
    if bool==0
        return 0
    endif
    #average bit rate
    import "int_to_double" int_to_double
    import "double_div" double_div
    import "double_to_int" double_to_int
    sd avgBitrate
    set avgBitrate all_size
    sd br_double#2
    sd br^br_double
    sd tscale_double#2
    sd tscale^tscale_double
    sd avgb_double#2
    sd avgb^avgb_double
    sd value
    setcall value mp4_timescale((value_get))
    sd len
    setcall len mp4_SampleCount((value_get))
    mult len (sample_delta)
    call int_to_double(len,br)
    call int_to_double(value,tscale)
    call double_div(br,tscale)
    call int_to_double(avgBitrate,avgb)
    call double_div(avgb,br)
    setcall avgBitrate double_to_int(avgb)
    mult avgBitrate 8
    sd avg_off
    setcall avg_off mp4_avgbitrateOffset((value_get))
    setcall bool file_seekSet_setDwRev_goEnd(file,avg_off,avgBitrate)
    if bool!=1
        return 0
    endif
    #avgBitrate = (u32) ((Double) (s64)avg_rate / br)
    #avgBitrate *= 8
    return 1
endfunction

#bool
function mp4_avc_loop_sizes(sd file,sd size_of_sample,sd p_all_size_of_sample,sd p_sz_off,sd p_max_size,sd p_all_size)
    #all_size_of_sample is needed at start when we have the header included in the first frame
    add p_all_size_of_sample# size_of_sample
    if p_all_size_of_sample#>p_max_size#
        #about max buffer size
        set p_max_size# p_all_size_of_sample#
    endif
    #about average bit rate
    add p_all_size# p_all_size_of_sample#
    #add at stsz
    sd bool
    setcall bool file_seekSet_setDwRev_goEnd(file,p_sz_off#,p_all_size_of_sample#)
    if bool!=(TRUE)
        return (FALSE)
    endif
    #next offset at stsz
    add p_sz_off# 4
    #
    set p_all_size_of_sample# 0
    return (TRUE)
endfunction

#bool
function mp4_avc(sd file,sd current_slice)
    sd stop
    setcall stop av_dialog_stop((value_get))
    if stop==1
        return 0
    endif
    if current_slice<0
        return 1
    endif
    #
    import "av_display_info" av_display_info
    call av_display_info((value_get),file)
    #
    sd bool
    sd eventbox
    setcall eventbox stage_nthwidgetFromcontainer(current_slice)
    sd pixbuf
    setcall pixbuf object_get_dword_name(eventbox)
    setcall bool avc_encode(file,(avc_frame),pixbuf)
    if bool!=1
        return 0
    endif
    #info display
    import "av_display_info_progress" av_display_info_progress
    call av_display_info_progress(file,current_slice)
    #
    return 1
endfunction

#sound
import "mp4_audio_offset_set" mp4_audio_offset_set
import "mp4_audio_offset_get" mp4_audio_offset_get
import "mp4_audio_bufferSz_set" mp4_audio_bufferSz_set
import "mp4_audio_bufferSz_get" mp4_audio_bufferSz_get
import "mp4_audio_maxBitrate_set" mp4_audio_maxBitrate_set
import "mp4_audio_maxBitrate_get" mp4_audio_maxBitrate_get

#bool
function mp4_mdat_sound(sd file)
    sd bool
    sd err
    sd file_pos
    sd ptr_file_pos^file_pos

    #sound
    import "mp3_encode" mp3_encode
    sd is_sound_or_is_not
    setcall is_sound_or_is_not mp4_sound_presence_get()
    if is_sound_or_is_not!=0
        sd off
        #sound offset
        setcall off mp4_chunkoff()
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        #
        setcall bool file_seekSet_setDwRev_goEnd(file,off#,file_pos)
        if bool!=1
            return 0
        endif
        #
        sd sound_size=0
        sd p_sound_size^sound_size
        #can be expand
        sd off_a
        setcall off_a mp4_audio_offset_get()
        if off_a!=0
            sd off_v
            setcall off_v mp4_video_offset_get()
            if off_v!=0
                set sound_size off_v
                sub sound_size off_a
                sd ex_file
                setcall ex_file mp4_expand_startfile_get()
                setcall err file_seek_set(ex_file,off_a)
                if err!=(noerror)
                    return 0
                endif
                sd mem
                setcall mem memalloc(sound_size)
                if mem==0
                    call free(mem)
                    return 0
                endif
                setcall err file_read(mem,sound_size,ex_file)
                if err!=(noerror)
                    call free(mem)
                    return 0
                endif
                setcall err file_write(mem,sound_size,file)
                if err!=(noerror)
                    call free(mem)
                    return 0
                endif
                call free(mem)
            endif
        endif
        #
        sd max_sound_size
        setcall max_sound_size mp4_audio_bufferSz_get()
        #
        sd all_sound_size
        set all_sound_size sound_size
        #
        #sd count=0
        sd rate=0
        #
        sd max_rate
        setcall max_rate mp4_audio_maxBitrate_get()
        #
        sd timescale=mp3_samplerate
        sd samples=0
        sd loop=1
        while loop==1
            sd stop_question
            setcall stop_question av_dialog_stop((value_get))
            if stop_question==1
                return 0
            endif
            setcall err file_tell(file,ptr_file_pos)
            if err!=(noerror)
                return 0
            endif
            setcall bool mp3_encode(file)
            if bool!=1
                return 0
            endif
            setcall err file_tell(file,p_sound_size)
            if err!=(noerror)
                return 0
            endif
            sub sound_size file_pos
            if max_sound_size<sound_size
                set max_sound_size sound_size
            endif
            #inc count
            add rate sound_size
            add samples (samp_per_frame)
            add all_sound_size sound_size
            if samples>=timescale
                if max_rate<rate
                    set max_rate rate
                endif
                set samples 0
                set rate 0
            endif
            #
            importx "_sprintf" sprintf
            sd bytesleft
            setcall bytesleft stage_sound_alloc_getremainingsize()
            const soundbufstart=!
            char format="Sound Bytes Left: %u"
            char buffer#!-soundbufstart-2+dword_max
            vstr buf^buffer
            call sprintf(buf,#format,bytesleft)
            call dialog_modal_texter_draw(buf)
            #
            import "mp3_encode_test" mp3_encode_test
            setcall loop mp3_encode_test()
        endwhile
        #at stsz
        setcall off mp4_entrysize_offset()
        setcall bool file_seekSet_setDwRev_goEnd(file,off#,max_sound_size)
        if bool!=1
            return 0
        endif
        #move to esds
        sd esds_offsets
        setcall esds_offsets mp4_sound_esds_items_offset()
        setcall err file_seek_set(file,esds_offsets#)
        if err!=(noerror)
            return 0
        endif
        #bufferSizeDB
        mult max_sound_size 0x100
        setcall max_sound_size dword_reverse(max_sound_size)
        sd p_max^max_sound_size
        setcall err file_write(p_max,3,file)
        if err!=(noerror)
            return 0
        endif
        #maxBitrate
        sd maxBitrate
        sd p_maxBitrate^maxBitrate
        set maxBitrate max_rate
        mult maxBitrate 8
        setcall maxBitrate dword_reverse(maxBitrate)
        setcall err file_write(p_maxBitrate,4,file)
        if err!=(noerror)
            return 0
        endif
        #avgBitrate
        import "fild_value" fild_value
        import "fstp_quad" fstp_quad
        import "fdiv_quad" fdiv_quad
        import "fistp" fistp
        call fild_value(all_sound_size)
        sd all_samples
        setcall all_samples mp4_all_samples()
        call fild_value(all_samples#)
        data double_data#2
        data double^double_data
        call fild_value(timescale)
        call fstp_quad(double)
        call fdiv_quad(double)
        call fstp_quad(double)
        call fdiv_quad(double)
        data sound_avgBitrate#1
        data p_sound_avgBitrate^sound_avgBitrate
        call fistp(p_sound_avgBitrate)
        mult sound_avgBitrate 8
        setcall sound_avgBitrate dword_reverse(sound_avgBitrate)
        setcall err file_write(p_sound_avgBitrate,4,file)
        if err!=(noerror)
            return 0
        endif
        #
        import "file_seek_end" file_seek_end
        setcall err file_seek_end(file)
        if err!=(noerror)
            return 0
        endif
    endif

    return 1
endfunction

#bool
function mp4_soundtrak(sd file)
    sd bool
    str tkh="tkhd"
    data tkh_fwd^mp4_soundtkhd
    setcall bool mp4_piece(file,tkh,tkh_fwd)
    if bool!=1
        return 0
    endif
    str md="mdia"
    data md_fwd^mp4_soundmdia
    setcall bool mp4_piece(file,md,md_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_soundtkhd(sd file)
const soundtkhd_start=!
    char version_u8={0}
    char *flags_u24={0,0,enable_flag}
    data creationTime#1
    data *modificationTime#1
    char *trackID={0,0,0,soundId}
    data *reserved1=0
    data duration#1
    data *reserved2={0,0}
    char *layer={0,0}
    char *alternate_group={0,0}
    char *volume={1,0}
    char *reserved3={0,0}
    char *matrix0={0,1,0,0}
    data *matrix1=0
    data *matrix2=0
    data *matrix3=0
    char *matrix4={0,1,0,0}
    data *matrix5=0
    data *matrix6=0
    data *matrix7=0
    char *matrix8={0x40,0,0,0}
    data *width=0
    data *height=0
const soundtkhd_size=!-soundtkhd_start
    data tkhd^version_u8
    data tkhd_size=soundtkhd_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        data tm^creationTime
        call mp4_times((value_get),tm)
        setcall duration mp4_sound_duration()
        set duration duration#

        sd err
        setcall err file_write(tkhd,tkhd_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_soundmdia(sd file)
    sd bool

    str mhd="mdhd"
    data mhd_fwd^mp4_soundmdhd
    setcall bool mp4_piece(file,mhd,mhd_fwd)
    if bool!=1
        return 0
    endif
    str hdl="hdlr"
    data hdl_fwd^mp4_soundhdlr
    setcall bool mp4_piece(file,hdl,hdl_fwd)
    if bool!=1
        return 0
    endif
    str mi="minf"
    data mi_fwd^mp4_soundminf
    setcall bool mp4_piece(file,mi,mi_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_soundmdhd(sd file)
const soundmdhd_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    data creationTime#1
    data *modificationTime#1
    data timeScale#1
const soundmdhd_duration=!-soundmdhd_start
    data duration#1
    char language#2
    char *reserved={0,0}
const soundmdhd_size=!-soundmdhd_start
    data mdhd^version_u8
    data mdhd_size=soundmdhd_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd times^creationTime
        call mp4_times((value_get),times)
        set timeScale (mp3_samplerate)
        setcall timeScale dword_reverse(timeScale)
        setcall duration mp4_all_samples()
        setcall duration dword_reverse(duration#)
        data lang_str^language
        call mp4_set_language(lang_str)
        sd err
        setcall err file_write(mdhd,mdhd_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor_get_dword_reverse(file,(soundmdhd_duration),#duration)
        if err!=(noerror)
            return 0
        endif
        mult duration (mp3_blockalign)
        call mp4_audio_samples_set(duration)
    endelse
    return 1
endfunction

#bool
function mp4_soundhdlr(sd file)
const soundhdlr_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    data *reserved1=0
    char *handlerType={s,o,u,n}
    char *reserved2={0,0,0,0,0,0,0,0,0,0,0,0}
    #is null terminated
    #char *nameUTF8="GPAC ISO Audio Handler"
    char *nameUTF8="OApplications Audio"
const soundhdlr_size=!-soundhdlr_start
    data hdlr^version_u8
    data hdlr_size=soundhdlr_size

    sd err
    setcall err mp4_write_or_no(hdlr,hdlr_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_soundminf(sd file)
    sd bool
    str shd="smhd"
    data shd_fwd^mp4_smhd
    setcall bool mp4_piece(file,shd,shd_fwd)
    if bool!=1
        return 0
    endif
    #data info
    str di="dinf"
    data di_fwd^mp4_dinf
    setcall bool mp4_piece(file,di,di_fwd)
    if bool!=1
        return 0
    endif
    #sample table
    str stb="stbl"
    data stb_fwd^mp4_soundstbl
    setcall bool mp4_piece(file,stb,stb_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_smhd(sd file)
const sound_smhd_start=!
    char version=0
    char *flags={0,0,0}
    data *reserved=0
const sound_smhd_size=!-sound_smhd_start
    data smhd^version
    data smhd_size=sound_smhd_size

    sd err
    setcall err mp4_write_or_no(smhd,smhd_size,file)
    if err!=(noerror)
        return 0
    endif
    return 1
endfunction

#bool
function mp4_soundstbl(sd file)
    sd bool
    #sample description
    str sd="stsd"
    data sd_fwd^mp4_soundstsd
    setcall bool mp4_piece(file,sd,sd_fwd)
    if bool!=1
        return 0
    endif
    #time scale
    str ts="stts"
    data ts_fwd^mp4_soundstts
    setcall bool mp4_piece(file,ts,ts_fwd)
    if bool!=1
        return 0
    endif
    #sample to chunk
    str sc="stsc"
    data sc_fwd^mp4_soundstsc
    setcall bool mp4_piece(file,sc,sc_fwd)
    if bool!=1
        return 0
    endif
    #sample size
    str sz="stsz"
    data sz_fwd^mp4_soundstsz
    setcall bool mp4_piece(file,sz,sz_fwd)
    if bool!=1
        return 0
    endif
    #chunk offset
    str co="stco"
    data co_fwd^mp4_soundstco
    setcall bool mp4_piece(file,co,co_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction

#bool
function mp4_soundstsd(sd file)
const soundstsd_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *entryCount={0,0,0,1}
const soundstsd_size=!-soundstsd_start
    data stsd^version_u8
    data stsd_size=soundstsd_size

    sd bool
    setcall bool mp4_write_seek(stsd,stsd_size,file)
    if bool!=1
        return 0
    endif

    str avc="mp4a"
    data avc_fwd^mp4_mp4a
    setcall bool mp4_piece(file,avc,avc_fwd)
    if bool!=1
        return 0
    endif

    return 1
endfunction

#bool
function mp4_mp4a(sd file)
const mp4a_start=!
    char reserved={0,0,0,0,0,0}
    char *dataReferenceIndex={0,videoId}
    char *version={0,0}
    char *revision={0,0}
    data *vendor=0
    char *channel_count={0,mp3_channels}
    char *bitspersample={0,mp3_bitspersample}
    char *compression_id={0,0}
    char *packet_size={0,0}
    char samplerate_hi#2
    char *samplerate_lo={0,0}
const mp4a_size=!-mp4a_start
    data mp4a^reserved
    data mp4a_size=mp4a_size
    #
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        import "int_into_short" int_into_short
        sd sr
        setcall sr dword_reverse((mp3_samplerate))
        div sr (0x100*0x100)
        sd p^samplerate_hi
        call int_into_short(sr,p)
    endif

    sd bool
    setcall bool mp4_write_seek(mp4a,mp4a_size,file)
    if bool!=(TRUE)
        return (FALSE)
    endif


    str esds="esds"
    data esds_fwd^mp4_esds
    setcall bool mp4_piece(file,esds,esds_fwd)
    if bool!=1
        return 0
    endif
    return 1
endfunction


#bool
function mp4_esds(sd file)
const esds_start=!
    char version=0
    char *flags={0,0,0}
    char *GF_ODF_ESD_TAG=3
    char esd_size#1

    char ESID={0,0}
    #lengths: dependsOnESID 1,URLString 1,OCRESID 1,streamPriority 5
    char *info=0

    char *GF_ODF_DCD_TAG=4
    char dcd_size#1
        const objectTypeIndication_MPEG1Audio=0x6b
    char objectTypeIndication=objectTypeIndication_MPEG1Audio
        const GF_STREAM_AUDIO=5
    const streamType_value=GF_STREAM_AUDIO
    const upstream_value=0
    const upstream_shift=2$1
    const reserved_value=1
        const reserved_shift=2$1
        const upstream_pack=upstream_value*reserved_shift
        const streamType_shift_pack=reserved_shift*upstream_shift
        const streamType_pack=streamType_value*streamType_shift_pack
    char *info=streamType_pack|upstream_pack|reserved_value
const sound_bufferSizeDB_offset=!-esds_start
    char bufferSizeDB#3
    data maxBitrate#1
    data *avgBitrate#1

    char GF_ODF_SLC_TAG=6
    char slc_size#1
        const SLPredef_MP4=2
    char predefined=SLPredef_MP4
const esds_size=!-esds_start
    data esds^version
    data esds_size=esds_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        const _esds^ESID
        const esds_^esds
        set esd_size (esds_-_esds)

        const _dcd^objectTypeIndication
        const dcd_^GF_ODF_SLC_TAG
        set dcd_size (dcd_-_dcd)

        const _slc^predefined
        const slc_^esds
        set slc_size (slc_-_slc)

        sd err
        sd file_pos
        sd ptr_file_pos^file_pos

        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif

        setcall err file_write(esds,esds_size,file)
        if err!=(noerror)
            return 0
        endif

        const _DCD^version
        const DCD_^bufferSizeDB
        add file_pos (DCD_-_DCD)

        sd off
        setcall off mp4_sound_esds_items_offset()
        set off# file_pos
    else
        setcall err file_seek_cursor(file,(sound_bufferSizeDB_offset))
        if err!=(noerror)
            return 0
        endif
        sd bf_sz
        setcall err file_read(#bf_sz,3,file)
        if err!=(noerror)
            return 0
        endif
        setcall bf_sz dword_reverse(bf_sz)
        div bf_sz 0x100
        call mp4_audio_bufferSz_set(bf_sz)
        #
        setcall err file_get_dword(file,#maxBitrate)
        if err!=(noerror)
            return 0
        endif
        setcall maxBitrate dword_reverse(maxBitrate)
        div maxBitrate 8
        call mp4_audio_maxBitrate_set(maxBitrate)
    endelse
    return 1
endfunction

function mp4_sound_esds_items_offset()
    data offset#1
    data p^offset
    return p
endfunction

#bool
function mp4_soundstts(sd file)
const soundstts_start=!
    char version_u8={0}
    char *flags_u24={0,0,0}
    char *list_count={0,0,0,1}
    data sampleCount#1
    data sampleDelta#1
const soundstts_size=!-soundstts_start
    data stts^version_u8
    data stts_size=soundstts_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd sample_count
        setcall sample_count mp4_sample_count()
        setcall sampleCount dword_reverse(sample_count#)
        setcall sampleDelta dword_reverse((samp_per_frame))

        sd err
        setcall err file_write(stts,stts_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_soundstsc(sd file)
const soundstsc_start=!
    char version={0}
    char *flags={0,0,0}
    char *list_count={0,0,0,1}
    char *firstChunk={0,0,0,1}
    data samplesPerChunk#1
    char *sampleDescriptionIndex={0,0,0,1}
const soundstsc_size=!-soundstsc_start
    data stsc^version
    data stsc_size=soundstsc_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd sample_count
        setcall sample_count mp4_sample_count()
        setcall samplesPerChunk dword_reverse(sample_count#)

        sd err
        setcall err file_write(stsc,stsc_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_soundstsz(sd file)
const soundstsz_start=!
    char version={0}
    char *flags={0,0,0}
    data sampleSize#1
    data sampleCount#1
const soundstsz_size=!-soundstsz_start
    data stsz^version
    data stsz_size=soundstsz_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd err
        sd file_pos
        sd ptr_file_pos^file_pos
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        const _stsz_size^version
        const stsz_size_^sampleSize
        sd off
        setcall off mp4_entrysize_offset()
        add file_pos (stsz_size_-_stsz_size)
        set off# file_pos

        sd sample_count
        setcall sample_count mp4_sample_count()
        setcall sampleCount dword_reverse(sample_count#)

        setcall err file_write(stsz,stsz_size,file)
        if err!=(noerror)
            return 0
        endif
    endif
    return 1
endfunction

#bool
function mp4_soundstco(sd file)
const soundstco_start=!
    char version={0}
    char *flags={0,0,0}
    char *entries={0,0,0,1}
const soundstco_offset_pos=!-soundstco_start
    data offset#1
const soundstco_size=!-soundstco_start
    data stco^version
    data stco_size=soundstco_size

    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        sd err
        sd file_pos
        sd ptr_file_pos^file_pos
        setcall err file_tell(file,ptr_file_pos)
        if err!=(noerror)
            return 0
        endif
        const _stco_off^version
        const stco_off_^offset
        sd off
        setcall off mp4_chunkoff()
        add file_pos (stco_off_-_stco_off)
        set off# file_pos

        setcall err file_write(stco,stco_size,file)
        if err!=(noerror)
            return 0
        endif
    else
        setcall err file_seek_cursor_get_dword_reverse(file,(soundstco_offset_pos),#offset)
        if err!=(noerror)
            return 0
        endif
        call mp4_audio_offset_set(offset)
    endelse
    return 1
endfunction

#
#bool
function mp4_sound_init(sd all_size)
    #all samples
    sd all_samples
    setcall all_samples mp4_all_samples()
    sd samples
    set samples all_size
    div samples (buffer_size)
    mult samples (buffer_size)
    div samples (mp3_channels*mp3_bytespersample)
    set all_samples# samples
    #duration at the default timescale
    import "fmul_quad" fmul_quad
    sd duration
    call fild_value(samples)
    sd tscale
    setcall tscale mp4_tscale()
    data double_data#2
    data double^double_data
    call fild_value(tscale)
    call fstp_quad(double)
    call fmul_quad(double)
    call fild_value((mp3_samplerate))
    call fstp_quad(double)
    call fdiv_quad(double)
    setcall duration mp4_sound_duration()
    call fstp_quad(double)
    sd sound_duration
    setcall sound_duration double_to_int(double)
    setcall duration# dword_reverse(sound_duration)
    #sample count
    div samples (samp_per_frame)
    sd sample_count
    setcall sample_count mp4_sample_count()
    set sample_count# samples
    #sound or video duration for all file
    sd video_duration
    setcall video_duration mp4_duration((value_get))
    if sound_duration>video_duration
        sd l_duration
        setcall l_duration mp4_longest_duration()
        set l_duration# sound_duration
    endif
    #next track
    call mp4_next_track_set((emptyId))
    #Not part of MPEG-4 audio profiles
    call mp4_audio_profile_set(0xfe)
    #verify for the used format
    import "stage_sound_channels" stage_sound_channels
    import "stage_sound_bps" stage_sound_bps
    import "stage_sound_rate" stage_sound_rate
    sd ch
    setcall ch stage_sound_channels((value_get))
    if ch!=(mp3_channels)
        str ch_err="Sound with 2 channels required"
        call texter(ch_err)
        return 0
    endif
    sd bps
    setcall bps stage_sound_bps((value_get))
    if bps!=(mp3_bitspersample)
        str bps_err="Sound with 16 bits-per-sample required"
        call texter(bps_err)
        return 0
    endif
    sd rate
    setcall rate stage_sound_rate((value_get))
    if rate!=(mp3_samplerate)
        str sr_err="Sound with 48000 sample rate required"
        call texter(sr_err)
        return 0
    endif
    return 1
endfunction


##extend + write
import "file_write_forward" file_write_forward
function mp4_dialog(ss filename)
    #init expand values
    sd presence
    setcall presence mp4_sound_presence()
    set presence# 0
    call mp4_video_samples_set(0)
    call mp4_video_bufferSz_set(0)
    call mp4_video_offset_set(0)
    call mp4_audio_samples_set(0)
    call mp4_audio_bufferSz_set(0)
    call mp4_audio_maxBitrate_set(0)
    call mp4_audio_offset_set(0)
    #
    call mp4_info_set(0)
    #
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        #write
        call file_write_forward(filename,mp4_filewrite)
    else
        #expand
        #mem for temp file path name
        import "slen" slen
        sd len
        setcall len slen(filename)
        inc len
        ss mem
        setcall mem memalloc(len)
        if mem!=0
            call mp4_expand_go(filename,mem)
            call free(mem)
        endif
    endelse

    sd info
    setcall info mp4_info_get()
    if info==(TRUE)
        import "save_inform_saved" save_inform_saved
        call save_inform_saved(filename)
    endif

    call av_dialog_close()
endfunction

#bool
function mp4_write_seek(sd mem,sd size,sd file)
    sd procedure
    sd err
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_write)
        setcall err file_write(mem,size,file)
        if err!=(noerror)
            return (FALSE)
        endif
    else
        setcall err file_seek_cursor(file,size)
        if err!=(noerror)
            return (FALSE)
        endif
    endelse
    return (TRUE)
endfunction

#err
function mp4_write_or_no(sd mem,sd size,sd file)
    sd procedure
    setcall procedure mp4_write_expand_get()
    if procedure==(mp4_expand)
        return (noerror)
    endif
    sd err
    setcall err file_write(mem,size,file)
    return err
endfunction

#implement expand mp4
#at video:
#             all sample count at samplecount for a few factors
#             bufferSz at         max_size
#at sound:
#             all pcm samples at all_size(at sound init)
#             maxBitrate at      max_rate
#             bufferSizeDB at    max_sound_size
#at takings, also get the video and sound movie data offset and size
#at write calculate:
#             all video size at   all_size for avgbitrate
#             all sound size at  all_sound_size for avg

function mp4_extend(ss filename)
    call mp4_write_expand_set((mp4_expand))
    call av_dialog_run(mp4_dialog,filename)
endfunction
import "change_name" change_name
importx "_remove" remove
function mp4_expand_go(ss filepath,ss temppath)
    #rename
    import "cpymem" cpymem
    sd len
    setcall len slen(filepath)
    dec len
    call cpymem(temppath,filepath,len)
    ss cursor
    set cursor temppath
    add cursor len
    set cursor# 0
    sd ret
    setcall ret change_name(filepath,temppath)
    if ret!=0
        return (void)
    endif
    #open read to get previous values
    import "openfile" openfile
    importx "_fclose" fclose
    sd file
    sd err
    setcall err openfile(#file,temppath,"rb")
    if err==(noerror)
        #info
        call dialog_modal_texter_draw("Prepare the original file")
        #store read handle for reading at the other file
        call mp4_expand_startfile_set(file)
        sd info
        #read data
        sd read_bool
        setcall read_bool mp4_start(file)
        if read_bool==(TRUE)
            #open write
            call mp4_write_expand_set((mp4_write))
            call file_write_forward(filepath,mp4_filewrite)
            #
            setcall info mp4_info_get()
        endif
        #close old file
        call fclose(file)
        if read_bool==(FALSE)
            #change back if was an error at read
            call change_name(temppath,filepath)
        else
            if info==(TRUE)
                #remove initial file
                call remove(temppath)
            endif
        endelse
    endif
endfunction
