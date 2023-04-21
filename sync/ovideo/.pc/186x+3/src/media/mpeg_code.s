




format elfobj

include "../_include/include.h"

const MODE_INTRA=3

import "array_get_int16" array_get_int16
import "shl" shl
import "array_get_int" array_get_int

#bool
function mpeg_mb_code(sd cbp,sd acpred_direction,sd qcoeff,sd type)
    sd bool

    import "mpeg_file_mem_append" mpeg_file_mem_append
    import "mpeg_mem_bit" mpeg_mem_bit

    if type==(P_VOP)
        #not skip
        setcall bool mpeg_mem_bit(0)
        if bool!=1
            return 0
        endif
    endif

    const mb_mode=MODE_INTRA
    #write mcbpc
    sd mcbpc
    sd mb_cbp
    sd code
    sd len
    set mcbpc (mb_mode)
    set mb_cbp cbp
    if type==(I_VOP)
        div mcbpc 2
        and mcbpc 3

        and mb_cbp 3
        mult mb_cbp 4
        or mcbpc mb_cbp

        setcall code mcbpc_intra_tab(mcbpc,(VLC_code))
        setcall len mcbpc_intra_tab(mcbpc,(VLC_len))
    else
        and mcbpc 7

        and mb_cbp 3
        setcall mb_cbp shl(mb_cbp,3)
        or mcbpc mb_cbp

        setcall code mcbpc_inter_tab(mcbpc,(VLC_code))
        setcall len mcbpc_inter_tab(mcbpc,(VLC_len))
    endelse
    setcall bool mpeg_file_mem_append(code,len)
    if bool!=1
        return 0
    endif

    sd acpred
    if acpred_direction#!=0
        set acpred 1
    else
        set acpred 0
    endelse
    setcall bool mpeg_mem_bit(acpred)
    if bool!=1
        return 0
    endif

    #write cbpy
    sd cbp_y
    set cbp_y cbp
    div cbp_y 4

    setcall code cbpy_tab(cbp_y,(VLC_code))
    setcall len cbpy_tab(cbp_y,(VLC_len))
    setcall bool mpeg_file_mem_append(code,len)
    if bool!=1
        return 0
    endif

    #code block coeffs
    sd i=0
    sd ind
    while i<6
        set ind i
        mult ind 64
        setcall ind array_get_int16(qcoeff,ind)
        add ind 255
        if i<4
            setcall code dcy_tab(ind,(VLC_code))
            setcall len dcy_tab(ind,(VLC_len))
        else
            setcall code dcc_tab(ind,(VLC_code))
            setcall len dcc_tab(ind,(VLC_len))
        endelse
        setcall bool mpeg_file_mem_append(code,len)
        if bool!=1
            return 0
        endif

        sd value
        set value 5
        sub value i
        setcall value shl(1,value)
        and value cbp

        if value!=0
            set ind (64*int16)
            mult ind i
            sd qcoeff_cursor
            set qcoeff_cursor qcoeff
            add qcoeff_cursor ind

            setcall ind array_get_int(acpred_direction,i)

            setcall bool coef_intra_calc_code(qcoeff_cursor,ind)
            if bool!=1
                return 0
            endif
        endif

        inc i
    endwhile
    return 1
endfunction

function mcbpc_intra_tab(sd x,sd block)
#MCBPC Indexing by cbpc in first two bits, mode in last two.
#CBPC as in table 4/H.263, MB type (mode): 3 = 01, 4 = 10.
#Example: cbpc = 01 and mode = 4 gives index = 0110 = 6.
    chars mcbpc_intra_tab_data={0x01,0,0,0, 9, 0x01,0,0,0, 1, 0x01,0,0,0, 4, 0x00,0,0,0, 0}
    chars *                   ={0x00,0,0,0, 0, 0x01,0,0,0, 3, 0x01,0,0,0, 6, 0x00,0,0,0, 0}
    chars *                   ={0x00,0,0,0, 0, 0x02,0,0,0, 3, 0x02,0,0,0, 6, 0x00,0,0,0, 0}
    chars *                   ={0x00,0,0,0, 0, 0x03,0,0,0, 3, 0x03,0,0,0, 6}

    sd ind
    set ind x
    mult ind (VLC_size)
    add ind block

    sd mcbpc_intra^mcbpc_intra_tab_data
    add mcbpc_intra ind
    if block==(VLC_code)
        return mcbpc_intra#
    else
        ss byte
        set byte mcbpc_intra
        return byte#
    endelse
endfunction

function mcbpc_inter_tab(sd x,sd block)
    #MCBPC inter.
    #Addressing: 5 bit ccmmm (cc = CBPC, mmm = mode (1-4 binary))
    #29 entries
    chars mcbpc_inter_tab_data={0x01,0,0,0, 1, 0x03,0,0,0, 3, 0x02,0,0,0, 3, 0x03,0,0,0, 5, 0x04,0,0,0, 6, 0x01,0,0,0, 9, 0x00,0,0,0, 0, 0x00,0,0,0, 0}
    chars *                   ={0x03,0,0,0, 4, 0x07,0,0,0, 7, 0x05,0,0,0, 7, 0x04,0,0,0, 8, 0x04,0,0,0, 9, 0x00,0,0,0, 0, 0x00,0,0,0, 0, 0x00,0,0,0, 0}
    chars *                   ={0x02,0,0,0, 4, 0x06,0,0,0, 7, 0x04,0,0,0, 7, 0x03,0,0,0, 8, 0x03,0,0,0, 9, 0x00,0,0,0, 0, 0x00,0,0,0, 0, 0x00,0,0,0, 0}
    chars *                   ={0x05,0,0,0, 6, 0x05,0,0,0, 9, 0x05,0,0,0, 8, 0x03,0,0,0, 7, 0x02,0,0,0, 9}

    sd ind
    set ind x
    mult ind (VLC_size)
    add ind block

    sd mcbpc_inter^mcbpc_inter_tab_data
    add mcbpc_inter ind
    if block==(VLC_code)
        return mcbpc_inter#
    else
        ss byte
        set byte mcbpc_inter
        return byte#
    endelse
endfunction

