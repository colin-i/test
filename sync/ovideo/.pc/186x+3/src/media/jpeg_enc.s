

format elfobj

include "../_include/include.h"

import "file_write" file_write
import "pixbuf_get_wh" pixbuf_get_wh
import "alloc_block" alloc_block
import "memoryalloc" memoryalloc
importx "_free" free

#bool
function write_jpeg(sd file,sd pixbuf,sd quality)
    sd bool
    setcall bool jpeg_file_mem((value_set))
    if bool==0
        return 0
    endif
    setcall bool write_jpeg_file(pixbuf,quality)
    if bool==0
        return 0
    endif

    setcall bool jpeg_file_mem((value_filewrite),file)
    if bool==0
        return 0
    endif

    call jpeg_file_mem((value_unset))

    return 1
endfunction

#bool
function write_jpeg_file(sd pixbuf,sd quality)
    sd bool
    setcall bool write_jpeg_headers(pixbuf,quality)
    if bool==0
        return 0
    endif

    setcall bool jpeg_encode_main(pixbuf)
    return bool
endfunction


#bool
function write_jpeg_headers(sd pixbuf,sd quality)
    sd bool
    setcall bool write_jpeg_headers_appinfo()
    if bool==0
        return 0
    endif
    setcall bool write_jpeg_quantizationTables(quality)
    if bool==0
        return 0
    endif
    setcall bool write_jpeg_sof(pixbuf)
    if bool==0
        return 0
    endif
    setcall bool write_jpeg_Huffman()
    if bool==0
        return 0
    endif
    setcall bool write_jpeg_sos()
    if bool==0
        return 0
    endif
    return 1
endfunction

#bool
function jpeg_encode_main(sd pixbuf)
    sd bool
    setcall bool jpeg_category((value_set))
    if bool==0
        return 0
    endif
    setcall bool jpeg_length((value_set))
    if bool==0
        call jpeg_category((value_unset))
        return 0
    endif
    setcall bool jpeg_value((value_set))
    if bool==0
        call jpeg_category((value_unset))
        call jpeg_length((value_unset))
        return 0
    endif

    setcall bool write_jpeg_blocks(pixbuf)

    call jpeg_category((value_unset))
    call jpeg_length((value_unset))
    call jpeg_value((value_unset))

    return bool
endfunction

const lum=0
const crom=1

#bool
function write_jpeg_blocks(sd pixbuf)
    sd w
    sd h
    sd wh^w
    call pixbuf_get_wh(pixbuf,wh)

    #need when get 8x8
    ##1
    call jpeg_YCbCr_256color((value_set))

    #need at quantization
    ##2
    call jpeg_FDCT_Quantization_Tables((value_set))
    sd FDCT_Y
    sd FDCT_CbCr
    sd p_FDCT_CbCr^FDCT_CbCr
    setcall FDCT_Y jpeg_FDCT_Quantization_Tables((value_get),p_FDCT_CbCr)

    ##3
    call jpeg_FDCT_Quantization_And_ZigZag((value_set))

    ##4
    call jpeg_encode_Huffman((value_set))
    data prev_DC_Y#1
    data prev_DC_Cb#1
    data prev_DC_Cr#1
    set prev_DC_Y 0
    set prev_DC_Cb 0
    set prev_DC_Cr 0
    data p_prev_DC_Y^prev_DC_Y
    data p_prev_DC_Cb^prev_DC_Cb
    data p_prev_DC_Cr^prev_DC_Cr

    #write blocks from top to bottom 8x8 pieces
    sd j=0
    while j<h
        sd i=0
        while i<w
            #get a 8x8 block
            chars Y_data#8*8
            chars Cb_data#8*8
            chars Cr_data#8*8
            str Y^Y_data
            str Cb^Cb_data
            str Cr^Cr_data
            ##1
            call jpeg_blocks_8x8(Y,Cb,Cr,pixbuf,i,j,w,h)

            sd bool

            #apply fast DCT and zigzag
            #int16
            chars DCT_Quant_Y_data#64*2
            str DCT_Quant_Y^DCT_Quant_Y_data
            ##3,4
            call jpeg_FDCT_Quantization_And_ZigZag((value_run),Y,DCT_Quant_Y,FDCT_Y)
            #                                1 is for encode
            setcall bool jpeg_encode_Huffman(1,DCT_Quant_Y,(lum),p_prev_DC_Y)
            if bool!=1
                return 0
            endif
            #
            chars DCT_Quant_Cb_data#64*2
            str DCT_Quant_Cb^DCT_Quant_Cb_data
            call jpeg_FDCT_Quantization_And_ZigZag((value_run),Cb,DCT_Quant_Cb,FDCT_CbCr)
            setcall bool jpeg_encode_Huffman(1,DCT_Quant_Cb,(crom),p_prev_DC_Cb)
            if bool!=1
                return 0
            endif
            #
            chars DCT_Quant_Cr_data#64*2
            str DCT_Quant_Cr^DCT_Quant_Cr_data
            call jpeg_FDCT_Quantization_And_ZigZag((value_run),Cr,DCT_Quant_Cr,FDCT_CbCr)
            setcall bool jpeg_encode_Huffman(1,DCT_Quant_Cr,(crom),p_prev_DC_Cr)
            if bool!=1
                return 0
            endif
            add i 8
        endwhile
        add j 8
    endwhile

    #Write End of Image Marker
    chars EOI_data={0xFF,0xD9}
    str EOI^EOI_data
    setcall bool jpeg_file_mem_add(EOI,2)
    if bool!=1
        return 0
    endif
    return 1
endfunction




function jpeg_file_mem(sd action,sd arg,sd append_size)
    data mem#1
    data size#1
    if action==(value_set)
    #bool
        setcall mem alloc_block((value_set))
        if mem==0
            return 0
        endif
        set size 0
        return 1
    elseif action==(value_unset)
        call free(mem)
    elseif action==(value_append)
    #bool
        sd append
        set append arg
        sd appendresult
        setcall appendresult alloc_block((value_append),mem,size,append,append_size)
        if appendresult==0
            return 0
        endif
        set mem appendresult
        add size append_size
        return 1
    else
    #if action==(value_filewrite)
    #bool
        sd file
        set file arg
        sd err
        setcall err file_write(mem,size,file)
        if err!=(noerror)
            return 0
        endif
        return 1
    endelse
endfunction

function jpeg_file_mem_add(sd append,sd append_size)
    sd bool
    setcall bool jpeg_file_mem((value_append),append,append_size)
    return bool
endfunction















##

