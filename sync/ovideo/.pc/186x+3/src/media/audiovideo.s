
format elfobj
include "../_include/include.h"

#audio video read or write

function av_readwrite_value(sd action,sd value)
    data readwrite_value#1
    if action==(value_set)
        set readwrite_value value
    else
        return readwrite_value
    endelse
endfunction

#container read or write, little endian
#bool
function av_chunk_readwrite(sd file,sd forward,ss riff)
    sd bool
    sd err
    sd io
    setcall io av_readwrite_value((value_get))

    import "file_write" file_write

    sd chunk_id
    sd chunk_size
    sd p_chunk^chunk_id

    if io==(write_file)
        import "cpymem" cpymem
        call cpymem(p_chunk,riff,4)

        #write id-size, 8 bytes
        setcall err file_write(p_chunk,8,file)
        if err!=(noerror)
            return 0
        endif
    else
        #get id-size
        import "file_read" file_read
        setcall err file_read(p_chunk,8,file)
        if err!=(noerror)
            return 0
        endif
    endelse

    import "file_tell" file_tell

    #get the point for write/read calculations
    sd file_pos
    sd ptr_file_pos^file_pos
    setcall err file_tell(file,ptr_file_pos)
    if err!=(noerror)
        return 0
    endif

    #write only, but can be used if io is changed inside
    sd writepoint
    set writepoint file_pos
    sub writepoint 4

    #                         write+read(segment offset)
    setcall bool forward(file,file_pos,p_chunk,chunk_size)
    #                                  read(iterate chunks)

    import "file_set_dword" file_set_dword
    import "file_seek" file_seek
    #io again if changed inside the riff
    setcall io av_readwrite_value((value_get))

    if io==(write_file)
    #set the size at write
        sd seg_size_after
        sd ptr_seg_size_after^seg_size_after
        setcall err file_tell(file,ptr_seg_size_after)
        if err!=(noerror)
            return 0
        endif
        sub seg_size_after file_pos

        setcall err file_set_dword(file,writepoint,ptr_seg_size_after)
        if err!=(noerror)
            return 0
        endif
    else
    #at read, advance remaining/all size cursor
        add file_pos chunk_size
        setcall err file_seek(file,file_pos,(SEEK_SET))
        if err!=(noerror)
            return 0
        endif
    endelse

    return bool
endfunction

#bool
function av_writeseek(sd mem,sd size,sd file)
    sd err
    sd io
    setcall io av_readwrite_value((value_get))
    if io==(write_file)
        setcall err file_write(mem,size,file)
        if err!=(noerror)
            return 0
        endif
    else
        import "file_seek_cursor" file_seek_cursor
        setcall err file_seek_cursor(file,size)
        if err!=(noerror)
            return 0
        endif
    endelse
    return 1
endfunction

#riff chunks
#bool
function riff_chunk_w_r(sd file,sd forward,ss riff)
    sd err

    sd startpos
    sd p_startpos^startpos

    setcall err file_tell(file,p_startpos)
    if err!=(noerror)
        return 0
    endif

    sd bool
    setcall bool av_chunk_readwrite(file,forward,riff)
    if bool!=1
        return 0
    endif

    sd endpos
    sd p_endpos^endpos
    setcall err file_tell(file,p_endpos)
    if err!=(noerror)
        return 0
    endif

    sub endpos startpos
    and endpos 1
    if endpos!=0
        sd pad=0
        sd p_pad^pad
        setcall bool av_writeseek(p_pad,1,file)
        if bool!=1
            return 0
        endif
    endif
    return 1
endfunction

function riff_w_r_name(sd file,ss name)
    sd bool
    setcall bool av_writeseek(name,4,file)
    return bool
endfunction






#dialog for read/write waiting

import "dialog_modal_texter_draw" dialog_modal_texter_draw

function av_dialog_run_simple(sd forward)
    call av_dialog_run(forward,0)
endfunction

