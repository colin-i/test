



format elfobj

include "../_include/include.h"

function mpeg_init_vlc()
    call vlc_tables_intra((value_set))
endfunction

const levelstride=VLC_size
const runstride=64*levelstride
const laststride=64*runstride

function vlc_tables_intra(sd action,sd name,sd last,sd run,sd level)
    const vlc_array_size=2*64*64*VLC_size
    #[2][64][64]
    #data code
    #chars len
    chars vlc_data#vlc_array_size
    if action==(value_set)
        #set tables to 0 or bad code can be written
        import "setmem" setmem
        sd vlc_init^vlc_data
        call setmem(vlc_init,(vlc_array_size),0)
        call vlc_tables_len_init()
        call vlc_tables_len_init2()
        call vlc_tables_len_init3()
    else
    #if action==(value_get)
    #pointer
        ss vlc^vlc_data
        mult last (laststride)
        mult run (runstride)
        mult level (levelstride)
        add vlc last
        add vlc run
        add vlc level
        add vlc name
        return vlc
    endelse
endfunction

##1

#const LEVELOFFSET=32
function vlc_tables_len_init()
    sd last=0
    while last<2
        sd run=0
        sd last_run
        set last_run 63
        add last_run last
        while run<last_run
            sd level=0
            while level<(32*2)
                ss vlc_l
                setcall vlc_l vlc_tables_intra((value_get),(VLC_len),last,level,run)
                set vlc_l# 128

                inc level
            endwhile
            inc run
        endwhile
        inc last
    endwhile
endfunction

const coeff_tab_vlc=VLC_code
const coeff_tab_vlc_code=VLC_code
const coeff_tab_vlc_len=VLC_len

const coeff_tab_event=coeff_tab_vlc_len+1
const coeff_tab_event_last=0
const coeff_tab_event_run=1
const coeff_tab_event_level=2

##2