#bool
function write_jpeg_headers_appinfo()
    #JPEG INIT
    chars JPEG_INIT={0xff,0xD8}
    #marker
    chars *={0xff,0xE0}
    #length = 16 for usual JPEG, no thumbnail
    chars *={0,16}
    #signature
    chars *="JFIF"
    #high version,low version
    chars *={1,1}
    #xyunits = 0 = no units, normal density
    chars *=0
    #x density = 1
    chars *={0,1}
    #y density = 1
    chars *={0,1}
    #thumb n width, thumb n height
    chars *={0,0}

    data size#1

    const _appinfo^JPEG_INIT
    const appinfo_^size
    set size (appinfo_-_appinfo)

    sd buffer^JPEG_INIT

    sd bool
    setcall bool jpeg_file_mem_add(buffer,size)
    if bool!=1
        return 0
    endif

    return 1
endfunction


#Quantization Tables
#bool
function write_jpeg_quantizationTables(sd quality)
    chars marker={0xFF,0xDB}
    #length = 132
    chars *={0,132}
    #QTYinfo
    #bit 0..3: number of QT = 0 (table for Y)
    #bit 4..7: precision of QT, 0 = 8 bit
    chars *=0
    #Y Table, luminance table
    chars Y_Table#64
    #QTCbinfo
    #quantization table for Cb,Cr
    chars *=1
    #CbCr Table, chromiance table
    chars CbCr_Table#64

    data size#1
    const _quantizationTables^marker
    const quantizationTables_^size
    set size (quantizationTables_-_quantizationTables)

    chars luminance_r1={16, 11, 10, 16,24, 40, 51, 61}
    chars *         r2={12, 12, 14, 19,26, 58, 60, 55}
    chars *         r3={14, 13, 16, 24,40, 57, 69, 56}
    chars *         r4={14, 17, 22, 29,51, 87, 80, 62}
    chars *         r5={18, 22, 37, 56,68, 109,103,77}
    chars *         r6={24, 35, 55, 64,81, 104,113,92}
    chars *         r7={49, 64, 78, 87,103,121,120,101}
    chars *         r8={72, 92, 95, 98,112,100,103,99}

    str luminance^luminance_r1
    str Y_Tab^Y_Table
    call jpeg_Scale_And_ZigZag_Quantization_Table(luminance,Y_Tab,quality)

    chars chromiance_r1={17,  18,  24,  47,  99,  99,  99,  99}
    chars *          r2={18,  21,  26,  66,  99,  99,  99,  99}
    chars *          r3={24,  26,  56,  99,  99,  99,  99,  99}
    chars *          r4={47,  66,  99,  99,  99,  99,  99,  99}
    chars *          r5={99,  99,  99,  99,  99,  99,  99,  99}
    chars *          r6={99,  99,  99,  99,  99,  99,  99,  99}
    chars *          r7={99,  99,  99,  99,  99,  99,  99,  99}
    chars *          r8={99,  99,  99,  99,  99,  99,  99,  99}

    str chromiance^chromiance_r1
    str CbCr_Tab^CbCr_Table
    call jpeg_Scale_And_ZigZag_Quantization_Table(chromiance,CbCr_Tab,quality)

    sd buffer^marker
    sd bool
    setcall bool jpeg_file_mem_add(buffer,size)
    if bool!=1
        return 0
    endif
    return 1

    const Y_Tab^Y_Table
    const CbCr_Tab^CbCr_Table
endfunction

function jpeg_Y_Table()
    sd p%Y_Tab
    return p
endfunction
function jpeg_CbCr_Table()
    sd p%CbCr_Tab
    return p
endfunction


function jpeg_Scale_And_ZigZag_Quantization_Table(ss srctable,ss desttable,sd quality)
    sd i=0
    while i!=64
        #quality_scale=1(best) (x*quality_scale+50)/100
        sd temp
        set temp srctable#
        #quality
        mult temp quality
        #
        add temp 50
        div temp 100
        if temp<=0
            set temp 1
        elseif temp>0xff
            set temp 0xff
        endelseif

        call jpeg_ZigZag((value_set),desttable,i,temp)

        inc srctable
        inc i
    endwhile
endfunction

function jpeg_ZigZag_get(sd i)
    chars zigzag_r1={0, 1, 5, 6, 14,15,27,28}
    chars *      r2={2, 4, 7, 13,16,26,29,42}
    chars *      r3={3, 8, 12,17,25,30,41,43}
    chars *      r4={9, 11,18,24,31,40,44,53}
    chars *      r5={10,19,23,32,39,45,52,54}
    chars *      r6={20,22,33,38,46,51,55,60}
    chars *      r7={21,34,37,47,50,56,59,61}
    chars *      r8={35,36,48,49,57,58,62,63}

    str zigzag^zigzag_r1
    ss ztab
    set ztab zigzag
    add ztab i

    return ztab#
endfunction

function jpeg_ZigZag(sd action,ss table,sd i,sd value)
    sd jump
    setcall jump jpeg_ZigZag_get(i)
    add table jump

    if action==(value_set)
        set table# value
    else
        return table#
    endelse
endfunction

##

#bool
function write_jpeg_sof(sd pixbuf)
    chars marker={0xFF,0xC0}
    #length = 17 for a truecolor YCbCr JPG
    chars *={0,17}
    #precision, Should be 8: 8 bits/sample
    chars *=8
    #height
    chars height#2
    #width
    chars width#2
    #nrofcomponents, Should be 3: We encode a truecolor JPG
    chars *=3
    #IdY
    chars *=1
    #HVY, sampling factors for Y (bit 0-3 vert., 4-7 hor.)
    chars *=0x11
    #QTY, Quantization Table number for Y = 0
    chars *=0
    #IdCb
    chars *=2
    #HVCb
    chars *=0x11
    #QTCb
    chars *=1
    #IdCr
    chars *=3
    #HVCr
    chars *=0x11
    #QTCr, Normally equal to QTCb = 1
    chars *=1

    data size#1
    const _sof^marker
    const sof_^size
    set size (sof_-_sof)

    import "word_reverse" word_reverse
    sd w
    sd h
    sd wh^w
    call pixbuf_get_wh(pixbuf,wh)
    str wd^width
    str ht^height
    call word_reverse(h,ht)
    call word_reverse(w,wd)

    sd buffer^marker
    sd bool
    setcall bool jpeg_file_mem_add(buffer,size)
    if bool!=1
        return 0
    endif
    return 1
endfunction

##

const Huffman_init=0
const Huffman_get=1

#bool
function write_jpeg_Huffman()
    chars marker={0xFF,0xC4}
    #length
    chars *={0x01,0xA2}

    data size#1
    const _Huffman^marker
    const Huffman_^size
    set size (Huffman_-_Huffman)

    sd buffer^marker
    sd bool
    setcall bool jpeg_file_mem_add(buffer,size)
    if bool!=1
        return 0
    endif

    setcall bool Huffman_DC_Luminance((Huffman_init))
    if bool==0
        return 0
    endif

    setcall bool Huffman_AC_Luminance((Huffman_init))
    if bool==0
        return 0
    endif

    setcall bool Huffman_DC_Chromiance((Huffman_init))
    if bool==0
        return 0
    endif

    setcall bool Huffman_AC_Chromiance((Huffman_init))
    if bool==0
        return 0
    endif

    return 1
