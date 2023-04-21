


format elfobj

include "../../_include/include.h"

function stage_file_options_got_file(sd mem,sd *size)
    #values and initial default set
    data fps#1
    data ptr_fps^fps
    const ptr_fps^fps
    set fps 2

    data output#1
    data ptr_output^output
    const ptr_output^output
    set output 0

    #set from the option file
    sd err
    data noerr=noerror
    import "get_mem_int_advance" get_mem_int_advance
    sd mem_sz^mem

    setcall err get_mem_int_advance(ptr_fps,mem_sz)
    if err!=noerr
        return err
    endif

    import "av_good_fps" av_good_fps
    call av_good_fps(ptr_fps)

    setcall err get_mem_int_advance(ptr_output,mem_sz)
    if err!=noerr
        return err
    endif

    sd value
    sd p_value^value
    setcall err get_mem_int_advance(p_value,mem_sz)
    if err!=noerr
        return err
    endif
    call stage_file_options_info_message((value_set),value)
endfunction

function stage_file_options_fname()
    str stagedata="stage.data"
    return stagedata
endfunction

function stage_file_options_init()
    #stage data
    ss stagedata
    setcall stagedata stage_file_options_fname()

    import "file_get_content_forward" file_get_content_forward
    data f^stage_file_options_got_file
    call file_get_content_forward(stagedata,f)

    #jpeg specific
    import "jpeg_get_quality" jpeg_get_quality
    data j_f^jpeg_get_quality
    ss jpeg_data
    setcall jpeg_data jpeg_file()
    call file_get_content_forward(jpeg_data,j_f)

    #mpeg specific
    import "mpeg_options" mpeg_options
    data mpeg_f^mpeg_options
    sd mpeg_data
    setcall mpeg_data mpeg_file()
    call file_get_content_forward(mpeg_data,mpeg_f)

    #sound data
    import "sound_get_values" sound_get_values
    data s_f^sound_get_values
    sd sdata
    setcall sdata sound_file()
    call file_get_content_forward(sdata,s_f)

    #capture data
    import "capture_get_data" capture_get_data
    data c_f^capture_get_data
    sd cdata
    setcall cdata capture_file()
    call file_get_content_forward(cdata,c_f)
endfunction
function jpeg_file()
    str jpeg_data="jpeg.data"
    return jpeg_data
endfunction
function mpeg_file()
    str mpeg_data="mpeg.data"
    return mpeg_data
endfunction
function sound_file()
    str sdata="sound.data"
    return sdata
endfunction
function capture_file()
    str cdata="capture.data"
    return cdata
endfunction

function stage_file_options_fps_pointer()
    data ptr_fps%ptr_fps
    return ptr_fps
endfunction
function stage_file_options_fps()
    sd p_fps
    setcall p_fps stage_file_options_fps_pointer()
    return p_fps#
endfunction

function stage_file_options_output_pointer()
    data ptr_output%ptr_output
    return ptr_output
endfunction
function stage_file_options_output()
    data ptr_output#1
    setcall ptr_output stage_file_options_output_pointer()
    return ptr_output#
endfunction
function stage_file_options_info_message(sd action,sd value)
    data flag#1
    if action==(value_set)
        set flag value
    else
        return flag
    endelse
endfunction

import "jpeg_dialog" jpeg_dialog
import "update_set" update_set
import "update_mem" update_mem
#case start:arg1 is vbox
#case notstart:arg1 fileout
function stage_file_options_structure(sd start,sd arg1)
    data true=1
    data rows=4
    data cols=2

    #also it is required to look at values above and at strings below
    #and at constants (format_avi, format_mkv, ...)

    data fps_label#1
    data fps_edit#1
    data outformat_label#1
    data outformat_list#1
    data *space=0
    data options#1
    data img_jpeg#1
    data *space=0
    data v_cells^fps_label

    data ch_txt#1
    data ch_opt#1
    data rate_txt#1
    data rate_opt#1
    data bps_txt#1
    data bps_opt#1
    data a_cells^ch_txt

    data results_toggle#1
    data update_toggle#1

    import "stage_sound_channels" stage_sound_channels
    import "stage_sound_rate" stage_sound_rate
    import "stage_sound_bps" stage_sound_bps
    sd channels
    sd rate
    sd bps
    sd p_channels^channels
    sd p_rate^rate
    sd p_bps^bps

    sd ptr_out
    setcall ptr_out stage_file_options_output_pointer()
    if start==true
        sd vbox
        set vbox arg1
        importx "_gtk_frame_new" gtk_frame_new
        import "packstart" packstart
        import "tablefield_cells" tablefield_cells
