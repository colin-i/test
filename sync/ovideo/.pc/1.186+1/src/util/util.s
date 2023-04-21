
format elfobj

include "../_include/include.h"


import "texter" texter

##display

#void
function strvaluedisp(str text,data part2,data formattype)
    str int="%s%i"
    str uint="%s%u"
    str str="%s%s"

    data si=stringinteger
    data su=stringUinteger

    const infomax=200
    char disp#infomax
    str display^disp

    import "slen" slen
    data max=infomax
    data truncation#1
    data notruncation=0
    data dword=4
    char truncdata="..."
    data truncdots^truncdata

    set truncation notruncation

    str format#1
    if formattype==si
        set format int
    elseif formattype==su
        set format uint
    else
        set format str

        data sz#1
        setcall sz slen(text)
        addcall sz slen(part2)
        if sz>=max
            set truncation display
            add truncation max
            sub truncation dword
        endif
    endelse

    import "c_snprintf_strvaluedisp" c_snprintf_strvaluedisp
    call c_snprintf_strvaluedisp(display,max,format,text,part2)

    if truncation!=notruncation
        set truncation# truncdots#
    endif

    call texter(display)
endfunction

function strstrdisp(str text,str part2)
    data ss=stringstring
    call strvaluedisp(text,part2,ss)
endfunction

function strdworddisp(str text,sd part2)
    data sd=stringUinteger
    call strvaluedisp(text,part2,sd)
endfunction


function content_size(sd ptrdata1,sd ptrdata2)
    set ptrdata2# ptrdata1#
    data dw=4
    add ptrdata1 dw
    add ptrdata2 dw
    set ptrdata2# ptrdata1#
endfunction




