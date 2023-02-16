


format elfobj

#float and double add,sub and other operations
#we use a trick by placing the cpu asm with HEX language command

include "../_include/include.h"

import "getoneax" getoneax

##float

#float
function double_to_float(sd p_double)
    call fld_quad(p_double)
    sd value
    sd p_value^value
    call fstp(p_value)
    return value
endfunction

importx "_sscanf" sscanf

#float
function int_to_float(sd number)
    sd p_number^number
    call fild(p_number)
    call fstp(p_number)
    return number
endfunction

function float_to_int(sd number)
    sd p_number^number
    call fld(p_number)
    call fistp(p_number)
    return number
endfunction

#float
function str_to_float(ss strbytes)
    ss floatformat="%f"
    sd f
    sd p_f^f
    call sscanf(strbytes,floatformat,p_f)
    return f
endfunction

##double

#double
function float_to_double(sd float,sd p_d)
    sd p^float
    call fld(p)
    call fstp_quad(p_d)
endfunction

#int
function double_to_int(sd p_double)
    call fld_quad(p_double)
    sd value#2
    sd p_value^value
    call fstp_quad(p_value)
    call getoneax(p_value)

    #esi,eax up
    hex 0x56
    hex 0x50

    hex 0xf2
    #MOVUPS
    hex 0x0f,0x10,0x00
    hex 0xf2
    hex 0x0f,0x2c,0xf0

    hex 0x58
    #esi at [eax]
    hex 0x89,6*8

    #esi down
    hex 0x5e

    return value
endfunction

function str_to_double(ss strbytes,sd p_double)
    ss doubleformat="%lf"
    call sscanf(strbytes,doubleformat,p_double)
endfunction

function int_to_double(sd integer,sd p_double)
    sd p_int^integer
    call fild(p_int)
    call fstp_quad(p_double)
endfunction

##tricks

function fild(sd p_value)
    call getoneax(p_value)
    HEX 0xDB,0
endfunction
function fild_value(sd value)
    sd p_value^value
    call getoneax(p_value)
    HEX 0xDB,0
endfunction

function fld(sd p_value)
    call getoneax(p_value)
    HEX 0xD9,0x00
endfunction
function fld_quad(sd p_value)
    call getoneax(p_value)
    HEX 0xDD,0x00
endfunction

function fistp(sd p_value)
    call getoneax(p_value)
    HEX 0xDB,3*8
endfunction

function fstp(sd p_value)
    call getoneax(p_value)
    HEX 0xD9,0x18
endfunction
function fst_quad(sd p_value)
    call getoneax(p_value)
    HEX 0xDD,2*to_regopcode
endfunction
function fstp_quad(sd p_value)
    call getoneax(p_value)
    HEX 0xDD,0x18
endfunction

#
const fadd_op=0
function fiadd(sd p_value)
    call getoneax(p_value)
    HEX 0xDA,fadd_op*to_regopcode
endfunction
function float_add(sd A,sd B)
    sd p_A^A
    sd p_B^B
    call fld(p_A)
    call getoneax(p_B)
    HEX 0xD8,fadd_op*to_regopcode
    call fstp(p_A)
    return A
endfunction
function double_add(sd p_A,sd p_B)
    call fld_quad(p_A)
    call getoneax(p_B)
    HEX 0xDC,fadd_op*to_regopcode
    call fstp_quad(p_A)
endfunction
function fadd_quad(sd p_A)
    call getoneax(p_A)
    HEX 0xDC,fadd_op*to_regopcode
endfunction

const fsub_op=4
function float_sub(sd A,sd B)
    sd p_A^A
    sd p_B^B
    call fld(p_A)
    call getoneax(p_B)
    HEX 0xD8,fsub_op*to_regopcode
    call fstp(p_A)
    return A
endfunction
#function double_sub(sd p_A,sd p_B)
#    call fld_quad(p_A)
#    call getoneax(p_B)
#    HEX 0xDC,fsub_op*to_regopcode
#    call fstp_quad(p_A)
#endfunction
function fsub_quad(sd p_A)
    call getoneax(p_A)
    HEX 0xDC,fsub_op*to_regopcode
endfunction

const fmul_op=1
function fimul(sd p_value)
    call getoneax(p_value)
    HEX 0xDA,fmul_op*to_regopcode
endfunction
function float_mult(sd A,sd B)
    sd p_A^A
    sd p_B^B
    call fld(p_A)
    call getoneax(p_B)
    HEX 0xD8,fmul_op*to_regopcode
    call fstp(p_A)
    return A
endfunction
function double_mult(sd p_A,sd p_B)
    call fld_quad(p_A)
    call getoneax(p_B)
    HEX 0xDC,fmul_op*to_regopcode
    call fstp_quad(p_A)
endfunction
function fmul_quad(sd p_A)
    call getoneax(p_A)
    HEX 0xDC,fmul_op*to_regopcode
endfunction

const fdiv_op=6
function fidiv(sd p_value)
    call getoneax(p_value)
    HEX 0xDA,fdiv_op*to_regopcode
endfunction
function double_div(sd p_A,sd p_B)
    call fld_quad(p_A)
    call getoneax(p_B)
    HEX 0xDC,fdiv_op*to_regopcode
    call fstp_quad(p_A)
endfunction
function fdiv_quad(sd p_A)
    call getoneax(p_A)
    HEX 0xDC,fdiv_op*to_regopcode
endfunction



#
#bool
function fcom_quad_greater(sd p_A)
    sd aux
    sd value
    set aux p_A
    sd p_aux^aux
    #
    call getoneax(p_aux)
    #ecx eax
    hex 0x8b,ecx*to_regopcode|mod_reg|eax
    #eax [eax]
    hex 0x8b,0
    #fcom
    HEX 0xDC,2*to_regopcode
    #fstsw ax
    HEX 0xDF,0xE0
    #ecx +4
    hex 0x81,mod_reg|ecx,4,0,0,0
    #[ecx] eax
    hex 0x8b,ecx*to_regopcode|eax
    #
    and value 0x00004100
    if value==0
        return 1
    else
        return 0
    endelse
endfunction
#bool
function fcom_quad_greater_or_equal(sd p_A)
    sd aux
    sd value
    set aux p_A
    sd p_aux^aux
    #
    call getoneax(p_aux)
    #ecx eax
    hex 0x8b,ecx*to_regopcode|mod_reg|eax
    #eax [eax]
    hex 0x8b,0
    #fcom
    HEX 0xDC,2*to_regopcode
    #fstsw ax
    HEX 0xDF,0xE0
    #ecx +4
    hex 0x81,mod_reg|ecx,4,0,0,0
    #[ecx] eax
    hex 0x8b,ecx*to_regopcode|eax
    #
    and value 0x00000100
    if value==0
        return 1
    else
        return 0
    endelse
endfunction
