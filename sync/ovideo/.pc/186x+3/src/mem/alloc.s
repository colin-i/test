

format elfobj

include "../_include/include.h"

importx "_realloc" realloc

import "strerrno" strerrno

#0/mem
function memrealloc(sd block,sd size)
    sd newblock
    SetCall newblock realloc(block,size)
    If newblock==0
            Chars newmem="Realloc failed with error: "
            str pnewmem^newmem
            call strerrno(pnewmem)
    EndIf
    return newblock
EndFunction

#0/mem
function memalloc(sd size)
    sd mem
    setcall mem memrealloc(0,size)
    return mem
endfunction

#################

#err
Function memoryrealloc(data ptrpointer,data size)
        Data newpointer#1
        Data oldpointer#1
        Set oldpointer ptrpointer#

        SetCall newpointer memrealloc(oldpointer,size)
        If newpointer==0
                Return (error)
        EndIf
        Set ptrpointer# newpointer
        Data noerr=noerror
        Return noerr
EndFunction

#err
function memoryalloc(data size,data memptr)
        Data err#1
        Data null=NULL
        Set memptr# null
        SetCall err memoryrealloc(memptr,size)
        Return err
endfunction

import "slen" slen
#e
#s1+s1+\+...sn+1
function allocsum_numbers_null(sd strings,sd numbers_total,sd ptrmem)
    data sizetoalloc#1
    data z=0
    data dword=4

    set sizetoalloc z
    while strings#!=z
        addcall sizetoalloc slen(strings#)
        add strings dword
    endwhile

    if numbers_total!=z
        data nr=sign_int_null
        while numbers_total!=z
            add sizetoalloc nr
            dec numbers_total
        endwhile
    endif

    inc sizetoalloc

    data err#1
    setcall err memoryalloc(sizetoalloc,ptrmem)
    return err
endfunction

#e
function allocsum_null(sd strings,sd ptrmem)
    data null=0
    sd err
    setcall err allocsum_numbers_null(strings,null,ptrmem)
    return err
endfunction

#################################################################

function alloc_block(sd action,sd mem,sd size,sd append,sd append_size)
    sd err
    if action==(value_set)
    #0/block
        sd value=0
        sd p_value^value
        setcall err memoryrealloc(p_value,0)
        if err!=(noerror)
            return 0
        endif
        return value
    elseif action==(value_unset)
        importx "_free" free
        call free(mem)
    else
    #if action==(value_append)
    #new mem pointer,or old one
        import "multiple_of_nr" multiple_of_nr
        sd page=0x1000
        sd currentsize
        if size==0
            set currentsize 0
        else
            setcall currentsize multiple_of_nr(size,page)
        endelse

        sd newsize
        set newsize size
        add newsize append_size
        if newsize>currentsize
            setcall newsize multiple_of_nr(newsize,page)
            sd p_mem^mem

            setcall err memoryrealloc(p_mem,newsize)
            if err!=(noerror)
                return 0
            endif
        endif

        if append!=0
            sd cursor
            set cursor mem
            add cursor size

            import "cpymem" cpymem
            call cpymem(cursor,append,append_size)
        endif

        return mem
    endelse
endfunction