#bool
function av_dialog_run(sd forward,sd data)
    data dialog#1

    #init for linux terminal capture
    import "dialog_modal_texter_drawwidget" dialog_modal_texter_drawwidget
    call dialog_modal_texter_drawwidget((value_set),0)
    call av_dialog_multiline_info((value_set),0)
    set dialog 0

    import "capture_terminal" capture_terminal
    sd term
    setcall term capture_terminal((value_get))
    if term==0
        #initiate the dialog
        import "dialogfield_modal_texter_core" dialogfield_modal_texter_core
        ss title="Audio Video Dialog"
        ss button="Close"
        data init_forward^av_dialog_init
        setcall dialog dialogfield_modal_texter_core(title,init_forward,button)
    endif

    #flag to stop the read/write on another thread
    call av_dialog_stop((value_set),0)

    sd bool=0

    #create the thread
    import "getptrgerr" getptrgerr
    sd ptrgerr
    setcall ptrgerr getptrgerr()
    importx "_g_thread_create" g_thread_create
    sd thread
    setcall thread g_thread_create(forward,data,1,ptrgerr)
    if thread==0
        import "gerrtoerr" gerrtoerr
        call gerrtoerr(ptrgerr)
    else
        if term==0
            #dialog run
            importx "_gtk_dialog_run" gtk_dialog_run
            sd response=GTK_RESPONSE_OK+1
            sd stop_click=0
            while response!=(GTK_RESPONSE_OK)
                setcall response gtk_dialog_run(dialog)
                if response!=(GTK_RESPONSE_OK)
                    call av_dialog_stop((value_set),1)
                    set stop_click 1
                endif
            endwhile
            if stop_click==0
                #keep the dialog for viewing informations
                sd toggle
                setcall toggle av_results((value_get))
                if toggle!=0
                    call gtk_dialog_run(dialog)
                    import "stage_file_options_info_message" stage_file_options_info_message
                    sd toggle_button
                    setcall toggle_button av_results_toggle_button((value_get))
                    importx "_gtk_toggle_button_get_active" gtk_toggle_button_get_active
                    setcall toggle gtk_toggle_button_get_active(toggle_button)
                    if toggle==1
                        call stage_file_options_info_message((value_set),0)
                    endif
                endif
            endif
        else
            import "capture_alt_ev_wait" capture_alt_ev_wait
            call capture_alt_ev_wait()
        endelse
        #close the other thread and get return(optional)
        importx "_g_thread_join" g_thread_join
        setcall bool g_thread_join(thread)
    endelse

    if dialog!=0
        #for text draw callbacks
        call dialog_modal_texter_drawwidget((value_set),0)
        #free dialog
        importx "_gtk_widget_destroy" gtk_widget_destroy
        call gtk_widget_destroy(dialog) #here is not saying critical at windows, but also on linux the dialog needs to be destroyed
    endif

    return bool

    const av_dialog^dialog
endfunction
function av_dialog_handle()
    sd p%av_dialog
    return p#
endfunction
function av_dialog_close()
    sd dialog
    setcall dialog av_dialog_handle()
    if dialog!=0
    #close the dialog
        importx "_gtk_dialog_response" gtk_dialog_response
        call gtk_dialog_response(dialog,(GTK_RESPONSE_OK))
    else
    #signal the terminal
        import "capture_alt_ev_set" capture_alt_ev_set
        call capture_alt_ev_set()
    endelse
endfunction
function av_dialog_stop(sd action,sd value)
    data x#1
    if action==(value_set)
        set x value
    else
        return x
    endelse
endfunction

import "slen" slen

#text iter at get
function av_dialog_multiline_info(sd action,sd arg)
    data view#1
    sd buffer
    if action==(value_set)
        set view arg
    else
    #if action==(value_insert)
        if view==0
            return 0
        endif
        importx "_gtk_text_view_get_buffer" gtk_text_view_get_buffer
        sd text
        set text arg
        setcall buffer gtk_text_view_get_buffer(view)
        sd len
        setcall len slen(text)
        importx "_gtk_text_buffer_insert_at_cursor" gtk_text_buffer_insert_at_cursor
        call gtk_text_buffer_insert_at_cursor(buffer,text,len)
    endelse