function cbpy_tab(sd x,sd block)
    chars cbpy_data={3,0,0,0, 4, 5,0,0,0, 5, 4,0,0,0, 5, 9, 0,0,0, 4, 3,0,0,0, 5, 7,0,0,0, 4, 2,0,0,0, 6, 11,0,0,0, 4}
    chars *        ={2,0,0,0, 5, 3,0,0,0, 6, 5,0,0,0, 4, 10,0,0,0, 4, 4,0,0,0, 4, 8,0,0,0, 4, 6,0,0,0, 4, 3, 0,0,0, 2}

    sd ind
    set ind x
    mult ind (VLC_size)
    add ind block

    sd cbpy^cbpy_data
    add cbpy ind
    if block==(VLC_code)
        return cbpy#
    else
        ss byte
        set byte cbpy
        return byte#
    endelse
endfunction

function dcy_tab(sd x,sd block)
    chars dcy_tab_data={0x00,1,0,0, 15, 0x01,1,0,0, 15, 0x02,1,0,0, 15, 0x03,1,0,0, 15}
    chars *           ={0x04,1,0,0, 15, 0x05,1,0,0, 15, 0x06,1,0,0, 15, 0x07,1,0,0, 15}
    chars *           ={0x08,1,0,0, 15, 0x09,1,0,0, 15, 0x0a,1,0,0, 15, 0x0b,1,0,0, 15}
    chars *           ={0x0c,1,0,0, 15, 0x0d,1,0,0, 15, 0x0e,1,0,0, 15, 0x0f,1,0,0, 15}
    chars *           ={0x10,1,0,0, 15, 0x11,1,0,0, 15, 0x12,1,0,0, 15, 0x13,1,0,0, 15}
    chars *           ={0x14,1,0,0, 15, 0x15,1,0,0, 15, 0x16,1,0,0, 15, 0x17,1,0,0, 15}
    chars *           ={0x18,1,0,0, 15, 0x19,1,0,0, 15, 0x1a,1,0,0, 15, 0x1b,1,0,0, 15}
    chars *           ={0x1c,1,0,0, 15, 0x1d,1,0,0, 15, 0x1e,1,0,0, 15, 0x1f,1,0,0, 15}
    chars *           ={0x20,1,0,0, 15, 0x21,1,0,0, 15, 0x22,1,0,0, 15, 0x23,1,0,0, 15}
    chars *           ={0x24,1,0,0, 15, 0x25,1,0,0, 15, 0x26,1,0,0, 15, 0x27,1,0,0, 15}
    chars *           ={0x28,1,0,0, 15, 0x29,1,0,0, 15, 0x2a,1,0,0, 15, 0x2b,1,0,0, 15}
    chars *           ={0x2c,1,0,0, 15, 0x2d,1,0,0, 15, 0x2e,1,0,0, 15, 0x2f,1,0,0, 15}
    chars *           ={0x30,1,0,0, 15, 0x31,1,0,0, 15, 0x32,1,0,0, 15, 0x33,1,0,0, 15}
    chars *           ={0x34,1,0,0, 15, 0x35,1,0,0, 15, 0x36,1,0,0, 15, 0x37,1,0,0, 15}
    chars *           ={0x38,1,0,0, 15, 0x39,1,0,0, 15, 0x3a,1,0,0, 15, 0x3b,1,0,0, 15}
    chars *           ={0x3c,1,0,0, 15, 0x3d,1,0,0, 15, 0x3e,1,0,0, 15, 0x3f,1,0,0, 15}
    chars *           ={0x40,1,0,0, 15, 0x41,1,0,0, 15, 0x42,1,0,0, 15, 0x43,1,0,0, 15}
    chars *           ={0x44,1,0,0, 15, 0x45,1,0,0, 15, 0x46,1,0,0, 15, 0x47,1,0,0, 15}
    chars *           ={0x48,1,0,0, 15, 0x49,1,0,0, 15, 0x4a,1,0,0, 15, 0x4b,1,0,0, 15}
    chars *           ={0x4c,1,0,0, 15, 0x4d,1,0,0, 15, 0x4e,1,0,0, 15, 0x4f,1,0,0, 15}
    chars *           ={0x50,1,0,0, 15, 0x51,1,0,0, 15, 0x52,1,0,0, 15, 0x53,1,0,0, 15}
    chars *           ={0x54,1,0,0, 15, 0x55,1,0,0, 15, 0x56,1,0,0, 15, 0x57,1,0,0, 15}
    chars *           ={0x58,1,0,0, 15, 0x59,1,0,0, 15, 0x5a,1,0,0, 15, 0x5b,1,0,0, 15}
    chars *           ={0x5c,1,0,0, 15, 0x5d,1,0,0, 15, 0x5e,1,0,0, 15, 0x5f,1,0,0, 15}
    chars *           ={0x60,1,0,0, 15, 0x61,1,0,0, 15, 0x62,1,0,0, 15, 0x63,1,0,0, 15}
    chars *           ={0x64,1,0,0, 15, 0x65,1,0,0, 15, 0x66,1,0,0, 15, 0x67,1,0,0, 15}
    chars *           ={0x68,1,0,0, 15, 0x69,1,0,0, 15, 0x6a,1,0,0, 15, 0x6b,1,0,0, 15}
    chars *           ={0x6c,1,0,0, 15, 0x6d,1,0,0, 15, 0x6e,1,0,0, 15, 0x6f,1,0,0, 15}
    chars *           ={0x70,1,0,0, 15, 0x71,1,0,0, 15, 0x72,1,0,0, 15, 0x73,1,0,0, 15}
    chars *           ={0x74,1,0,0, 15, 0x75,1,0,0, 15, 0x76,1,0,0, 15, 0x77,1,0,0, 15}
    chars *           ={0x78,1,0,0, 15, 0x79,1,0,0, 15, 0x7a,1,0,0, 15, 0x7b,1,0,0, 15}
    chars *           ={0x7c,1,0,0, 15, 0x7d,1,0,0, 15, 0x7e,1,0,0, 15, 0x7f,1,0,0, 15}
    chars *           ={0x80,0,0,0, 13, 0x81,0,0,0, 13, 0x82,0,0,0, 13, 0x83,0,0,0, 13}
    chars *           ={0x84,0,0,0, 13, 0x85,0,0,0, 13, 0x86,0,0,0, 13, 0x87,0,0,0, 13}
    chars *           ={0x88,0,0,0, 13, 0x89,0,0,0, 13, 0x8a,0,0,0, 13, 0x8b,0,0,0, 13}
    chars *           ={0x8c,0,0,0, 13, 0x8d,0,0,0, 13, 0x8e,0,0,0, 13, 0x8f,0,0,0, 13}
    chars *           ={0x90,0,0,0, 13, 0x91,0,0,0, 13, 0x92,0,0,0, 13, 0x93,0,0,0, 13}
    chars *           ={0x94,0,0,0, 13, 0x95,0,0,0, 13, 0x96,0,0,0, 13, 0x97,0,0,0, 13}
    chars *           ={0x98,0,0,0, 13, 0x99,0,0,0, 13, 0x9a,0,0,0, 13, 0x9b,0,0,0, 13}
    chars *           ={0x9c,0,0,0, 13, 0x9d,0,0,0, 13, 0x9e,0,0,0, 13, 0x9f,0,0,0, 13}
    chars *           ={0xa0,0,0,0, 13, 0xa1,0,0,0, 13, 0xa2,0,0,0, 13, 0xa3,0,0,0, 13}
    chars *           ={0xa4,0,0,0, 13, 0xa5,0,0,0, 13, 0xa6,0,0,0, 13, 0xa7,0,0,0, 13}
    chars *           ={0xa8,0,0,0, 13, 0xa9,0,0,0, 13, 0xaa,0,0,0, 13, 0xab,0,0,0, 13}
    chars *           ={0xac,0,0,0, 13, 0xad,0,0,0, 13, 0xae,0,0,0, 13, 0xaf,0,0,0, 13}
    chars *           ={0xb0,0,0,0, 13, 0xb1,0,0,0, 13, 0xb2,0,0,0, 13, 0xb3,0,0,0, 13}
    chars *           ={0xb4,0,0,0, 13, 0xb5,0,0,0, 13, 0xb6,0,0,0, 13, 0xb7,0,0,0, 13}
    chars *           ={0xb8,0,0,0, 13, 0xb9,0,0,0, 13, 0xba,0,0,0, 13, 0xbb,0,0,0, 13}
    chars *           ={0xbc,0,0,0, 13, 0xbd,0,0,0, 13, 0xbe,0,0,0, 13, 0xbf,0,0,0, 13}
    chars *           ={0x40,0,0,0, 11, 0x41,0,0,0, 11, 0x42,0,0,0, 11, 0x43,0,0,0, 11}
    chars *           ={0x44,0,0,0, 11, 0x45,0,0,0, 11, 0x46,0,0,0, 11, 0x47,0,0,0, 11}
    chars *           ={0x48,0,0,0, 11, 0x49,0,0,0, 11, 0x4a,0,0,0, 11, 0x4b,0,0,0, 11}
    chars *           ={0x4c,0,0,0, 11, 0x4d,0,0,0, 11, 0x4e,0,0,0, 11, 0x4f,0,0,0, 11}
    chars *           ={0x50,0,0,0, 11, 0x51,0,0,0, 11, 0x52,0,0,0, 11, 0x53,0,0,0, 11}
    chars *           ={0x54,0,0,0, 11, 0x55,0,0,0, 11, 0x56,0,0,0, 11, 0x57,0,0,0, 11}
    chars *           ={0x58,0,0,0, 11, 0x59,0,0,0, 11, 0x5a,0,0,0, 11, 0x5b,0,0,0, 11}
    chars *           ={0x5c,0,0,0, 11, 0x5d,0,0,0, 11, 0x5e,0,0,0, 11, 0x5f,0,0,0, 11}
    chars *           ={0x20,0,0,0, 9,  0x21,0,0,0, 9,  0x22,0,0,0, 9,  0x23,0,0,0, 9}
    chars *           ={0x24,0,0,0, 9,  0x25,0,0,0, 9,  0x26,0,0,0, 9,  0x27,0,0,0, 9}
    chars *           ={0x28,0,0,0, 9,  0x29,0,0,0, 9,  0x2a,0,0,0, 9,  0x2b,0,0,0, 9}
    chars *           ={0x2c,0,0,0, 9,  0x2d,0,0,0, 9,  0x2e,0,0,0, 9,  0x2f,0,0,0, 9}
    chars *           ={0x10,0,0,0, 7,  0x11,0,0,0, 7,  0x12,0,0,0, 7,  0x13,0,0,0, 7}
    chars *           ={0x14,0,0,0, 7,  0x15,0,0,0, 7,  0x16,0,0,0, 7,  0x17,0,0,0, 7}
    chars *           ={0x10,0,0,0, 6,  0x11,0,0,0, 6,  0x12,0,0,0, 6,  0x13,0,0,0, 6}
    chars *           ={0x08,0,0,0, 4,  0x09,0,0,0, 4,  0x06,0,0,0, 3,  0x03,0,0,0, 3}
    chars *           ={0x07,0,0,0, 3,  0x0a,0,0,0, 4,  0x0b,0,0,0, 4,  0x14,0,0,0, 6}
    chars *           ={0x15,0,0,0, 6,  0x16,0,0,0, 6,  0x17,0,0,0, 6,  0x18,0,0,0, 7}
    chars *           ={0x19,0,0,0, 7,  0x1a,0,0,0, 7,  0x1b,0,0,0, 7,  0x1c,0,0,0, 7}
    chars *           ={0x1d,0,0,0, 7,  0x1e,0,0,0, 7,  0x1f,0,0,0, 7,  0x30,0,0,0, 9}
    chars *           ={0x31,0,0,0, 9,  0x32,0,0,0, 9,  0x33,0,0,0, 9,  0x34,0,0,0, 9}
    chars *           ={0x35,0,0,0, 9,  0x36,0,0,0, 9,  0x37,0,0,0, 9,  0x38,0,0,0, 9}
    chars *           ={0x39,0,0,0, 9,  0x3a,0,0,0, 9,  0x3b,0,0,0, 9,  0x3c,0,0,0, 9}
    chars *           ={0x3d,0,0,0, 9,  0x3e,0,0,0, 9,  0x3f,0,0,0, 9,  0x60,0,0,0, 11}
    chars *           ={0x61,0,0,0, 11, 0x62,0,0,0, 11, 0x63,0,0,0, 11, 0x64,0,0,0, 11}
    chars *           ={0x65,0,0,0, 11, 0x66,0,0,0, 11, 0x67,0,0,0, 11, 0x68,0,0,0, 11}
    chars *           ={0x69,0,0,0, 11, 0x6a,0,0,0, 11, 0x6b,0,0,0, 11, 0x6c,0,0,0, 11}
    chars *           ={0x6d,0,0,0, 11, 0x6e,0,0,0, 11, 0x6f,0,0,0, 11, 0x70,0,0,0, 11}
    chars *           ={0x71,0,0,0, 11, 0x72,0,0,0, 11, 0x73,0,0,0, 11, 0x74,0,0,0, 11}
    chars *           ={0x75,0,0,0, 11, 0x76,0,0,0, 11, 0x77,0,0,0, 11, 0x78,0,0,0, 11}
    chars *           ={0x79,0,0,0, 11, 0x7a,0,0,0, 11, 0x7b,0,0,0, 11, 0x7c,0,0,0, 11}
    chars *           ={0x7d,0,0,0, 11, 0x7e,0,0,0, 11, 0x7f,0,0,0, 11, 0xc0,0,0,0, 13}
    chars *           ={0xc1,0,0,0, 13, 0xc2,0,0,0, 13, 0xc3,0,0,0, 13, 0xc4,0,0,0, 13}
    chars *           ={0xc5,0,0,0, 13, 0xc6,0,0,0, 13, 0xc7,0,0,0, 13, 0xc8,0,0,0, 13}
    chars *           ={0xc9,0,0,0, 13, 0xca,0,0,0, 13, 0xcb,0,0,0, 13, 0xcc,0,0,0, 13}
    chars *           ={0xcd,0,0,0, 13, 0xce,0,0,0, 13, 0xcf,0,0,0, 13, 0xd0,0,0,0, 13}
    chars *           ={0xd1,0,0,0, 13, 0xd2,0,0,0, 13, 0xd3,0,0,0, 13, 0xd4,0,0,0, 13}
    chars *           ={0xd5,0,0,0, 13, 0xd6,0,0,0, 13, 0xd7,0,0,0, 13, 0xd8,0,0,0, 13}
    chars *           ={0xd9,0,0,0, 13, 0xda,0,0,0, 13, 0xdb,0,0,0, 13, 0xdc,0,0,0, 13}
    chars *           ={0xdd,0,0,0, 13, 0xde,0,0,0, 13, 0xdf,0,0,0, 13, 0xe0,0,0,0, 13}
    chars *           ={0xe1,0,0,0, 13, 0xe2,0,0,0, 13, 0xe3,0,0,0, 13, 0xe4,0,0,0, 13}
    chars *           ={0xe5,0,0,0, 13, 0xe6,0,0,0, 13, 0xe7,0,0,0, 13, 0xe8,0,0,0, 13}
    chars *           ={0xe9,0,0,0, 13, 0xea,0,0,0, 13, 0xeb,0,0,0, 13, 0xec,0,0,0, 13}
    chars *           ={0xed,0,0,0, 13, 0xee,0,0,0, 13, 0xef,0,0,0, 13, 0xf0,0,0,0, 13}
    chars *           ={0xf1,0,0,0, 13, 0xf2,0,0,0, 13, 0xf3,0,0,0, 13, 0xf4,0,0,0, 13}
    chars *           ={0xf5,0,0,0, 13, 0xf6,0,0,0, 13, 0xf7,0,0,0, 13, 0xf8,0,0,0, 13}
    chars *           ={0xf9,0,0,0, 13, 0xfa,0,0,0, 13, 0xfb,0,0,0, 13, 0xfc,0,0,0, 13}
    chars *           ={0xfd,0,0,0, 13, 0xfe,0,0,0, 13, 0xff,0,0,0, 13, 0x80,1,0,0, 15}
    chars *           ={0x81,1,0,0, 15, 0x82,1,0,0, 15, 0x83,1,0,0, 15, 0x84,1,0,0, 15}
    chars *           ={0x85,1,0,0, 15, 0x86,1,0,0, 15, 0x87,1,0,0, 15, 0x88,1,0,0, 15}
    chars *           ={0x89,1,0,0, 15, 0x8a,1,0,0, 15, 0x8b,1,0,0, 15, 0x8c,1,0,0, 15}
    chars *           ={0x8d,1,0,0, 15, 0x8e,1,0,0, 15, 0x8f,1,0,0, 15, 0x90,1,0,0, 15}
    chars *           ={0x91,1,0,0, 15, 0x92,1,0,0, 15, 0x93,1,0,0, 15, 0x94,1,0,0, 15}
    chars *           ={0x95,1,0,0, 15, 0x96,1,0,0, 15, 0x97,1,0,0, 15, 0x98,1,0,0, 15}
    chars *           ={0x99,1,0,0, 15, 0x9a,1,0,0, 15, 0x9b,1,0,0, 15, 0x9c,1,0,0, 15}
    chars *           ={0x9d,1,0,0, 15, 0x9e,1,0,0, 15, 0x9f,1,0,0, 15, 0xa0,1,0,0, 15}
    chars *           ={0xa1,1,0,0, 15, 0xa2,1,0,0, 15, 0xa3,1,0,0, 15, 0xa4,1,0,0, 15}
    chars *           ={0xa5,1,0,0, 15, 0xa6,1,0,0, 15, 0xa7,1,0,0, 15, 0xa8,1,0,0, 15}
    chars *           ={0xa9,1,0,0, 15, 0xaa,1,0,0, 15, 0xab,1,0,0, 15, 0xac,1,0,0, 15}
    chars *           ={0xad,1,0,0, 15, 0xae,1,0,0, 15, 0xaf,1,0,0, 15, 0xb0,1,0,0, 15}
    chars *           ={0xb1,1,0,0, 15, 0xb2,1,0,0, 15, 0xb3,1,0,0, 15, 0xb4,1,0,0, 15}
    chars *           ={0xb5,1,0,0, 15, 0xb6,1,0,0, 15, 0xb7,1,0,0, 15, 0xb8,1,0,0, 15}
    chars *           ={0xb9,1,0,0, 15, 0xba,1,0,0, 15, 0xbb,1,0,0, 15, 0xbc,1,0,0, 15}
    chars *           ={0xbd,1,0,0, 15, 0xbe,1,0,0, 15, 0xbf,1,0,0, 15, 0xc0,1,0,0, 15}
    chars *           ={0xc1,1,0,0, 15, 0xc2,1,0,0, 15, 0xc3,1,0,0, 15, 0xc4,1,0,0, 15}
    chars *           ={0xc5,1,0,0, 15, 0xc6,1,0,0, 15, 0xc7,1,0,0, 15, 0xc8,1,0,0, 15}
    chars *           ={0xc9,1,0,0, 15, 0xca,1,0,0, 15, 0xcb,1,0,0, 15, 0xcc,1,0,0, 15}
    chars *           ={0xcd,1,0,0, 15, 0xce,1,0,0, 15, 0xcf,1,0,0, 15, 0xd0,1,0,0, 15}
    chars *           ={0xd1,1,0,0, 15, 0xd2,1,0,0, 15, 0xd3,1,0,0, 15, 0xd4,1,0,0, 15}
    chars *           ={0xd5,1,0,0, 15, 0xd6,1,0,0, 15, 0xd7,1,0,0, 15, 0xd8,1,0,0, 15}
    chars *           ={0xd9,1,0,0, 15, 0xda,1,0,0, 15, 0xdb,1,0,0, 15, 0xdc,1,0,0, 15}
    chars *           ={0xdd,1,0,0, 15, 0xde,1,0,0, 15, 0xdf,1,0,0, 15, 0xe0,1,0,0, 15}
    chars *           ={0xe1,1,0,0, 15, 0xe2,1,0,0, 15, 0xe3,1,0,0, 15, 0xe4,1,0,0, 15}
    chars *           ={0xe5,1,0,0, 15, 0xe6,1,0,0, 15, 0xe7,1,0,0, 15, 0xe8,1,0,0, 15}
    chars *           ={0xe9,1,0,0, 15, 0xea,1,0,0, 15, 0xeb,1,0,0, 15, 0xec,1,0,0, 15}
    chars *           ={0xed,1,0,0, 15, 0xee,1,0,0, 15, 0xef,1,0,0, 15, 0xf0,1,0,0, 15}
    chars *           ={0xf1,1,0,0, 15, 0xf2,1,0,0, 15, 0xf3,1,0,0, 15, 0xf4,1,0,0, 15}
    chars *           ={0xf5,1,0,0, 15, 0xf6,1,0,0, 15, 0xf7,1,0,0, 15, 0xf8,1,0,0, 15}
    chars *           ={0xf9,1,0,0, 15, 0xfa,1,0,0, 15, 0xfb,1,0,0, 15, 0xfc,1,0,0, 15}
    chars *           ={0xfd,1,0,0, 15, 0xfe,1,0,0, 15, 0xff,1,0,0, 15}

    sd ind
    set ind x
    mult ind (VLC_size)
    add ind block

    sd dcy^dcy_tab_data
    add dcy ind
    if block==(VLC_code)
        return dcy#
    else
        ss byte
        set byte dcy
        return byte#
    endelse
