

Const noerror=0
Const error=-1

#Const BACKWARD=-1

const void=0


const dword_max=10
const format_max=6

#Const charnullcompilationstyle=1
#-charnullcompilationstyle
Const dword_null=1+dword_max
Const sign_int_null=1+10+1
#Const sign_int_null_dwords=sign_int_null/4

Const mainwinEditIndex=0
Const mainwinDrawIndex=mainwinEditIndex+1
Const mainwinButtonsIndex=mainwinDrawIndex+1
Const mainwinStageIndex=mainwinButtonsIndex+1
#Const mainwinInfoIndex=mainwinStageIndex+1

#Const mainwintotal=mainwinInfoIndex+1
#Const reverseSubstract=mainwintotal/2
#Const reverseAddBack=mainwintotal-1/2
#last inserted entry is at index 0
#Data mainwinInfoIndex=mainwinInfoIndex-reverseSubstract*-1+reverseAddBack


const differentCompare=-1
const equalCompare=0

const stringinteger=-1
const stringUinteger=0
const stringstring=1


const video=1
const audio=2
const audiovideo=video|audio



const search_preferences_uri_index=0
const search_preferences_wrap_index=search_preferences_uri_index+1


const stage_bpp=32


#const stage_f_length_init=0
#const stage_f_length_add=1
#const stage_f_length_free=2
const stage_f_length_get=3
#const stage_f_length_set=4
#const stage_f_length_insert=5

const get_rgb=0
const set_rgb=1


const buttons_panel_open=0
const buttons_panel_close=1

const stage_frame_form_data_width=0
const stage_frame_form_data_height=1
const stage_frame_form_data_color=2
const stage_frame_form_data_pixbuf=3


const uncover=0
const cover=1
#const in_effect=0
const out_effect=1


const value_set=0
#
const value_get=1
const value_run=1
#
const value_unset=2
const value_item=2
const value_extra=2
#
const value_append=3
const value_insert=3
#
const value_write=4
const value_filewrite=4
#
const value_custom=5
#

const format_raw=-1

const format_avi=0
    const format_avi_raw=0
    const format_avi_i420=1
    const format_avi_mjpg=2
    const format_avi_xvid=3
        const format_avi_last=format_avi+format_avi_xvid
const format_mxf=format_avi_last+1
const format_mkv=format_mxf+1
    const format_mkv_i420=0
    const format_mkv_mjpg=1
    const format_mkv_xvid=2
    const format_mkv_rgb24=3
        const format_mkv_last=format_mkv+format_mkv_rgb24
#const format_mp4=format_mkv_last+1

const sound_endian_def=1234

const jpeg_min_quality=1
const jpeg_max_quality=900

const write_file=0
const read_file=1



const int16=2
const int32=4

const stage_frame_time_init=0
const stage_frame_time_append=1
const stage_frame_time_free=2
const stage_frame_time_get_at_index=3
const stage_frame_time_set_frame_length=4
const stage_frame_time_insert=5
const stage_frame_time_delete_frame=6
const stage_frame_time_sum_at_index=7
const stage_frame_time_total_sum=8



const get_buffer=value_extra

const capture_flag_off=0
const capture_flag_on=1

const avi_new=0
const avi_expand=1

#

#const sound_preview_buffers=32

const modal_texter_mark=dword_max+dword_max
