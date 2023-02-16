

format elfobj

include "../_include/include.h"

import "texter" texter

#err
function mix_timeout_verify(sd file)
    data filelength#1
    const ptr_filelength^filelength
    sd newfilelength
    sd ptr_newfilelength^newfilelength
    import "file_length" file_length
    sd err
    setcall err file_length(file,ptr_newfilelength)
    if err!=(noerror)
        return err
    endif
    if filelength==newfilelength
        str timeexpired="Timeout, stopped"
        call texter(timeexpired)
        data dialog#1
        const ptr_dlg_for_time^dialog
        importx "_gtk_dialog_response" gtk_dialog_response
        call gtk_dialog_response(dialog,(GTK_RESPONSE_CANCEL))
        return timeexpired
    endif
    set filelength newfilelength
    return (noerror)
endfunction

importx "_gtk_entry_get_text" gtk_entry_get_text

#timeout function 0 stop
function mix_timeout(sd *data)
    #terminates this loop if pipe was unset
    data pipe#1
    const ptr_pipe_for_timeout^pipe
    if pipe==0
        return 0
    endif

    #verify if file length was changed
    str dest#1
    const ptr_dest^dest
    import "file_forward_read" file_forward_read
    data f^mix_timeout_verify
    sd err
    setcall err file_forward_read(dest,f)
    if err!=(noerror)
        return 0
    endif

    #append one dot or set one dot
    str maxdots="........"
    import "get_current_texter_pointer" get_current_texter_pointer
    sd texter_ptr
    setcall texter_ptr get_current_texter_pointer()
    sd widget
    set widget texter_ptr#
    sd text
    setcall text gtk_entry_get_text(widget)
    import "cmpstr" cmpstr
    sd cmpresult
    setcall cmpresult cmpstr(text,maxdots)
    str onedot="."
    if cmpresult==0
        call texter(onedot)
        return 1
    endif
    importx "_gtk_editable_insert_text" gtk_editable_insert_text
    sd pos
    sd ptr_pos^pos
    import "slen" slen
    setcall pos slen(text)
    call gtk_editable_insert_text(widget,onedot,1,ptr_pos)
    return 1
endfunction

function mix_init_save(sd vbox,sd dialog)
    #modal with pipe signals
    data pipe#1
    const ptr_pipe^pipe
    import "default_signals_for_modal" default_signals_for_modal
    call default_signals_for_modal(pipe,dialog)

    #label
    str text="Muxing to file. Please wait..."
    import "labelfield_l" labelfield_l
    call labelfield_l(text,vbox)

    #new texter
    import "new_texter_modal" new_texter_modal
    call new_texter_modal(vbox,dialog)

    #pointer for timeout and close dialog
    data ptr_dlg%ptr_dlg_for_time
    set ptr_dlg# dialog
