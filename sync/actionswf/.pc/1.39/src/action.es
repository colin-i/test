Format ElfObj64

importaftercall ebool
include "../include/prog.h"

#this/an action

import "action__code" action__code
import "action_code_set" action_code_set
import "action_code_row" action_code_row
import "action_debug" action_debug
import "dupreserve_string" dupreserve_string
import "brace_blocks_counter_init" brace_blocks_counter_init
import "brace_blocks_end" brace_blocks_end
import "action_code_values" action_code_values
import "action_code_values_index" action_code_values_index
import "escape_action" escape_action
functionX action(ss ac)
#ss ac       actionscript string to be parsed
    sd p_values
    setcall p_values action_code_values()
    import "error" error
    if p_values==(NULL);call error("Don't call the action now.");endif
    #
    sd nr
    setcall nr action_code_values_index()
    set nr# 0
    call brace_blocks_counter_init()
    #
    ss mem
    setcall mem dupreserve_string(ac)
    sd p_action_errors
    setcall p_action_errors action_debug((TRUE))
    set p_action_errors# (TRUE);add p_action_errors (DWORD);set p_action_errors# ac;add p_action_errors (DWORD);set p_action_errors# mem
    call escape_action(ac,mem,0)
    while mem#!=0
        setcall mem action_code_row(mem,(FALSE))
    endwhile
    call action_code_set((math_end))

    #set false to stop adding row nr at errors
    set p_action_errors# (FALSE)

    call brace_blocks_end()

    #                 code_values are not reallocated
    call action__code(p_values)

    #free mem ok,another free can be at errors
    import "action_debug_free" action_debug_free
    call action_debug_free()
endfunction
import "action_format" action_format
functionX actionf(ss buffer,ss *format)
#ss buffer   the buffer where to sprintf the format and the arguments
#ss format   the format
#...         % arguments here
    call action_format(#buffer)
endfunction

#sprite

import "swf_actionblock" swf_actionblock
functionX action_sprite(sd sprite,ss actions)
#sd sprite    sprite id
#ss actions   same as action
    call swf_actionblock((mem_exp_change),sprite)
    call action(actions)
    call swf_actionblock((mem_exp_change_back))
endfunction
functionX actionf_sprite(sd sprite,ss buffer,ss *format)
#sd sprite    sprite id
#ss buffer    same as actionf
#ss format    same as actionf
    call swf_actionblock((mem_exp_change),sprite)
    call action_format(#buffer)
    call swf_actionblock((mem_exp_change_back))
endfunction
