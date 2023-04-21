

format elfobj


include "../_include/include.h"

import "getoneax" getoneax
##math
#low
function mult64(sd a,sd *b,sd *ptrhigh)
    sd pointer^a
    call getoneax(pointer)
    #ecx eax
    hex 0x8b,ecx*to_regopcode|mod_reg|eax
    #edx [eax+4]
    hex 0x8b,edx*to_regopcode|mod_disp8|eax,4
    #eax [eax]
    hex 0x8b,0
    #imul,edx
    hex 0xf7,5*to_regopcode|mod_reg|edx
    #[ecx] eax
    hex 0x89,ecx
    #eax [ecx+8]
    hex 0x8b,mod_disp8|ecx,8
    #[eax] edx
    hex 0x89,edx*to_regopcode
    #
    return a
endfunction
#highint
function mult64_highint_rounded(sd A,sd B)
    sd value
    sd p_value^value
    sd low
    setcall low mult64(A,B,p_value)
    if low<0
        inc value
    endif
    return value
endfunction

#return neg(nr)
Function neg(data nr)
        Data negative#1
        Set negative nr
        Sub nr negative
        Sub nr negative
        Return nr
EndFunction



function foreach_dword(sd size,sd vars,sd forward,sd data)
    sd last
    set last vars
    add last size

    data dw=4
    sd e
    data noe=noerror
    while vars!=last
#e
        setcall e forward(vars,data)
        if e!=noe
            return e
        endif
        add vars dw
    endwhile
endfunction



#bool numeric
Function numeric(char c)
        char zero="0"
        char nine="9"
        Data false=FALSE
        Data true=TRUE
        If c<zero
                Return false
        ElseIf c>nine
                Return false
        EndElseIf
        Return true
EndFunction

#bool
Function memtoint(str content,data size,data outvalue)
    set outvalue# 0
    if size==0
        return (FALSE)
    endif
    sd minusbool=FALSE
    char negsign="-"
    If content#==negsign
        Inc content;Dec size
        If size==0
            Return (FALSE)
        EndIf
        set minusbool (TRUE)
    EndIf
    sd b;setcall b memtoint_add(content,size,outvalue,minusbool)
    if minusbool==(TRUE)
        if outvalue#>0
#will go also at 4.294.967.296-6.442.450.943
#                8.589.934.592-9.999.999.999
#the truncations will be the user mistake
            mult outvalue# -1
        endif
    endif
    return b
EndFunction
#bool
Function memtoint_add(str content,data size,data outvalue,data minusbool)
#add at outvalue
    Data number#1
    data multx#1
    set multx 1
    Add content size
    While size!=0
        Dec content;Dec size

        Data bool#1
        char byte#1
        Set byte content#
        SetCall bool numeric(byte)
        If bool==(FALSE)
            Return (FALSE)
        EndIf
        Sub byte (_0)
        Set number byte

        sd adding;set adding number;mult adding multx
        sd value;set value outvalue#
        add outvalue# adding

        const bil_1=1000*1000*1000
        const bil_2=2*bil_1
        const max_int=0x80*0x100*0x100*0x100
        const max_int_bil_2_rest=max_int-bil_2
        if multx==(bil_1)
            if size!=0
                #(...)x xxx xxx xxx
                while size!=0
                    Dec content;Dec size
                    if content#!=(_0)
                        return (FALSE)
                    endif
                endwhile
            endif
            if number>2
                #3 xxx xxx xxx-9 xxx xxx xxx
                return (FALSE)
            elseif number==2
                if value>(max_int_bil_2_rest)
                    #2 147 483 649-2 999 999 999
                    return (FALSE)
                elseif value==(max_int_bil_2_rest)
                    if minusbool==(FALSE)
                        #2 147 483 648 is the first positive overflow
                        return (FALSE)
                    endif
                endelseif
            endelseif
        endif
        mult multx 10
    EndWhile
    Return (TRUE)
EndFunction

import "slen" slen