endfunction

#HT info,   bit 0..3: number of HT (0..3), for Y =0, Cb=1
#           bit 4  :type of HT, 0 = DC table,1 = AC table
#           bit 5..7: not used, must be 0

const Y_table=0
const Cb_table=1

const DC_table=0
const AC_table=0x10

function Huffman_DC_Luminance(sd action,sd ptr_values)
    chars HT=Y_table|DC_table
    chars NRCodes={0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0}
    chars Values={ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

    data Values_size#1

    const YDC_NRCodes^NRCodes
    const YDC_Values^Values
    const YDC_Values_^Values_size

    sd p_NRCodes^NRCodes
    sd p_Values^Values

    if action==(Huffman_init)
    #bool
        inc p_NRCodes
        sd NRCodes_size=YDC_Values-YDC_NRCodes
        dec NRCodes_size

        set Values_size (YDC_Values_-YDC_Values)

        sd bool
        setcall bool Huffman_init_write(HT,p_NRCodes,NRCodes_size,p_Values,Values_size)
        return bool
    endif

    set ptr_values# p_Values
    return p_NRCodes
endfunction

function Huffman_AC_Luminance(sd action,sd ptr_values)
    chars HT=Y_table|AC_table
    chars NRCodes={0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d}
    chars Values={0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12}
    chars     *2={0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07}
    chars     *3={0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08}
    chars     *4={0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0}
    chars     *5={0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16}
    chars     *6={0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28}
    chars     *7={0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39}
    chars     *8={0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49}
    chars     *9={0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59}
    chars    *10={0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69}
    chars    *11={0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79}
    chars    *12={0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89}
    chars    *13={0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98}
    chars    *14={0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7}
    chars    *15={0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6}
    chars    *16={0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5}
    chars    *17={0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4}
    chars    *18={0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2}
    chars    *19={0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea}
    chars    *20={0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8}
    chars    *21={0xf9, 0xfa}

    data Values_size#1

    const YAC_NRCodes^NRCodes
    const YAC_Values^Values
    const YAC_Values_^Values_size

    sd p_NRCodes^NRCodes
    sd p_Values^Values

    if action==(Huffman_init)
    #bool
        inc p_NRCodes
        sd NRCodes_size=YAC_Values-YAC_NRCodes
        dec NRCodes_size

        set Values_size (YAC_Values_-YAC_Values)

        sd bool
        setcall bool Huffman_init_write(HT,p_NRCodes,NRCodes_size,p_Values,Values_size)
        return bool
    endif
    set ptr_values# p_Values
    return p_NRCodes
endfunction

function Huffman_DC_Chromiance(sd action,sd ptr_values)
    chars HT=Cb_table|DC_table
    chars NRCodes={0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0}
    chars Values={0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

    data Values_size#1

    const CbDC_NRCodes^NRCodes
    const CbDC_Values^Values
    const CbDC_Values_^Values_size

    sd p_NRCodes^NRCodes
    sd p_Values^Values

    if action==(Huffman_init)
    #bool
        inc p_NRCodes
        sd NRCodes_size=CbDC_Values-CbDC_NRCodes
        dec NRCodes_size

        set Values_size (CbDC_Values_-CbDC_Values)

        sd bool
        setcall bool Huffman_init_write(HT,p_NRCodes,NRCodes_size,p_Values,Values_size)
        return bool
    endif
    set ptr_values# p_Values
    return p_NRCodes
endfunction

function Huffman_AC_Chromiance(sd action,sd ptr_values)
    chars HT=Cb_table|AC_table
    chars NRCodes={0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77}
    chars Values={0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21}
    chars     *2={0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71}
    chars     *3={0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91}
    chars     *4={0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0}
    chars     *5={0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34}
    chars     *6={0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26}
    chars     *7={0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38}
    chars     *8={0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48}
    chars     *9={0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58}
    chars    *10={0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68}
    chars    *11={0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78}
    chars    *12={0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87}
    chars    *13={0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96}
    chars    *14={0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5}
    chars    *15={0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4}
    chars    *16={0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3}
    chars    *17={0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2}
    chars    *18={0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda}
    chars    *19={0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9}
    chars    *20={0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8}
    chars    *21={0xf9, 0xfa}

    data Values_size#1

    const CbAC_NRCodes^NRCodes
    const CbAC_Values^Values
    const CbAC_Values_^Values_size

    sd p_NRCodes^NRCodes
    sd p_Values^Values

    if action==(Huffman_init)
    #bool
        inc p_NRCodes
        sd NRCodes_size=CbAC_Values-CbAC_NRCodes
        dec NRCodes_size

        set Values_size (CbAC_Values_-CbAC_Values)

        sd bool
        setcall bool Huffman_init_write(HT,p_NRCodes,NRCodes_size,p_Values,Values_size)
        return bool
    endif
    set ptr_values# p_Values
    return p_NRCodes
endfunction

#bool
function Huffman_init_write(sd HTbyte,sd NRCodes,sd NRCodes_size,sd Values,sd Values_size)
    sd p_HTbyte^HTbyte
    sd bool
    setcall bool jpeg_file_mem_add(p_HTbyte,1)
    if bool!=1
        return 0
    endif
    setcall bool jpeg_file_mem_add(NRCodes,NRCodes_size)
    if bool!=1
        return 0
    endif
    setcall bool jpeg_file_mem_add(Values,Values_size)
    if bool!=1
        return 0
    endif
    return 1
endfunction

##

#bool
function write_jpeg_sos()
    chars marker={0xFF,0xDA}
    chars *length={0,12}
    #nrofcomponents Should be 3: truecolor JPG
    chars *=3

    chars *IdY=1
    #HT, bits 0..3: AC table (0..3)
    #    bits 4..7: DC table (0..3)
    chars *HTY=0
    chars *IdCb=2
    chars *HTCb=0x11
    chars *IdCr=3
    chars *HTCr=0x11
    chars *Ss=0
    chars *Se=0x3F
    chars *Bf=0

    data size#1
    const _sos^marker
    const sos_^size
    set size (sos_-_sos)

    sd buffer^marker
    sd bool
    setcall bool jpeg_file_mem_add(buffer,size)
    if bool!=1
        return 0
    endif
    return 1
endfunction

##

###

function jpeg_YCbCr_256color(sd action,sd red,sd green,sd blue,sd p_Y,sd p_Cb,sd p_Cr,sd x,sd y)
    data Y_Red_Table_data#256
    data Cb_Red_Table_data#256
    data Cr_Red_Table_data#256
    data Y_Green_Table_data#256
    data Cb_Green_Table_data#256
    data Cr_Green_Table_data#256
    data Y_Blue_Table_data#256
    data Cb_Blue_Table_data#256
    data Cr_Blue_Table_data#256

    sd Y_Red_Table^Y_Red_Table_data
    sd Cb_Red_Table^Cb_Red_Table_data
    sd Cr_Red_Table^Cr_Red_Table_data
    sd Y_Green_Table^Y_Green_Table_data
    sd Cb_Green_Table^Cb_Green_Table_data
    sd Cr_Green_Table^Cr_Green_Table_data
    sd Y_Blue_Table^Y_Blue_Table_data
    sd Cb_Blue_Table^Cb_Blue_Table_data
    sd Cr_Blue_Table^Cr_Blue_Table_data

    sd variable
    if action==(value_set)
        sd color
        set color 0
        while color!=256
            str Y_Red_coef="0.299"
            setcall Y_Red_Table# jpeg_YCbCr_256color_equation(Y_Red_coef,color)
            add Y_Red_Table 4

            str Cb_Red_coef="-0.16874"
            setcall Cb_Red_Table# jpeg_YCbCr_256color_equation(Cb_Red_coef,color)
            add Cb_Red_Table 4

            set variable color
            mult variable 32768
            set Cr_Red_Table# variable
            add Cr_Red_Table 4

            inc color
        endwhile

        set color 0
        while color!=256
            str Y_Green_coef="0.587"
            setcall Y_Green_Table# jpeg_YCbCr_256color_equation(Y_Green_coef,color)
            add Y_Green_Table 4

            str Cb_Green_coef="-0.33126"
            setcall Cb_Green_Table# jpeg_YCbCr_256color_equation(Cb_Green_coef,color)
            add Cb_Green_Table 4

            str Cr_Green_coef="-0.41869"
            setcall Cr_Green_Table# jpeg_YCbCr_256color_equation(Cr_Green_coef,color)
            add Cr_Green_Table 4

            inc color
        endwhile
        set color 0
        while color!=256
            str Y_Blue_coef="0.114"
            setcall Y_Blue_Table# jpeg_YCbCr_256color_equation(Y_Blue_coef,color)
            add Y_Blue_Table 4

            set variable color
            mult variable 32768
            set Cb_Blue_Table# variable
            add Cb_Blue_Table 4

            str Cr_Blue_coef="-0.08131"
            setcall Cr_Blue_Table# jpeg_YCbCr_256color_equation(Cr_Blue_coef,color)
            add Cr_Blue_Table 4

            inc color
        endwhile
        return (void)
    endif

    import "array_byte_setAtXY" array_byte_setAtXY
    sd Y
    setcall Y jpeg_YCbCr_256color_get3(red,green,blue,Y_Red_Table,Y_Green_Table,Y_Blue_Table)
    sub Y 128
    call array_byte_setAtXY(p_Y,Y,x,y,8)

    sd Cb
    setcall Cb jpeg_YCbCr_256color_get3(red,green,blue,Cb_Red_Table,Cb_Green_Table,Cb_Blue_Table)
    call array_byte_setAtXY(p_Cb,Cb,x,y,8)

    sd Cr
    setcall Cr jpeg_YCbCr_256color_get3(red,green,blue,Cr_Red_Table,Cr_Green_Table,Cr_Blue_Table)
    call array_byte_setAtXY(p_Cr,Cr,x,y,8)
endfunction

import "str_to_double" str_to_double
import "int_to_double" int_to_double
import "double_mult" double_mult
import "double_add" double_add
import "double_to_int" double_to_int
#res
function jpeg_YCbCr_256color_equation(sd value,sd color)
    #int((65536 * value + 0.5) * color)
    #65536
    str predef_double_str="65536"
    sd predef_double#2
    sd p_predef_double^predef_double
    call str_to_double(predef_double_str,p_predef_double)
    #value
    sd double#2
    sd p_double^double
    call str_to_double(value,p_double)
    #0.5
    str pre_double_str="0.5"
    sd pre_double#2
    sd p_pre_double^pre_double
    call str_to_double(pre_double_str,p_pre_double)
    #color
    sd color_double#2
    sd p_color_double^color_double
    call int_to_double(color,p_color_double)

    call double_mult(p_double,p_predef_double)
    call double_add(p_double,p_pre_double)
    call double_mult(p_double,p_color_double)

    sd res
    setcall res double_to_int(p_double)
    return res
endfunction

function bytemult4_getfromstruct(sd index,sd block)
    mult index 4
    import "structure_get_int" structure_get_int
    sd value
    setcall value structure_get_int(block,index)
    return value
endfunction
function jpeg_YCbCr_256color_get3(sd red,sd green,sd blue,sd red_tab,sd green_tab,sd blue_tab)
    sd value
    setcall value bytemult4_getfromstruct(red,red_tab)
    addcall value bytemult4_getfromstruct(green,green_tab)
    addcall value bytemult4_getfromstruct(blue,blue_tab)
    import "sar32" sar32
    setcall value sar32(value,16)
    return value
endfunction

function jpeg_blocks_8x8(ss Y_tab,ss Cb_tab,ss Cr_tab,sd pixbuf,sd i,sd j,sd max_i,sd max_j)
    sd x
    sd max_x
    set x i
    set max_x x
    add max_x 8
    sd min_y
    sd max_y
    set min_y j
    set max_y min_y
    add max_y 8

    sd red
    sd green
    sd blue
    sd colors^red

    while x!=max_x
        sd send_x
        set send_x x
        sub send_x i

        sd y
        set y min_y
        while y!=max_y
            sd send_y
            set send_y y
            sub send_y j

            set red 0
            set green 0
            set blue 0
            if x<max_i
                if y<max_j
                    import "pixbuf_get_pixel" pixbuf_get_pixel
                    sd value
                    setcall value pixbuf_get_pixel(pixbuf,x,y)
                    import "rgb_uint_to_colors" rgb_uint_to_colors
                    call rgb_uint_to_colors(value,colors)
                endif
            endif

            call jpeg_YCbCr_256color((value_get),red,green,blue,Y_tab,Cb_tab,Cr_tab,send_x,send_y)

            inc y
        endwhile
        inc x
    endwhile
endfunction

###

function jpeg_FDCT_Quantization_Tables(sd action,sd p_CbCr)
    data FDCT_Y_Quantization#64
    sd FDCT_Y^FDCT_Y_Quantization
    data FDCT_CbCr_Quantization#64
    sd FDCT_CbCr^FDCT_CbCr_Quantization
    if action==(value_set)
        data CosineScaleFactor_data#8*2
        sd CosineScaleFactor^CosineScaleFactor_data

        chars CosineScaleFactor_coef1="1.0"
        chars *CosineScaleFactor_coef2="1.387039845"
        chars *CosineScaleFactor_coef3="1.306562965"
        chars *CosineScaleFactor_coef4="1.175875602"
        chars *CosineScaleFactor_coef5="1.0"
        chars *CosineScaleFactor_coef6="0.785694958"
        chars *CosineScaleFactor_coef7="0.541196100"
        chars *CosineScaleFactor_coef8="0.275899379"
        chars *=0

        ss CosineScaleFactor_coef^CosineScaleFactor_coef1

#1.0 / (X_Table[Tables.ZigZag[i]]*CSF[row]*CSF[col]*8.0)
        #8.0 to double
        sd const_denom#2
        sd p_const_denom^const_denom
        str c_denom="1.0"
        call str_to_double(c_denom,p_const_denom)

        #8.0 to double
        sd const_double#2
        sd p_const_double^const_double
        str c_double="8.0"
        call str_to_double(c_double,p_const_double)

        #cosines to double

        while CosineScaleFactor_coef#!=0
            call str_to_double(CosineScaleFactor_coef,CosineScaleFactor)

            add CosineScaleFactor 8
            import "slen" slen
            addcall CosineScaleFactor_coef slen(CosineScaleFactor_coef)
            inc CosineScaleFactor_coef
        endwhile

        #for cpy 1.0 here
        sd res_value#2
        sd p_res_value^res_value

        sd tabs=0
        while tabs!=2
            sd Table
            sd dest_table
            if tabs==0
                setcall Table jpeg_Y_Table()
                set dest_table FDCT_Y
            else
                setcall Table jpeg_CbCr_Table()
                set dest_table FDCT_CbCr
            endelse

            sd i=0
            sd row=0
            sd CosineScaleFactor_row^CosineScaleFactor_data
            while row!=8
                sd col=0
                sd CosineScaleFactor_col^CosineScaleFactor_data
                while col!=8
                    import "cpymem" cpymem
                    import "double_div" double_div
                    import "double_to_float" double_to_float

                    #get
                    sd value
                    setcall value jpeg_ZigZag((value_get),Table,i)
                    sd double_value#2
                    sd p_double_value^double_value
                    call int_to_double(value,p_double_value)

                    call double_mult(p_double_value,CosineScaleFactor_row)
                    call double_mult(p_double_value,CosineScaleFactor_col)
                    call double_mult(p_double_value,p_const_double)

                    call cpymem(p_res_value,p_const_denom,8)
                    call double_div(p_res_value,p_double_value)

                    setcall dest_table# double_to_float(p_res_value)

                    add dest_table 4
                    add CosineScaleFactor_col 8
                    inc i
                    inc col
                endwhile
                add CosineScaleFactor_row 8
                inc row
            endwhile
            inc tabs
        endwhile
        return (void)
    endif
    #get
    set p_CbCr# FDCT_CbCr
    return FDCT_Y
endfunction

###

import "float_add" float_add
import "array_set_word_off" array_set_word_off

#                                                    char        int16            float
function jpeg_FDCT_Quantization_And_ZigZag(sd action,ss data8x8,sd out_DCT_Quant,sd FDCT_table)
    if action==(value_set)
        import "str_to_float" str_to_float

        str fstr="0.707106781"
        data float_0#1
        setcall float_0 str_to_float(fstr)
        str fstr_1="0.382683433"
        data float_1#1
        setcall float_1 str_to_float(fstr_1)
        str fstr_2="0.541196100"
        data float_2#1
        setcall float_2 str_to_float(fstr_2)
        str fstr_3="1.306562965"
        data float_3#1
        setcall float_3 str_to_float(fstr_3)
        str fstr_4="0.707106781"
        data float_4#1
        setcall float_4 str_to_float(fstr_4)
        return 1
    endif
    sd tmp0
    sd tmp1
    sd tmp2
    sd tmp3
    sd tmp4
    sd tmp5
    sd tmp6
    sd tmp7
    #
    sd tmp10
    sd tmp11
    sd tmp12
    sd tmp13
    #
    sd zA
    sd zB
    sd zC
    sd zD
    sd zE
    sd zF
    sd zG

    sd cursor
    sd value
    #convert the sbyte table to float
    chars temp_data#64*4
    sd temp^temp_data
    sd i=0
    set cursor temp
    while i!=64
        import "int_to_float" int_to_float
        import "char_to_int" char_to_int
        setcall value char_to_int(data8x8#)
        setcall cursor# int_to_float(value)
        add cursor 4
        inc data8x8
        inc i
    endwhile

    import "array_set_4value_offsets" array_set_4value_offsets
    import "float_mult" float_mult
    import "float_sub" float_sub

    #Pass 1: process rows.
    sd k=0
    while k!=64
    #0=add; 1=sub
        setcall tmp0 gettwofloats_offs_and_op(temp,0,7,k,0)
        setcall tmp7 gettwofloats_offs_and_op(temp,0,7,k,1)
        setcall tmp1 gettwofloats_offs_and_op(temp,1,6,k,0)
        setcall tmp6 gettwofloats_offs_and_op(temp,1,6,k,1)
        setcall tmp2 gettwofloats_offs_and_op(temp,2,5,k,0)
        setcall tmp5 gettwofloats_offs_and_op(temp,2,5,k,1)
        setcall tmp3 gettwofloats_offs_and_op(temp,3,4,k,0)
        setcall tmp4 gettwofloats_offs_and_op(temp,3,4,k,1)

        #Even part
        setcall tmp10 float_add(tmp0,tmp3)
        setcall tmp13 float_sub(tmp0,tmp3)
        setcall tmp11 float_add(tmp1,tmp2)
        setcall tmp12 float_sub(tmp1,tmp2)

        #
        setcall value float_add(tmp10,tmp11)
        call array_set_4value_offsets(temp,value,0,k)
        setcall value float_sub(tmp10,tmp11)
        call array_set_4value_offsets(temp,value,4,k)

        #
        setcall zA float_add(tmp12,tmp13)
        setcall zA float_mult(zA,float_0)

        #
        setcall value float_add(tmp13,zA)
        call array_set_4value_offsets(temp,value,2,k)
        setcall value float_sub(tmp13,zA)
        call array_set_4value_offsets(temp,value,6,k)

        #Odd part
        setcall tmp10 float_add(tmp4,tmp5)
        setcall tmp11 float_add(tmp5,tmp6)
        setcall tmp12 float_add(tmp6,tmp7)

        #The rotator is modified to avoid extra negations.
        setcall zE float_sub(tmp10,tmp12)
        setcall zE float_mult(zE,float_1)

        set zB float_2
        setcall zB float_mult(zB,tmp10)
        setcall zB float_add(zB,zE)

        set zD float_3
        setcall zD float_mult(zD,tmp12)
        setcall zD float_add(zD,zE)

        set zC float_4
        setcall zC float_mult(zC,tmp11)

        #
        setcall zF float_add(tmp7,zC)
        setcall zG float_sub(tmp7,zC)
        #

        setcall value float_add(zG,zB)
        call array_set_4value_offsets(temp,value,5,k)

        setcall value float_sub(zG,zB)
        call array_set_4value_offsets(temp,value,3,k)

        setcall value float_add(zF,zD)
        call array_set_4value_offsets(temp,value,1,k)

        setcall value float_sub(zF,zD)
        call array_set_4value_offsets(temp,value,7,k)

        #go to next row
        add k 8
    endwhile

    #Pass 2: process columns.
    set k 0
    while k!=8
        setcall tmp0 gettwofloats_offs_and_op(temp,0,56,k,0)
        setcall tmp7 gettwofloats_offs_and_op(temp,0,56,k,1)
        setcall tmp1 gettwofloats_offs_and_op(temp,8,48,k,0)
        setcall tmp6 gettwofloats_offs_and_op(temp,8,48,k,1)
        setcall tmp2 gettwofloats_offs_and_op(temp,16,40,k,0)
        setcall tmp5 gettwofloats_offs_and_op(temp,16,40,k,1)
        setcall tmp3 gettwofloats_offs_and_op(temp,24,32,k,0)
        setcall tmp4 gettwofloats_offs_and_op(temp,24,32,k,1)

        #
        setcall tmp10 float_add(tmp0,tmp3)
        setcall tmp13 float_sub(tmp0,tmp3)
        setcall tmp11 float_add(tmp1,tmp2)
        setcall tmp12 float_sub(tmp1,tmp2)
        #
        setcall value float_add(tmp10,tmp11)
        call array_set_4value_offsets(temp,value,0,k)
        setcall value float_sub(tmp10,tmp11)
        call array_set_4value_offsets(temp,value,32,k)

        #
        setcall zA float_add(tmp12,tmp13)
        setcall value str_to_float(fstr)
        setcall zA float_mult(zA,value)
        #
        setcall value float_add(tmp13,zA)
        call array_set_4value_offsets(temp,value,16,k)
        setcall value float_sub(tmp13,zA)
        call array_set_4value_offsets(temp,value,48,k)

        #Odd part
        setcall tmp10 float_add(tmp4,tmp5)
        setcall tmp11 float_add(tmp5,tmp6)
        setcall tmp12 float_add(tmp6,tmp7)

        #The rotator is modified to avoid extra negations.
        setcall zE float_sub(tmp10,tmp12)
        setcall value str_to_float(fstr_1)
        setcall zE float_mult(zE,value)

        setcall zB str_to_float(fstr_2)
        setcall zB float_mult(zB,tmp10)
        setcall zB float_add(zB,zE)

        setcall zD str_to_float(fstr_3)
        setcall zD float_mult(zD,tmp12)
        setcall zD float_add(zD,zE)

        setcall zC str_to_float(fstr_4)
        setcall zC float_mult(zC,tmp11)

        #
        setcall zF float_add(tmp7,zC)
        setcall zG float_sub(tmp7,zC)
        #

        setcall value float_add(zG,zB)
        call array_set_4value_offsets(temp,value,40,k)

        setcall value float_sub(zG,zB)
        call array_set_4value_offsets(temp,value,24,k)

        setcall value float_add(zF,zD)
        call array_set_4value_offsets(temp,value,8,k)

        setcall value float_sub(zF,zD)
        call array_set_4value_offsets(temp,value,56,k)

        inc k
    endwhile

    #Do Quantization, ZigZag and proper roundoff.
    set i 0
    str temp_str="16384.5"
    sd temp_value
    setcall temp_value str_to_float(temp_str)
    sd t_double#2
    sd p_t_double^t_double
    while i!=64
        #temp[i] * FDCT_table[i];
        setcall value float_mult(temp#,FDCT_table#)
        add temp 4
        add FDCT_table 4
        #
        #((Data)(temp + 16384.5) - 16384)
        setcall value float_add(value,temp_value)
        #
        import "float_to_double" float_to_double
        call float_to_double(value,p_t_double)
        #
        setcall value double_to_int(p_t_double)
        #
        sub value 16384
        #outdata[Tables.ZigZag[i]]=value
        sd pos
        setcall pos jpeg_ZigZag_get(i)
        #
        call array_set_word_off(out_DCT_Quant,value,pos)
        #
        inc i
    endwhile
endfunction

#float
function gettwofloats_offs_and_op(sd floats,sd offA,sd offB,sd offset,sd operation)
    sd k

    sd f1
    set f1 floats
    mult offA 4
    add f1 offA
    set k offset
    mult k 4
    add f1 k
    set f1 f1#

    sd f2
    set f2 floats
    mult offB 4
    add f2 offB
    mult offset 4
    add f2 offset

    sd value
    #0=add,1=sub
    if operation==0
        setcall value float_add(f1,f2#)
    else
        setcall value float_sub(f1,f2#)
    endelse
    return value
endfunction

###
#bool
function jpeg_category(sd action)
    data category#1
    if action==(value_set)
        sd p_category^category
        sd err
        setcall err memoryalloc(65535,p_category)
        if err!=(noerror)
            return 0
        endif
        return 1
    elseif action==(value_get)
        return category
    else
        call free(category)
    endelse
endfunction
#bool
function jpeg_length(sd action)
    data length#1
    if action==(value_set)
        sd p_length^length
        sd err
        setcall err memoryalloc(65535,p_length)
        if err!=(noerror)
            return 0
        endif
        return 1
    elseif action==(value_get)
        return length
    else
        call free(length)
    endelse
endfunction
#bool
function jpeg_value(sd action)
    data value#1
    if action==(value_set)
        sd p_value^value
        sd err
        setcall err memoryalloc((2*65535),p_value)
        if err!=(noerror)
            return 0
        endif
        return 1
    elseif action==(value_get)
        return value
    else
        call free(value)
    endelse
endfunction

import "array_get_byte" array_get_byte
import "array_set_byte_off" array_set_byte_off

function jpeg_encode_init_Huffman(sd standard_nr,sd standard_val,sd p_nr,sd p_val)
    sd code_value=0
    sd pos_in_table=0
    sd k=1
    while k<=16
        sd j=1
        sd max_j
        setcall max_j array_get_byte(standard_nr,k)
        while j<=max_j
            sd pos
            setcall pos array_get_byte(standard_val,pos_in_table)

            call array_set_byte_off(p_nr,k,pos)
            call array_set_word_off(p_val,code_value,pos)

            inc pos_in_table
            inc code_value
            inc j
        endwhile

        mult code_value 2

        inc k
    endwhile
endfunction

const bytenew_start=0
const bytepos_start=7

function jpeg_encode_Huffman(sd action,sd DCT_tab,sd lum_or_crom,sd prev_DC)
    sd category
    sd bits_length
    sd bits_value

    setcall category jpeg_category((value_get))
    setcall bits_length jpeg_length((value_get))
    setcall bits_value jpeg_value((value_get))
    if action==(value_set)
        #init category and bitcodes
        import "array_set_byte_offsets" array_set_byte_offsets
        import "array_set_word_offsets" array_set_word_offsets

        sd nr
        sd nr_lower=1
        sd nr_upper=2
        sd categ=1
        while categ<=15
            #Positive numbers
            set nr nr_lower
            while nr<nr_upper
                call array_set_byte_offsets(category,categ,32767,nr)
                call array_set_byte_offsets(bits_length,categ,32767,nr)
                call array_set_word_offsets(bits_value,nr,32767,nr)

                inc nr
            endwhile

            #Negative numbers
            import "neg" neg

            setcall nr neg(nr_upper)
            inc nr

            sd neg_nr_lower
            setcall neg_nr_lower neg(nr_lower)

            while nr<=neg_nr_lower
                call array_set_byte_offsets(category,categ,32767,nr)
                call array_set_byte_offsets(bits_length,categ,32767,nr)

                sd bts_val
                set bts_val nr_upper
                dec bts_val
                add bts_val nr
                call array_set_word_offsets(bits_value,bts_val,32767,nr)

                inc nr
            endwhile

            mult nr_lower 2
            mult nr_upper 2

            inc categ
        endwhile

        #init encoding tables
        sd Standard_DC_Luminance_Nr
        sd Standard_DC_Luminance_Val
        sd p_Standard_DC_Luminance_Val^Standard_DC_Luminance_Val
        setcall Standard_DC_Luminance_Nr Huffman_DC_Luminance((Huffman_get),p_Standard_DC_Luminance_Val)

        sd Standard_AC_Luminance_Nr
        sd Standard_AC_Luminance_Val
        sd p_Standard_AC_Luminance_Val^Standard_AC_Luminance_Val
        setcall Standard_AC_Luminance_Nr Huffman_AC_Luminance((Huffman_get),p_Standard_AC_Luminance_Val)

        sd Standard_DC_Chromiance_Nr
        sd Standard_DC_Chromiance_Val
        sd p_Standard_DC_Chromiance_Val^Standard_DC_Chromiance_Val
        setcall Standard_DC_Chromiance_Nr Huffman_DC_Chromiance((Huffman_get),p_Standard_DC_Chromiance_Val)

        sd Standard_AC_Chromiance_Nr
        sd Standard_AC_Chromiance_Val
        sd p_Standard_AC_Chromiance_Val^Standard_AC_Chromiance_Val
        setcall Standard_AC_Chromiance_Nr Huffman_AC_Chromiance((Huffman_get),p_Standard_AC_Chromiance_Val)

        chars Y_DC_Huffman_Table_nr#12
        chars Y_DC_Huffman_Table_value#12*2
        chars Y_AC_Huffman_Table_nr#256
        chars Y_AC_Huffman_Table_value#256*2

        chars CbCr_DC_Huffman_Table_nr#12
        chars CbCr_DC_Huffman_Table_value#12*2
        chars CbCr_AC_Huffman_Table_nr#256
        chars CbCr_AC_Huffman_Table_value#256*2

        data p_Lum_DC_nr^Y_DC_Huffman_Table_nr
        data p_Lum_DC_val^Y_DC_Huffman_Table_value
        call jpeg_encode_init_Huffman(Standard_DC_Luminance_Nr,Standard_DC_Luminance_Val,p_Lum_DC_nr,p_Lum_DC_val)
        data p_Lum_AC_nr^Y_AC_Huffman_Table_nr
        data p_Lum_AC_val^Y_AC_Huffman_Table_value
        call jpeg_encode_init_Huffman(Standard_AC_Luminance_Nr,Standard_AC_Luminance_Val,p_Lum_AC_nr,p_Lum_AC_val)

        data p_Crom_DC_nr^CbCr_DC_Huffman_Table_nr
        data p_Crom_DC_val^CbCr_DC_Huffman_Table_value
        call jpeg_encode_init_Huffman(Standard_DC_Chromiance_Nr,Standard_DC_Chromiance_Val,p_Crom_DC_nr,p_Crom_DC_val)
        data p_Crom_AC_nr^CbCr_AC_Huffman_Table_nr
        data p_Crom_AC_val^CbCr_AC_Huffman_Table_value
        call jpeg_encode_init_Huffman(Standard_AC_Chromiance_Nr,Standard_AC_Chromiance_Val,p_Crom_AC_nr,p_Crom_AC_val)

        call jpeg_bytenew((value_set),(bytenew_start))
        call jpeg_bytepos((value_set),(bytepos_start))

        return (void)
    endif
    #bool
    import "array_get_word" array_get_word
    sd len
    sd value
    sd HTDC_nr
    sd HTDC_val
    sd HTAC_nr
    sd HTAC_val
    if lum_or_crom==(lum)
        set HTDC_nr p_Lum_DC_nr
        set HTDC_val p_Lum_DC_val
        set HTAC_nr p_Lum_AC_nr
        set HTAC_val p_Lum_AC_val
    else
        set HTDC_nr p_Crom_DC_nr
        set HTDC_val p_Crom_DC_val
        set HTAC_nr p_Crom_AC_nr
        set HTAC_val p_Crom_AC_val
    endelse
    #encode DC
    #(sd action,sd DCT_tab,sd lum_or_crom,sd prev_DC)
    import "short_to_int" short_to_int
    sd DCT_tab_0
    setcall DCT_tab_0 array_get_word(DCT_tab,0)
    setcall DCT_tab_0 short_to_int(DCT_tab_0)

    sd Diff
    set Diff DCT_tab_0
    sub Diff prev_DC#
    set prev_DC# DCT_tab_0

    if Diff==0
        setcall len array_get_byte(HTDC_nr,0)
        setcall value array_get_word(HTDC_val,0)
        sd bool
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif
    else
        sd pos
        set pos Diff
        add pos 32767

        sd cat_value
        setcall cat_value array_get_byte(category,pos)
        setcall len array_get_byte(HTDC_nr,cat_value)
        setcall value array_get_word(HTDC_val,cat_value)
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif

        setcall len array_get_byte(bits_length,pos)
        setcall value array_get_word(bits_value,pos)
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif
    endelse
    #encode AC
    #get first element !=0 in reverse order
    sd DCT_val
    sd startpos
    sd endpos
    set endpos 63
    sd loop=1
    while loop==1
        if endpos==0
            set loop 0
        else
            setcall DCT_val array_get_word(DCT_tab,endpos)
            if DCT_val!=0
                set loop 0
            else
                dec endpos
            endelse
        endelse
    endwhile
    sd i=1
    while i<=endpos
        set startpos i
        #advance i to first non zero
        set loop 1
        while loop==1
            if i>endpos
                set loop 0
            else
                setcall DCT_val array_get_word(DCT_tab,i)
                if DCT_val!=0
                    set loop 0
                else
                   inc i
                endelse
            endelse
        endwhile
        #total zeroes
        sd nr_zeroes
        set nr_zeroes i
        sub nr_zeroes startpos
        #
        if nr_zeroes>=16
            const HTAC_zeroes=0xF0
            setcall len array_get_byte(HTAC_nr,(HTAC_zeroes))
            setcall value array_get_word(HTAC_val,(HTAC_zeroes))

            sd nr_marker_max
            set nr_marker_max nr_zeroes
            div nr_marker_max 16

            sd nr_marker
            set nr_marker 1
            while nr_marker<=nr_marker_max
                setcall bool jpeg_write_data(len,value)
                if bool==0
                    return 0
                endif
                inc nr_marker
            endwhile

            import "rest" rest
            setcall nr_zeroes rest(nr_zeroes,16)
        endif
        #
        sd index
        setcall index array_get_word(DCT_tab,i)
        setcall index short_to_int(index)
        add index 32767
        #
        sd coef
        set coef nr_zeroes
        mult coef 16
        addcall coef array_get_byte(category,index)

        setcall len array_get_byte(HTAC_nr,coef)
        setcall value array_get_word(HTAC_val,coef)
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif
        #
        setcall len array_get_byte(bits_length,index)
        setcall value array_get_word(bits_value,index)
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif
        #
        inc i
    endwhile
    if endpos!=63
        const EOB=0x00
        setcall len array_get_byte(HTAC_nr,(EOB))
        setcall value array_get_word(HTAC_val,(EOB))
        setcall bool jpeg_write_data(len,value)
        if bool==0
            return 0
        endif
    endif
    return 1
endfunction

function jpeg_bytenew(sd action,sd value)
    data bytenew#1
    if action==(value_set)
        set bytenew value
    else
        return bytenew
    endelse
endfunction
function jpeg_bytepos(sd action,sd value)
    data bytepos#1
    if action==(value_set)
        set bytepos value
    else
        return bytepos
    endelse
endfunction

function jpeg_write_data(sd pos,sd data)
    #words style from chars
    chars m_data={1,   0,         2,   0,         4,    0,          8,    0}
    chars      *={16,  0,         32,  0,         64,   0,          128,  0}
    chars      *={256, 256/0x100, 512, 512/0x100, 1024, 1024/0x100, 2048, 2048/0x100}
    chars      *={4096,4096/0x100,8192,8192/0x100,16384,16384/0x100,32768,32768/0x100}
    str mask^m_data

    dec pos

    sd bytenew
    sd bytepos
    sd pbyte^bytenew
    setcall bytenew jpeg_bytenew((value_get))
    setcall bytepos jpeg_bytepos((value_get))

    while pos>=0
        sd mask_value
        setcall mask_value array_get_word(mask,pos)
        and mask_value data
        if mask_value!=0
            orcall bytenew array_get_word(mask,bytepos)
        endif
        dec pos
        dec bytepos
        #write file data
        if bytepos<0
            sd bool
            setcall bool jpeg_file_mem_add(pbyte,1)
            if bool!=1
                return 0
            endif
            if bytenew==0xff
                str null=""
                setcall bool jpeg_file_mem_add(null,1)
                if bool!=1
                    return 0
                endif
            endif

            set bytenew (bytenew_start)
            set bytepos (bytepos_start)
        endif
    endwhile
    #store the bytenew and bytepos for next round
    call jpeg_bytenew((value_set),bytenew)
    call jpeg_bytepos((value_set),bytepos)

    return 1
endfunction












#settings

function jpeg_dialog()
    ss j_sets="JPEG - Settings"
    import "dialogfield_size" dialogfield_size
    data jpeg_i_f^jpeg_settings_init
    data jpeg_s_f^jpeg_settings_set
    call dialogfield_size(j_sets,(GTK_DIALOG_MODAL),jpeg_i_f,jpeg_s_f,300,-1)
endfunction

function jpeg_settings_init(sd vbox,sd *dialog)
    str q="Quality: "
    import "hboxfield_cnt" hboxfield_cnt
    sd hbox
    setcall hbox hboxfield_cnt(vbox)
    import "labelfield_left_default" labelfield_left_default
    call labelfield_left_default(q,hbox)
    #
    importx "_gtk_hscale_new_with_range" gtk_hscale_new_with_range
    sd min_d_low
    sd min_d_high
    sd max_d_low
    sd max_d_high
    sd step_d_low
    sd step_d_high
    sd p_min_d^min_d_low
    sd p_max_d^max_d_low
    sd p_step_d^step_d_low
    call int_to_double(1,p_min_d)
    call int_to_double(900,p_max_d)
    call int_to_double(100,p_step_d)

    data hscale#1
    setcall hscale gtk_hscale_new_with_range(min_d_low,min_d_high,max_d_low,max_d_high,step_d_low,step_d_high)

    importx "_gtk_range_set_value" gtk_range_set_value
    sd currentpos
    setcall currentpos jpeg_quality((value_get))
    sd doublepos_low
    sd doublepos_high
    sd p_doublepos^doublepos_low
    call int_to_double(currentpos,p_doublepos)
    call gtk_range_set_value(hscale,doublepos_low,doublepos_high)

    import "packstart" packstart
    call packstart(hbox,hscale,(TRUE))
    #
    str max="Best"
    call labelfield_left_default(max,hbox)

    const p_hscale^hscale
endfunction

function jpeg_settings_set()
    import "file_write_forward_sys_folder_enter_leave" file_write_forward_sys_folder_enter_leave
    data forw_jpeg^jpeg_settings_set_write
    import "jpeg_file" jpeg_file
    ss jpeg_fl_str
    setcall jpeg_fl_str jpeg_file()
    call file_write_forward_sys_folder_enter_leave(jpeg_fl_str,forw_jpeg)
endfunction
function jpeg_settings_set_write(sd jpeg_fl)
    import "hscale_get" hscale_get
    sd p_hscale%p_hscale
    sd value
    setcall value hscale_get(p_hscale#)
    call jpeg_quality((value_set),value)

    sd p_value^value
    call file_write(p_value,4,jpeg_fl)
endfunction


#quality
function jpeg_quality(sd action,sd value)
    data quality#1
    if action==(value_set)
        set quality value
    else
        return quality
    endelse
endfunction

function jpeg_get_quality(sd mem,sd *size)
    sd quality
    sd p_quality^quality

    import "get_mem_int_advance" get_mem_int_advance
    sd mem_sz^mem
    sd err
    setcall err get_mem_int_advance(p_quality,mem_sz)
    if err!=(noerror)
        return 0
    endif
    call jpeg_quality((value_set),quality)
endfunction
