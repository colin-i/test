Format ElfObj64

importaftercall ebool
include "../include/prog.h"

function bits_packs(ss dest,sd packs)
    sd i=0
    sd pos=0x80
    sd value
    sd size
    sd src^packs
    while i<packs
        incst src
        set value src#
        incst src
        set size src#
        call bits_bigendian(value,size,#dest,#pos)
        inc i
    endwhile
endfunction
function bits_bigendian(sd value,sd size,sv p_dest,sd p_pos)
    ss dest
    sd pos
    set dest p_dest#
    set pos p_pos#
    sd iter=-1
    while size!=0
        mult iter 2
        dec size
    endwhile
    not iter
    inc iter
    div iter 2
    while iter!=0
        if pos==0x80
            set dest# 0
        endif
        sd test
        set test iter
        and test value
        if test!=0
            or dest# pos
        endif
        div pos 2
        if pos==0
            set pos 0x80
            inc dest
        endif
        div iter 2
    endwhile
    set p_dest# dest
    set p_pos# pos
endfunction


function num_bits(sd value)
    sd sign=~0x7fFFffFF
    and sign value
    sd mask=~0x7fFFffFF
    sd i=32
    while i!=0
        dec i
        div mask 2
        sd test
        set test mask
        and test value
        if sign==0
            if test!=0
                return i
            endif
        else
            if test!=mask
                return i
            endif
        endelse
    endwhile
    return i
endfunction

function numbitsMax(sd width,sd height)
    sd value1
    setcall value1 num_bits(width)
    sd value2
    setcall value2 num_bits(height)
    sd NBits
    set NBits value1
    if value2>value1
        set NBits value2
    endif
    #is signed
    inc NBits
    return NBits
endfunction
#
import "swf_mem_add" swf_mem_add
function rect_add(sd width,sd height)
    sd mem
    sd sz
    call rect_prepare(#mem,#sz,width,height)
    call swf_mem_add(mem,sz)
endfunction
function rect_prepare(sv p_out,sd p_size,sd width,sd height)
    sd NBits
    mult width 20
    mult height 20
    setcall NBits numbitsMax(width,height)
    chars rect#31*4+5
    call bits_packs(#rect,5,NBits,(NBits_size),0,NBits,width,NBits,0,NBits,height,NBits)
    sd size=4
    mult size NBits
    add size 5
        #to bytes
        add size 7
        div size 8
    set p_out# #rect
    set p_size# size
endfunction
function matrix_translate(sv p_dest,sd p_size,sd x,sd y)
    chars matrix#1+4+4
    set p_dest# #matrix
    if x==0
        if y==0
            set matrix 0
            set p_size# 1
            return (void)
        endif
    endif
    sd NBits
    mult x 20
    mult y 20
    setcall NBits numbitsMax(x,y)
    call bits_packs(#matrix,(3+2),0,1,0,1,NBits,(NBits_size),x,NBits,y,NBits)
    sd size=2
    mult size NBits
    add size (1+1+5)
        #to bytes
        add size 7
        div size 8
    set p_size# size
endfunction
#