endfunction
function mix_done_save()
    sd ptr_dest%ptr_dest
    import "save_inform_saved" save_inform_saved
    call save_inform_saved(ptr_dest#)
endfunction

importx "_sprintf" sprintf

function mix_launch_got_command(sd command)
    #create the pipe
    import "launch_pipe_start" launch_pipe_start
    sd ptr_pipe_tm%ptr_pipe_for_timeout
    setcall ptr_pipe_tm# launch_pipe_start(command)
    sd pipe
    set pipe ptr_pipe_tm#
    if pipe==0
        return 0
    endif
    sd ptr_pipe%ptr_pipe
    set ptr_pipe# pipe

    #set the timeout interval
    import "strtoint_positive" strtoint_positive
    data tm#1
    const ptr_tm^tm
    sd timeout
    sd ptr_timeout^timeout
    ss text
    setcall text gtk_entry_get_text(tm)
    sd bool
    setcall bool strtoint_positive(text,ptr_timeout)
    if bool==0
        return 0
    endif
    mult timeout 1000
    data f^mix_timeout
    importx "_gdk_threads_add_timeout" gdk_threads_add_timeout
    call gdk_threads_add_timeout(timeout,f,0)
    #and set the file length value to 0
    sd ptr_length%ptr_filelength
    set ptr_length# 0

    #launch the modal waiter
    sd init^mix_init_save
    sd done^mix_done_save
    str waiter="Mux save"

    import "dialogfield_size_button" dialogfield_size_button
    str GTK_STOCK_CANCEL="gtk-cancel"
    call dialogfield_size_button(waiter,(GTK_DIALOG_MODAL),init,done,200,100,GTK_STOCK_CANCEL,(GTK_RESPONSE_CANCEL))

    import "default_unref_ptr" default_unref_ptr
    call default_unref_ptr(ptr_pipe_tm)
endfunction

import "allocsum_null" allocsum_null
importx "_free" free

function mix_launch_got_audio_string(sd audiostring)
    data vid#1
    const ptr_vid^vid

    str format#1
    str sr#1
    str sr_prop#1
    str video#1
    str dst#1
    str audio#1
    data *=0
    sd ptr_launchformat^format

    str nullstr=""

    import "save_get_main_format" save_get_main_format
    import "save_get_video_format" save_get_video_format
    import "save_get_ogg_dest" save_get_ogg_dest

    setcall format save_get_main_format()
    setcall sr gtk_entry_get_text(vid)
    set sr_prop nullstr
    setcall video save_get_video_format()
    setcall dst save_get_ogg_dest()
    sd ptr_destination%ptr_dest
    set ptr_destination# dst
    set audio audiostring

    sd launchstring
    sd ptr_launchstring^launchstring
    sd err
    setcall err allocsum_null(ptr_launchformat,ptr_launchstring)
    if err!=(noerror)
        return err
    endif

    call sprintf(launchstring,format,sr,sr_prop,video,dst,audio)
    call mix_launch_got_command(launchstring)

    call free(launchstring)
endfunction


function mix_launch()
    data snd#1
    const ptr_snd^snd

    import "save_get_sec_format" save_get_sec_format
    import "save_get_audio_format" save_get_audio_format

    chars audio_vars_data#40

    #let first space otherelse will be pipe start unable
    ss audiogetformat=" uridecodebin uri=\"%s\"%s"
    ss audioloc#1
    ss audio_vars^audio_vars_data
    ss *=0
    sd ptr_audio_uri^audiogetformat

    str nullstr=""

    setcall audioloc gtk_entry_get_text(snd)

    sd audioformat
    setcall audioformat save_get_sec_format()
    sd audio
    setcall audio save_get_audio_format()
    call sprintf(audio_vars,audioformat,nullstr,audio)

    sd audiostring
    sd ptr_audiostring^audiostring
    sd err
    setcall err allocsum_null(ptr_audio_uri,ptr_audiostring)
    if err!=(noerror)
        return err
    endif

    call sprintf(audiostring,audiogetformat,audioloc,audio_vars)
    call mix_launch_got_audio_string(audiostring)

    call free(audiostring)
endfunction


function mix_init(sd vbox,sd *dialog)
    sd video
    sd entryv
    sd audio
    sd entrya
    sd timeout
    sd entryt
    sd cells^video

    data rows=3
    data cols=2

    importx "_gtk_entry_new" gtk_entry_new

    import "labelfield_left_prepare" labelfield_left_prepare

    str v="Video source uri"
    setcall video labelfield_left_prepare(v)
    setcall entryv gtk_entry_new()
    sd vd%ptr_vid
    set vd# entryv
    str a="Audio source uri"
    setcall audio labelfield_left_prepare(a)
    setcall entrya gtk_entry_new()
    sd sd%ptr_snd
    set sd# entrya
    str t="Inactivity timeout in seconds"
    setcall timeout labelfield_left_prepare(t)
    setcall entryt gtk_entry_new()
    sd tm%ptr_tm
    set tm# entryt

    importx "_gtk_entry_set_text" gtk_entry_set_text
    str defaulttimeout="5"
    call gtk_entry_set_text(entryt,defaulttimeout)

    import "tablefield_cells" tablefield_cells
    call tablefield_cells(vbox,rows,cols,cells)
endfunction

function mix_start()
    ss title="Audio Video Mix"
    data init^mix_init
    data do^mix_launch
    import "dialogfield" dialogfield
    call dialogfield(title,(GTK_DIALOG_MODAL),init,do)
endfunction
