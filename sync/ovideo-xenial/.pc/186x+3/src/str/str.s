
format elfobj

include "../_include/include.h"

import "memoryalloc" memalloc

function tostring(str string,data size)
        data zero=0
        str s#1

        set s string
        add s size
        set s# zero
endfunction

import "cpymem" cpymem

#void/err
function memtostrFw_s(str mem,data size,str dest,data destsize,data forward)
    if size>destsize
        import "texter" texter
        vstr memtostrconflict="Mem2Str: destination is too small."
        call texter(memtostrconflict)
    endif

    call cpymem(dest,mem,size)
    call tostring(dest,size)

    call forward(dest)
endfunction

#e
function slen_s(ss str,sd size,sd ptrszout)
    Chars term={0}
    Chars byte={0}
    Data zero=0
    data one=1
    sd loop

    set ptrszout# size
    set loop one
    while loop==one
        if size==zero
            set loop zero
        else
            Set byte str#
            if byte==term
                set loop zero
            else
                Inc str
                dec size
            endelse
        endelse
    endwhile
    sub ptrszout# size
    if size==zero
        str er="String null termination expected."
        call texter(er)
        return er
    endif
    data ne=noerror
    return ne
endfunction

#sizeof the string
function slen(str str)
        data maxsize=0xffFFffFF
        sd sz
        sd ptrsz^sz
        call slen_s(str,maxsize,ptrsz)
        return sz
endfunction

function path_extension(ss path)
    sd len
    ss cursor
    chars delim="."

    setcall len slen(path)

    set cursor path
    add cursor len
    while cursor!=path
        dec cursor
        if cursor#==delim
            inc cursor
            return cursor
        endif
    endwhile
    add path len
    return path
endfunction

import "move_cursors" move_cursors
function move_cursors_test(sd str_sz,sd size,sd advance)
    data true=1
    if advance==true
        call move_cursors(str_sz,size)
    endif
endfunction

import "cmpmem" cmpmem
#size before string(if match found);
#size(if match is not;if match points to a null string and takeall is true)
#0(if match points to a null string and takeall is false)
Function strinmem_portions_advance(sd str_sz,str match,sd takeall,sd advance)
        data true=1
        Data zero=0
        Data nrsz#1
        SetCall nrsz slen(match)

        ss content
        sd size

        sd string_size^content

        import "content_size" content_size
        call content_size(str_sz,string_size)

        if nrsz==zero
            if takeall==true
                call move_cursors_test(str_sz,size,advance)
                return size
            else
                return zero
            endelse
        elseif size<nrsz
            call move_cursors_test(str_sz,size,advance)
            Return size
        endelseif

        Str cnt#1
        Set cnt content
        Data sz#1
        Set sz size
        Data b#1
        While sz>=nrsz
                SetCall b cmpmem(cnt,match,nrsz)
                If b==zero
                    Sub cnt content
                    call move_cursors_test(str_sz,cnt,advance)
                    call move_cursors_test(str_sz,nrsz,advance)
                    return cnt
                EndIf
                If b!=zero
                        Inc cnt
                        Dec sz
                EndIf
        EndWhile
        call move_cursors_test(str_sz,size,advance)
        Return size
EndFunction

importx "_free" free
#e
function memtostrFw_data(sd mem,sd size,sd forward,sd data)
    sd err
    sd noerr=noerror
    ss alloc
    sd ptralloc^alloc
    inc size
    setcall err memalloc(size,ptralloc)
    if err!=noerr
        return err
    endif
    dec size
    call cpymem(alloc,mem,size)
    add alloc size
    chars n=0
    set alloc# n
    sub alloc size
    call forward(alloc,data)
    call free(alloc)
    return noerr
endfunction

#str
function get_string_at_index(ss iter,sd index)
    sd i=0
    while i!=index
        while iter#!=0
            inc iter
        endwhile
        inc iter
        inc i
    endwhile
    return iter
endfunction

#function catstrings(sd strings,ss dest)
#    sd src
#    while strings#!=0
#        #take every string
#        set src strings#
#        sd srcsz
#        #get src size
#        setcall srcsz slen(src)
#        #add null term
#        inc srcsz
#        #copy
#        call cpymem(dest,src,srcsz)
#        #dest cursor at null term
#        add dest srcsz
#        dec dest
#        #advance iterators
#        add strings 4
#    endwhile
#endfunction

#0/alloc
function string_alloc_escaped(ss unescaped)
    sd len
    setcall len slen(unescaped)
    sd escaped_len
    set escaped_len len
    mult escaped_len 2
    inc escaped_len
    ss escaped
    sd p_escaped^escaped
    sd err
    setcall err memalloc(escaped_len,p_escaped)
    if err!=(noerror)
        return 0
    endif
    ss cursor_escaped
    set cursor_escaped escaped
    while unescaped#!=0
        set cursor_escaped# unescaped#
        chars bslash="\\"
        if unescaped#==bslash
            inc cursor_escaped
            set cursor_escaped# bslash
        endif
        inc unescaped
        inc cursor_escaped
    endwhile
    set cursor_escaped# 0
    return escaped
endfunction

function strcpy(ss dest,ss src)
    sd len
    setcall len slen(src)
    call cpymem(dest,src,len)
    add dest len
    set dest# 0
endfunction
