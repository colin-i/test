Format ElfObj64

include "../include/prog.h"

#win32 with _
importx "strlen" strlen
importx "memcpy" memcpy
importx "sprintf" sprintf

import "spaces" spaces

#strings

#error_row
function escape_action(ss ac,ss pointer,ss stop_pointer)
    sd row=1
    sd loop1=1
    sd error_row=0
    #
    sd comments=0
    chars lines_com_c1="*";chars lines_com_c2="/";ss test
    const line_comment=1
    const multiLine_comment=2
    #
    while loop1==1
        sd loop2=1
        setcall ac spaces(ac)
        #
        if comments!=(multiLine_comment)
            set comments 0
            if ac#==(Slash)
                set test ac
                inc test
                if test#==(Slash)
                    set comments (line_comment)
                    add ac 2
                elseif test#==lines_com_c1
                    set comments (multiLine_comment)
                    add ac 2
                endelseif
            endif
        endif
        #
        while loop2==1
            if ac#==0xa
                set loop2 0
                inc row
            elseif ac#==0xd
                set loop2 0
                set test ac;inc test;if test#==0xa;inc ac;endif
                inc row
            elseif ac#==0
                set loop2 0
                set loop1 0
                set pointer# 0
            else
                if comments==0
                    if pointer==stop_pointer
                        set error_row row
                    else
                        set pointer# ac#
                    endelse
                    inc pointer
                elseif comments==(multiLine_comment)
                    if ac#==lines_com_c1
                        set test ac;inc test;if test#==lines_com_c2;set comments 0;inc ac;endif
                    endif
                endelseif
            endelse
            inc ac
        endwhile
	if error_row!=0
            set pointer# 0
            set loop1 0
        endif
    endwhile
    return error_row
endfunction
#nr
function escape_count(ss string,sd escape)
    sd nr=0
    sd escaped=0
    while string#!=0
        if string#==escape
            if escaped==0
                #
                ss double_test
                set double_test string
                inc double_test
                chars l="l";chars f="f";
                if double_test#==l
                    inc double_test
                    if double_test#==f
                        inc nr
                    endif
                endif
                #
                inc nr
            endif
            xor escaped 1
        elseif escaped==1
            set escaped 0
        endelseif
        inc string
    endwhile
    return nr
endfunction

#debug

