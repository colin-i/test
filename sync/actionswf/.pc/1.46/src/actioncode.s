Format ElfObj64

#win32 with _
importx "strcmp" strcmp
importx "sprintf" sprintf
importx "strlen" strlen

importaftercall ebool
include "../include/prog.h"

const totalvalues=65535
function action_code_values_container()
    value setofvalues=NULL
    return #setofvalues
endfunction
function action_code_values()
    sv m
    setcall m action_code_values_container()
    return m#
endfunction
function action_code_values_init()
    import "memalloc" memalloc
    sv m
    setcall m action_code_values_container()
    setcall m# memalloc((totalvalues*DWORD))
endfunction
import "mem_free" mem_free
function action_code_values_free()
    sv p
    setcall p action_code_values_container()
    if p#!=(NULL);call mem_free(p);endif
endfunction
function action_code_values_index()
    data nr#1
    return #nr
endfunction
#pointer
function action_code_get()
    sd nr
    setcall nr action_code_values_index()
    sd x
    set x nr#
    sv pointer
    setcall pointer action_code_values()
    mult x (DWORD)
    add pointer x
    return pointer
endfunction
function action_code_set(sd value)
	call action_code_set_ex(value,1)
endfunction
function action_code_set_pointer(sd value)
	call action_code_set_ex(value,(:/DWORD))
endfunction
function action_code_set_ex(sd value,sd size)
	sd nr
	setcall nr action_code_values_index()
	sd x
	set x nr#
	sd to=DWORD
	mult to x
	add x size
	if x>=(totalvalues)
		import "error" error
		call error("size error")
	endif
	sd pointer
	setcall pointer action_code_values()
	add pointer to
	if size==1
		set pointer# value
	else
		set pointer#v^ value
	endelse
	set nr# x
endfunction
function forward_values_expand(sd forward,sd data)
    sd currentnr
    sd p_currentnr
    setcall p_currentnr action_code_values_index()
    set currentnr p_currentnr#
    sv values
    setcall values action_code_get()
    #
    call forward(values,data)
    #
    set p_currentnr# currentnr
endfunction



#entries write

function action__code(sd mathpointer)
    while mathpointer#!=(math_end)
        setcall mathpointer action__code_row(mathpointer)
    endwhile
endfunction
import "action_push" action_push
import "action_one" action_one
import "action_member_loop" action_member_loop
import "brace_blocks_add_write" brace_blocks_add_write
import "brace_blocks_remove_write" brace_blocks_remove_write
#position
function action__code_row(sd codepointer)
    sd pointer
    set pointer codepointer
    setcall pointer action_code_write_conditions(codepointer)
    if pointer!=codepointer
        return pointer
    endif
    setcall pointer action_code_write_function(codepointer)
    if pointer!=codepointer
        return pointer
    endif
    sd attrib
    set attrib codepointer#
    if attrib==(ActionReturn)
        add codepointer (DWORD)
        call close_scope_forIn_statements()
        setcall codepointer action_code_right_util(codepointer)
        call action_one((ActionReturn))
        return codepointer
    elseif attrib==(block_end)
        add codepointer (DWORD)
        if codepointer#==(else_flag)
            call action_code_else_add()
            add codepointer (DWORD)
        else
            call brace_blocks_remove_write()
        endelse
        return codepointer
    elseif attrib==(block_else_end)
        setcall codepointer action_code_conditions_end(codepointer)
        return codepointer
    elseif attrib==(whileblock_end)
        import "brace_blocks_remove_write_jump" brace_blocks_remove_write_jump
        call brace_blocks_remove_write_jump()
        add codepointer (DWORD)
        return codepointer
    elseif attrib==(break_flag)
        call action_code_break()
        add codepointer (DWORD);return codepointer
    elseif attrib==(continue_flag)
        call action_code_continue()
        add codepointer (DWORD);return codepointer
    endelseif
    setcall codepointer action_code_pack(codepointer)
    return codepointer
