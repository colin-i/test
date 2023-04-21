

format elfobj

include "../_include/include.h"

const JPEG_LIB_VERSION=80
#const JCS_RGB=2

import "texter" texter



chars jerrstruct#jerr_size
const p_jerrstruct^jerrstruct
function get_jerr()
    data p%p_jerrstruct
    return p
endfunction

function init_jerr(sd jstruct)
    sd jerr
    setcall jerr get_jerr()

    importx "_jpeg_std_error" jpeg_std_error
    #jstruct.err
    setcall jstruct# jpeg_std_error(jerr)

    #jerr.error_exit
    data f^jpeg_errorhandle
    set jerr# f

    #execution allowed
    call jpeg_continue((value_set),1)
endfunction

#void
function jpeg_errorhandle(sd *j_common_ptr cinfo)
    #execution blocked
    call jpeg_continue((value_set),0)
    ss jerrtext="Jpeg error"
    call texter(jerrtext)
endfunction
function jpeg_continue(sd action,sd value)
    data continue#1
    if action==(value_set)
        set continue value
    else
        return continue
    endelse
endfunction














chars deinfo#jdestruct_size
const p_deinfo^deinfo
function get_jdestruct()
    data p%p_deinfo
    return p
endfunction

#bool continuation
function read_jpeg(sd file,sd forward)
    sd jdestruct
    setcall jdestruct get_jdestruct()

    #set error handle
    call init_jerr(jdestruct)

    sd continue

    #get memory
    import "jpeg_get_jdestruct_size" jpeg_get_jdestruct_size
    sd jdestruct_size
    setcall jdestruct_size jpeg_get_jdestruct_size()
    importx "_jpeg_CreateDecompress" jpeg_CreateDecompress
    call jpeg_CreateDecompress(jdestruct,(JPEG_LIB_VERSION),jdestruct_size)
    setcall continue jpeg_continue((value_get))
    if continue==0
        return continue
    endif

    call read_jpeg_prepare(file,forward)

    #free memory
    importx "_jpeg_destroy_decompress" jpeg_destroy_decompress
    call jpeg_destroy_decompress(jdestruct)

    setcall continue jpeg_continue((value_get))
    return continue
endfunction

function read_jpeg_prepare(sd file,sd forward)
    sd jdestruct
    setcall jdestruct get_jdestruct()

    sd continue

    #associate decompress file
    importx "_jpeg_stdio_src" jpeg_stdio_src
    call jpeg_stdio_src(jdestruct,file)
    setcall continue jpeg_continue((value_get))
    if continue==0
        return continue
    endif

    #read headers
    importx "_jpeg_read_header" jpeg_read_header
    #2nd arg=TRUE to reject a tables-only JPEG file as an error
    call jpeg_read_header(jdestruct,(TRUE))
    setcall continue jpeg_continue((value_get))
    if continue==0
        return continue
    endif

    importx "_jpeg_start_decompress" jpeg_start_decompress
    call jpeg_start_decompress(jdestruct)
    setcall continue jpeg_continue((value_get))
    if continue==0
        return continue
    endif

    call read_jpeg_scanlines(forward)

    importx "_jpeg_finish_decompress" jpeg_finish_decompress
    call jpeg_finish_decompress(jdestruct)
endfunction

function read_jpeg_scanlines(sd forward)
    sd jdestruct
    setcall jdestruct get_jdestruct()

    sd continue

    import "structure_get_int" structure_get_int
    #get file rowstride
    sd filerowstride
    import "jpeg_get_jdestruct_output_width" jpeg_get_jdestruct_output_width
    sd output_width
    setcall output_width jpeg_get_jdestruct_output_width()
    setcall output_width structure_get_int(jdestruct,output_width)

    import "jpeg_get_jdestruct_output_components" jpeg_get_jdestruct_output_components
    sd output_components
    setcall output_components jpeg_get_jdestruct_output_components()
    setcall output_components structure_get_int(jdestruct,output_components)

    set filerowstride output_width
    mult filerowstride output_components

    #alloc for reading
    sd alloc_sarray
    setcall alloc_sarray structure_get_int(jdestruct,4)
    setcall alloc_sarray structure_get_int(alloc_sarray,8)

    #Make a one-row-high sample array that will go away when done with image
    sd buffer
    setcall buffer alloc_sarray(jdestruct,(JPOOL_IMAGE),filerowstride,1)

    #read and forward the scanlines
    import "jpeg_get_jdestruct_output_height" jpeg_get_jdestruct_output_height
    sd output_height
    setcall output_height jpeg_get_jdestruct_output_height()
    setcall output_height structure_get_int(jdestruct,output_height)

    importx "_jpeg_read_scanlines" jpeg_read_scanlines
    sd j=0
    while j!=output_height
        call jpeg_read_scanlines(jdestruct,buffer,1)
        setcall continue jpeg_continue((value_get))
        if continue==0
            return continue
        endif
        setcall continue forward(buffer#,filerowstride,j)
        if continue==0
            call jpeg_continue((value_set),0)
            return continue
        endif
        inc j
    endwhile
endfunction
