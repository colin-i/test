Format ElfObj64

importx "strcspn" strcspn
importx "strchr" strchr
importx "memcpy" memcpy
importx "sscanf" sscanf
importx "strpbrk" strpbrk

importaftercall ebool
include "../include/prog.h"

import "str_next" str_next
import "str_expression_at_start" str_expression_at_start
import "action_code_set" action_code_set
import "error" error
const add=Plus
const sub=Hyphen
const mlt=Asterisk
const div=Slash
const modulo=Procenttecken
const and=Ampersand
const or=Verticalbar
const xor=Caret
const shl=Lessthan
const sar_shr=Greaterthan
const ifElse_sign=Questionmark
#pointer
function action_code_row(ss ac,sd a_block_detected)
    setcall ac action_code_row_ex(ac,a_block_detected,-1)
    return ac
endfunction
#pointer
function action_code_row_ex(ss ac,sd a_block_detected,sd else_index)
    import "debug_code" debug_code
    sd p_c
    setcall p_c debug_code()
    set p_c# ac
    ss atstart=NULL
    while atstart!=ac
        sd flags
        sd for_detected=0
        set atstart ac
        setcall ac action_parse_conditions(ac,#flags,#for_detected)
        if atstart!=ac
            if for_detected==0
                if ac#!=(Openparenthesis)
                    call error("open parenthesis sign expected")
                endif
                #using the operations function
                inc ac
                chars closecompare=")"
                setcall ac action_code_row_parse_tool(ac,closecompare)
                #if ac#!=closecompare
                #    call error("close parenthesis expected")
                #endif
            endif
            #important settings
            if a_block_detected==(TRUE)
                or flags (consecutive_flag)
            endif
            call brace_blocks_add_parse(flags)
            set a_block_detected (TRUE)
        endif
    endwhile
    setcall ac action_code_row_parse(ac,a_block_detected,else_index)
    return ac
endfunction
#pointer
function action_parse_conditions(ss ac,sd p_flags,sd p_for_detected)
    #if
    ss pointer
    setcall pointer str_expression_at_start(ac,"if")
    if pointer!=ac
        set p_flags# (if_marker)
        call action_code_set((ActionIf))
        return pointer
    endif
    #while
    setcall pointer str_expression_at_start(ac,"while")
    if pointer!=ac
        call action_code_set((while_marker))
        set p_flags# (while_marker)
        return pointer
    else
    #for
        setcall pointer str_expression_at_start(ac,"for")
        if pointer==ac;return pointer;endif
        #
        call action_code_set((for_marker))
        set p_flags# (while_marker)
        set p_for_detected# 1
        #
        if pointer#!=(Openparenthesis)
            call error("expecting Open Parenthesis at for loop")
        endif
        inc pointer
        set ac pointer
        #
        ss cursor;ss marker
        #forIn or for x;x;x
        sd pos1;setcall pos1 strcspn(pointer,")")
        sd pos2;setcall pos2 strcspn(pointer,";")
        if pos2<pos1
            #for x;x;x
            call action_code_set((for_three))
            #ac X;x;x
            set cursor pointer;add cursor pos2
            if cursor#==0
                call error("expecting ';' at for loop, first part")
            endif
                            #is for for(;x;x) the !=
            if cursor!=ac;call action_parse_pack(ac,(Semicolon));endif
                            #is for for(;x;x)
            call action_code_set((inter_for))
            inc cursor
            #pointer x;X;x
            set pointer cursor
            setcall pos2 strcspn(pointer,";")
            add cursor pos2
            if cursor#==0
                call error("expecting ';' at for loop, second part")
            endif
            #cursor x;x;X
            inc cursor
            #not let for(x;x;heatMaker), heatMaker will be ignored and violation will come
            if cursor#!=(Closeparenthesis);setcall cursor action_parse_pack(cursor,(Closeparenthesis))
            else;inc cursor;endelse
            call action_code_set((inter_for))
            call action_code_row_parse_tool(pointer,(Semicolon))
            return cursor
        endif
        #
        setcall pointer str_expression_at_start(pointer,"var")
        setcall pos1 strcspn(pointer," ")
        set cursor pointer;add cursor pos1
        if cursor#==0
            call error("expecting 'space' at for loop")
        endif
        set cursor# 0
        import "spaces" spaces
        inc cursor;setcall cursor spaces(cursor)
        setcall marker str_expression_at_start(cursor,"in")
        if marker==cursor
            call error("expecting 'in' at for loop")
        endif
        setcall pos1 strcspn(marker,")")
        set cursor marker
        add cursor pos1
        if cursor#==0
            call error("expecting Close Parenthesis at for loop")
        endif
        set cursor# 0
        #
        #enum can take ActionEnumerate(x.x[z])
        call action_code_set(marker)
        #
        if pointer!=ac
            call action_code_set((ActionDefineLocal))
            call action_code_set(pointer)
        else
            call action_parse_left_holder(pointer,(ActionSetVariable),(ActionSetMember))
        endelse
        inc cursor
        return cursor
    endelse
endfunction
#pointer
function action_code_row_parse(ss ac,sd a_block_detected,sd else_index)
    if ac#==(Openingbrace)
        if a_block_detected==(FALSE)
            call brace_blocks_add_parse((normal_marker))
        endif
        inc ac
        return ac
    elseif ac#==(Closingbrace)
        if a_block_detected==(TRUE)
            call error("unexpected closing brace sign after code block opened")
        endif
        inc ac
        setcall ac else_verify(ac,else_index)
        return ac
    endelseif
    setcall ac action_code_row_parse_instrument(ac)
    if a_block_detected==(TRUE)
    #ex: if(a==b)x=3;
        setcall ac else_verify(ac,else_index)
    endif
    return ac
endfunction
#pointer
function else_verify(ss ac,sd else_index)
    sd p_ind
    sd c_ind

    setcall p_ind brace_blocks_counter()
    set c_ind p_ind#
    #this condition for: else >expression<
    if c_ind>else_index
        call brace_blocks_remove_parse()
    endif
    setcall p_ind brace_blocks_counter()
    set c_ind p_ind#
    #opened else index same with current index: return at else
    if else_index==c_ind
        return ac
    endif

    sd bool_is_elseif

    ss pointer
    setcall pointer else_elseif_expression(ac,#bool_is_elseif)
    if pointer==ac
        return ac
    endif
    while pointer!=ac
        call action_code_set((else_flag))
        call brace_blocks_add_parse((else_flag))
        sd ind
        setcall p_ind brace_blocks_counter()
        set ind p_ind#
        #c_ind is lower
        while ind!=c_ind
			ss the_new_pointer;set the_new_pointer pointer
            setcall the_new_pointer action_code_row_ex(pointer,(FALSE),ind)
			if the_new_pointer==pointer;call error("Else not closed");endif
			set pointer the_new_pointer
            #
            setcall p_ind brace_blocks_counter()
            set c_ind p_ind#
        endwhile
        set ac pointer
        sd prev_else_elseif;set prev_else_elseif bool_is_elseif
        setcall pointer else_elseif_expression(ac,#bool_is_elseif)
        if prev_else_elseif==(FALSE);if bool_is_elseif==(TRUE)
            call error("not expecting Else and then Else If")
        endif;endif
    endwhile
    call brace_blocks_remove_parse_else()
    return ac
endfunction
#next/same
function else_elseif_expression(ss ac,sd p_elseif)
    set p_elseif# (FALSE)
    ss pointer
    setcall pointer str_expression_at_start(ac,"else")
    if pointer==ac
        return ac
    endif
    setcall ac str_expression_at_start(pointer,"if")
    if pointer==ac
        return pointer
    endif
    set p_elseif# (TRUE)
    return pointer
endfunction
import "str_expression_at_start_withEndCare" str_expression_at_start_withEndCare
#pointer
function action_code_row_parse_instrument(ss ac)
    ss pointer
    setcall pointer action_code_parse_leftfunction(ac)
    if pointer!=ac
        return pointer
    endif
    setcall pointer str_expression_at_start(ac,"return")
    if pointer!=ac
        call action_code_set((ActionReturn))
        chars an_end=";"
        setcall ac action_code_row_parse_tool(pointer,an_end)
        return ac
    endif
    setcall pointer str_expression_at_start_withEndCare(ac,"break")
    if pointer!=ac
        call action_code_set((break_flag))
        return pointer
    endif
    setcall pointer str_expression_at_start_withEndCare(ac,"continue")
    if pointer!=ac
        call action_code_set((continue_flag))
        return pointer
    endif
    #
    setcall pointer action_parse_pack(ac,(Semicolon))
    return pointer
endfunction
#pointer
function action_parse_pack(ss ac,sd endChar)
    ss pointer
    sd isnewvar=FALSE
    sd isdelete
    setcall pointer str_expression_at_start(ac,"var")
    if pointer!=ac
        set isnewvar (TRUE)
    else
        set isdelete (FALSE)
        setcall pointer str_expression_at_start(ac,"delete")
        if pointer!=ac
            set isdelete (TRUE)
        endif
    endelse
    sd op
    chars set={Equals}
    chars secondChar#1
    chars *term=0
    set secondChar endChar
    ss delims^set

    setcall ac str_next(pointer,delims,#op)

    if isnewvar==(TRUE)
        if op==set
            call action_code_set((ActionDefineLocal))
            call action_code_set(pointer)
        else
            call action_code_set((ActionDefineLocal2))
            call action_code_set(pointer)
            return ac
        endelse
    else
        if isdelete==(FALSE)
            sd inc_dec
            if op!=set
                set inc_dec 0
                ss test
                set test ac
                if op!=0
                    sub test 3
                else
                    sub test 2
                endelse
                sd another_test
                set another_test test
                sub another_test pointer
                #test for some size for ++ or --
                if another_test>0
                    if test#==(Plus)
                        inc test
                        if test#==(Plus)
                            set inc_dec (ActionIncrement)
                            dec test
                            set test# 0
                        endif
                    elseif test#==(Hyphen)
                        inc test
                        if test#==(Hyphen)
                            set inc_dec (ActionDecrement)
                            dec test
                            set test# 0
                        endif
                    endelseif
                endif
                #if not ++ or -- return the current location (x;heatMaker;)
                if inc_dec==0
                    return ac
                endif
            else
                #test for += .. |= ..
                sd mixt_action;setcall mixt_action action_parse_test_mixt_equal(pointer,ac)
            endelse
            call action_parse_left_holder(pointer,(ActionSetVariable),(ActionSetMember))
            if op==set
            #mixt or not mixt
                if mixt_action!=0
                    call action_code_set((mixt_equal))
                    call action_code_set(mixt_action)
                endif
            else
                #is inc dec case
                call action_code_set(inc_dec)
                return ac
            endelse
        else
            call action_parse_left_holder(pointer,(ActionDelete2),(ActionDelete))
            return ac
        endelse
    endelse
    setcall ac action_parse_right(ac,endChar)
    return ac
endfunction
function action_parse_left_holder(ss pointer,sd ac1,sd ac2)
    ss test
    setcall test action_code_membersplit(pointer)
    if test==(NULL)
        call action_code_set(ac1)
        call action_code_set(pointer)
    else
        call action_code_set(ac2)
        call action_code_member(pointer)
    endelse
endfunction
#0/action
function action_parse_test_mixt_equal(ss start,ss ac)
    dec ac
    ss pointer;set pointer ac
    dec ac
    ss dif;set dif ac;sub dif start
    if dif<=0
        return 0
    endif
    if ac#==0
        #0 can be set(qw['z']=x will be 00x) and at strchr will not be NULL
        return 0
    endif
    ss operations;setcall operations get_operations()
    ss p_op;setcall p_op strchr(operations,ac#)
    if p_op==(NULL);return 0;endif;sd op;set op p_op#
    if op==(shl);ss missing_shl="expecting value and <<"
        dec ac
        if ac==start
            call error(missing_shl)
        elseif ac#!=(shl)
            call error(missing_shl)
        endelseif
    elseif op==(sar_shr);ss missing_sar_shr="expecting value and >>"
        dec ac
        if ac==start
            call error(missing_sar_shr)
        elseif ac#!=(sar_shr)
            call error(missing_sar_shr)
        endelseif
        dec ac
        if ac#!=(sar_shr)
            inc ac
        endif
    endelseif
    set ac# 0
    sd action;setcall action action_parse_take_action(op,pointer)
    return action
endfunction
#pointer
function action_parse_right(ss ac,sd endChar)
    ss pointer
    #can be a function definition
    setcall pointer action_code_parse_deffunction(ac)
    if pointer!=ac
        return pointer
    endif
    #
    setcall ac action_code_row_parse_tool(ac,endChar)
    return ac
endfunction
#pointer
function action_code_row_parse_tool(ss ac,sd endtype)
    setcall ac action_code_row_parse_tool_util(ac,0,endtype,0)
    return ac
endfunction
#operations str
function get_operations()
    const operations_begin=!
    chars operations="+-*/%&|^<>?"
    #subtract 1 is for the string termination
    const operations_size=!-operations_begin-1
    return #operations
endfunction

#pointer
function action_code_row_parse_tool_util(ss ac,sd p_op,sd endtype1,sd endtype2)
    if ac#==0
        call error("expeting a number, variables operations")
    endif
    #a new object
    ss pointer
    setcall pointer str_expression_at_start(ac,"new")
    if pointer!=ac
        setcall ac action_code_parse_new_or_call(pointer,(new_action))
        sd bool;setcall bool action_parse_utilEndTypes(ac#,p_op,endtype1,endtype2)
        if bool==(TRUE);inc ac;endif
        return ac
    endif
    sd ifElse_bool=FALSE
    setcall ac action_parse_loop(ac,p_op,endtype1,endtype2,#ifElse_bool)
    if ifElse_bool==(FALSE)
        call action_code_set((math_end))
    endif
    return ac
endfunction
#pointer
function action_parse_loop(ss ac,sd p_op,sd endtype1,sd endtype2,sd p_ifElse_bool)
    sd bool
    #can be on the stack but chars are low values; ends are set again when recursivity
    chars oprs#operations_size
    chars *=Openingbracket
    chars *=Exclamationmark
    chars *=Equals
    chars end#1
    chars end2#1
    chars *term=0
    #
    sd is_compare_ptr
    setcall is_compare_ptr compare_bool_pointer()
    #
    str op_set^oprs
    ss ops;setcall ops get_operations();call memcpy(op_set,ops,(operations_size))
    while 1==1
        sd op
        sd was_parenthesis=0
        if ac#==(Openparenthesis)
            call action_code_set((parenthesis_start))
            inc ac
            setcall ac action_code_row_parse_tool(ac,(Closeparenthesis))
            #0 is the marker after op set; used at strings; and logicalAnd logicalOr shr and sar are not needing 0 but it's faster for strings, and are comparing with !=sign(0 is used); used at action_parse_take_action
            set op ac#;set ac# 0
            set was_parenthesis 1
        endif
        #set end: is static variable and can be mod again inside previous function
        set end endtype1
        set end2 endtype2
        #
        if was_parenthesis==0
            setcall ac action_code_take_main(ac,#op,op_set)
            if op==(ifElse_sign)
                inc ac
                call action_code_set((ifElse_start))
                set p_ifElse_bool# (TRUE)
                setcall ac action_code_row_parse_tool(ac,(Colon))
                setcall ac action_code_row_parse_tool_util(ac,p_op,endtype1,endtype2)
                return ac
            endif
        endif
        #
        setcall ac action_code_extended_operations(ac,op)
        if is_compare_ptr#==(TRUE)
            set is_compare_ptr# (FALSE)
        else
            if op==0
                if p_op!=0
                    set p_op# op
                endif
                return ac
            else
                setcall bool action_parse_utilEndTypes(op,p_op,endtype1,endtype2)
                if bool==(TRUE);return ac;endif
            endelse
            sd x;setcall x action_parse_take_action(op,ac)
            call action_code_set(x)
        endelse
    endwhile
endfunction
#bool
function action_parse_utilEndTypes(sd op,sd p_op,sd endtype1,sd endtype2)
    #when p_op is set, is to store the multiple kind of endtypes
    if p_op!=0
        set p_op# op
        if op==endtype2
            return (TRUE)
        endif
    endif
    if op==endtype1;return (TRUE);endif
    return (FALSE)
endfunction
#action
function action_parse_take_action(sd op,ss ac)
    sd x
    ss test
    if op==(add);set x (ActionAdd2)
    elseif op==(sub);set x (ActionSubtract)
    elseif op==(mlt);set x (ActionMultiply)
    elseif op==(div);set x (ActionDivide)
    elseif op==(modulo);set x (ActionModulo)
    elseif op==(and)
        set test ac;dec test
        if test#==(and);set x (ActionAnd);else;set x (ActionBitAnd);endelse
    elseif op==(or)
        set test ac;dec test
        if test#==(or);set x (ActionOr);else;set x (ActionBitOr);endelse
    elseif op==(xor);set x (ActionBitXor)
    elseif op==(shl);set x (ActionBitLShift)
    elseif op==(sar_shr)
        set test ac
        sub test 2
        if test#==0;set x (ActionBitRShift)
        else;set x (ActionBitURShift);endelse
    else
        #at "qwer"x can be x
        call error("unrecognized actionscript operation")
    endelse
    return x
endfunction
#pointer
function action_code_extended_operations(ss pointer,sd op)
    #comparison
    sd compareaction
    setcall compareaction action_compare(op,(NULL))
    if compareaction!=(NULL)
        inc pointer
        sd oneSign_two_or_noCompare;setcall oneSign_two_or_noCompare action_compare(pointer#,compareaction)
        dec pointer
        if oneSign_two_or_noCompare!=2
            sd compare_bool_ptr;setcall compare_bool_ptr compare_bool_pointer();set compare_bool_ptr# (TRUE)
            add pointer oneSign_two_or_noCompare
            inc pointer
            return pointer
        endif
    endif

    #shl/shr/sar / && ||
    if op==(shl)
        inc pointer
        if pointer#!=(shl);call error("expecting <<");endif
    elseif op==(sar_shr)
        inc pointer
        if pointer#!=(sar_shr);call error("expecting >>");endif
        inc pointer
        if pointer#!=(sar_shr)
        #not >>> case
            dec pointer
        endif
    elseif op==(and)
        inc pointer;if pointer#!=(and);dec pointer;endif
    elseif op==(or)
        inc pointer;if pointer#!=(or);dec pointer;endif
    endelseif

    if op!=0
        inc pointer
    endif

    return pointer
endfunction
#pointer
function action_code_take_main(ss ac,sd p_op,ss delims)
    #a string
    ss pointer
    setcall pointer action_code_str(ac)
    if pointer!=0
        set p_op# pointer#;set pointer# 0
        return pointer
    endif
    #a function
    setcall pointer action_code_parse_new_or_call(ac,(call_action_right))
    if pointer!=ac
        set p_op# pointer#;set pointer# 0
        return pointer
    endif
    #a variable(a.b.c[1+d])
    chars neg="-"
    if pointer#==neg
        inc pointer
    endif
    sd pos
    setcall pos strcspn(pointer,delims)
    add pointer pos
    while pointer#==(Openingbracket)
        setcall pointer brackets_test(pointer)
        #continue with the member
        setcall pos strcspn(pointer,delims)
        add pointer pos
    endwhile
    sd op
    set op pointer#
    set p_op# op;set pointer# 0
    call action_code_take(ac)
    return pointer
endfunction
#pointer
function brackets_test(ss pointer)
    sd multidim=1
    while multidim==1
        sd openedbrackets=1
        while openedbrackets>0
            inc pointer
            if pointer#==(Openingbracket)
                inc openedbrackets
            elseif pointer#==(Closingbracket)
                dec openedbrackets
            elseif pointer#==0
                call error("unclosed bracket detected")
            endelseif
        endwhile
        inc pointer
        if pointer#!=(Openingbracket)
            set multidim 0
        endif
    endwhile
    return pointer
endfunction

import "str_escape" str_escape
#next/0
function action_code_str(ss ac)
    sd delim
    chars stringdelim="\""
    chars stringdelim2="'"
    set delim stringdelim
    if ac#!=stringdelim
        if ac#!=stringdelim2
            return 0
        else
            set delim stringdelim2
        endelse
    endif
    ss next
    ss dest
    set dest ac
    inc dest
    setcall next str_escape(ac,dest,delim)
    call action_code_set((ap_Constant8))
    call action_code_set(dest)
    return next
endfunction
function action_code_take(ss ac)
    sd b;setcall b numeric_code(ac)
    if b==(TRUE)
        return (void)
    endif
    ss test
    setcall test action_code_membersplit(ac)
    if test==0
        call action_code_set((ActionGetVariable))
        call action_code_set(ac)
    else
        call action_code_set((ActionGetMember))
        call action_code_member(ac)
    endelse
endfunction
import "is_numeric" is_numeric
#bool
function numeric_code(ss ac)
    ss pointer;set pointer ac
    chars neg="-"
    if pointer#==neg
        inc pointer
    endif
    sd bool
    setcall bool is_numeric(pointer#)
    if bool!=(TRUE);return (FALSE);endif
    #
    data value_low#1;data value_high#1
    #
    ss decimal_symbol_test
    chars dot="."
    setcall decimal_symbol_test strchr(pointer,dot)
    if decimal_symbol_test!=(NULL)
        call action_code_set((ap_double))
        call sscanf(ac,"%lf",#value_low)
        call action_code_set(value_high)
        call action_code_set(value_low)
        return (TRUE)
    endif
    #
    call action_code_set((ap_Integer))
    #
    ss hextest
    set hextest pointer
    inc hextest
    chars hex="x"
    if hextest#==hex
        call sscanf(ac,"%x",#value_low)
    else
        call sscanf(ac,"%u",#value_low)
    endelse
    call action_code_set(value_low)
    return (TRUE)
endfunction
#strpbrk
function action_code_membersplit(ss ac)
    chars delims=".["
    ss next
    setcall next strpbrk(ac,#delims)
    return next
endfunction
function action_code_member(ss ac)
    str delims=".["
    chars dot=".";chars sqbrace_start="["
    chars sqbrace_end="]"
    while ac#!=0
        sd pos
        setcall pos strcspn(ac,delims)
        ss pointer
        set pointer ac
        if pos!=0
        #0 is at second+ multi-dimensional arrays levels
            add pointer pos
            call action_code_set(ac)
        endif
        if pointer#==sqbrace_start
            set pointer# 0
            inc pointer
            call action_code_set((square_bracket_start))
            setcall pointer action_code_row_parse_tool(pointer,sqbrace_end)
        endif
        if pointer#==dot
            set pointer# 0
            inc pointer
        endif
        set ac pointer
    endwhile
    call action_code_set(0)
endfunction


#condition


#str
function compares_signs()
    return "<>=!"
endfunction
function compare_bool_pointer()
    data compare_bool=FALSE;return #compare_bool
endfunction
#firstcompare==NULL:action code/NULL;else oneSign_two_or_noCompare 0/1/2
function action_compare(sd value,sd firstcompare)
    #
    ss compares
    setcall compares compares_signs()
    #<
    if compares#==value
        if firstcompare!=(NULL)
                                           #is shl
            if firstcompare==(ActionLess2);return 2
            else;call error("not expeting < here");endelse
        endif
        return (ActionLess2)
    endif
    #>
    inc compares
    if compares#==value
        if firstcompare!=(NULL)
                                             #is sar_shr
            if firstcompare==(ActionGreater);return 2
            else;call error("not expeting > here");endelse
        endif
        return (ActionGreater)
    endif
    #
    if firstcompare!=(NULL)
        call action_code_set((compare_action))
    endif
    #=
    inc compares
    if compares#==value
        if firstcompare==(ActionLess2)
            call action_code_set((ActionGreater))
            call action_code_set((ActionNot))
            return 1
        elseif firstcompare==(ActionGreater)
            call action_code_set((ActionLess2))
            call action_code_set((ActionNot))
            return 1
        elseif firstcompare==(ActionEquals2)
            call action_code_set((ActionEquals2))
            call action_code_set(0)
            return 1
        elseif firstcompare==(ActionNot)
            call action_code_set((ActionEquals2))
            call action_code_set((ActionNot))
            return 1
        endelseif
        return (ActionEquals2)
    endif
    #!
    inc compares
    if compares#==value
        if firstcompare!=(NULL)
            call error("not expecting ! here")
        endif
        return (ActionNot)
    endif
    #another char
    if firstcompare==(NULL)
        #call error("expecting a comparison")
        return (NULL)
    elseif firstcompare==(ActionEquals2)
        call error("expecting a == comparison")
    elseif firstcompare==(ActionNot)
        call error("expecting a != comparison")
    endelseif
    if firstcompare==(ActionLess2)
        call action_code_set((ActionLess2))
        call action_code_set(0)
    else
    #if firstcompare==(ActionGreater)
        call action_code_set((ActionGreater))
        call action_code_set(0)
    endelse
    return 0
endfunction

#{} blocks

const cond_block_size=DWORD
const brace_blocks_max=100*cond_block_size
function brace_blocks_counter()
    data counter#1
    return #counter
endfunction
function brace_blocks_counter_init()
    sd c
    setcall c brace_blocks_counter()
    set c# 0
endfunction
function brace_blocks_counter_inc()
    sd c
    setcall c brace_blocks_counter()
    if c#>=(brace_blocks_max)
        call error("too many blocks: {}")
    endif
    inc c#
endfunction
function brace_blocks_counter_dec()
    sd c
    setcall c brace_blocks_counter()
    if c#<=0
        call error("unexpected end block: }")
    endif
    dec c#
endfunction
#
function cond_blocks()
    sd p_i
    setcall p_i brace_blocks_counter()
    sd blocks
    setcall blocks cond_blocks_at_index(p_i#)
    return blocks
endfunction
function cond_blocks_at_index(sd i)
    data blocks_mem#brace_blocks_max
    sd blocks^blocks_mem
    #
    mult i (cond_block_size)
    add blocks i
    return blocks
endfunction
import "swf_actionblock" swf_actionblock
function brace_blocks_get_memblock()
    sd memblock
    setcall memblock swf_actionblock((mem_exp_get_block))
    return memblock
endfunction
#
function brace_blocks_add_parse(sd type)
    sd block
    setcall block cond_blocks()
    set block# type
    call brace_blocks_counter_inc()
endfunction
function brace_blocks_remove_parse_else()
    sd p_type
    sd type
    #
    sd p_i
    setcall p_i brace_blocks_counter()
    sd i
    set i p_i#
    dec i
    setcall p_type cond_blocks_at_index(i)
    set type p_type#
    if type==(else_flag)
        sd else_number=0
        while type==(else_flag)
            inc else_number
            dec p_i#
            if i!=0
                dec i
                setcall p_type cond_blocks_at_index(i)
                set type p_type#
            else
                set type 0
            endelse
        endwhile
        call action_code_set((block_else_end))
        call action_code_set(else_number)
    endif
endfunction
function brace_blocks_remove_parse()
    sd p_type
    sd type
    sd consecutive=consecutive_flag
    while consecutive==(consecutive_flag)
        call brace_blocks_counter_dec()
        #
        setcall p_type cond_blocks()
        setcall type type_consecutive(p_type#,#consecutive)
        if type!=(normal_marker)
            if type==(while_marker)
                call action_code_set((whileblock_end))
            else
                call action_code_set((block_end))
            endelse
        endif
    endwhile
endfunction
#type
function type_consecutive(sd type,sd p_consecutive)
    and p_consecutive# type
    and type (~consecutive_flag)
    return type
endfunction
function brace_blocks_end()
    sd c
    setcall c brace_blocks_counter()
    if c#!=0
        call error("unclosed block(s): {}")
    endif
endfunction
#
import "block_get_size" block_get_size
function brace_blocks_add_write()
    call brace_blocks_add_write_offset(-2)
endfunction
function brace_blocks_add_write_current()
    call brace_blocks_add_write_offset(0)
endfunction
function brace_blocks_add_write_offset(sd offset)
    sd block
    setcall block cond_blocks()
    sd memblock
    setcall memblock brace_blocks_get_memblock()
    setcall block# block_get_size(memblock)
    add block# offset
    call brace_blocks_counter_inc()
endfunction
    #
import "block_get_mem_size" block_get_mem_size
function brace_blocks_remove_write()
    sd offset
    setcall offset brace_blocks_remove_write_offset()
    call write_forward_offset(offset)
endfunction
function write_forward_offset(sd offset)
    sd mem
    sd size
    sd memblock
    setcall memblock brace_blocks_get_memblock()
    call block_get_mem_size(memblock,#mem,#size)
    #
    add mem offset
    add offset (WORD)
    sub size offset
    #
    if size>0x7fFF
        call error("offset>(signed word size) error")
    endif
    #
    import "dword_to_word_arg" dword_to_word_arg
    call dword_to_word_arg(size,mem)
endfunction
#offset
function brace_blocks_remove_write_offset()
    call brace_blocks_counter_dec()
    sd block
    setcall block cond_blocks()
    return block#
endfunction

function brace_blocks_remove_write_jump()
    call add_dummy_jump()
    #
    call brace_blocks_remove_write_loopIfJumps_at_current_offset()
    #
    sd jumpoffset
    setcall jumpoffset brace_blocks_remove_write_offset()
    call resolve_dummy_jump(jumpoffset)
endfunction
function add_dummy_jump()
    import "actionrecordheader" actionrecordheader
    call actionrecordheader((ActionJump),2)
    import "swf_actionblock_add" swf_actionblock_add
    sd dummy_size=0
    call swf_actionblock_add(#dummy_size,2)
endfunction
function resolve_dummy_jump(sd jumpoffset)
    sd memblock
    ss mem
    sd size
    setcall memblock brace_blocks_get_memblock()
    call block_get_mem_size(memblock,#mem,#size)
    add mem size;sub mem (WORD)
    #
    sub size jumpoffset
    mult size -1
    if size<0xFFff8000
        call error("offset>(signed word size) error (at jump back)")
    endif
    #
    set mem# size
    sd byte=0x0000ff00;and byte size;div byte 0x100
    inc mem;set mem# byte
endfunction
function brace_blocks_remove_write_loopIfJumps_at_current_offset()
    while 1==1
        sd ifoffset
        setcall ifoffset brace_blocks_remove_write_offset()
        if ifoffset==0
            #also remove the type of loop
            call brace_blocks_counter_dec()
            return (void)
        endif
        call write_forward_offset(ifoffset)
    endwhile
endfunction

#function

#pointer
function action_code_parse_leftfunction(ss ac)
    #function definition
    ss pointer
    setcall pointer action_code_parse_deffunction(ac)
    if pointer!=ac
        return pointer
    endif
    #a call
    setcall ac action_code_parse_new_or_call(ac,(call_action_left))
    chars end=";"
    if ac#==end
        inc ac
    endif
    return ac
endfunction
#pointer
function action_code_parse_new_or_call(ss ac,sd type)
    ss pointer
    set pointer ac
    import "part_of_variable" part_of_variable
    ss last_dot=0
    sd bool
    setcall bool part_of_variable(pointer#)
    while bool==(TRUE)
        inc pointer
        setcall bool part_of_variable(pointer#)
        if bool==(FALSE)
            if pointer#==(Openingbracket)
                setcall pointer brackets_test(pointer)
            endif
            if pointer#==(Period)
                set last_dot pointer
                set bool (TRUE)
            elseif pointer#==(Openparenthesis)
                setcall pointer action_code_parse_function_detected(ac,last_dot,pointer,type)
                return pointer
            endelseif
        endif
    endwhile
    return ac
endfunction
#pointer
function action_code_parse_function_detected(ss start,ss last_dot,ss pointer,sd type)
    #function mark
    call action_code_set(type)
    set pointer# 0
    #function name + member
    if last_dot!=0
        set last_dot# 0
        inc last_dot
        call action_code_set(start)
        call action_code_set(last_dot)
    else
        call action_code_set(0)
        call action_code_set(start)
    endelse
    setcall pointer action_code_parse_function_arguments(pointer)
    call action_code_set((args_end))
    return pointer
endfunction
import "action_code_get" action_code_get
import "action_code_values_index" action_code_values_index
#pointer
function action_code_parse_function_arguments(ss pointer)
    #arguments
    sd math_values
    setcall math_values action_code_get()
    chars comma=","
    chars close=")"
    inc pointer
    if pointer#==close
        inc pointer
        return pointer
    endif
    #
        #need to swap the arguments for the call function
    const swapdata_max=128
    sd swapdata#swapdata_max
    sd cursor^swapdata
    sd all_nr=swapdata_max*:
    sd nr
    set nr all_nr
    add cursor nr
    sd start_data
    sd data
    setcall start_data action_code_get()
    set data start_data
    sd sizemark
    setcall sizemark action_code_values_index()
    sd sizepointer
    set sizepointer sizemark#
    #
    sd op=0
    while op!=close
        setcall pointer action_code_row_parse_tool_util(pointer,#op,comma,close)
        if op==0
            call error("close the function arguments sign expected: )")
        endif
        #
        sd dif
        set dif sizemark#
        sub dif sizepointer
        set sizepointer sizemark#
        mult dif (DWORD)
            #
        sub nr dif
        if nr<0
            call error("too many function arguments")
        endif
        sub cursor dif
        call memcpy(cursor,data,dif)
        add data dif
        #
    endwhile
    #
    sub all_nr nr
    call memcpy(start_data,cursor,all_nr)
    #
    return pointer
endfunction

#

#pointer
function action_code_parse_deffunction(ss ac)
    ss pointer
    setcall pointer str_expression_at_start(ac,"function")
    if pointer==ac
        return ac
    endif
    call action_code_set((function_action))
    ss name_start
    set name_start pointer
    chars startsign="("
    ss args
    setcall args strchr(pointer,startsign)
    if args==(NULL)
        call error("start sign expected at function definition: (")
    endif
    set args# 0
    call action_code_set(name_start)
    setcall pointer action_code_parse_function_defarguments(args)
    call action_code_set(0)
    #
    call brace_blocks_add_parse((function_marker))
    #loop until the function code is over
    sd index_atstart
    setcall index_atstart brace_blocks_counter()
    set index_atstart index_atstart#
    #
    setcall pointer action_code_row(pointer,(TRUE))
    sd index_current
    setcall index_current brace_blocks_counter()
    set index_current index_current#
    while index_atstart<=index_current
        if pointer#==0
            call error("A define function was unclosed")
        endif
        setcall pointer action_code_row(pointer,(FALSE))
        setcall index_current brace_blocks_counter()
        set index_current index_current#
    endwhile
    return pointer
endfunction
#pointer
function action_code_parse_function_defarguments(ss ac)
    str argsdelims=",)"
    chars close=")"
    inc ac
    if ac#==close
        inc ac
        return ac
    endif
    sd op=0
    while op!=close
        sd pos
        setcall pos strcspn(ac,argsdelims)
        call action_code_set(ac)
        add ac pos
        if ac#==0
            call error("close the function arguments sign expected: )")
        endif
        set op ac#
        set ac# 0
        inc ac
    endwhile
    return ac
endfunction

