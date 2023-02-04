Format ElfObj64

#win32 with _
importx "strlen" strlen
importx "memcmp" memcmp

importaftercall ebool
include "../include/prog.h"

function actionpoolid_root()
    data id#1
    return #id
endfunction
function actionpoolid()
    data id#1
    return #id
endfunction
function actionpoolid_get()
    sd p_id
    setcall p_id actionpoolid()
    return p_id#
endfunction

import "struct_ids_actionpool" struct_ids_actionpool
#block
function actionpool_currentblock()
    sd poolid;sd block
    setcall poolid actionpoolid_get()
    setcall block struct_ids_actionpool((ids_get),poolid)
    return block
endfunction
import "swf_mem" swf_mem
#pool id
function actionpool_value(ss value)
    sd poolid
    setcall poolid actionpoolid_get()
    or poolid (negative_means_action_sprite_pool)
    sd nr
    call swf_mem((mem_exp_change),poolid)
    setcall nr actionpool_getvalue(value)
    call swf_mem((mem_exp_change_back))
    return nr
endfunction
import "block_get_mem" block_get_mem
import "block_get_size" block_get_size
import "swf_mem_add" swf_mem_add
import "dword_to_word_arg" dword_to_word_arg
#pool id
function actionpool_getvalue(ss value)
    sd block
    setcall block actionpool_currentblock()
    sd size
    setcall size block_get_size(block)
    sd nr
    sd newlen
    setcall newlen strlen(value)
    if size==0
    #add the pools header and count=1, later add value for count=1
        sd onevalue=1
        call swf_mem_add(#onevalue,2)
        set nr 0
    else
        import "word_arg_to_dword" word_arg_to_dword
        sd mem
        sd count
        setcall mem block_get_mem(block)
        setcall count word_arg_to_dword(mem)
        add mem (WORD)
        set nr count
        while count!=0
            sd len
            setcall len strlen(mem)
            if len==newlen
                sd comp
                setcall comp memcmp(mem,value,len)
                if comp==0
                    sub nr count
                    return nr
                endif
            endif
            inc len
            add mem len
            dec count
        endwhile
        setcall mem block_get_mem(block)
        set count nr
        inc count
        call dword_to_word_arg(count,mem)
    endelse
    inc newlen
    call swf_mem_add(value,newlen)
    return nr
endfunction
