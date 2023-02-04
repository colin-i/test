Format ElfObj64

import "erbool" erbool
functionx erbool_get()
    ss p;setcall p erbool()
    return p#
endfunction

functionx erbool_reset()
    ss p;setcall p erbool()
    set p# 0
endfunction

include "../include/prog.h"

import "swf_mem" swf_mem
functionx freereset()
    #free and set initial null/-1.....
    call swf_mem((mem_exp_free))
endfunction