endfunction

function av_dialog_init(sd vbox,sd *dialog)
    #init for read
    call av_display_info((value_set))
    #info widgets
    importx "_gtk_scrolled_window_new" gtk_scrolled_window_new
    sd scroll
    setcall scroll gtk_scrolled_window_new(0,0)
    call av_results((value_set),scroll,vbox)
    importx "_gtk_widget_set_size_request" gtk_widget_set_size_request
    call gtk_widget_set_size_request(scroll,-1,200)
    importx "_gtk_text_view_new" gtk_text_view_new
    sd view
    setcall view gtk_text_view_new()
    import "container_add" container_add
    call container_add(scroll,view)
    call av_dialog_multiline_info((value_set),view)
    importx "_gtk_text_view_set_editable" gtk_text_view_set_editable
    call gtk_text_view_set_editable(view,(FALSE))
endfunction

function av_results(sd action,sd scroll,sd vbox)
    data scroll_entry#1
    data vbox_entry#1
    if action==(value_set)
        set scroll_entry scroll
        set vbox_entry vbox
    else
    #returns toggle flag status (1/0)
        importx "_gtk_container_add" gtk_container_add
        call gtk_container_add(vbox_entry,scroll_entry)
        importx "_gtk_widget_show_all" gtk_widget_show_all
        call gtk_widget_show_all(scroll_entry)

        #info message flag
        sd toggle
        setcall toggle stage_file_options_info_message((value_get))
        if toggle==0
            return 0
        endif
        importx "_gtk_check_button_new_with_label" gtk_check_button_new_with_label
        ss txt="Disable results message(set from Stage Options to disable permanently)"
        sd results_toggle
        setcall results_toggle gtk_check_button_new_with_label(txt)
        import "packstart_default" packstart_default
        call packstart_default(vbox_entry,results_toggle)
        call av_results_toggle_button((value_set),results_toggle)
        importx "_gtk_widget_show" gtk_widget_show
        call gtk_widget_show(results_toggle)
        return 1
    endelse
endfunction

function av_results_toggle_button(sd action,sd value)
    data toggle#1
    if action==(value_set)
        set toggle value
    else
        return toggle
    endelse
endfunction

const av_info_all=0
const av_info_simple=1

