Format ElfObj64

importx "fwrite" fwrite
importx "realloc" realloc
importx "memcpy" memcpy
importx "free" free
importx "strcspn" strcspn
importx "strlen" strlen
importx "memcmp" memcmp

import "platform_iob" platform_iob

function erbool()
    aftercall ebool
    return #ebool
endfunction
include "../include/prog.h"

function printEr(ss msg)
    sd len;setcall len strlen(msg)
    call printEr_func(msg,(BYTE),len)
endfunction
#p
function printEr_func(ss msg,sd *item_size,sd *count,sd stderr)
#                                                    this argument is not passed, is structure last part
    setcall stderr platform_iob()
    callex fwrite #msg 4
    #bytes written,error:sz!=return
endfunction

function word_swap_arg(ss word)
    sd a
    ss aux^a
    set aux# word#
    ss dest
    set dest word
    inc word
    set dest# word#
    set word# aux#
endfunction
function dword_to_word_arg(sd int,ss arg)
    set arg# int
    inc arg
    div int 0x100
    set arg# int
endfunction
function word_arg_to_dword(ss arg)
    inc arg
    sd value
    set value arg#
    mult value 0x100
    dec arg
    or value arg#
    return value
endfunction
#swapped data
function dword_swap(sd value)
    sd al
    sd ah
    sd third
    sd last

    set al value
    and al 0xff

    set ah value
    and ah 0xff00

    set third value
    and third (0xff00*0x100)

    set last value
    and last (0xff00*0x100*0x100)

    sd res=0x100*0x100*0x100
    mult res al
    #
    mult ah 0x100
    or res ah
    #
    div third 0x100
    or res third
    #
    div last (0x100*0x100*0x100)
    #for negative division, the number can be negative
    and last 0xff
    or res last
    #
    return res
endfunction
function struct_off(sd struct,sd off)
    add struct off
    return struct#
endfunction

#util

function error(ss msg)
    call string_nl_print(msg)
    import "action_error" action_error
    call action_error()

    import "freereset" freereset
    call freereset()
    #this can be after code_values(in last_free); but normal is this at action and last_free at swf_done(without this)
    import "action_debug_free" action_debug_free
    call action_debug_free()
    #
    import "file_get_content__resources_free" file_get_content__resources_free
    call file_get_content__resources_free()

    call file_resources_free()

    ss p;setcall p erbool();set p# 1