function action_debug(sd is_on)
    data action_errors=FALSE
    vstr *#1
    vstr m=NULL
    if is_on==(FALSE)
        #set there and here, here good at errors and comeback
        set action_errors (FALSE)
        import "mem_free" mem_free
        if m!=(NULL);call mem_free(#m);endif
    else
        return #action_errors
    endelse
endfunction
function action_debug_free()
    call action_debug((FALSE))
endfunction

function debug_code()
    value code#1
    return #code
endfunction

function action_error()
    sd p_action_errors
    setcall p_action_errors action_debug((TRUE))
    if p_action_errors#==(FALSE)
        return (void)
    endif

    vstr ac#1
    vstr mem#1
    add p_action_errors (DWORD);call memcpy(#ac,p_action_errors,(2*:))

    import "printEr" printEr
    call printEr("Row: ")
    sv p_c
    setcall p_c debug_code()
    sd row
    setcall row escape_action(ac,mem,p_c#)
    import "string_nl_print" string_nl_print
    #a small reserve for a number like 2 000 000 000
    chars row_nr#dword_to_string_chars
    call sprintf(#row_nr,"%u",row)
    call string_nl_print(#row_nr)
    call string_nl_print(p_c#)
endfunction

#size
function action_size(sd id)
    import "block_get_size" block_get_size
    sd block
    setcall block struct_ids_action((ids_get),id)
    sd size
    setcall size block_get_size(block)
    addcall size pool_size(id)
    #add termination
    add size 1
    return size
endfunction

import "block_get_mem" block_get_mem

#these ids are get only, is safe at throwless
import "struct_ids_action" struct_ids_action
import "struct_ids_actionpool" struct_ids_actionpool

#size
function pool_size(sd id)
    sd poolblock
    setcall poolblock struct_ids_actionpool((ids_get),id)
    sd poolsize
    setcall poolsize block_get_size(poolblock)
    #detected at button actions="", swfdump giving error without "if poolsize!=0"
    if poolsize==0;return 0;endif
    #add header
    add poolsize (1+2)
    return poolsize
endfunction





importaftercall ebool

importx "action" action

import "swf_actionblock_add" swf_actionblock_add
import "actionrecordheader" actionrecordheader
import "actionpool_value" actionpool_value

#tags

function action_push(sd factors)
	sd iter^factors
	sd size=0
	while iter#!=-1
		inc size
		if iter#==(ap_Integer)
			add size (DWORD)
			incst iter
		elseif iter#==(ap_double)
			add size (QWORD)
			add iter (2*:)
		elseif iter#==(ap_Null)
		#skip
		elseif iter#==(ap_Undefined)
		#skip
		else
		#if iter#==(ap_RegisterNumber)
		#if iter#==(ap_Boolean)
		#if iter#==(ap_Constant8)
			add size (BYTE)
			sd value
			set value iter#
			incst iter
			if value==(ap_Constant8)
			#set the action pool(if isn't) and verify to add +1size if 8 will go to ap_Constant16
				sd translated_id
				setcall translated_id actionpool_value(iter#v^)
				if translated_id>0xff
					inc size
				endif
			endif
		endelse
		incst iter
	endwhile

	call actionrecordheader((ActionPush),size)

	sd cursor^factors
	while cursor#!=-1
		#test here Constant8 to Constant16
		if cursor#==(ap_Constant8)
			sv pointer
			set pointer cursor
			incst pointer
			#call actionpool_getvalue, the pool already exists(actionpool_value if not)
			import "actionpool_getvalue" actionpool_getvalue
			setcall translated_id actionpool_getvalue(pointer#)
			sd const_sz=BYTE
			if translated_id>0xff
				inc const_sz
				set cursor# (ap_Constant16)
			endif
		endif

		call swf_actionblock_add(cursor,1)

		if cursor#==(ap_Integer)
			incst cursor
			call swf_actionblock_add(cursor,(DWORD))
		elseif cursor#==(ap_double)
			incst cursor
			call swf_actionblock_add(cursor,(DWORD))
			incst cursor
			call swf_actionblock_add(cursor,(DWORD))
		elseif cursor#==(ap_RegisterNumber)
			incst cursor
			call swf_actionblock_add(cursor,(BYTE))
		elseif cursor#==(ap_Boolean)
			incst cursor
			call swf_actionblock_add(cursor,(BYTE))
		elseif cursor#==(ap_Null)
		#skip
		elseif cursor#==(ap_Undefined)
		#skip
		else
		#if cursor#==(ap_Constant8)
		#or was modified to (ap_Constant16)
			call swf_actionblock_add(#translated_id,const_sz)
			incst cursor
		endelse
		incst cursor
	endwhile
endfunction

function action_one(sd tag)
    call swf_actionblock_add(#tag,1)
endfunction

import "action_code_right_util" action_code_right_util
#codepointer
function action_caller(ss name,ss member,sd args_pointer)
    sd nrargs=0
    while args_pointer#!=(args_end)
        setcall args_pointer action_code_right_util(args_pointer)
        inc nrargs
    endwhile
    add args_pointer (DWORD)
    call action_push((ap_Integer),nrargs,-1)
    #
    if member!=0
        call action_member_write(member)
    endif
    call action_push((ap_Constant8),name,-1)
    return args_pointer
endfunction

#member

import "action_get_one" action_get_one
#the position where the mathpointer reachs
function action_member_loop(sd mathpointer,sd endoffset)
    call action_get_one(mathpointer#v^)
    while 1==1
        add mathpointer :  #to pass the pointer
        #
        while mathpointer#==(square_bracket_start)
        #multi-dim arrays
            add mathpointer (DWORD)
            setcall mathpointer action_code_right_util(mathpointer)
            if endoffset==(get_member)
                call action_one((ActionGetMember))
            else
                if mathpointer#v^!=(no_pointer)
                    call action_one((ActionGetMember))
                else
                    add mathpointer :  #to pass the pointer
                    return mathpointer
                endelse
            endelse
        endwhile
        sv endtest
        set endtest mathpointer
        add endtest endoffset
        #
        if endtest#==(no_pointer)
            if endoffset!=(no_pointer)
                #push to set later
                call action_push((ap_Constant8),mathpointer#v^,-1)
                add mathpointer :  #to pass the pointer
            endif
            add mathpointer :  #to pass the pointer
            return mathpointer
        endif
        call action_push((ap_Constant8),mathpointer#v^,-1)
        call action_one((ActionGetMember))
    endwhile
endfunction
import "action_code_member" action_code_member
import "error" error
import "forward_values_expand" forward_values_expand
function action_member_write(ss member)
    const dup_member=256
    chars dup_data#dup_member
    vstr code^dup_data
    sd len
    setcall len strlen(member)
    inc len
    if len>(dup_member)
        call error("actionscript code limit exceeded")
    endif
    call memcpy(code,member,len)
    call forward_values_expand(action_member_write_tool,code)
endfunction
function action_member_write_tool(sd values,ss names)
    call action_code_member(names)
    call action_member_loop(values,(get_member))
endfunction

#action

import "swf_actionrecordheader" swf_actionrecordheader
import "swf_mem_add" swf_mem_add
function write_action(sd id)
    sd block
    setcall block struct_ids_action((ids_get),id)
    sd mem
    setcall mem block_get_mem(block)
    sd size
    setcall size block_get_size(block)
    call pool_wr(id)
    call swf_mem_add(mem,size)
    #this is ActionEndFlag after ACTIONRECORD [zero or more]
    data end=0
    call swf_mem_add(#end,1)
endfunction
#void
function pool_wr(sd id)
    sd poolblock
    setcall poolblock struct_ids_actionpool((ids_get),id)
    sd poolsize
    setcall poolsize block_get_size(poolblock)
    #detected at button actions="", swfdump giving error without "if poolsize!=0"
    if poolsize==0;return 0;endif
    sd poolmem
    setcall poolmem block_get_mem(poolblock)
    call swf_actionrecordheader((ActionConstantPool),poolsize)
    call swf_mem_add(poolmem,poolsize)
endfunction

#format

function action_format(sv args)
    sd args_nr=2
    sv args_format
    set args_format args;incst args_format
    chars e="%"
    addcall args_nr escape_count(args_format#,e)
    callex sprintf args args_nr
    call action(args#)
endfunction
