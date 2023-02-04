

Const NULL=0
Const FALSE=0
Const TRUE=1

Const BYTE=1
Const WORD=2*BYTE
Const DWORD=2*WORD
Const QWORD=2*DWORD

#const INVALID_HANDLE=-1

Const SEEK_SET=0
Const SEEK_CUR=1
Const SEEK_END=2


const bitsperbyte=8



const BI_RGB=0



const eax=0
const ecx=1
const edx=2
#const ebx=3
#const esp=4
#const ebp=5
#const esi=6
#const edi=7

const to_regopcode=8
const to_mod=to_regopcode*8

#const mod_main=0
const mod_disp8=1*to_mod
#const mod_disp32=2*to_mod
const mod_reg=3*to_mod