endfunction
#function temporary_number();#p
#    data n#1
#    return #n
#endfunction
#function temporary_bool();#p
#    data b=FALSE
#    return #b
#endfunction
function string_nl_print(ss msg)
    call printEr(msg)
    chars nl={0xa,0}
    call printEr(#nl)
endfunction
#
function memrealloc(sd mem,sd size)
#unele fisiere pot da eroare de la realocare; fara functia asta aftercall poate fi degeaba
    sd ptr;sd n=NULL
    setcall ptr realloc(mem,size)
    sd comp;setcall comp memcmp(#ptr,#n,:)
    if comp==0
        call error("realloc failed")
    endif
    return ptr
endfunction
function memalloc(sd size)
    sd mem
    setcall mem memrealloc(0,size)
    return mem
endfunction

#inits

#id
function def_mem()
    sd id
    setcall id struct_ids((ids_set))
    return id
endfunction
#mem
function def_data()
    sd all
    sd sz
    sd mem
    call mem_init(#mem,#all,#sz)
    set mem# all
    call block_reset_size(mem)
    return mem
endfunction

#block

function block_reset_size(sd block)
    add block (mem_struct__size_off)
    set block# (mem_struct_size)
endfunction
#size
function block_get_size(sd block)
    sd size
    setcall size struct_off(block,(mem_struct__size_off))
    sub size (mem_struct_size)
    return size
endfunction
#size
function block_get_fullsize(sd block)
    sd size
    setcall size struct_off(block,(mem_struct__size_off))
    return size
endfunction
#mem
function block_get_mem(sd block)
    add block (mem_struct_size)
    return block
endfunction
function block_get_mem_size(sd block,sd p_mem,sd p_size)
    setcall p_mem# block_get_mem(block)
    setcall p_size# block_get_size(block)
endfunction

#mem procedures

function mem_init(sd p_mem,sd p_allsize,sd p_size)
    set p_allsize# (block_size)
    set p_size# 0
    setcall p_mem# memalloc(p_allsize#)
endfunction

function mem_block_add(sd p_block,ss newblock,sd newblock_size)
    sd block
    sd allsize
    sd size

    set block p_block#
    sd sz_test
    setcall size block_get_fullsize(block)
    set allsize block#
    set sz_test size
    add sz_test newblock_size
    if sz_test>=allsize
        div sz_test (block_size)
        mult sz_test (block_size)
        add sz_test (block_size)
        set allsize sz_test
        setcall block memrealloc(block,allsize)
        set p_block# block
        set block# allsize
    endif
    sd pointer
    set pointer block
    add pointer size
    call memcpy(pointer,newblock,newblock_size)
    add size newblock_size
    add block (mem_struct__size_off)
    set block# size
endfunction

function mem_free(sd p_mem)
    call free(p_mem#)
    set p_mem# (NULL)
endfunction

#structure ids

const max_structures=100
function struct_ids(sd proc,sd id)
    data structures#max_structures
    data strct^structures
    data counter=0
    sd ac_ptr
    sd pointer
    if proc==(ids_all_free)
        #starting with ids_all_free:
        #                #counter increment#, then null at ac,pools
        #   mem_free at struct_ids_action_expand
        #   can have errors at any point and here all are verified
        set pointer (DWORD);mult pointer counter;add pointer strct
        while strct!=pointer
            sub pointer (DWORD);if pointer#!=(NULL);call free(pointer#);endif
            dec counter
            setcall ac_ptr struct_ids_action((ids_get),counter);if ac_ptr!=(NULL);call free(ac_ptr);endif
            setcall ac_ptr struct_ids_actionpool((ids_get),counter);if ac_ptr!=(NULL);call free(ac_ptr);endif
        endwhile
        return (void)
    elseif proc==(ids_counter)
        return counter
    endelseif

    sd ident
    if proc==(ids_set)
        set ident counter
    else
        set ident id
    endelse
    setcall pointer move_to_n_dword(strct,ident)
    if proc==(ids_set)
    #id
        if counter==(max_structures)
            call error("too many objects")
        endif
        sd iter
        sd newblock
        setcall newblock def_data()
        set iter pointer
        while iter!=strct
        #can be in a free place
            sub iter (DWORD)
            if iter#==0
                set iter# newblock
                sub iter strct
                div iter (DWORD)
                return iter
            endif
        endwhile
        set pointer# newblock
        #counter increment#
        #sd c; for counter verification inside
        sd c;set c counter;inc counter
        setcall ac_ptr struct_ids_action((ids_get_pointer),c);set ac_ptr# (NULL)
        setcall ac_ptr struct_ids_actionpool((ids_get_pointer),c);set ac_ptr# (NULL)
        #counter increment#
        return ident
    elseif proc==(ids_get_pointer)
        if ident>=counter;call error("Unexistent input id.");endif
        return pointer
    elseif proc==(ids_get)
        return pointer#
    else
    #if proc==(ids_free)
        call mem_free(pointer)
    endelse
endfunction
function struct_ids_action(sd proc,sd id)
    data action_structures#max_structures
    sd v;setcall v struct_ids_expand(proc,id,#action_structures)
    return v
endfunction
function struct_ids_actionpool(sd proc,sd id)
    data actionpool_structures#max_structures
    sd v;setcall v struct_ids_expand(proc,id,#actionpool_structures)
    return v
endfunction
function struct_ids_expand(sd proc,sd id,sd p_action_structures)
    sd pointer;setcall pointer move_to_n_dword(p_action_structures,id)
    if proc==(ids_set)
        setcall pointer# def_data()
    elseif proc==(ids_get_pointer)
        #call to verify if the user input has a wrong id
        sd c;setcall c struct_ids((ids_counter))
        if id>=c;call error("Unregistered input id.");endif
        #
        return pointer
    elseif proc==(ids_get)
        return pointer#
    else
    #if proc==(ids_free)
        call mem_free(pointer)
    endelse
endfunction
#pointer
function move_to_n_dword(sd pointer,sd id)
    mult id (DWORD)
    add pointer id
    return pointer
endfunction


#strings/chars

#chars

#bool
function is_numeric(sd char)
    chars min="0"
    chars max="9"
    if char<min
        return (FALSE)
    elseif char<=max
        return (TRUE)
    endelseif
    return (FALSE)
endfunction
#bool
function part_of_variable(sd value)
    sd bool
    setcall bool is_numeric(value)
    if bool==(TRUE)
        return (TRUE)
    endif
    setcall bool is_letter(value)
    return bool
endfunction
#bool
function is_letter(sd value)
    if value<(A)
        return (FALSE)
    elseif value<=(Z)
        return (TRUE)
    elseif value==(_)
        return (TRUE)
    elseif value<(a)
        return (FALSE)
    elseif value<=(z)
        return (TRUE)
    endelseif
    return (FALSE)
endfunction

#strings

#str
function str_next(ss s,ss delims,sd p_op)
    sd pos
    setcall pos strcspn(s,delims)
    ss x
    set x s
    add x pos
    set p_op# x#
    if x#==0
        return x
    endif
    set x# 0
    inc x
    return x
endfunction
#bool
function str_at_str_start(ss s1,ss s2)
    sd l1
    sd l2
    setcall l1 strlen(s1)
    setcall l2 strlen(s2)
    if l1<l2
        return (FALSE)
    endif
    sd comp
    setcall comp memcmp(s1,s2,l2)
    if comp==0
        return (TRUE)
    endif
    return (FALSE)
endfunction

#alloc
function dupreserve_string(ss str)
    sd len
    setcall len strlen(str)
    inc len
    sd mem
    setcall mem memalloc(len)
    return mem
endfunction

#pointer after "abc"
function str_escape(ss src,ss dest,sd delim)
    sd loop=1
    sd escapes=0
    inc src
    while loop==1
    if src#==delim
        set loop 0
    #elseif src#==delim2
    #    set loop 0
    else
        chars escape="\\"
        while src#==escape
            if escapes==0
                set escapes 1
            else
                set dest# src#
                inc dest
                set escapes 0
            endelse
            inc src
        endwhile
        if src#==0
            call error("end string expected")
        endif
        if escapes==1
            set dest# src#
            inc src
            inc dest
            set escapes 0
        elseif src#!=delim
            #if src#!=delim2
                set dest# src#
                inc src
                inc dest
            #endif
        endelseif
    endelse
    endwhile
    set dest# 0
    inc src
    return src
endfunction

#next/same
function str_expression_at_start(ss string,ss expression)
    sd bool
    setcall bool str_at_str_start(string,expression)
    if bool==(FALSE)
        return string
    endif
    ss next
    set next string
    addcall next strlen(expression)
    setcall bool part_of_variable(next#)
    if bool==(TRUE)
        return string
    endif
    setcall next spaces(next)
    return next
endfunction
#next/same
function str_expression_at_start_withEndCare(ss ac,ss expression)
    ss pointer
    setcall pointer str_expression_at_start(ac,expression)
    if pointer==ac
        return ac
    endif
    chars term=";"
    if pointer#==term
        inc pointer
    endif
    return pointer
endfunction

#str
function spaces(ss str)
    while 1==1
        if str#!=(Space)
            if str#!=(HorizontalTab)
                return str
            endif
        endif
        inc str
    endwhile
endfunction

#closings

import "file_close" file_close
function file_resources(sd trueIsSet_falseIsFree,sd fileIn)
    data file=fd_none
    if trueIsSet_falseIsFree==(TRUE)
        set file fileIn
    else
        if file!=(fd_none)
            call file_close(#file)
        endif
    endelse
endfunction
function file_resources_set(sd file)
    call file_resources((TRUE),file)
endfunction
function file_resources_free()
    call file_resources((FALSE))
endfunction