#bool
function strtoint(sd str,sd ptrout)
    sd sz
    setcall sz slen(str)
    sd bool
    setcall bool memtoint(str,sz,ptrout)
    return bool
endfunction

import "texter" texter

#bool
function strtoint_positive(ss str,sd ptr_out)
    sd bool
    setcall bool strtoint(str,ptr_out)
    str posint="Positive integer number expected"
    if bool==0
        call texter(posint)
        return 0
    endif
    if ptr_out#<0
        call texter(posint)
        return 0
    endif
    return 1
endfunction

#bool
function strtoint_positive_not_zero(ss str,sd ptr_out)
    sd bool
    setcall bool strtoint_positive(str,ptr_out)
    if bool==0
        return 0
    elseif ptr_out#==0
        str notzero="Unexpected 0(zero) number"
        call texter(notzero)
        return 0
    endelseif
    return 1
endfunction

#bool
function strtoint_positive_twoorgreater(ss str,sd ptr_out)
    sd bool
    setcall bool strtoint_positive(str,ptr_out)
    if bool==0
        return 0
    elseif ptr_out#<2
        str errnr="A number equal or greater than 2 expected"
        call texter(errnr)
        return 0
    endelseif
    return 1
endfunction

#bool
function strtoint_positive_N_or_Greater(ss str,sd ptr_out,sd n)
    sd bool
    setcall bool strtoint_positive(str,ptr_out)
    if bool==0
        return 0
    elseif ptr_out#<n
        import "strdworddisp" strdworddisp
        str errnr="Expecting a number equal or greater than "
        call strdworddisp(errnr,n)
        return 0
    endelseif
    return 1
endfunction

function word_reverse(sd word,ss dest)
    #256=0x01 00
    ss src^word

    #01
    inc dest
    set dest# word
    dec dest

    #00
    inc src
    set dest# src#
endfunction

function dword_reverse(sd value)
    sd al
    sd ah
    sd third
    sd last

    set al value
    and al 0xff

    set ah value
    and ah 0xff00

    set third value
    and third 0xff0000

    set last value
    and last 0xff000000

    mult al 0x1000000
    mult ah 0x100
    div third 0x100
    div last 0x1000000
    #for negative division, the number can be negative
    and last 0xff

    or al ah
    or al third
    or al last
    return al
endfunction

function rule3(sd knownA,sd knownB,sd unknownB)
    #kA       x
    #kB       uB
    sd x
    set x unknownB
    mult x knownA
    div x knownB
    return x
endfunction

function rule3_offset(sd knownA,sd knownB,sd x_off,sd unknownB)
#kA    kB
#x ukB-off
#x+off
    sd x
    sub unknownB x_off
    setcall x rule3(knownA,knownB,unknownB)
    add x x_off
    return x
endfunction

function rule3_two_offsets(sd k_off,sd knownA,sd knownB,sd x_off,sd unknownB)
#kA-k_off  kB-k_off
#x      ukB-off
#x+off
    sub knownA k_off
    sub knownB k_off
    sd x
    setcall x rule3_offset(knownA,knownB,x_off,unknownB)
    return x
endfunction

#width,height in p_height
function rectangle_fit_container_rectangle(sd width,sd height,sd c_width,sd c_height,sd p_height)
    #get the fit width and height
    sd value
    #get the width if the height is like container
    setcall value rule3(width,height,c_height)

    if value<c_width
        #width is lower and is ok, height is like container
        set c_width value
    else
        #width is higher and like container is returned,get the width
        setcall c_height rule3(height,width,c_width)
    endelse

    set p_height# c_height
    return c_width
endfunction

#a-(a/b*b)
function rest(sd a,sd b)
    sd trunc
    set trunc a
    div trunc b
    mult trunc b
    sub a trunc
    return a
endfunction

function multiple_of_nr(sd value,sd nr)
    sd result
    set result value
    div value nr
    mult value nr
    if value==result
        return result
    endif
    div result nr
    inc result
    mult result nr
    return result
endfunction


function centered(sd line,sd part)
    sub line part
    div line 2
    return line
endfunction