#at write
function av_display_progress(sd image_nr,sd flag_simple)
    #capture_flag and read info both goes in flag_simple
	const procimgstrstart=!
	chars format_stage="Processed images: %u/%u"
	chars data#!-procimgstrstart-2-2+dword_max+dword_max
	vstr string^data
	chars format_capture="Processed images: %u"
    importx "_sprintf" sprintf
    if flag_simple==(av_info_all)
        import "stage_get_frames" stage_get_frames
        sd totalframes
        setcall totalframes stage_get_frames()
        call sprintf(string,#format_stage,image_nr,totalframes)
    else
    #on
        call sprintf(string,#format_capture,image_nr)
    endelse
    call dialog_modal_texter_draw(string)
endfunction

function av_display_info_progress(sd file,sd current_frame)
    sd image_nr
    set image_nr current_frame
    inc image_nr
    call av_display_progress(image_nr,(av_info_all))
    call av_display_info((value_write),file,current_frame)
endfunction

function av_display_info(sd action,sd file,sd nr,sd frame_size)
    data start#1
    data end#1
    data p_start^start
    data p_end^end
    data read_counter#1
    if action==(value_set)
        #set read counter
        set read_counter 0
    elseif action==(value_get)
        call file_tell(file,p_start)
        #get start pointer
    else
        #if action==(value_write)
        #get/display
        chars bf#100
        str text^bf
        str format="Frame: %u, Size: %u bytes"
        sd size

        if nr!=-1
            #write
            call file_tell(file,p_end)
            set size end
            sub size start
        else
            #read
            set nr read_counter
            inc read_counter
            set size frame_size
            #add visual info
            sd imgs
            set imgs nr
            inc imgs
            call av_display_progress(imgs,(av_info_simple))
        endelse

        call sprintf(text,format,nr,size)
        sd len
        setcall len slen(text)
        ss cursor
        set cursor text
        add cursor len
        set cursor# (LineFeed)
        inc cursor
        set cursor# 0
        call av_dialog_multiline_info((value_insert),text)
    endelse
endfunction

#bool
function av_read_row(sd width,sd height,sd buffer,sd bytes,sd filerowstride,sd rowindex)
    import "rgb_get_rowstride" rgb_get_rowstride
    sd bufferrowstride
    setcall bufferrowstride rgb_get_rowstride(width)

    import "texter" texter
    if filerowstride>bufferrowstride
        ss rstr="Rowstride too large"
        call texter(rstr)
        return 0
    elseif rowindex>=height
        ss herr="Height too big"
        call texter(herr)
        return 0
    endelseif

    mult bufferrowstride rowindex
    add buffer bufferrowstride

    call cpymem(buffer,bytes,filerowstride)

    return 1
endfunction

#bool
function riff_head(sd mem_sz,ss chunk,sd p_chunk_size,ss riff_ex)
    sd mem
    sd size
    sd block^mem
    call cpymem(block,mem_sz,8)
    if size<8
        str er="More size expected"
        call texter(er)
        return 0
    endif
    import "cmpmem" cmpmem
    sd cmp
    setcall cmp cmpmem(chunk,mem,4)
    if cmp!=(equalCompare)
        str cmp_er="Unrecognized chunk"
        call texter(cmp_er)
        return 0
    endif
    import "move_cursors" move_cursors
    call move_cursors(block,4)
    set p_chunk_size# mem#
    call move_cursors(block,4)
    if p_chunk_size#>size
        str sz_er="Too much size"
        call texter(sz_er)
        return 0
    endif
    if riff_ex!=0
        #ex: RIFF,size,WAVE
        if size<4
            call texter(er)
            return 0
        endif
        setcall cmp cmpmem(riff_ex,mem,4)
        if cmp!=(equalCompare)
            call texter(cmp_er)
            return 0
        endif
        call move_cursors(block,4)
        sub p_chunk_size# 4
    endif
    call cpymem(mem_sz,block,8)
    return 1
endfunction


function combo_location(sd bool,sd data)
    import "stage_get_output_container" stage_get_output_container
    sd location
    if bool==0
        setcall location stage_get_output_container()
    else
        import "capture_path" capture_path
        import "stage_file_get_format" stage_file_get_format
        ss format
        setcall format stage_file_get_format()
        setcall location capture_path(format,1,data)
    endelse
    return location
endfunction


function av_expand()
    import "frame_jobs" frame_jobs
    sd bool
    setcall bool frame_jobs()
    if bool!=1
        return 0
    endif

    import "filechooserfield" filechooserfield
    sd filename
    setcall filename filechooserfield()
    if filename==0
        return 0
    endif

    call av_expand_go(filename)

    importx "_free" free
    call free(filename)
endfunction
import "cmpmem_s" cmpmem_s
function av_expand_go(ss filename)
    import "path_extension" path_extension
    ss extension
    setcall extension path_extension(filename)
    sd length
    setcall length slen(extension)
    inc length
    str a="avi"
    str m="mp4"
    sd frm_len
    sd compare

    import "avi_write_fname" avi_write_fname
    setcall frm_len slen(a)
    inc frm_len
    setcall compare cmpmem_s(extension,length,a,frm_len)
    if compare==(equalCompare)
        call avi_write_fname(filename,(avi_expand))
        return (void)
    endif

    setcall frm_len slen(m)
    inc frm_len
    setcall compare cmpmem_s(extension,length,m,frm_len)
    if compare==(equalCompare)
        import "mp4_extend" mp4_extend
        call mp4_extend(filename)
        return (void)
    endif

    call texter("Unrecognized format")
endfunction
