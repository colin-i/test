Format ElfObj64

importx "strlen" strlen
importx "memcpy" memcpy

importaftercall ebool
include "../include/prog.h"

import "mem_free" mem_free
import "error" error
import "struct_ids" struct_ids
import "struct_ids_actionpool" struct_ids_actionpool
import "mem_block_add" mem_block_add
import "def_mem" def_mem

function swf_mem(sd proc,sd arg,sd len)
    data path_mem=NULL
    data path_size#1
    data filelength_offset#1
    data file_out=fd_error

    data id#1
    data main_id#1
    data call_struct#1;data c_main^struct_ids;data c_pool^struct_ids_actionpool

    if proc==(mem_exp_init)
    #arg is file
    #len is filelength offset
        if path_mem!=(NULL)
            call error("The previous swf was not ended.")
        endif
        #0
        import "memalloc" memalloc
        setcall path_size strlen(arg);inc path_size
        setcall path_mem memalloc(path_size)
        call memcpy(path_mem,arg,path_size)
        #1
        setcall main_id def_mem()
        set id main_id
        call swf_actionblock((mem_exp_init),main_id)
        set call_struct c_main
        #2
        call exports_init()
        #3
        import "action_code_values_init" action_code_values_init
        call action_code_values_init()
        #
        set filelength_offset len
        #
        return (void)
    elseif proc==(mem_exp_free)
        if path_mem!=(NULL)
            #0
            call mem_free(#path_mem)
            #1 freeing all ids(main(exports,root+sprites),acs,pools)
            call struct_ids((ids_all_free))
            #2 exports
            sd exports
            setcall exports exportsId()
            set exports# (not_an_id)
            #3 set of values
            import "action_code_values_free" action_code_values_free
            call action_code_values_free()
            #file
            if file_out!=(fd_error)
                import "file_close" file_close
                call file_close(#file_out)
            endif
        endif
        return (void)
    elseif proc==(mem_exp_change_back)
        set id main_id
        set call_struct c_main
        return (void)
    endelseif
    if path_mem==(NULL)
    #swf_(placeobject...)->mem_exp_add;swf_sprite_(placeobject...)->mem_exp_change;swf_done->mem_exp_done
        call error("there isn't a swf started")
    endif
    if proc==(mem_exp_add)
        #blockMain blockPool
        sd p_block
        setcall p_block call_struct((ids_get_pointer),id)
        call mem_block_add(p_block,arg,len)
    elseif proc==(mem_exp_change)
        if arg<0;set call_struct c_pool
            xor arg (negative_means_action_sprite_pool)
        else;set call_struct c_main;endelse
        set id arg
    else
    #if proc==(mem_exp_done)
        call swf_tag_end()

        sd block
        setcall block call_struct((ids_get),main_id)
        import "block_get_mem_size" block_get_mem_size
        sd mem;sd size;call block_get_mem_size(block,#mem,#size)

        sd pointer
        set pointer mem
        add pointer filelength_offset
        set pointer# size

        import "file_open" file_open
        setcall file_out file_open(path_mem,(_open_write))
        import "file_write" file_write
        call file_write(file_out,mem,size)
    endelse
endfunction
function swf_mem_add(ss dest,sd size)
    call swf_mem((mem_exp_add),dest,size)
endfunction
function swf_tag_end()
    call swf_tag_recordheader_entry((End),0)
endfunction
const recordheader_long_mark=0x3f
function swf_tag_recordheader_entry(sd tag,sd size)
    if size<(recordheader_long_mark)
        sd tag_plus_size
        call swf_tag_recordheader(#tag_plus_size,tag,size)
    else
        call swf_tag_recordheader_long_entry(tag,size)
    endelse
endfunction
function swf_tag_recordheader_long_entry(sd tag,sd size)
    sd tag_plus_size
    call swf_tag_recordheader(#tag_plus_size,tag,(recordheader_long_mark))
    call swf_mem_add(#size,(DWORD))
endfunction
const short_header=2
import "bits_packs" bits_packs
import "word_swap_arg" word_swap_arg
function swf_tag_recordheader(ss dest,sd tag,sd size)
    call bits_packs(dest,2,tag,10,size,6)
    call word_swap_arg(dest)
    call swf_mem((mem_exp_add),dest,(short_header))
endfunction
function swf_tag(ss dest,sd tag,sd size)
    call swf_tag_recordheader(dest,tag,size)
    add dest (short_header)
    call swf_mem((mem_exp_add),dest,size)
endfunction

#
import "block_get_size" block_get_size
import "block_reset_size" block_reset_size
import "struct_ids_action" struct_ids_action
import "actionpoolid" actionpoolid;import "actionpoolid_root" actionpoolid_root
import "actionpool_currentblock" actionpool_currentblock
function swf_actionblock(sd proc,sd arg,sd newmem_len)
    data id#1
    data id_back#1
    sd poolid
    if proc==(mem_exp_init)
        set id arg
        set id_back id
        call struct_ids_action((ids_set),id)
        call struct_ids_actionpool((ids_set),id)
        sd p_poolid;setcall p_poolid actionpoolid();set p_poolid# id
        sd p_poolrootid;setcall p_poolrootid actionpoolid_root();set p_poolrootid# id
        return (void)
    elseif proc==(mem_exp_change)
        #must verify to be a valid user input id
        call struct_ids_actionpool((ids_get_pointer),id)
        #
        set id arg
        #
        setcall poolid actionpoolid()
        set poolid# id
        return (void)
    elseif proc==(mem_exp_change_back)
        set id id_back
        #
        sd root_poolid
        setcall root_poolid actionpoolid_root()
        setcall poolid actionpoolid()
        set poolid# root_poolid#
        return (void)
    endelseif
    sd p_block
    setcall p_block struct_ids_action((ids_get_pointer),id)
    if proc==(mem_exp_add)
        call mem_block_add(p_block,arg,newmem_len)
    elseif proc==(mem_exp_part_done)
        sd block
        set block p_block#
        sd size
        setcall size block_get_size(block)
        if size!=0
            import "action_size" action_size
            import "write_action" write_action
            sd tagsz
            setcall tagsz action_size(id)
            call swf_tag_recordheader_entry((DoAction),tagsz)
            call write_action(id)
            sd poolblock
            setcall poolblock actionpool_currentblock()
            call block_reset_size(poolblock)
            call block_reset_size(block)
        endif
    else
    #if proc==(mem_exp_get_block)
        return p_block#
    endelse
endfunction

function swf_actionblock_add(sd value,sd size)
    call swf_actionblock((mem_exp_add),value,size)
endfunction
import "dword_to_word_arg" dword_to_word_arg
function actionrecordheader(sd tag,sd size)
    chars t#1
    chars length#2
    set t tag
    call dword_to_word_arg(size,#length)
    call swf_actionblock_add(#t,3)
endfunction
function swf_actionrecordheader(sd tag,sd size)
    chars t#1
    chars length#2
    set t tag
    call dword_to_word_arg(size,#length)
    call swf_mem_add(#t,3)
endfunction

#preid
function new_sprite_id()
    sd id
    setcall id def_mem()
    call struct_ids_action((ids_set),id)
    call struct_ids_actionpool((ids_set),id)
    return id
endfunction
function free_sprite_id(sd id)
    call struct_ids((ids_free),id)
    call struct_ids_action((ids_free),id)
    call struct_ids_actionpool((ids_free),id)
endfunction

#
function identifiers()
    data id#1
    return #id
endfunction
function identifiers_set(sd value)
    sd id
    setcall id identifiers()
    set id# value
endfunction
#id
function identifiers_get()
    sd id
    setcall id identifiers()
    sd value
    set value id#
    inc id#
    call identifiers_set(id#)
    return value
endfunction

#
function exports_init()
    sd exports
    setcall exports exportsId()
    sd id
    setcall id def_mem()
    set exports# id
endfunction
#p
function exportsId()
    data exports=not_an_id
    return #exports
endfunction
#id
function exportsId_get()
    sd e
    setcall e exportsId()
    if e#==(not_an_id);call error("Do not call the exports at this moment.");endif
    return e#
endfunction