endfunction
function action_code_pack(sd codepointer)
    sd attrib
    set attrib codepointer#
    add codepointer (DWORD)
    #
    sd is_member=FALSE
    sd need_right=TRUE
    sd need_pop=FALSE
    if attrib==(ActionSetMember)
        set is_member (TRUE)
    elseif attrib==(ActionDelete)
        set is_member (TRUE)
        set need_right (FALSE)
        set need_pop (TRUE)
    elseif attrib==(ActionDefineLocal2)
        set need_right (FALSE)
    elseif attrib==(ActionDelete2)
        set need_right (FALSE)
        set need_pop (TRUE)
    endelseif
    #
    if is_member==(TRUE)
        setcall codepointer action_member_loop(codepointer,:)   #to pass the pointer
    else
    #definelocal or setvariable or delete2
        call action_push((ap_Constant8),codepointer#v^,-1)
        add codepointer :  #to pass the pointer
    endelse
    if need_right==(TRUE)
        if codepointer#==(ActionIncrement)
            add codepointer (DWORD)
            call action_code_inc_dec((ActionIncrement),attrib)
        elseif codepointer#==(ActionDecrement)
            add codepointer (DWORD)
            call action_code_inc_dec((ActionDecrement),attrib)
        elseif codepointer#==(mixt_equal)
            #+= .. ^= ..
            add codepointer (DWORD)
            sd mixt_op;set mixt_op codepointer#;add codepointer (DWORD)
            if attrib==(ActionSetVariable);call action_code_dupGet_var()
            else;call action_code_dupGet_member();endelse
            setcall codepointer action_code_right(codepointer)
            call action_one(mixt_op)
        else
            setcall codepointer action_code_right(codepointer)
        endelse
    endif
    call action_one(attrib)
    if need_pop==(TRUE)
        call action_one((ActionPop))
    endif
    return codepointer
endfunction
import "actionrecordheader" actionrecordheader
import "swf_actionblock_add" swf_actionblock_add
function action_code_inc_dec(sd inc_dec,sd setvar_or_setmember)
    if setvar_or_setmember==(ActionSetVariable)
        call action_code_dupGet_var()
        call action_one(inc_dec)
    else
        call action_code_dupGet_member()
        call action_one(inc_dec)
    endelse
endfunction
function action_code_dupGet_var()
    call action_one((ActionPushDuplicate))
    call action_one((ActionGetVariable))
endfunction
function action_code_dupGet_member()
    sd second_reg=1
    call actionrecordheader((ActionStoreRegister),1)
        call swf_actionblock_add(#second_reg,1)
    call action_one((ActionPop))
    sd first_reg=0
    call actionrecordheader((ActionStoreRegister),1)
        call swf_actionblock_add(#first_reg,1)
    call action_push((ap_RegisterNumber),second_reg,-1)
    call action_push((ap_RegisterNumber),first_reg,-1)
    call action_push((ap_RegisterNumber),second_reg,-1)
    call action_one((ActionGetMember))
endfunction
import "brace_blocks_add_write_current" brace_blocks_add_write_current

import "add_dummy_jump" add_dummy_jump
import "resolve_dummy_jump" resolve_dummy_jump
import "brace_blocks_get_memblock" brace_blocks_get_memblock
import "block_get_size" block_get_size

#next/same
function action_code_write_conditions(sd codepointer)
    #verify for condition tag
    sd cond;set cond codepointer#
    if cond==(for_marker)
        add codepointer (DWORD)
        if codepointer#!=(for_three)
            call action_push((ap_Constant8),codepointer#v^,-1);add codepointer :   #to pass the pointer
            call action_one((ActionEnumerate))
            #
            call add_while_top_off((for_marker))
            #
            sd first_reg=0
            call actionrecordheader((ActionStoreRegister),1)
            call swf_actionblock_add(#first_reg,1)
            #
            call action_push((ap_Null),-1)
            call action_one((ActionEquals2))
            #write the jump offset
            call write_ifjump_addTo_braceBlocks()
            #
            sd attr2;set attr2 codepointer#;add codepointer (DWORD)
            #
            if attr2==(ActionSetMember)
                setcall codepointer action_member_loop(codepointer,:)  #to pass the pointer
            else
                #var or set variable
                call action_push((ap_Constant8),codepointer#,-1)
                add codepointer :   #to pass the pointer
            endelse
            #
            call action_push((ap_RegisterNumber),first_reg,-1)
            call action_one(attr2)
            return codepointer
        endif
        add codepointer (DWORD)
        if codepointer#!=(inter_for);setcall codepointer action_code_pack(codepointer);endif
        add codepointer (DWORD)
        #
        call add_dummy_jump()
        sd memblock;setcall memblock brace_blocks_get_memblock()
        sd sizeOff;setcall sizeOff block_get_size(memblock)
        #
        call add_while_top_off((while_marker))
        #
        if codepointer#!=(inter_for);setcall codepointer action_code_pack(codepointer);endif
        add codepointer (DWORD)
        #
        import "write_forward_offset" write_forward_offset
        sub sizeOff (WORD)
        call write_forward_offset(sizeOff)
    elseif cond==(while_marker)
        call add_while_top_off((while_marker))
        add codepointer (DWORD)
    elseif cond==(ActionIf)
        add codepointer (DWORD)
    else
        return codepointer
    endelse
    #using the operations function
    setcall codepointer action_code_right_util(codepointer)
    call write_ifjump_withNot()
    #return the current pointer
    return codepointer
endfunction
function write_ifjump_withNot()
    #set to be not for entering the block
    call action_one((ActionNot))
    #write the jump offset
    call write_ifjump_addTo_braceBlocks()
endfunction
import "cond_blocks" cond_blocks
import "brace_blocks_counter_inc" brace_blocks_counter_inc
function add_while_top_off(sd typeOfLoop)
    call brace_blocks_add_write_current()
    sd block
    setcall block cond_blocks()
    set block# typeOfLoop
    call brace_blocks_counter_inc();add block (DWORD)
    set block# 0
    call brace_blocks_counter_inc()
endfunction
const forIn_ifBreak_size=3+1+1+3+2
function action_code_break()
    sd c_block;setcall c_block prepare_space_for_break()
    sd p_type;set p_type c_block;sub p_type (2*DWORD)
    if p_type#==(while_marker)
        call write_jump(0)
    else
        call action_push((ap_Null),-1)
        call action_one((ActionEquals2))
        call write_ifjump()
    endelse
    #
    sd memblock
    setcall memblock brace_blocks_get_memblock()
    setcall c_block# block_get_size(memblock);sub c_block# (WORD)
    #
    if p_type#==(for_marker);call write_jump((-2-3-forIn_ifBreak_size));endif
    #
    call brace_blocks_counter_inc()
endfunction
function remove_forIn_stack()
    call action_push((ap_Null),-1)
    call action_one((ActionEquals2))
    call action_one((ActionNot))
    call actionrecordheader((ActionIf),2)
    #minus ActionNot
    sd sz=-1-forIn_ifBreak_size
    call swf_actionblock_add(#sz,2)
endfunction
function close_scope_forIn_statements()
    sd nr_of_forIn_statements;setcall nr_of_forIn_statements get_nr_of_forIn_statements()
    while nr_of_forIn_statements>0
        call remove_forIn_stack()
        dec nr_of_forIn_statements
    endwhile
endfunction
import "brace_blocks_counter" brace_blocks_counter
function get_nr_of_forIn_statements()
    sd block;setcall block cond_blocks()
    sd counter;sd c;setcall c brace_blocks_counter();set counter c#
    sd nr=0
    while counter>0
        dec counter
        sub block (DWORD)
        if block#==(brace_blocks_function)
            return nr
        elseif block#==(for_marker)
            inc nr
        endelseif
    endwhile
    return nr
endfunction
function write_jump(sd size)
    call actionrecordheader((ActionJump),2)
    call swf_actionblock_add(#size,2)
endfunction
#cond_blocks top pointer
function prepare_space_for_break()
    sd c_blocks;setcall c_blocks cond_blocks()
    sd c;setcall c brace_blocks_counter();sd counter;set counter c#
    sd copy_cursor;set copy_cursor c_blocks
    while counter>0
        sub c_blocks (DWORD)
        if c_blocks#==0
            add c_blocks (DWORD)
            sd cursor;set cursor copy_cursor;sub cursor (DWORD)
            while copy_cursor!=c_blocks
                set copy_cursor# cursor#
                sub copy_cursor (DWORD)
                sub cursor (DWORD)
            endwhile
            return c_blocks
        endif
        dec counter
    endwhile
    call error("it is not the right place for Break")
endfunction
function write_ifjump_addTo_braceBlocks()
    call write_ifjump()
    call brace_blocks_add_write()
endfunction
function write_ifjump()
    call actionrecordheader((ActionIf),2)
    data dummyoffset=0
    call swf_actionblock_add(#dummyoffset,2)
endfunction

function action_code_continue()
    sd c_blocks;setcall c_blocks cond_blocks()
    sd c;setcall c brace_blocks_counter();sd counter;set counter c#
    while counter>0
        sub c_blocks (DWORD)
        if c_blocks#==0
            #the loop type and to the offset to jump from here
            sub c_blocks (2*DWORD)
            sd off_to_jump;set off_to_jump c_blocks#
            #
            call add_dummy_jump()
            call resolve_dummy_jump(off_to_jump)
            return (void)
        endif
        dec counter
    endwhile
    call error("Continue without a loop error")
endfunction

function action_code_else_add()
    #write dummy jump
    call actionrecordheader((ActionJump),2)
    sd dummyjump
    call swf_actionblock_add(#dummyjump,2)
    #end previous if
    call brace_blocks_remove_write()
    #add current offset
    call brace_blocks_add_write()
endfunction
function action_code_conditions_end(sd codepointer)
    add codepointer (DWORD)
    sd number_of_unclosed
    set number_of_unclosed codepointer#
    add codepointer (DWORD)
    while number_of_unclosed>0
        call brace_blocks_remove_write()
        dec number_of_unclosed
    endwhile
    return codepointer
endfunction

#codepointer
function action_code_write_function(sd codepointer)
    sd pointer
    setcall pointer action_definefunction(codepointer)
    if pointer!=codepointer
        return pointer
    endif
    if codepointer#!=(call_action_left)
        return codepointer
    endif
    setcall codepointer action_code_write_function_call(codepointer)
    call action_one((ActionPop))
    return codepointer
endfunction

#codepointer
function action_code_write_function_call(sv codepointer)
    add codepointer (DWORD)
    sd pointer
    setcall pointer action_code_write_builtin_function(codepointer)
    if pointer!=codepointer
        return pointer
    endif
    sd member
    set member codepointer#
    setcall codepointer action_code_new_or_call(codepointer)
    if member==0
        call action_one((ActionCallFunction))
    else
        call action_one((ActionCallMethod))
    endelse
    return codepointer
endfunction
#codepointer
function action_code_write_builtin_function(sv codepointer)
    sv pointer
    set pointer codepointer
    if pointer#!=(no_pointer)
        #no builtin at members
        return codepointer
    endif
    add pointer :  #to pass the pointer
    #
    sd cursor
    setcall cursor action_code_write_builtin_set(pointer)
    if cursor==pointer
        return codepointer
    endif
    return cursor
endfunction
#name/0
function action_code_write_builtin_names(sv codepointer,sd p_action)
    ss int="int"
    sd compare
    setcall compare strcmp(codepointer#,int)
    if compare==0
        set p_action# (ActionToInteger)
        return int
    endif
    ss rnd="random"
    setcall compare strcmp(codepointer#,rnd)
    if compare==0
    #0�(maximum-1)
        set p_action# (ActionRandomNumber)
        return rnd
    endif
    ss ascii="ord"
    setcall compare strcmp(codepointer#,ascii)
    if compare==0
        set p_action# (ActionCharToAscii)
        return ascii
    endif
    ss chr="chr"
    setcall compare strcmp(codepointer#,chr)
    if compare==0
        set p_action# (ActionAsciiToChar)
        return chr
    endif
    ss typeOf="TypeOf"
    setcall compare strcmp(codepointer#,typeOf)
    if compare==0
        set p_action# (ActionTypeOf)
        return typeOf
    endif
    return 0
endfunction
#codepointer
function action_code_write_builtin_set(sd codepointer)
    ss name
    sd act
    #
    setcall name action_code_write_builtin_names(codepointer,#act)
    if name==0
        return codepointer
    endif
    #
    chars er#256
    add codepointer :   #to pass the pointer
    if codepointer#==(args_end)
        call sprintf(#er,"%s builtin function expects at least one parameter",name)
        call error(#er)
    endif
    setcall codepointer action_code_right_util(codepointer)
    if codepointer#!=(args_end)
        call sprintf(#er,"%s builtin function expects at most one parameter",name)
        call error(#er)
    endif
    add codepointer (DWORD)
    call action_one(act)
    return codepointer
endfunction
#codepointer
function action_code_new_or_call(sv codepointer)
    sd member
    set member codepointer#
    #
    add codepointer :  #to pass the pointer
    sd fname
    set fname codepointer#
    #
    import "action_caller" action_caller
    add codepointer :  #to pass the pointer
    setcall codepointer action_caller(fname,member,codepointer)
    return codepointer
endfunction
#codepointer
function action_code_right(sd codepointer)
    sd pointer
    setcall pointer action_definefunction(codepointer)
    if pointer!=codepointer
        return pointer
    endif
    setcall codepointer action_code_right_util(codepointer)
    return codepointer
endfunction
#codepointer
function action_code_right_util(sd codepointer)
    if codepointer#==(new_action)
        add codepointer (DWORD)
        sd member
        set member codepointer#v^
        setcall codepointer action_code_new_or_call(codepointer)
        if member==0
            call action_one((ActionNewObject))
        else
            call action_one((ActionNewMethod))
        endelse
        return codepointer
    endif
    sd compare_op_1
    sd compare_op_2
    setcall codepointer action_code_right_number(codepointer)
    while codepointer#!=(math_end)
        sd operation
        set operation codepointer#
        add codepointer (DWORD)
        if operation==(compare_action)
            set compare_op_1 codepointer#
            add codepointer (DWORD)
            set compare_op_2 codepointer#
            add codepointer (DWORD)
        elseif operation==(ifElse_start)
            call write_ifjump_withNot()
            setcall codepointer action_code_right_util(codepointer)
            call action_code_else_add()
            setcall codepointer action_code_right_util(codepointer)
            call brace_blocks_remove_write()
            return codepointer
        endelseif
        setcall codepointer action_code_right_number(codepointer)
        if operation!=(compare_action)
            call action_one(operation)
        else
            call action_one(compare_op_1)
            if compare_op_2!=0;call action_one(compare_op_2);endif
        endelse
    endwhile
    add codepointer (DWORD)
    return codepointer
endfunction

#codepointer
function action_code_right_number(sd codepointer)
    if codepointer#==(parenthesis_start)
        add codepointer (DWORD)
        setcall codepointer action_code_right_util(codepointer)
        return codepointer
    endif
    if codepointer#==(call_action_right)
        setcall codepointer action_code_write_function_call(codepointer)
        return codepointer
    endif
    sd attrib
    set attrib codepointer#
    add codepointer (DWORD)
    if attrib==(ActionGetMember)
        setcall codepointer action_member_loop(codepointer,(get_member))
    else
        if attrib==(ActionGetVariable)
            call action_one_command(codepointer#v^)
            add codepointer (pointer_rest)
        elseif attrib==(ap_double)
            sd low;set low codepointer#;add codepointer (DWORD)
            call action_push(attrib,low,codepointer#,-1)
        elseif attrib==(ap_Integer)
            call action_push(attrib,codepointer#,-1)
        else
        #ap_Constant8
            call action_push(attrib,codepointer#v^,-1)
            add codepointer (pointer_rest)
        endelse
        add codepointer (DWORD)
    endelse
    return codepointer
endfunction
function action_one_command(ss command)
    sd compare
    #
    setcall compare strcmp("null",command)
    if compare==0
        call action_push((ap_Null),-1)
        return (void)
    endif
    setcall compare strcmp("undefined",command)
    if compare==0
        call action_push((ap_Undefined),-1)
        return (void)
    endif
    setcall compare strcmp("true",command)
    if compare==0
        call action_push((ap_Boolean),1,-1)
        return (void)
    endif
    setcall compare strcmp("false",command)
    if compare==0
        call action_push((ap_Boolean),0,-1)
        return (void)
    endif
    call action_get_one(command)
endfunction
function action_get_one(ss variable)
    call action_push((ap_Constant8),variable,-1)
    call action_one((ActionGetVariable))
endfunction

#codepointer
function action_definefunction(sd codepointer)
    if codepointer#!=(function_action)
        return codepointer
    endif
    add codepointer (DWORD)
    setcall codepointer action_deffunction(codepointer)
    #a function marker for return and for..in case
    sd block;setcall block cond_blocks();set block# (brace_blocks_function);call brace_blocks_counter_inc()
    #
    call brace_blocks_add_write()
    #
    sd index_atstart
    setcall index_atstart brace_blocks_counter()
    set index_atstart index_atstart#
    #
    sd index_current=0x7fFFffFF
    while index_atstart<=index_current
        setcall codepointer action__code_row(codepointer)
        setcall index_current brace_blocks_counter()
        set index_current index_current#
    endwhile
    #close function marker for return and for..in case
    import "brace_blocks_counter_dec" brace_blocks_counter_dec
    call brace_blocks_counter_dec()
    #
    return codepointer
endfunction
#codepointer
function action_deffunction(sv codepointer)
    ss fn_name
    set fn_name codepointer#
    add codepointer :  #to pass the pointer
    sd fn_name_size
    setcall fn_name_size strlen(fn_name)
    inc fn_name_size
    #
    sd fn_size
    set fn_size fn_name_size
    const NumParams_size=2
    const codeSize_size=2
    add fn_size (NumParams_size+codeSize_size)
    #
    sd NumParams=0
    sd args
    set args codepointer
    while codepointer#!=(no_pointer)
        addcall fn_size strlen(codepointer#)
        inc fn_size
        inc NumParams
        add codepointer :  #to pass the pointer
    endwhile
    add codepointer :  #to pass the pointer
    #
    call actionrecordheader((ActionDefineFunction),fn_size)
    call swf_actionblock_add(fn_name,fn_name_size)
    call swf_actionblock_add(#NumParams,(NumParams_size))
    #
    sd wr_size
    while args#!=(no_pointer)
        setcall wr_size strlen(args#)
        inc wr_size
        call swf_actionblock_add(args#,wr_size)
        add args :  #to pass the pointer
    endwhile
    #
    data dummyoffset=0
    call swf_actionblock_add(#dummyoffset,(WORD))
    #
    return codepointer
endfunction