endfunction

function dcc_tab(sd x,sd block)
    chars dcc_tab_data={0x00,1,0,0, 16, 0x01,1,0,0, 16, 0x02,1,0,0, 16, 0x03,1,0,0, 16}
    chars *      ={0x04,1,0,0, 16, 0x05,1,0,0, 16, 0x06,1,0,0, 16, 0x07,1,0,0, 16}
    chars *      ={0x08,1,0,0, 16, 0x09,1,0,0, 16, 0x0a,1,0,0, 16, 0x0b,1,0,0, 16}
    chars *      ={0x0c,1,0,0, 16, 0x0d,1,0,0, 16, 0x0e,1,0,0, 16, 0x0f,1,0,0, 16}
    chars *      ={0x10,1,0,0, 16, 0x11,1,0,0, 16, 0x12,1,0,0, 16, 0x13,1,0,0, 16}
    chars *      ={0x14,1,0,0, 16, 0x15,1,0,0, 16, 0x16,1,0,0, 16, 0x17,1,0,0, 16}
    chars *      ={0x18,1,0,0, 16, 0x19,1,0,0, 16, 0x1a,1,0,0, 16, 0x1b,1,0,0, 16}
    chars *      ={0x1c,1,0,0, 16, 0x1d,1,0,0, 16, 0x1e,1,0,0, 16, 0x1f,1,0,0, 16}
    chars *      ={0x20,1,0,0, 16, 0x21,1,0,0, 16, 0x22,1,0,0, 16, 0x23,1,0,0, 16}
    chars *      ={0x24,1,0,0, 16, 0x25,1,0,0, 16, 0x26,1,0,0, 16, 0x27,1,0,0, 16}
    chars *      ={0x28,1,0,0, 16, 0x29,1,0,0, 16, 0x2a,1,0,0, 16, 0x2b,1,0,0, 16}
    chars *      ={0x2c,1,0,0, 16, 0x2d,1,0,0, 16, 0x2e,1,0,0, 16, 0x2f,1,0,0, 16}
    chars *      ={0x30,1,0,0, 16, 0x31,1,0,0, 16, 0x32,1,0,0, 16, 0x33,1,0,0, 16}
    chars *      ={0x34,1,0,0, 16, 0x35,1,0,0, 16, 0x36,1,0,0, 16, 0x37,1,0,0, 16}
    chars *      ={0x38,1,0,0, 16, 0x39,1,0,0, 16, 0x3a,1,0,0, 16, 0x3b,1,0,0, 16}
    chars *      ={0x3c,1,0,0, 16, 0x3d,1,0,0, 16, 0x3e,1,0,0, 16, 0x3f,1,0,0, 16}
    chars *      ={0x40,1,0,0, 16, 0x41,1,0,0, 16, 0x42,1,0,0, 16, 0x43,1,0,0, 16}
    chars *      ={0x44,1,0,0, 16, 0x45,1,0,0, 16, 0x46,1,0,0, 16, 0x47,1,0,0, 16}
    chars *      ={0x48,1,0,0, 16, 0x49,1,0,0, 16, 0x4a,1,0,0, 16, 0x4b,1,0,0, 16}
    chars *      ={0x4c,1,0,0, 16, 0x4d,1,0,0, 16, 0x4e,1,0,0, 16, 0x4f,1,0,0, 16}
    chars *      ={0x50,1,0,0, 16, 0x51,1,0,0, 16, 0x52,1,0,0, 16, 0x53,1,0,0, 16}
    chars *      ={0x54,1,0,0, 16, 0x55,1,0,0, 16, 0x56,1,0,0, 16, 0x57,1,0,0, 16}
    chars *      ={0x58,1,0,0, 16, 0x59,1,0,0, 16, 0x5a,1,0,0, 16, 0x5b,1,0,0, 16}
    chars *      ={0x5c,1,0,0, 16, 0x5d,1,0,0, 16, 0x5e,1,0,0, 16, 0x5f,1,0,0, 16}
    chars *      ={0x60,1,0,0, 16, 0x61,1,0,0, 16, 0x62,1,0,0, 16, 0x63,1,0,0, 16}
    chars *      ={0x64,1,0,0, 16, 0x65,1,0,0, 16, 0x66,1,0,0, 16, 0x67,1,0,0, 16}
    chars *      ={0x68,1,0,0, 16, 0x69,1,0,0, 16, 0x6a,1,0,0, 16, 0x6b,1,0,0, 16}
    chars *      ={0x6c,1,0,0, 16, 0x6d,1,0,0, 16, 0x6e,1,0,0, 16, 0x6f,1,0,0, 16}
    chars *      ={0x70,1,0,0, 16, 0x71,1,0,0, 16, 0x72,1,0,0, 16, 0x73,1,0,0, 16}
    chars *      ={0x74,1,0,0, 16, 0x75,1,0,0, 16, 0x76,1,0,0, 16, 0x77,1,0,0, 16}
    chars *      ={0x78,1,0,0, 16, 0x79,1,0,0, 16, 0x7a,1,0,0, 16, 0x7b,1,0,0, 16}
    chars *      ={0x7c,1,0,0, 16, 0x7d,1,0,0, 16, 0x7e,1,0,0, 16, 0x7f,1,0,0, 16}
    chars *      ={0x80,0,0,0, 14, 0x81,0,0,0, 14, 0x82,0,0,0, 14, 0x83,0,0,0, 14}
    chars *      ={0x84,0,0,0, 14, 0x85,0,0,0, 14, 0x86,0,0,0, 14, 0x87,0,0,0, 14}
    chars *      ={0x88,0,0,0, 14, 0x89,0,0,0, 14, 0x8a,0,0,0, 14, 0x8b,0,0,0, 14}
    chars *      ={0x8c,0,0,0, 14, 0x8d,0,0,0, 14, 0x8e,0,0,0, 14, 0x8f,0,0,0, 14}
    chars *      ={0x90,0,0,0, 14, 0x91,0,0,0, 14, 0x92,0,0,0, 14, 0x93,0,0,0, 14}
    chars *      ={0x94,0,0,0, 14, 0x95,0,0,0, 14, 0x96,0,0,0, 14, 0x97,0,0,0, 14}
    chars *      ={0x98,0,0,0, 14, 0x99,0,0,0, 14, 0x9a,0,0,0, 14, 0x9b,0,0,0, 14}
    chars *      ={0x9c,0,0,0, 14, 0x9d,0,0,0, 14, 0x9e,0,0,0, 14, 0x9f,0,0,0, 14}
    chars *      ={0xa0,0,0,0, 14, 0xa1,0,0,0, 14, 0xa2,0,0,0, 14, 0xa3,0,0,0, 14}
    chars *      ={0xa4,0,0,0, 14, 0xa5,0,0,0, 14, 0xa6,0,0,0, 14, 0xa7,0,0,0, 14}
    chars *      ={0xa8,0,0,0, 14, 0xa9,0,0,0, 14, 0xaa,0,0,0, 14, 0xab,0,0,0, 14}
    chars *      ={0xac,0,0,0, 14, 0xad,0,0,0, 14, 0xae,0,0,0, 14, 0xaf,0,0,0, 14}
    chars *      ={0xb0,0,0,0, 14, 0xb1,0,0,0, 14, 0xb2,0,0,0, 14, 0xb3,0,0,0, 14}
    chars *      ={0xb4,0,0,0, 14, 0xb5,0,0,0, 14, 0xb6,0,0,0, 14, 0xb7,0,0,0, 14}
    chars *      ={0xb8,0,0,0, 14, 0xb9,0,0,0, 14, 0xba,0,0,0, 14, 0xbb,0,0,0, 14}
    chars *      ={0xbc,0,0,0, 14, 0xbd,0,0,0, 14, 0xbe,0,0,0, 14, 0xbf,0,0,0, 14}
    chars *      ={0x40,0,0,0, 12, 0x41,0,0,0, 12, 0x42,0,0,0, 12, 0x43,0,0,0, 12}
    chars *      ={0x44,0,0,0, 12, 0x45,0,0,0, 12, 0x46,0,0,0, 12, 0x47,0,0,0, 12}
    chars *      ={0x48,0,0,0, 12, 0x49,0,0,0, 12, 0x4a,0,0,0, 12, 0x4b,0,0,0, 12}
    chars *      ={0x4c,0,0,0, 12, 0x4d,0,0,0, 12, 0x4e,0,0,0, 12, 0x4f,0,0,0, 12}
    chars *      ={0x50,0,0,0, 12, 0x51,0,0,0, 12, 0x52,0,0,0, 12, 0x53,0,0,0, 12}
    chars *      ={0x54,0,0,0, 12, 0x55,0,0,0, 12, 0x56,0,0,0, 12, 0x57,0,0,0, 12}
    chars *      ={0x58,0,0,0, 12, 0x59,0,0,0, 12, 0x5a,0,0,0, 12, 0x5b,0,0,0, 12}
    chars *      ={0x5c,0,0,0, 12, 0x5d,0,0,0, 12, 0x5e,0,0,0, 12, 0x5f,0,0,0, 12}
    chars *      ={0x20,0,0,0, 10, 0x21,0,0,0, 10, 0x22,0,0,0, 10, 0x23,0,0,0, 10}
    chars *      ={0x24,0,0,0, 10, 0x25,0,0,0, 10, 0x26,0,0,0, 10, 0x27,0,0,0, 10}
    chars *      ={0x28,0,0,0, 10, 0x29,0,0,0, 10, 0x2a,0,0,0, 10, 0x2b,0,0,0, 10}
    chars *      ={0x2c,0,0,0, 10, 0x2d,0,0,0, 10, 0x2e,0,0,0, 10, 0x2f,0,0,0, 10}
    chars *      ={0x10,0,0,0, 8,  0x11,0,0,0, 8,  0x12,0,0,0, 8,  0x13,0,0,0, 8}
    chars *      ={0x14,0,0,0, 8,  0x15,0,0,0, 8,  0x16,0,0,0, 8,  0x17,0,0,0, 8}
    chars *      ={0x08,0,0,0, 6,  0x09,0,0,0, 6,  0x0a,0,0,0, 6,  0x0b,0,0,0, 6}
    chars *      ={0x04,0,0,0, 4,  0x05,0,0,0, 4,  0x04,0,0,0, 3,  0x03,0,0,0, 2}
    chars *      ={0x05,0,0,0, 3,  0x06,0,0,0, 4,  0x07,0,0,0, 4,  0x0c,0,0,0, 6}
    chars *      ={0x0d,0,0,0, 6,  0x0e,0,0,0, 6,  0x0f,0,0,0, 6,  0x18,0,0,0, 8}
    chars *      ={0x19,0,0,0, 8,  0x1a,0,0,0, 8,  0x1b,0,0,0, 8,  0x1c,0,0,0, 8}
    chars *      ={0x1d,0,0,0, 8,  0x1e,0,0,0, 8,  0x1f,0,0,0, 8,  0x30,0,0,0, 10}
    chars *      ={0x31,0,0,0, 10, 0x32,0,0,0, 10, 0x33,0,0,0, 10, 0x34,0,0,0, 10}
    chars *      ={0x35,0,0,0, 10, 0x36,0,0,0, 10, 0x37,0,0,0, 10, 0x38,0,0,0, 10}
    chars *      ={0x39,0,0,0, 10, 0x3a,0,0,0, 10, 0x3b,0,0,0, 10, 0x3c,0,0,0, 10}
    chars *      ={0x3d,0,0,0, 10, 0x3e,0,0,0, 10, 0x3f,0,0,0, 10, 0x60,0,0,0, 12}
    chars *      ={0x61,0,0,0, 12, 0x62,0,0,0, 12, 0x63,0,0,0, 12, 0x64,0,0,0, 12}
    chars *      ={0x65,0,0,0, 12, 0x66,0,0,0, 12, 0x67,0,0,0, 12, 0x68,0,0,0, 12}
    chars *      ={0x69,0,0,0, 12, 0x6a,0,0,0, 12, 0x6b,0,0,0, 12, 0x6c,0,0,0, 12}
    chars *      ={0x6d,0,0,0, 12, 0x6e,0,0,0, 12, 0x6f,0,0,0, 12, 0x70,0,0,0, 12}
    chars *      ={0x71,0,0,0, 12, 0x72,0,0,0, 12, 0x73,0,0,0, 12, 0x74,0,0,0, 12}
    chars *      ={0x75,0,0,0, 12, 0x76,0,0,0, 12, 0x77,0,0,0, 12, 0x78,0,0,0, 12}
    chars *      ={0x79,0,0,0, 12, 0x7a,0,0,0, 12, 0x7b,0,0,0, 12, 0x7c,0,0,0, 12}
    chars *      ={0x7d,0,0,0, 12, 0x7e,0,0,0, 12, 0x7f,0,0,0, 12, 0xc0,0,0,0, 14}
    chars *      ={0xc1,0,0,0, 14, 0xc2,0,0,0, 14, 0xc3,0,0,0, 14, 0xc4,0,0,0, 14}
    chars *      ={0xc5,0,0,0, 14, 0xc6,0,0,0, 14, 0xc7,0,0,0, 14, 0xc8,0,0,0, 14}
    chars *      ={0xc9,0,0,0, 14, 0xca,0,0,0, 14, 0xcb,0,0,0, 14, 0xcc,0,0,0, 14}
    chars *      ={0xcd,0,0,0, 14, 0xce,0,0,0, 14, 0xcf,0,0,0, 14, 0xd0,0,0,0, 14}
    chars *      ={0xd1,0,0,0, 14, 0xd2,0,0,0, 14, 0xd3,0,0,0, 14, 0xd4,0,0,0, 14}
    chars *      ={0xd5,0,0,0, 14, 0xd6,0,0,0, 14, 0xd7,0,0,0, 14, 0xd8,0,0,0, 14}
    chars *      ={0xd9,0,0,0, 14, 0xda,0,0,0, 14, 0xdb,0,0,0, 14, 0xdc,0,0,0, 14}
    chars *      ={0xdd,0,0,0, 14, 0xde,0,0,0, 14, 0xdf,0,0,0, 14, 0xe0,0,0,0, 14}
    chars *      ={0xe1,0,0,0, 14, 0xe2,0,0,0, 14, 0xe3,0,0,0, 14, 0xe4,0,0,0, 14}
    chars *      ={0xe5,0,0,0, 14, 0xe6,0,0,0, 14, 0xe7,0,0,0, 14, 0xe8,0,0,0, 14}
    chars *      ={0xe9,0,0,0, 14, 0xea,0,0,0, 14, 0xeb,0,0,0, 14, 0xec,0,0,0, 14}
    chars *      ={0xed,0,0,0, 14, 0xee,0,0,0, 14, 0xef,0,0,0, 14, 0xf0,0,0,0, 14}
    chars *      ={0xf1,0,0,0, 14, 0xf2,0,0,0, 14, 0xf3,0,0,0, 14, 0xf4,0,0,0, 14}
    chars *      ={0xf5,0,0,0, 14, 0xf6,0,0,0, 14, 0xf7,0,0,0, 14, 0xf8,0,0,0, 14}
    chars *      ={0xf9,0,0,0, 14, 0xfa,0,0,0, 14, 0xfb,0,0,0, 14, 0xfc,0,0,0, 14}
    chars *      ={0xfd,0,0,0, 14, 0xfe,0,0,0, 14, 0xff,0,0,0, 14, 0x80,1,0,0, 16}
    chars *      ={0x81,1,0,0, 16, 0x82,1,0,0, 16, 0x83,1,0,0, 16, 0x84,1,0,0, 16}
    chars *      ={0x85,1,0,0, 16, 0x86,1,0,0, 16, 0x87,1,0,0, 16, 0x88,1,0,0, 16}
    chars *      ={0x89,1,0,0, 16, 0x8a,1,0,0, 16, 0x8b,1,0,0, 16, 0x8c,1,0,0, 16}
    chars *      ={0x8d,1,0,0, 16, 0x8e,1,0,0, 16, 0x8f,1,0,0, 16, 0x90,1,0,0, 16}
    chars *      ={0x91,1,0,0, 16, 0x92,1,0,0, 16, 0x93,1,0,0, 16, 0x94,1,0,0, 16}
    chars *      ={0x95,1,0,0, 16, 0x96,1,0,0, 16, 0x97,1,0,0, 16, 0x98,1,0,0, 16}
    chars *      ={0x99,1,0,0, 16, 0x9a,1,0,0, 16, 0x9b,1,0,0, 16, 0x9c,1,0,0, 16}
    chars *      ={0x9d,1,0,0, 16, 0x9e,1,0,0, 16, 0x9f,1,0,0, 16, 0xa0,1,0,0, 16}
    chars *      ={0xa1,1,0,0, 16, 0xa2,1,0,0, 16, 0xa3,1,0,0, 16, 0xa4,1,0,0, 16}
    chars *      ={0xa5,1,0,0, 16, 0xa6,1,0,0, 16, 0xa7,1,0,0, 16, 0xa8,1,0,0, 16}
    chars *      ={0xa9,1,0,0, 16, 0xaa,1,0,0, 16, 0xab,1,0,0, 16, 0xac,1,0,0, 16}
    chars *      ={0xad,1,0,0, 16, 0xae,1,0,0, 16, 0xaf,1,0,0, 16, 0xb0,1,0,0, 16}
    chars *      ={0xb1,1,0,0, 16, 0xb2,1,0,0, 16, 0xb3,1,0,0, 16, 0xb4,1,0,0, 16}
    chars *      ={0xb5,1,0,0, 16, 0xb6,1,0,0, 16, 0xb7,1,0,0, 16, 0xb8,1,0,0, 16}
    chars *      ={0xb9,1,0,0, 16, 0xba,1,0,0, 16, 0xbb,1,0,0, 16, 0xbc,1,0,0, 16}
    chars *      ={0xbd,1,0,0, 16, 0xbe,1,0,0, 16, 0xbf,1,0,0, 16, 0xc0,1,0,0, 16}
    chars *      ={0xc1,1,0,0, 16, 0xc2,1,0,0, 16, 0xc3,1,0,0, 16, 0xc4,1,0,0, 16}
    chars *      ={0xc5,1,0,0, 16, 0xc6,1,0,0, 16, 0xc7,1,0,0, 16, 0xc8,1,0,0, 16}
    chars *      ={0xc9,1,0,0, 16, 0xca,1,0,0, 16, 0xcb,1,0,0, 16, 0xcc,1,0,0, 16}
    chars *      ={0xcd,1,0,0, 16, 0xce,1,0,0, 16, 0xcf,1,0,0, 16, 0xd0,1,0,0, 16}
    chars *      ={0xd1,1,0,0, 16, 0xd2,1,0,0, 16, 0xd3,1,0,0, 16, 0xd4,1,0,0, 16}
    chars *      ={0xd5,1,0,0, 16, 0xd6,1,0,0, 16, 0xd7,1,0,0, 16, 0xd8,1,0,0, 16}
    chars *      ={0xd9,1,0,0, 16, 0xda,1,0,0, 16, 0xdb,1,0,0, 16, 0xdc,1,0,0, 16}
    chars *      ={0xdd,1,0,0, 16, 0xde,1,0,0, 16, 0xdf,1,0,0, 16, 0xe0,1,0,0, 16}
    chars *      ={0xe1,1,0,0, 16, 0xe2,1,0,0, 16, 0xe3,1,0,0, 16, 0xe4,1,0,0, 16}
    chars *      ={0xe5,1,0,0, 16, 0xe6,1,0,0, 16, 0xe7,1,0,0, 16, 0xe8,1,0,0, 16}
    chars *      ={0xe9,1,0,0, 16, 0xea,1,0,0, 16, 0xeb,1,0,0, 16, 0xec,1,0,0, 16}
    chars *      ={0xed,1,0,0, 16, 0xee,1,0,0, 16, 0xef,1,0,0, 16, 0xf0,1,0,0, 16}
    chars *      ={0xf1,1,0,0, 16, 0xf2,1,0,0, 16, 0xf3,1,0,0, 16, 0xf4,1,0,0, 16}
    chars *      ={0xf5,1,0,0, 16, 0xf6,1,0,0, 16, 0xf7,1,0,0, 16, 0xf8,1,0,0, 16}
    chars *      ={0xf9,1,0,0, 16, 0xfa,1,0,0, 16, 0xfb,1,0,0, 16, 0xfc,1,0,0, 16}
    chars *      ={0xfd,1,0,0, 16, 0xfe,1,0,0, 16, 0xff,1,0,0, 16}

    sd ind
    set ind x
    mult ind (VLC_size)
    add ind block

    sd dcc^dcc_tab_data
    add dcc ind
    if block==(VLC_code)
        return dcc#
    else
        ss byte
        set byte dcc
        return byte#
    endelse