function get_lower(sd A,sd B)
    if A<B
        return A
    else
        return B
    endelse
endfunction
function get_higher(sd A,sd B)
    if A>B
        return A
    else
        return B
    endelse
endfunction

##char,short,int

function char_to_int(sd char)
    sd test
    set test char
    and test 0x80
    sd result=0
    if test!=0
        set result 0xffFFff00
    endif
    or result char
    return result
endfunction
function short_to_int(sd short)
    sd test
    set test short
    and test 0x8000
    sd result=0
    if test!=0
        set result 0xffFF0000
    endif
    or result short
    return result
endfunction
import "cpymem" cpymem
function short_get_to_int(sd short)
    sd value=0
    sd p_value^value
    call cpymem(p_value,short,2)
    setcall value short_to_int(value)
    return value
endfunction
function int_into_short(sd int,sd p_short)
    sd p_int^int
    call cpymem(p_short,p_int,2)
endfunction

##structs/arrays

function array_bi_index(sd set1,sd set1_size,sd set2)
    mult set1 set1_size
    add set1 set2
    return set1
endfunction

#1, return 1
function array_get_byte(ss array,sd pos)
    add array pos
    return array#
endfunction


function array_byte_setAtXY(ss array,sd value,sd x,sd y,sd rowstride)
    mult rowstride y
    add rowstride x
    add array rowstride
    set array# value
endfunction

function array_set_byte_off(ss array,sd value,sd offset)
    add array offset
    set array# value
endfunction

function array_set_byte_offsets(ss array,sd value,sd off1,sd off2)
    add array off1
    add array off2
    set array# value
endfunction

#1, return 4

function structure_get_int(sd struct,sd pos)
    add struct pos
    return struct#
endfunction

#2
function array_get_word(ss array,sd pos)
    mult pos 2
    add array pos
    sd result
    set result array#
    inc array
    sd highword
    set highword array#
    mult highword 0x100
    or result highword
    return result
endfunction

function array_get_int16(ss array,sd pos)
    mult pos 2
    add array pos
    sd result
    set result array#
    inc array
    sd highword
    set highword array#
    mult highword 0x100
    or result highword
#
    setcall result short_to_int(result)
#
    return result
endfunction
function array_get_int16_bi(ss array,sd set1,sd set1_size,sd set2)
    sd pos
    setcall pos array_bi_index(set1,set1_size,set2)
    sd value
    setcall value array_get_int16(array,pos)
    return value
endfunction

function array_set_word_off(sd array,sd value,sd offset)
#off * 2
    mult offset 2
    add array offset

    sd P^value

    call cpymem(array,P,2)
endfunction

function array_set_word_bi(sd array,sd set1,sd set1_size,sd set2,sd value)
    mult set1 set1_size
    mult set1 2
    add array set1
    call array_set_word_off(array,value,set2)
endfunction
function array_set_word_offsets(sd array,sd value,sd off1,sd off2)
    mult off1 2
    add array off1
    call array_set_word_off(array,value,off2)
endfunction

#4
function array_get_int(sd array,sd pos)
    mult pos 4
    add array pos
    return array#
endfunction
function array_set_int(sd array,sd pos,sd value)
    mult pos 4
    add array pos
    set array# value
endfunction

function array_set_4value_offsets(sd struct,sd value,sd off1,sd off2)
#offsets are mult with 4
    mult off1 4
    mult off2 4
    add struct off1
    add struct off2
    set struct# value
endfunction

#mathings

#pos/-1
function int_in_set(sd int,sd set,sd set_count)
    if set_count==0
        return -1
    endif
    sd start
    set start set
    while set#!=int
        add set (DWORD)
        dec set_count
        if set_count==0
            return -1
        endif
    endwhile
    sub set start
    div set (DWORD)
    return set
endfunction


#others

#x                   known_denom
#unknown_nom         known_nom
function numbers_proportion(sd unknown_nom,sd known_denom,sd known_nom)
    mult known_denom unknown_nom
    div known_denom known_nom
    return known_denom
endfunction




