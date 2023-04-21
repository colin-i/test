

format elfobj

include "../_include/include.h"


##set

#void
function setmem(str pointer,data size,chars value)
    str end#1
    set end pointer
    add end size
    while pointer!=end
            set pointer# value
            inc pointer
    endwhile
endfunction

#void
function setmemzero(str pointer,data size)
    chars zero=0
    call setmem(pointer,size,zero)
endfunction


##cursors

import "content_size" content_size
#advance the content/size by value
Function move_cursors(sd str_sz,data nr)
    sd mem
    sd size

    sd ptrdata^mem

    call content_size(str_sz,ptrdata)

    Add mem nr

    #backward advance
    #take nr if nr>0 or -nr if nr<0
    Data zero=0
    If nr<zero
        import "neg" neg
        SetCall nr neg(nr)
    EndIf

    Sub size nr
    call content_size(ptrdata,str_sz)
EndFunction


##cpy

#void
function cpymem(ss dest,ss src,sd size)
    data zero=0
    while size!=zero
            set dest# src#
            inc dest
            inc src
            dec size
    endwhile
endfunction

#e
function cpymem_safesrc_advance(sd dest,sd src_sz,sd size)
    sd src
    sd sz
    sd srcsz^src
    call content_size(src_sz,srcsz)
    if sz<size
        import "texter" texter
        str cpysafesrcerr="Error with the length of some data."
        call texter(cpysafesrcerr)
        return cpysafesrcerr
    endif
    call cpymem(dest,src,size)
    call move_cursors(src_sz,size)
    data noerr=noerror
    return noerr
endfunction

#e
function get_mem_int_advance(sd dest,sd src_sz)
    sd er
    data a=4
    setcall er cpymem_safesrc_advance(dest,src_sz,a)
    return er
endfunction
#e
function get_str_advance(sd dest,sd size,sd src_sz)
    sd src
    sd sz
    sd srcsz^src
    call content_size(src_sz,srcsz)
    sd len
    import "slen_s" slen_s
    sd er
    setcall er slen_s(src,sz,#len)
    if er!=(noerror)
        return er
    endif
    inc len
    if len>size
        str szerr="String size is wrong"
        call texter(szerr)
        return szerr
    endif
    call cpymem(dest,src,len)
    call move_cursors(src_sz,len)
    return (noerror)
endfunction

##cmp

#0 equal -1 not
Function cmpmem(str m1,str m2,data size)
        Data zero=0

        Data equal=equalCompare
        Data notequal=differentCompare

        Chars c1#1
        Chars c2#1
        While size!=zero
                Set c1 m1#
                Set c2 m2#
                If c1!=c2
                        Return notequal
                EndIf
                Inc m1
                Inc m2
                Dec size
        EndWhile
        Return equal
EndFunction

#0 equal -1 not
function cmpmem_s(str m1,data s1,str m2,data s2)
    data different=differentCompare
    if s1!=s2
        return different
    endif
    data result#1
    setcall result cmpmem(m1,m2,s1)
    return result
endfunction

import "slen" slen

#0 equal -1 not
function cmpstr(ss s1,ss s2)
    sd size1
    sd size2
    setcall size1 slen(s1)
    setcall size2 slen(s2)
    sd result
    setcall result cmpmem_s(s1,size1,s2,size2)
    return result
endfunction

##valinmem

#return the size of the value, if the delim is found the size counts until there
Function valinmemsens(str content,data size,chars delim) #,data sens
        Data length#1
        Set length size
        Chars byte#1
        Data zero=0

        If size==zero
                Return size
        EndIf
        #Data backward=BACKWARD
        #If sens==backward
                Dec content
        #EndIf
        Set byte content#
        While byte!=delim
                #If sens!=backward
                #        Inc content
                #Else
                        Dec content
                #EndElse
                Dec size
                If size==zero
                        Set byte delim
                Else
                        Set byte content#
                EndElse
        EndWhile

        Sub length size
        Return length
EndFunction




##start end , center go

import "strinmem_portions_advance" strinmem_portions_advance
import "memtostrFw_data" memtostrFw_data
#v/e
function find_start_end_forward_center_data(sd mem,sd size,ss start,ss end,sd forward,sd data)
    data z=0
    data true=1
    data false=0
    sd err
    sd noerr=noerror
    while size!=z
        sd str_sz^mem
        call strinmem_portions_advance(str_sz,start,false,true)
        if size!=z
            sd center
            sd sz
            set center mem
            setcall sz strinmem_portions_advance(str_sz,end,true,true)
            setcall err memtostrFw_data(center,sz,forward,data)
            if err!=noerr
                return err
            endif
        endif
    endwhile
endfunction