endfunction



##code coeff function
#return bool
function coef_intra_calc_code(sd qcoeff,sd index)
    import "mpeg_scan_tables" mpeg_scan_tables
    sd scan_table
    setcall scan_table mpeg_scan_tables(index)

    sd i=1
    sd run=0
    sd level
    sd loop=1
    while loop==1
        setcall level array_get_int(scan_table,i)
        setcall level array_get_int16(qcoeff,level)
        inc i

        if level!=0
            set loop 0
        else
            if i>=64
                set loop 0
            else
                inc run
            endelse
        endelse
    endwhile

    sd prev_level
    set prev_level level
    sd prev_run
    set prev_run run
    set run 0
    sd abs_level
    sd code
    sd len
    import "vlc_tables_intra" vlc_tables_intra
    sd bool
    sd value
    sd p_code
    ss p_len

    while i<64
        setcall level array_get_int(scan_table,i)
        setcall level array_get_int16(qcoeff,level)
        inc i
        if level!=0
            set abs_level prev_level
            if abs_level<0
                mult abs_level -1
            endif
            if abs_level>=64
                set abs_level 0
            endif
            setcall p_code vlc_tables_intra((value_get),(VLC_code),0,abs_level,prev_run)
            set code p_code#
            setcall p_len vlc_tables_intra((value_get),(VLC_len),0,abs_level,prev_run)
            set len p_len#
            if len!=128
                if prev_level<0
                    or code 1
                endif
            else
                setcall code shl((ESCAPE3),21)
                orcall code shl(prev_run,14)
                or code (2$13)
                set value prev_level
                and value 0xfFF
                mult value 2
                or code value
                or code 1

                set len 30
            endelse
            setcall bool mpeg_file_mem_append(code,len)
            if bool!=1
                return 0
            endif
            set prev_level level
            set prev_run run
            set run 0
        else
            inc run
        endelse
    endwhile

    set abs_level prev_level
    if abs_level<0
        mult abs_level -1
    endif
    if abs_level>=64
        set abs_level 0
    endif

    setcall p_code vlc_tables_intra((value_get),(VLC_code),1,abs_level,prev_run)
    set code p_code#
    setcall p_len vlc_tables_intra((value_get),(VLC_len),1,abs_level,prev_run)
    set len p_len#
    if len!=128
        if prev_level<0
            or code 1
        endif
    else
        setcall code shl((ESCAPE3),21)
        or code (2$20)
        orcall code shl(prev_run,14)
        or code (2$13)
        set value prev_level
        and value 0xfFF
        mult value 2
        or code value
        or code 1

        set len 30
    endelse
    setcall bool mpeg_file_mem_append(code,len)
    if bool!=1
        return 0
    endif
    return 1
endfunction