function vlc_coeff_tab_intra(sd i,sd block,sd subblock)
    #vlc
        #code  u32
        #len   u8
    #event
        #last  u8
        #run   u8
        #level i8
    chars tab={2, 0,0,0,  2,    0, 0, 1}
    chars *  ={15,0,0,0,  4,    0, 0, 3}
    chars *  ={21,0,0,0,  6,    0, 0, 6}
    chars *  ={23,0,0,0,  7,    0, 0, 9}
    chars *  ={31,0,0,0,  8,    0, 0, 10}
    chars *  ={37,0,0,0,  9,    0, 0, 13}
    chars *  ={36,0,0,0,  9,    0, 0, 14}
    chars *  ={33,0,0,0, 10,    0, 0, 17}
    chars *  ={32,0,0,0, 10,    0, 0, 18}
    chars *  ={ 7,0,0,0, 11,    0, 0, 21}
    chars *  ={ 6,0,0,0, 11,    0, 0, 22}
    chars *  ={32,0,0,0, 11,    0, 0, 23}
    chars *  ={ 6,0,0,0,  3,    0, 0, 2}
    chars *  ={20,0,0,0,  6,    0, 1, 2}
    chars *  ={30,0,0,0,  8,    0, 0, 11}
    chars *  ={15,0,0,0, 10,    0, 0, 19}
    chars *  ={33,0,0,0, 11,    0, 0, 24}
    chars *  ={80,0,0,0, 12,    0, 0, 25}
    chars *  ={14,0,0,0,  4,    0, 1, 1}
    chars *  ={29,0,0,0,  8,    0, 0, 12}
    chars *  ={14,0,0,0, 10,    0, 0, 20}
    chars *  ={81,0,0,0, 12,    0, 0, 26}
    chars *  ={13,0,0,0,  5,    0, 0, 4}
    chars *  ={35,0,0,0,  9,    0, 0, 15}
    chars *  ={13,0,0,0, 10,    0, 1, 7}
    chars *  ={12,0,0,0,  5,    0, 0, 5}
    chars *  ={34,0,0,0,  9,    0, 4, 2}
    chars *  ={82,0,0,0, 12,    0, 0, 27}
    chars *  ={11,0,0,0,  5,    0, 2, 1}
    chars *  ={12,0,0,0, 10,    0, 2, 4}
    chars *  ={83,0,0,0, 12,    0, 1, 9}
    chars *  ={19,0,0,0,  6,    0, 0, 7}
    chars *  ={11,0,0,0, 10,    0, 3, 4}
    chars *  ={84,0,0,0, 12,    0, 6, 3}
    chars *  ={18,0,0,0,  6,    0, 0, 8}
    chars *  ={10,0,0,0, 10,    0, 4, 3}
    chars *  ={17,0,0,0,  6,    0, 3, 1}
    chars *  ={ 9,0,0,0, 10,    0, 8, 2}
    chars *  ={16,0,0,0,  6,    0, 4, 1}
    chars *  ={ 8,0,0,0, 10,    0, 5, 3}
    chars *  ={22,0,0,0,  7,    0, 1, 3}
    chars *  ={85,0,0,0, 12,    0, 1, 10}
    chars *  ={21,0,0,0,  7,    0, 2, 2}
    chars *  ={20,0,0,0,  7,    0, 7, 1}
    chars *  ={28,0,0,0,  8,    0, 1, 4}
    chars *  ={27,0,0,0,  8,    0, 3, 2}
    chars *  ={33,0,0,0,  9,    0, 0, 16}
    chars *  ={32,0,0,0,  9,    0, 1, 5}
    chars *  ={31,0,0,0,  9,    0, 1, 6}
    chars *  ={30,0,0,0,  9,    0, 2, 3}
    chars *  ={29,0,0,0,  9,    0, 3, 3}
    chars *  ={28,0,0,0,  9,    0, 5, 2}
    chars *  ={27,0,0,0,  9,    0, 6, 2}
    chars *  ={26,0,0,0,  9,    0, 7, 2}
    chars *  ={34,0,0,0, 11,    0, 1, 8}
    chars *  ={35,0,0,0, 11,    0, 9, 2}
    chars *  ={86,0,0,0, 12,    0, 2, 5}
    chars *  ={87,0,0,0, 12,    0, 7, 3}
    chars *  ={ 7,0,0,0,  4,    1, 0, 1}
    chars *  ={25,0,0,0,  9,    0, 11, 1}
    chars *  ={ 5,0,0,0, 11,    1, 0, 6}
    chars *  ={15,0,0,0,  6,    1, 1, 1}
    chars *  ={ 4,0,0,0, 11,    1, 0, 7}
    chars *  ={14,0,0,0,  6,    1, 2, 1}
    chars *  ={13,0,0,0,  6,    0, 5, 1}
    chars *  ={12,0,0,0,  6,    1, 0, 2}
    chars *  ={19,0,0,0,  7,    1, 5, 1}
    chars *  ={18,0,0,0,  7,    0, 6, 1}
    chars *  ={17,0,0,0,  7,    1, 3, 1}
    chars *  ={16,0,0,0,  7,    1, 4, 1}
    chars *  ={26,0,0,0,  8,    1, 9, 1}
    chars *  ={25,0,0,0,  8,    0, 8, 1}
    chars *  ={24,0,0,0,  8,    0, 9, 1}
    chars *  ={23,0,0,0,  8,    0, 10, 1}
    chars *  ={22,0,0,0,  8,    1, 0, 3}
    chars *  ={21,0,0,0,  8,    1, 6, 1}
    chars *  ={20,0,0,0,  8,    1, 7, 1}
    chars *  ={19,0,0,0,  8,    1, 8, 1}
    chars *  ={24,0,0,0,  9,    0, 12, 1}
    chars *  ={23,0,0,0,  9,    1, 0, 4}
    chars *  ={22,0,0,0,  9,    1, 1, 2}
    chars *  ={21,0,0,0,  9,    1, 10, 1}
    chars *  ={20,0,0,0,  9,    1, 11, 1}
    chars *  ={19,0,0,0,  9,    1, 12, 1}
    chars *  ={18,0,0,0,  9,    1, 13, 1}
    chars *  ={17,0,0,0,  9,    1, 14, 1}
    chars *  ={7, 0,0,0, 10,    0, 13, 1}
    chars *  ={6, 0,0,0, 10,    1, 0, 5}
    chars *  ={5, 0,0,0, 10,    1, 1, 3}
    chars *  ={4, 0,0,0, 10,    1, 2, 2}
    chars *  ={36,0,0,0, 11,    1, 3, 2}
    chars *  ={37,0,0,0, 11,    1, 4, 2}
    chars *  ={38,0,0,0, 11,    1, 15, 1}
    chars *  ={39,0,0,0, 11,    1, 16, 1}
    chars *  ={88,0,0,0, 12,    0, 14, 1}
    chars *  ={89,0,0,0, 12,    1, 0, 8}
    chars *  ={90,0,0,0, 12,    1, 5, 2}
    chars *  ={91,0,0,0, 12,    1, 6, 2}
    chars *  ={92,0,0,0, 12,    1, 17, 1}
    chars *  ={93,0,0,0, 12,    1, 18, 1}
    chars *  ={94,0,0,0, 12,    1, 19, 1}
    chars *  ={95,0,0,0, 12,    1, 20, 1}

    data coeff_tab^tab
    data stride=4+1+3

    sd value
    set value i
    mult value stride
    add value block
    add value subblock
    add value coeff_tab

    if block==(coeff_tab_vlc)
        if subblock==(coeff_tab_vlc_code)
            return value#
        endif
    endif
    ss byte
    set byte value
    return byte#
endfunction