#video
        str video="Video"
        sd v_frame
        setcall v_frame gtk_frame_new(video)
        call packstart(vbox,v_frame,(TRUE))

        #fps
        importx "_gtk_label_new" gtk_label_new
        str fps_label_text="Frames-per-second"
        setcall fps_label gtk_label_new(fps_label_text)
        import "editfield_with_int" editfield_with_int
        sd fps
        setcall fps stage_file_options_fps()
        setcall fps_edit editfield_with_int(fps)

        #output format
        str outformat_label_text="Output format"
        setcall outformat_label gtk_label_new(outformat_label_text)
        importx "_gtk_combo_box_text_new" gtk_combo_box_text_new
        setcall outformat_list gtk_combo_box_text_new()

        #connect changed signal for storing the index
        import "connect_signal_data" connect_signal_data
        str change="changed"
        data ch_fn^stage_oformat_changed
        call connect_signal_data(outformat_list,change,ch_fn,ptr_out)

        importx "_gtk_combo_box_text_append_text" gtk_combo_box_text_append_text

        str entry1="AVI yuv"
        call gtk_combo_box_text_append_text(outformat_list,entry1)
        str entry1_i420="AVI/I420\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry1_i420)
        str entry1_jpg="AVI/MJPEG\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry1_jpg)
        str entry1_xvid="AVI/MPG4-ASP\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry1_xvid)

        str entry2="MXF"
        call gtk_combo_box_text_append_text(outformat_list,entry2)

        str entry3_1="MKV/I420\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry3_1)
        str entry3_2="MKV/MJEPG\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry3_2)
        str entry3_3="MKV/MPG4-ASP\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry3_3)
        str entry3_4="MKV/RGB24\\PCM"
        call gtk_combo_box_text_append_text(outformat_list,entry3_4)

        str entry4_1="MP4/MPG4-AVC\\MP3"
        call gtk_combo_box_text_append_text(outformat_list,entry4_1)

        importx "_gtk_combo_box_set_active" gtk_combo_box_set_active
        call gtk_combo_box_set_active(outformat_list,ptr_out#)

        #configurations
        import "buttonfield_prepare_with_label" buttonfield_prepare_with_label
        str conf="Format configure"
        setcall options buttonfield_prepare_with_label(conf)
        import "connect_clicked" connect_clicked
        data f^stage_properties_enc
        call connect_clicked(options,f)

        #image
        ss jpg="Image - JPEG"
        setcall img_jpeg buttonfield_prepare_with_label(jpg)
        data f_jpg_img^jpeg_dialog
        call connect_clicked(img_jpeg,f_jpg_img)

        call tablefield_cells(v_frame,rows,cols,v_cells)
#audio
        str audio="Audio"
        sd a_frame
        setcall a_frame gtk_frame_new(audio)
        call packstart(vbox,a_frame,(TRUE))

        str ch_info="Channels"
        setcall ch_txt gtk_label_new(ch_info)
        setcall channels stage_sound_channels((value_get))
        setcall ch_opt editfield_with_int(channels)
        #
        str rate_info="Samples-per-sec"
        setcall rate_txt gtk_label_new(rate_info)
        setcall rate stage_sound_rate((value_get))
        setcall rate_opt editfield_with_int(rate)
        #
        str bps_info="Bits-per-sample"
        setcall bps_txt gtk_label_new(bps_info)
        setcall bps stage_sound_bps((value_get))
        setcall bps_opt editfield_with_int(bps)
        #
        call tablefield_cells(a_frame,3,2,a_cells)
#
        importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
        importx "_gtk_toggle_button_set_active" gtk_toggle_button_set_active
        import "packstart_default" packstart_default
        #results message
        ss txt="Show results message(if available)"
        setcall results_toggle gtk_check_button_new_with_label(txt)
        sd toggle
        setcall toggle stage_file_options_info_message((value_get))
        if toggle!=0
            call gtk_toggle_button_set_active(results_toggle,1)
        endif
        call packstart_default(vbox,results_toggle)
        #updates
        ss up_txt="Check for updates"
        setcall update_toggle gtk_check_button_new_with_label(up_txt)
        sd update
        setcall update update_mem()
        if update#==(TRUE)
            call gtk_toggle_button_set_active(update_toggle,1)
        endif
        call packstart_default(vbox,update_toggle)
    else
        import "file_write" file_write
        importx "_gtk_entry_get_text" gtk_entry_get_text
#
        ss currentframestext
        setcall currentframestext gtk_entry_get_text(fps_edit)

        sd err
        data noerr=noerror

        import "strtoint" strtoint
        sd fpspointer%ptr_fps
        call strtoint(currentframestext,fpspointer)
        call av_good_fps(fpspointer)
        setcall err file_write(fpspointer,4,arg1)
        if err!=noerr
            return err
        endif

        setcall err file_write(ptr_out,4,arg1)
        if err!=noerr
            return err
        endif
#
        ss file_sound
        setcall file_sound sound_file()
        sd audio_file
        sd p_audio_file^audio_file
        str s_fmode="wb"
        import "openfile" openfile
        setcall err openfile(p_audio_file,file_sound,s_fmode)
        if err!=noerr
            return err
        endif
        import "entry_to_nr_minValue" entry_to_nr_minValue

        call entry_to_nr_minValue(ch_opt,p_channels,1)
        call entry_to_nr_minValue(rate_opt,p_rate,1)
        call entry_to_nr_minValue(bps_opt,p_bps,8)

        call stage_sound_channels((value_set),channels)
        call stage_sound_rate((value_set),rate)
        call stage_sound_bps((value_set),bps)

        call write_sound_options(audio_file,p_channels,p_rate,p_bps)

        importx "_fclose" fclose
        call fclose(audio_file)
#
        importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
        #
        sd toggle_flag
        sd p_toggle_flag^toggle_flag
        setcall toggle_flag gtk_toggle_button_get_active(results_toggle)
        call stage_file_options_info_message((value_set),toggle_flag)
        setcall err file_write(p_toggle_flag,4,arg1)
        if err!=noerr
            return err
        endif
        #
        sd up_flag
        setcall up_flag gtk_toggle_button_get_active(update_toggle)
        call update_set(up_flag)
        #
    endelse
endfunction
function stage_oformat_changed(sd combo,sd p_loc)
    importx "_gtk_combo_box_get_active" gtk_combo_box_get_active
    setcall p_loc# gtk_combo_box_get_active(combo)
endfunction

import "get_string_at_index" get_string_at_index
#type/extension
function stage_file_get_format()
    sd ptr_index%ptr_output
#these formats are related to format_max
    #Audio Video Interleaved
    chars entry1="avi"
    #Audio Video Interleaved / I420
    chars *="avi"
    #Audio Video Interleaved / MJPEG
    chars *="avi"
    #Audio Video Interleaved / MPG4-ASP
    chars *="avi"
    #Material eXchange Format
    chars *="mxf"
    #Matroska / I420
    chars *="mkv"
    #Matroska / MJPEG
    chars *="mkv"
    #Matroska / MPG4-ASP
    chars *="mkv"
    #Matroska / RGB24
    chars *="mkv"
    #Mp4 / MPEG4-AVC
    chars *="mp4"

    sd index
    set index ptr_index#
    ss iter^entry1
    setcall iter get_string_at_index(iter,index)
    return iter
endfunction
#get the name string of the output format for gstreamer options
function stage_file_get_format_name()
    ss format
    setcall format stage_file_get_format()
    chars dest_data#format_max+1
    data dest^dest_data
    import "strcpy" strcpy
    import "slen" slen
    call strcpy(dest,format)
    sd len
    setcall len slen(dest)
    sd cursor
    set cursor dest
    add cursor len
    ss mux="mux"
    call strcpy(cursor,mux)
    return dest
endfunction
#get the encoder for mkv,avi files
function stage_file_get_mkv_encoder()
    sd ptr_index%ptr_output
    sd index
    set index ptr_index#
    sub index (format_mkv)
    return index
endfunction
function stage_file_get_avi_encoder()
    sd ptr_index%ptr_output
    sd index
    set index ptr_index#
    sub index (format_avi)
    return index
endfunction


#init
function stage_file_options_dialog_init(sd vbox,sd *dialog)
    call stage_file_options_structure((TRUE),vbox)
endfunction

import "move_to_home_v" move_to_home_v

#write if ok
function stage_file_options_dialog_got_file(sd file)
    data notstart=0
    call stage_file_options_structure(notstart,file)
endfunction
function stage_file_options_dialog_sysenter()
    import "file_write_forward" file_write_forward
    ss stagedata
    setcall stagedata stage_file_options_fname()
    data f^stage_file_options_dialog_got_file
    call file_write_forward(stagedata,f)
endfunction
function stage_file_options_dialog_continuation()
	call move_to_home_v()
	data f^stage_file_options_dialog_sysenter
	import "sys_folder_enterleave" sys_folder_enterleave
	call sys_folder_enterleave(f)
	#redraw the visual sound pulse
	import "sound_pixbuf_redraw" sound_pixbuf_redraw
	call sound_pixbuf_redraw()
endfunction

function file_write_forward_sys_folder_enter_leave(ss filename,sd forward)
	call move_to_home_v()
	call forward_in_sys_folder((value_set),filename,forward)
	data sys_forward^forward_file_sys_folder
	call sys_folder_enterleave(sys_forward)
endfunction
function forward_file_sys_folder()
    sd values
    setcall values forward_in_sys_folder((value_get))
    sd filename
    sd forward
    set filename values#
    add values 4
    set forward values#
    call file_write_forward(filename,forward)
endfunction
function forward_in_sys_folder(sd action,sd fname,sd frw)
    data filename#1
    data forward#1
    if action==(value_set)
        set filename fname
        set forward frw
    else
        data set^filename
        return set
    endelse
endfunction

#get container file
function stage_get_output_container()
    sd format
    setcall format stage_file_get_format()
    import "save_destination" save_destination

    sd output_container
    setcall output_container save_destination(format)

    return output_container
endfunction







#clicked

function stage_file_options()
    str stageoptions="Stage Options"
    data modal=GTK_DIALOG_MODAL
    data set^stage_file_options_dialog_init
    data continuation^stage_file_options_dialog_continuation

    import "dialogfield" dialogfield
    call dialogfield(stageoptions,modal,set,continuation)
endfunction

const options_na=0
const options_jpg=1
const options_mpg=2

#clicked,void
function stage_properties_enc(sd *button,sd *data)
    sd options
    str sets="Settings"

    setcall options stage_properties_enc_get_options_format()

    import "dialogfield_size" dialogfield_size
    if options==(options_jpg)
        call jpeg_dialog()
        return 1
    elseif options==(options_mpg)
        import "mpeg_settings_init" mpeg_settings_init
        import "mpeg_settings_set" mpeg_settings_set
        data mpeg_i_f^mpeg_settings_init
        data mpeg_s_f^mpeg_settings_set
        call dialogfield_size(sets,(GTK_DIALOG_MODAL),mpeg_i_f,mpeg_s_f,300,-1)
        return 1
    endelseif

    import "message_dialog" message_dialog
    str no="The encoder doesn't have specific options"
    call message_dialog(no)
endfunction

import "cmpmem" cmpmem

function stage_properties_enc_get_options_format()
    sd encoder
    sd cmp
    sd format
    setcall format stage_file_get_format()
    str mk="mkv"
    setcall cmp cmpmem(format,mk,3)
    if cmp==(equalCompare)
        setcall encoder stage_file_get_mkv_encoder()
        if encoder==(format_mkv_mjpg)
            return (options_jpg)
        elseif encoder==(format_mkv_xvid)
            return (options_mpg)
        endelseif
    endif
    str avi="avi"
    setcall cmp cmpmem(format,avi,3)
    if cmp==(equalCompare)
        setcall encoder stage_file_get_avi_encoder()
        if encoder==(format_avi_mjpg)
            return (options_jpg)
        elseif encoder==(format_avi_xvid)
            return (options_mpg)
        endelseif
    endif
    str mp4="mp4"
    setcall cmp cmpmem(format,mp4,3)
    if cmp==(equalCompare)
        return (options_mpg)
    endif
    return (options_na)
endfunction

function write_sound_options(sd file,sd p_channels,sd p_rate,sd p_bps)
    sd err
    setcall err file_write(p_channels,4,file)
    if err!=(noerror)
        return err
    endif
    setcall err file_write(p_rate,4,file)
    if err!=(noerror)
        return err
    endif
    setcall err file_write(p_bps,4,file)
    if err!=(noerror)
        return err
    endif
endfunction
