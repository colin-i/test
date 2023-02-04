Format ElfObj64

importx "_open" open
importx "_read" read
importx "_write" write
importx "_lseek" lseek
#importx tell   can't find it
importx "_close" close

importaftercall ebool
include "../include/prog.h"

import "printEr" printEr
import "error" error

#file
function file_open(ss filepath,sd flags)
    sd file
    sd permission
    sd creat_test;set creat_test flags;and creat_test (flag_O_CREAT);if creat_test!=0
        set permission (flag_pmode);endif
    SetCall file open(filepath,flags,permission)
    if file==(fd_error)
        call printEr("File: \"")
        call printEr(filepath)
        call error("\" cannot be opened")
    EndIf
    return file
endfunction
function file_seek(sd file,sd off,sd method)
    sd seekint
    setcall seekint lseek(file,off,method)
    If seekint==-1
        vstr seekerr="File seek error"
        call error(seekerr)
    endif
endfunction
#sz
function file_tell(sd file)
    sd sz
    setcall sz lseek(file,0,(SEEK_CUR))
    if sz==-1
        vstr tellerr="File tell error"
        call error(tellerr)
    endif
    return sz
endfunction
#size
function filesize(sd file)
    call file_seek(file,0,(SEEK_END))
    sd len
    setcall len file_tell(file)
    call file_seek(file,0,(SEEK_SET))
    return len
endfunction

#read
import "memalloc" memalloc
#mem
function file_get_content(ss filepath,sv p_size)  #size is a stack variable
    sd file
    setcall file file_open(filepath,(_open_read))
    call file_get_content__resources((TRUE),file)
    setcall p_size# filesize(file)
    sd mem
    setcall mem memalloc(p_size#)
    call file_get_content__resources((TRUE),(fd_none),mem)
    call file_read(file,mem,p_size#)
    return mem
endfunction
function file_read(sd file,sd mem,sd size)
    sd read_sz
    setcall read_sz read(file,mem,size)
    if read_sz!=size
        call error("Read length is different or error")
    endif
endfunction
function file_get_content__resources(sd trueIsSet_falseIsFree,sd fileIn,sd memIn)
    data file=fd_none;vdata mem=NULL
    if trueIsSet_falseIsFree==(TRUE)
        if fileIn!=(fd_none);set file fileIn
        else;set mem memIn;endelse
    else
        if file!=(fd_none)
            call file_close(#file)
            if mem!=(NULL)
                import "mem_free" mem_free
                call mem_free(#mem)
            endif
        endif
    endelse
endfunction
function file_get_content__resources_free()
    call file_get_content__resources((FALSE))
endfunction

#write

function file_write(sd file,sd buffer,sd size)
    if size==0
        return (void)
    endif
    sd len
    setcall len write(file,buffer,size)
    if len==size
        return (void)
    endif
    vstr er="File write error"
    call error(er)
endfunction

#close

function file_close(sd p_file)
    call close(p_file#)
    set p_file# (fd_none)
endfunction