function vlc_tables_len_init2()
    sd i=0
    while i<102
        sd value

        sd run
        setcall run vlc_coeff_tab_intra(i,(coeff_tab_event),(coeff_tab_event_run))
        sd level
        setcall level vlc_coeff_tab_intra(i,(coeff_tab_event),(coeff_tab_event_level))
        sd last
        setcall last vlc_coeff_tab_intra(i,(coeff_tab_event),(coeff_tab_event_last))

        #code
        sd code
        setcall code vlc_coeff_tab_intra(i,(coeff_tab_vlc),(coeff_tab_vlc_code))
        mult code 2
        #
        sd vlc_c
        setcall vlc_c vlc_tables_intra((value_get),(VLC_code),last,level,run)
        set vlc_c# code

        #len
        setcall value vlc_coeff_tab_intra(i,(coeff_tab_vlc),(coeff_tab_vlc_len))
        inc value
        #
        ss vlc_l
        setcall vlc_l vlc_tables_intra((value_get),(VLC_len),last,level,run)
        set vlc_l# value

        inc i
    endwhile
endfunction

##3

function vlc_tables_intra_maxrun(sd last,sd pos)
    chars last0={0, 14, 9, 7, 3, 2, 1, 1}
    chars *    ={1, 1,  1, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}

    chars last1={0, 20, 6, 1, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}
    chars *    ={0, 0,  0, 0, 0, 0, 0, 0}

    if last==0
        ss max0^last0
        add max0 pos
        return max0#
    else
        ss max1^last1
        add max1 pos
        return max1#
    endelse
endfunction

function vlc_tables_intra_maxlevel(sd last,sd pos)
    #u8
    chars last0={27,10, 5, 4, 3, 3, 3, 3}
    chars *    ={2,  2, 1, 1, 1, 1, 1, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}
    chars *    ={0,  0, 0, 0, 0, 0, 0, 0}

    chars last1={8, 3, 2, 2, 2, 2, 2, 1}
    chars *    ={1, 1, 1, 1, 1, 1, 1, 1}
    chars *    ={1, 1, 1, 1, 1, 0, 0, 0}
    chars *    ={0, 0, 0, 0, 0, 0, 0, 0}
    chars *    ={0, 0, 0, 0, 0, 0, 0, 0}
    chars *    ={0, 0, 0, 0, 0, 0, 0, 0}
    chars *    ={0, 0, 0, 0, 0, 0, 0, 0}
    chars *    ={0, 0, 0, 0, 0, 0, 0, 0}

    if last==0
        ss max0^last0
        add max0 pos
        return max0#
    else
        ss max1^last1
        add max1 pos
        return max1#
    endelse
endfunction

function vlc_tables_len_init3()
    sd last=0
    while last<2
        sd run=0
        sd last_run
        set last_run 63
        add last_run last
        while run<last_run
            sd level=1
            while level<(32*2)
                sd condition=0
                sd max
                setcall max vlc_tables_intra_maxlevel(last,run)
                if level<=max
                    setcall max vlc_tables_intra_maxrun(last,level)
                    if run<=max
                        set condition 1
                    endif
                endif
                if condition==0
                    sd continuation=1

                    sd level_esc
                    set level_esc level
                    subcall level_esc vlc_tables_intra_maxlevel(last,run)
                    sd run_esc
                    set run_esc run
                    dec run_esc
                    subcall run_esc vlc_tables_intra_maxrun(last,level)

                    set condition 0
                    setcall max vlc_tables_intra_maxlevel(last,run)
                    if level_esc<=max
                        setcall max vlc_tables_intra_maxrun(last,level_esc)
                        if run<=max
                            set condition 1
                        endif
                    endif
                    sd escape
                    sd escape_len
                    if condition==1
                        set escape (ESCAPE1)
                        set escape_len (7+1)
                        set run_esc run
                    else
                        set condition 0
                        setcall max vlc_tables_intra_maxrun(last,level)
                        if run_esc<=max
                            if run_esc<0
                                set max 0
                            else
                                setcall max vlc_tables_intra_maxlevel(last,run_esc)
                            endelse
                            if level<=max
                                set condition 1
                            endif
                        endif
                        if condition==1
                            set escape (ESCAPE2)
                            set escape_len (7+2)
                            set level_esc level
                        else
                            set continuation 0
                        endelse
                    endelse

                    if continuation==1
                        ss vlc_len_src
                        setcall vlc_len_src vlc_tables_intra((value_get),(VLC_len),last,level_esc,run_esc)
                        sd len
                        set len vlc_len_src#

                        #code
                        sd vlc_code_dest
                        setcall vlc_code_dest vlc_tables_intra((value_get),(VLC_code),last,level,run)
                        sd vlc_code_src
                        setcall vlc_code_src vlc_tables_intra((value_get),(VLC_code),last,level_esc,run_esc)
                        sd code
                        set code vlc_code_src#
                        import "shl" shl
                        orcall code shl(escape,len)
                        #len
                        ss vlc_len_dest
                        setcall vlc_len_dest vlc_tables_intra((value_get),(VLC_len),last,level,run)
                        add len escape_len

                        set vlc_code_dest# code
                        set vlc_len_dest# len
                    endif
                endif

                inc level
            endwhile
            inc run
        endwhile
        inc last
    endwhile
endfunction
