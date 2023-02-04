

format elfobj

include "../_include/include.h"

Const GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER=2

importx "_GetModuleFileNameA@12" GetModuleFileName
importx "_free" free

import "memoryalloc" memoryalloc
import "texter" texter

#err
function Scriptfullpath(sv ptrfullpath)
	data MAX_PATH=260
	sd err
	setcall err memoryalloc(MAX_PATH,ptrfullpath)
	if err==(noerror)
		data size#1
		setcall size GetModuleFileName((NULL),ptrfullpath#,MAX_PATH)
		if size!=(NULL)
			return (noerror)
		endif
		call free(ptrfullpath#)
		set err "Error."
		call texter(err)
	endif
	return err
endfunction

import "dirch" dirch

#void/err
function movetoScriptfolder(data forward)
	data path#1
	data ptrpath^path
	data err#1
	data noerr=noerror
	setcall err Scriptfullpath(ptrpath)
	if err==noerr
		data pointer#1
		chars z=0
		setcall pointer endoffolders(path)
		set pointer# z
		setcall err dirch(path)
		if err==noerr
			call forward()
		endif
		call free(path)
	endif
	return err
endfunction

import "slen" slen


#true if match or false
Function filepathdelims(chars chr)
        Chars bslash="\\"
        Chars slash="/"
        Data true=TRUE
        Data false=FALSE
        If chr==bslash
                Return true
        EndIf
        If chr==slash
                Return true
        EndIf
        Return false
EndFunction

#folders ('c:\folder\file.txt' will be pointer starting at 'file.txt')
Function endoffolders(ss path)
    sd sz
    setcall sz slen(path)
    ss cursor
    set cursor path
    add cursor sz
    sd i=0
    while i<sz
        dec cursor
        sd bool
        setcall bool filepathdelims(cursor#)
        if bool==(TRUE)
            inc cursor
            return cursor
        endif
        inc i
    endwhile
    return path
EndFunction

importx "__get_errno" get_errno
#errno
function geterrno()
    sd er
    call get_errno(#er)
    return er
endfunction


importx "_gdk_win32_drawable_get_handle" gdk_win32_drawable_get_handle
function gdkGetdrawable(data window)
    data windraw#1
    setcall windraw gdk_win32_drawable_get_handle(window)
    return windraw
endfunction

function system_variables_alignment_pad(data value,data greatest)
    sub greatest value
    return greatest
endfunction


importx "__time32" time
function timeNode(data ptrtime_t)
    data time_t#1
    setcall time_t time(ptrtime_t)
    return time_t
endfunction

import "_chdir" chd
function chdr(str value)
    data x#1
    setcall x chd(value)
    return x
endfunction

import "_snprintf" snprintf
function c_snprintf_strvaluedisp(str display,data max,str format,str text,data part2)
    call snprintf(display,max,format,text,part2)
endfunction




importx "_gtk_file_chooser_get_filename_utf8" gtk_file_chooser_get_filename_utf8
function file_chooser_get_fname(sd dialog)
    sd file
    setcall file gtk_file_chooser_get_filename_utf8(dialog)
    return file
endfunction






#jpeg

function jpeg_get_jdestruct_size()
    return (jdestruct_size_win)
endfunction


function jpeg_get_jdestruct_output_width()
    return (jdestruct_output_width_win)
endfunction
function jpeg_get_jdestruct_output_height()
    return (jdestruct_output_height_win)
endfunction
function jpeg_get_jdestruct_output_components()
    return (jdestruct_output_components_win)
endfunction

#

##times

#milliseconds
function get_time()
    importx "_GetTickCount@0" GetTickCount
    sd milliseconds
    setcall milliseconds GetTickCount()
    return milliseconds
endfunction

function sleepMs(sd value)
    importx "_Sleep@4" Sleep
    call Sleep(value)
endfunction


#######gdi alternative capture

const SRCCOPY=0x00CC0020
const DIB_RGB_COLORS=0

function dest_dc(sd action,sd value)
    data dc#1
    if action==(value_set)
        set dc value
    else
        return dc
    endelse
endfunction
function dest_dib(sd action,sd value)
    data dib#1
    if action==(value_set)
        set dib value
    else
        return dib
    endelse
endfunction
function gdi_toggle(sd action,sd value)
    data gdi_entry#1
    if action==(value_set)
        set gdi_entry value
    else
        return gdi_entry
    endelse
endfunction

function capture_alternative_init(sd vbox)
    importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
    importx "_gtk_toggle_button_set_active" gtk_toggle_button_set_active
    importx "_gtk_container_add" gtk_container_add
    ss gdi_txt="Use GDI"
    sd gdi_entry
    setcall gdi_entry gtk_check_button_new_with_label(gdi_txt)
    call gdi_toggle((value_set),gdi_entry)
    call gtk_toggle_button_set_active(gdi_entry,1)
    call gtk_container_add(vbox,gdi_entry)

##folder
    import "hseparatorfield" hseparatorfield
    call hseparatorfield(vbox)

    importx "_gtk_table_new" gtk_table_new
    importx "_gtk_table_attach" gtk_table_attach
    import "buttonfield_prepare_with_label" buttonfield_prepare_with_label
    import "connect_clicked" connect_clicked
    importx "_gtk_widget_set_tooltip_markup" gtk_widget_set_tooltip_markup
    sd table
    setcall table gtk_table_new(4,1,0)

    ss onefolder="Folder captures to file"
    sd one
    setcall one buttonfield_prepare_with_label(onefolder)
    data f_one^mass_folder
    call connect_clicked(one,f_one)
    ss inf="All mkv(i420,mjpeg,rgb) files from a folder to an avi(i420,mjpeg,mpg4-asp) file"
    call gtk_widget_set_tooltip_markup(one,inf)
    call gtk_table_attach(table,one,0,1,0,1,(GTK_FILL),0,0,0)

    ss allfolders="Folder folders captures to files"
    sd all
    setcall all buttonfield_prepare_with_label(allfolders)
    data f_many^mass_many_folders
    call connect_clicked(all,f_many)
    ss all_inf="All mkv(i420,mjpeg,rgb) files from a folder from all folders to avi(i420,mjpeg,mpg4-asp) files"
    call gtk_widget_set_tooltip_markup(all,all_inf)
    call gtk_table_attach(table,all,0,1,1,2,(GTK_FILL),0,0,0)

    import "labelfield_left_prepare" labelfield_left_prepare
    ss wr="Warning! This will remove the stage video and sound!"
    sd info
    setcall info labelfield_left_prepare(wr)
    call gtk_table_attach(table,info,0,1,2,3,(GTK_FILL),0,0,0)

    ss allfolders_poweroff="Folder folders captures + Shut Down"
    sd all_poweroff
    setcall all_poweroff buttonfield_prepare_with_label(allfolders_poweroff)
    data f_many_poweroff^mass_many_folders_with_poweroff
    call connect_clicked(all_poweroff,f_many_poweroff)
    call gtk_table_attach(table,all_poweroff,0,1,3,4,(GTK_FILL),0,0,0)

    import "packstart_default" packstart_default
    call packstart_default(vbox,table)

    call hseparatorfield(vbox)
##
endfunction
function capture_alternative_set(sd p_no_alternative)
    sd gdi_entry
    setcall gdi_entry gdi_toggle((value_get))
    importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
    setcall p_no_alternative# gtk_toggle_button_get_active(gdi_entry)
    xor p_no_alternative# 1
endfunction
#bool
function capture_alternative_prepare(sd p_mem,sd pix_width,sd pix_height)
    importx "_GetWindowDC@4" GetWindowDC
    importx "_CreateCompatibleDC@4" CreateCompatibleDC
    importx "_SelectObject@8" SelectObject
    importx "_DeleteObject@4" DeleteObject
    importx "_CreateDIBSection@24" CreateDIBSection

    sd srcDC
    setcall srcDC GetWindowDC(0)
    sd destDC
    setcall destDC CreateCompatibleDC(srcDC)
    if destDC==0
        str no_dc="DC error"
        call texter(no_dc)
        return 0
    endif
    call dest_dc((value_set),destDC)

    #BITMAPINFO
    data biSize=40
    data biWidth#1
    data biHeight#1
    chars *biPlanes={1,0}
    chars *biBitCount={24,0}
    data *biCompression=0
    data biSizeImage#1
    data *biXPelsPerMeter=0
    data *biYPelsPerMeter=0
    data *biClrUsed=0
    data *biClrImportant=0
    chars *bmiColors=0

    data bitmap^biSize
    set biWidth pix_width
    set biHeight pix_height
    import "rgb_get_size" rgb_get_size
    setcall biSizeImage rgb_get_size(biWidth,biHeight)

    sd dib
    setcall dib CreateDIBSection(destDC,bitmap,(DIB_RGB_COLORS),p_mem,0,0)
    if dib==0
        call DeleteObject(destDC)
        str no_dib="DIB error"
        call texter(no_dib)
        return 0
    endif
    call dest_dib((value_set),dib)
    call SelectObject(destDC,dib)
    return 1
endfunction
function capture_alternative_append(sd x,sd y,sd pix_width,sd pix_height,sd cursor_flag)
    importx "_BitBlt@36" BitBlt
    importx "_GetCursorInfo@4" GetCursorInfo
    importx "_DrawIcon@16" DrawIcon
    sd srcDC
    setcall srcDC GetWindowDC(0)
    sd destDC
    setcall destDC dest_dc((value_get))
    call BitBlt(destDC,0,0,pix_width,pix_height,srcDC,x,y,(SRCCOPY))
    if cursor_flag==1
        #CURSORINFO
        data cbSize#1
        data *flags#1
        data hCursor#1
        data ptScreenPos_x#1
        data ptScreenPos_y#1

        data CursorInfo^cbSize
        set cbSize 20
        call GetCursorInfo(CursorInfo)

        sub ptScreenPos_x x
        sub ptScreenPos_y y
        call DrawIcon(destDC,ptScreenPos_x,ptScreenPos_y,hCursor)
    endif
endfunction
function capture_alternative_free()
    sd destDIB
    setcall destDIB dest_dib((value_get))
    call DeleteObject(destDIB)
    sd destDC
    setcall destDC dest_dc((value_get))
    call DeleteObject(destDC)
endfunction

function capture_alt_ev_wait()
endfunction
function capture_alt_ev_set()
endfunction

###############mass capture to file

function mass_folder()
    sd foldername
    setcall foldername mass_init_file()
    call mass_foldername(foldername)
endfunction

function mass_foldername(ss foldername)
    #don't display the result message inter-files
    import "stage_file_options_info_message" stage_file_options_info_message
    sd info
    setcall info stage_file_options_info_message((value_get))
    call stage_file_options_info_message((value_set),0)

    ss spec="*.mkv"
    data forwrd^mass_folder_file
    sd counter=0
    sd p_counter^counter
    #fileiterate frees the foldername
    #fileiterate returns if folder==0
    call fileiterate(foldername,spec,forwrd,p_counter)

    call stage_file_options_info_message((value_set),info)
endfunction

function fileiterate(ss foldername,ss spec,sd forward,sd data)
    if foldername==0
        return 0
    endif
    sd p_foldername^foldername
    call fileiteration(p_foldername,spec,forward,data)
    call free(foldername)
endfunction

function fileiteration(sd p_foldername,ss spec,sd forward,sd data)
    sd folderlen
    setcall folderlen slen(p_foldername#)
    inc folderlen
    sd speclen
    setcall speclen slen(spec)
    inc speclen

    sd flen
    set flen folderlen
    add flen speclen

    import "memrealloc" memrealloc
    import "cpymem" cpymem
    sd foldername
    setcall foldername memrealloc(p_foldername#,flen)
    if foldername==0
        return 0
    endif
    set p_foldername# foldername

    ss path
    set path foldername
    add path folderlen
    dec path
    chars bslash="\\"
    set path# bslash
    inc path
    call cpymem(path,spec,speclen)

    data attrib#1
    data *attrib_align#1
    data *time_create#2
    data *time_access#2
    data *time_write#2
    data *size#1
    chars name#260

    data file_info^attrib
    str fname^name
    chars reserve_name#260
    str reserve^reserve_name

    importx "__findfirst64i32" findfirst
    importx "__findnext64i32" findnext
    importx "__findclose" findclose

    sd handle
    setcall handle findfirst(foldername,file_info)
    if handle==-1
        return 0
    endif
    str onedot="."
    str twodots=".."
    sd cmp

    set path fname
    add path folderlen
    sd end=0
    while end==0
        sd namelen
        setcall namelen slen(fname)

        import "cmpmem_s" cmpmem_s
        sd verify=1
        setcall cmp cmpmem_s(fname,namelen,onedot,1)
        if cmp!=(equalCompare)
            setcall cmp cmpmem_s(fname,namelen,twodots,2)
        endif
        if cmp==(equalCompare)
            set verify 0
        endif

        if verify==1
            inc namelen
            call cpymem(reserve,fname,namelen)
            call cpymem(fname,foldername,folderlen)
            call cpymem(path,reserve,namelen)
            call forward(fname,attrib,data)
        endif
        setcall end findnext(handle,file_info)
    endwhile
    call findclose(handle)
endfunction

function mass_folder_file(ss name,sd *attrib,sd p_counter)
    import "stage_prepare" stage_prepare
    call stage_prepare()
    import "stage_mkv_read" stage_mkv_read
    call stage_mkv_read(name)
    if p_counter#==0
        import "aviwrite" aviwrite
        str location#1
        sd counter
        setcall counter files_counter((value_get))
        setcall location aviwrite(1,counter)
        inc counter
        call files_counter((value_set),counter)
    else
        import "avi_write_fname" avi_write_fname
        call avi_write_fname(location,(avi_expand))
    endelse
    inc p_counter#
endfunction

#foldername/0
function mass_init_file()
    import "is_local_avi" is_local_avi
    sd bool
    setcall bool is_local_avi()
    if bool==0
        import "message_dialog" message_dialog
        ss er="Set avi(i420,mjpeg,mpg4-asp) from the Stage Options"
        call message_dialog(er)
        return 0
    endif
    call files_counter((value_set),0)
    sd foldername
    setcall foldername filechooserfield_folder()
    return foldername
endfunction

##all folders

function mass_many_folders()
    call mass_many_folders_poweroff(0)
endfunction
function mass_many_folders_with_poweroff()
    call mass_many_folders_poweroff(1)
endfunction

function mass_many_folders_poweroff(sd poweroff_flag)
    sd foldername
    setcall foldername mass_init_file()

    ss nullstr="*"
    data forwrd^mass_all_folders
    #fileiterate frees the foldername
    #fileiterate returns if folder==0
    call fileiterate(foldername,nullstr,forwrd,0)

    if foldername==0
        return 0
    endif
    if poweroff_flag==1
        call shutdown()
    endif
endfunction

const _A_SUBDIR=0x10

function mass_all_folders(ss filefolder_entry,sd attrib)
    and attrib (_A_SUBDIR)
    if attrib!=0
        import "memalloc" memalloc
        sd len
        setcall len slen(filefolder_entry)
        inc len
        sd mem
        setcall mem memalloc(len)
        if mem==0
            return 0
        endif
        call cpymem(mem,filefolder_entry,len)
        call mass_foldername(mem)
    endif
endfunction

function files_counter(sd action,sd value)
    data counter#1
    if action==(value_set)
        set counter value
    else
        return counter
    endelse
endfunction

const INFINITE=-1

function shutdown()
    importx "_CreateProcessA@40" CreateProcess
    import "setmemzero" setmemzero
    const startupsize=68
    chars startup#startupsize
    str startupInfo^startup
    call setmemzero(startupInfo,(startupsize))

    data hprocess#1
    data hthread#1
    chars *rest_hproc#16-4-4

    data procinfo^hprocess

    str comm="shutdown /p"
    sd bool
    setcall bool CreateProcess(0,comm,0,0,0,0,0,0,startupInfo,procinfo)
    if bool==0
        str er="CreateProcess failed"
        call texter(er)
        return 0
    endif
    importx "_WaitForSingleObject@8" WaitForSingleObject
    importx "_CloseHandle@4" CloseHandle
    call WaitForSingleObject(hprocess,(INFINITE))
    call CloseHandle(hprocess)
    call CloseHandle(hthread)
endfunction


#file seek dif

#er
function file_seek_dif_cursor(sd file,sd off)
    importx "__fseeki64" fseek64
    import "seek_err" seek_err
    sd int
    setcall int fseek64(file,off,0,(SEEK_CUR))
    sd err
    setcall err seek_err(int)
    return err
endfunction

#sound preview
importx "_waveOutOpen@24" waveOutOpen
importx "_waveOutClose@4" waveOutClose
importx "_waveOutReset@4" waveOutReset
importx "_waveOutPrepareHeader@12" waveOutPrepareHeader
importx "_waveOutUnprepareHeader@12" waveOutUnprepareHeader
importx "_waveOutWrite@12" waveOutWrite

import "stage_sound_channels" stage_sound_channels
import "stage_sound_rate" stage_sound_rate
import "stage_sound_bps" stage_sound_bps

import "stage_sound_blockalign" stage_sound_blockalign
import "stage_sound_avgbytespersec" stage_sound_avgbytespersec

const MMSYSERR_NOERROR=0
const WAVE_MAPPER=-1
const CALLBACK_NULL=0
#const CALLBACK_FUNCTION=0x30000
#const WOM_DONE=0x3BD
const WAVE_FORMAT_PCM=1

function sound_preview_mm_hwaveout()
    data hwaveout#1
    return #hwaveout
endfunction
import "sound_preview_buffers" sound_preview_buffers
function sound_mm_buffers()
    data bf#1
    return #bf
endfunction
function sound_mm_buffers_get()
    sd bf
    setcall bf sound_mm_buffers()
    return bf#
endfunction
function sound_mm_buffers_set()
    sd nmbr=10
    addcall nmbr sound_preview_buffers()
    sd bf
    setcall bf sound_mm_buffers()
    set bf# nmbr
endfunction

const sound_preview_buffers_max=128

function sound_preview_write_buffer(sd buffer,sd buffer_size)
    sd hwaveout
    setcall hwaveout sound_preview_mm_hwaveout()
    if hwaveout#==0
        return (void)
    endif
    data lpData#1
    data dwBufferLength#1
    data *dwBytesRecorded#1
    data *dwUser#1
    data *dwFlags=0
    data *dwLoops#1
    data *lpNext#1
    data *reserved#1
    #lpData, dwBufferLength, and dwFlags members must be set
    const wvhd^lpData
    const wvhd_size=!-wvhd
    data wavehd%wvhd

    set lpData buffer
    set dwBufferLength buffer_size
    data waveheaders_index#1
    inc waveheaders_index

    import "rest" rest
    sd buffers_count
    setcall buffers_count sound_mm_buffers_get()
    sd pos
    setcall pos rest(waveheaders_index,buffers_count)
    sd waveheader
    setcall waveheader sound_preview_mm_buffers(pos)
    #unprepare if prepared
    call sound_preview_buffers_unprep(pos)
    #
    call cpymem(waveheader,wavehd,(wvhd_size))

    sd mm
    setcall mm waveOutPrepareHeader(hwaveout#,waveheader,(wvhd_size))
    if mm!=(MMSYSERR_NOERROR)
        str er="Wave out prepare header error"
        call texter(er)
    endif
    #set bool true
    call sound_preview_buffers_set(pos)
    setcall mm waveOutWrite(hwaveout#,waveheader,(wvhd_size))
    if mm!=(MMSYSERR_NOERROR)
        str wr_er="Wave out write error"
        call texter(wr_er)
    endif
endfunction

function sound_preview_mm_buffers(sd nr)
    sd data_ptr
    setcall data_ptr sound_preview_mm_buffers_data()
    sd data
    set data data_ptr#
    mult nr (wvhd_size)
    add data nr
    return data
endfunction
function sound_preview_mm_buffers_data()
    data ptr#1
    return #ptr
endfunction
#function sound_preview_mm_buffers_data_set(sd value)
#    sd data
#    setcall data sound_preview_mm_buffers_data()
#    set data# value
#endfunction

#
function sound_preview_buffers_bool()
    data buffers#sound_preview_buffers_max
    return #buffers
endfunction
function sound_preview_buffers_unprep(sd nr,sd wavehdr)
    sd bools
    setcall bools sound_preview_buffers_bool()
    mult nr (DWORD)
    add bools nr
    if bools#==1
        sd hwo
        setcall hwo sound_preview_mm_hwaveout()
        sd waveheader
        setcall waveheader sound_preview_mm_buffers(nr)
        call waveOutUnprepareHeader(hwo#,wavehdr)
        set bools# 0
    endif
endfunction
function sound_preview_buffers_set(sd nr)
    sd bools
    setcall bools sound_preview_buffers_bool()
    mult nr (DWORD)
    add bools nr
    set bools# 1
endfunction

#bool
function sound_preview_init()
    sd hwaveout
    setcall hwaveout sound_preview_mm_hwaveout()
    set hwaveout# 0
    sd buffers
    setcall buffers sound_preview_mm_buffers_data()
    set buffers# 0
    #
    call sound_mm_buffers_set()
    sd nr
    setcall nr sound_mm_buffers_get()
    if nr>(sound_preview_buffers_max)
        str er="Set a lower fps for sound playback"
        call texter(er)
        return 0
    endif
    #
    sd value
    #WAVEFORMATEX
    chars wFormatTag={WAVE_FORMAT_PCM,0}
    chars nChannels#2
    data nSamplesPerSec#1
    data nAvgBytesPerSec#1
    chars nBlockAlign#2
    chars wBitsPerSample#2
    #EX
    #no extra data, simple PCM-format used
    chars *cbSize={0,0}
    #
    import "int_into_short" int_into_short
    data WAVEFORMATEX^wFormatTag
    setcall value stage_sound_channels((value_get))
    call int_into_short(value,#nChannels)
    setcall nSamplesPerSec stage_sound_rate((value_get))
    setcall nAvgBytesPerSec stage_sound_avgbytespersec()
    setcall value stage_sound_blockalign()
    call int_into_short(value,#nBlockAlign)
    setcall value stage_sound_bps((value_get))
    call int_into_short(value,#wBitsPerSample)
    #
    #data f^sound_preview_mm_callback
    sd res
    setcall res waveOutOpen(hwaveout,(WAVE_MAPPER),WAVEFORMATEX,0,0,(CALLBACK_NULL))
    if res!=(MMSYSERR_NOERROR)
        return 0
    endif
    #
    sd i=0
    sd bf_bool
    setcall bf_bool sound_preview_buffers_bool()
    sd max
    setcall max sound_mm_buffers_get()
    while i<max
        set bf_bool# 0
        add bf_bool (DWORD)
        inc i
    endwhile
    #
    sd size=wvhd_size
    mult size nr
    sd buffers_space
    setcall buffers_space memalloc(size)
    if buffers_space==0
        call sound_preview_free()
        return 0
    endif
    set buffers# buffers_space
    #
    return 1
endfunction

function sound_preview_free()
    sd pointer
    setcall pointer sound_preview_mm_hwaveout()
    sd hwaveout
    set hwaveout pointer#
    if hwaveout!=0
        call waveOutReset(hwaveout)
        sd i=0
        sd max
        setcall max sound_mm_buffers_get()
        while i<max
            call sound_preview_buffers_unprep(i)
            inc i
        endwhile
        call waveOutClose(hwaveout)
        sd buffers
        setcall buffers sound_preview_mm_buffers_data()
        if buffers#!=0
            call free(buffers#)
        endif
    endif
endfunction

#bool
function sound_preview_end_and_no_errors()
    sd i=0
    sd bools
    setcall bools sound_preview_buffers_bool()
    sd max
    setcall max sound_mm_buffers_get()
    while i<max
        if bools#==(TRUE)
            sd buffer
            setcall buffer sound_preview_mm_buffers(i)
            const off_lpData=0
            const off_dwBufferLength=off_lpData+DWORD
            const off_dwBytesRecorded=off_dwBufferLength+DWORD
            const off_dwUser=off_dwBytesRecorded+DWORD
            const off_dwFlags=off_dwUser+DWORD
            const WHDR_DONE=1
            add buffer (off_dwFlags)
            sd flags
            set flags buffer#
            and flags (WHDR_DONE)
            if flags==0
                return (FALSE)
            endif
        endif
        add bools (DWORD)
        inc i
    endwhile
    return (TRUE)
endfunction

import "mainwidget" mainwidget
importx "_gtk_file_chooser_dialog_new" gtk_file_chooser_dialog_new
import "filechooserfield_dialog" filechooserfield_dialog

#folder/0
function filechooserfield_folder()
    str select_folder="Select Folder"
    sd main
    setcall main mainwidget()
    str GTK_STOCK_CANCEL="gtk-cancel"
    data responsecancel=GTK_RESPONSE_CANCEL
    str GTK_STOCK_OK="gtk-ok"
    sd dialog
    setcall dialog gtk_file_chooser_dialog_new(select_folder,main,(GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER),GTK_STOCK_CANCEL,responsecancel,GTK_STOCK_OK,(GTK_RESPONSE_ACCEPT),0)
    sd filename
    setcall filename filechooserfield_dialog(dialog)
    return filename
endfunction

#e
function move_to_home()
	return (noerror)
endfunction
function move_to_home_v()
endfunction
function move_to_share_v()
endfunction
function move_to_home_core()
endfunction
function move_to_share_core()
endfunction
function prog_free()
endfunction

importx "_ulltoa" ulltoa_extern

function ulltoa(sd low,sd high,sd instr)
	call ulltoa_extern(low,high,instr,10)
endfunction

