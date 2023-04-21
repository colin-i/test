


format elfobj

include "../_include/include.h"

import "foreach_dword" foreach_dword

import "content_size" content_size


function search_preferences_set_init()
    DATA search_preferences_mem#1
    const search_preferences_mem^search_preferences_mem


    #FIELDS
    #group1
    DATA startlabel#1
    #
    const search_structures^startlabel
    #
    DATA startentry#1
    #
    const search_start_entry^startentry
    const search_start=search_start_entry-search_structures
    #
    DATA *get_uri#1
    DATA endentry#1
    #
    const search_end_entry^endentry
    const search_end=search_end_entry-search_structures
    #
    DATA *endlabel#1
    #group2
    DATA search_wrap_begin#1
    const search_start_wrap=0
    const search_group2^search_wrap_begin
    const search_fields_struct_size=search_group2-search_structures
    DATA *#3
    DATA search_wrap_end#1
    const search_end_wrap_entry^search_wrap_end
    const search_end_wrap=search_end_wrap_entry-search_group2
    #

    #VARS
    #group1
    DATA search_preferences_uri_start#1
    #
    const search_first_var_offset^search_preferences_uri_start
    #
    DATA *search_preferences_uri_end#1
    #group2
    DATA search_preferences_wrap_start#1
    const search_group2_vars^search_preferences_wrap_start
    const search_vars_struct_size=search_group2_vars-search_first_var_offset
    #
    DATA search_preferences_wrap_end#1
    const search_last_var_offset^search_preferences_wrap_end
    const search_after_last_var_offset=search_last_var_offset+DWORD
    const search_vars_size=search_after_last_var_offset-search_first_var_offset
    #

    data z=0
    set search_preferences_mem z
endfunction

function search_get_mem()
    data search_preferences_mem%search_preferences_mem
    return search_preferences_mem
endfunction

function search_get_fields()
    data uri%search_structures
    return uri
endfunction
function search_get_vars()
    data offset%search_first_var_offset
    return offset
endfunction
function search_get_vars_based_on_index(sd index)
    sd vars
    setcall vars search_get_vars()
    sd off=search_vars_struct_size
    mult off index
    add vars off
    return vars
endfunction
function search_get_fields_based_on_var(sd number)
    data vars_size=search_vars_struct_size
    sd vars
    setcall vars search_get_vars()
    sub number vars
    div number vars_size
    data fields_size=search_fields_struct_size
    mult number fields_size
    sd fields
    setcall fields search_get_fields()
    add fields number
    return fields
endfunction

function search_clear_memory()
    sd mem
    setcall mem search_get_mem()
    set mem mem#
    data null=0
    if mem!=null
        importx "_free" free
        call free(mem)
    endif
endfunction

function search_foreach(sd forward,sd data)
    data nr=search_vars_size
    sd vars
    setcall vars search_get_vars()
    call foreach_dword(nr,vars,forward,data)
endfunction

#e
function getvar(sd var,sd str_sz)
    data mem#1
    data size#1

    sd ptrdata^mem
    call content_size(str_sz,ptrdata)

    import "slen_s" slen_s
    sd sz
    sd ptrsz^sz
    sd err
    sd noerr=noerror

    setcall err slen_s(mem,size,ptrsz)
    if err!=noerr
        return err
    endif
    set var# mem
    import "move_cursors" move_cursors
    inc sz
    call move_cursors(str_sz,sz)

    return noerr
endfunction

function search_filename()
    str path="search.data"
    return path
endfunction

import "file_get_content" file_get_content
function search_preferences_read_set()
    sd err
    data noerr=noerror
    ss path
    setcall path search_filename()

    data mem#1
    data sz#1

    sd ptrsz^sz

    sd str_sz^mem

    sd ptr_search_mem

    #mem
    setcall ptr_search_mem search_get_mem()

    setcall err file_get_content(path,ptrsz,ptr_search_mem)
    if err!=noerr
        return err
    endif
    set mem ptr_search_mem#

    #packs
    data fn^getvar
    call search_foreach(fn,str_sz)
endfunction

function search_preferences_init_vars(sd var,sd *data)
    str nullstr=""
    set var# nullstr
    data noError=noerror
    return noError
endfunction

function search_preferences_init()
    call search_preferences_set_init()
    data f^search_preferences_init_vars
    data null=0
    call search_foreach(f,null)
    call search_preferences_read_set()
endfunction



#read to display or write to file

function setdisplay_setfile_search(sd method,sd argument,sd text)
#method calls
#           selection 0, field,text
#           selection 1, field
#method init
#           selection 0
#           selection 1, file

    const search_setdisplay=0
    const search_setfile=1
    const search_calls=2
    data setdisplay=2
    data setfile=3
    data selection#1

    if method<setdisplay
        add method setdisplay
        set selection method
        if method==setfile
            data file#1
            set file argument
        endif
    else
        if selection==setdisplay
            importx "_gtk_entry_set_text" gtk_entry_set_text
            call gtk_entry_set_text(argument,text)
        else
            importx "_gtk_entry_get_text" gtk_entry_get_text
            import "slen" slen
            ss buffer
            setcall buffer gtk_entry_get_text(argument)
            sd size
            setcall size slen(buffer)
            inc size
            sd e
            import "file_write" file_write
            setcall e file_write(buffer,size,file)
            return e
        endelse
    endelse
    data noe=noerror
    return noe
endfunction


function set_field_loop(sd var,sd ptroff)
    sd fields
    setcall fields search_get_fields_based_on_var(var)
    sd off
    set off ptroff#
    add fields off#

    data calls=search_calls
    sd e
    data noe=noerror
    setcall e setdisplay_setfile_search(calls,fields#,var#)
    if e!=noe
        return e
    endif

    data dw=4
    add ptroff# dw
    return noe
endfunction

function search_set_field_or_file()
    data startoffset=search_start
    data *endoffset=search_end
    data *wrapstartoffset=search_start_wrap
    data *wrapendoffset=search_end_wrap
    sd off^startoffset
    sd ptroff^off

    data fn^set_field_loop
    call search_foreach(fn,ptroff)
endfunction


#read
function set_field_pack()
    data search_setdisplay=search_setdisplay
    call setdisplay_setfile_search(search_setdisplay)
    call search_set_field_or_file()
endfunction


#settings ok button pressed

function search_file_write(sd file)
    data search_setfile=search_setfile
    call setdisplay_setfile_search(search_setfile,file)
    call search_set_field_or_file()
endfunction

function write_free_read()
    import "file_write_forward" file_write_forward
    data f^search_file_write
    ss path
    setcall path search_filename()
    call file_write_forward(path,f)

    call search_clear_memory()

    call search_preferences_init()
endfunction
