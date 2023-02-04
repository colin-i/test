
format elfobj

include "../_include/include.h"

importx "_sprintf" sprintf
importx "_sscanf" sscanf
importx "_strlen" strlen

import "getplaybin2ptr" getplaybin2ptr

import "nullifyplaybin" nullifyplaybin
import "texter" texter
function endofstream()
    str eos="End Of Stream"
    call texter(eos)
    call nullifyplaybin()
endfunction

importx "_gst_message_parse_error" gst_message_parse_error
import "getptrgerr" getptrgerr
import "gerrtoerr" gerrtoerr
function stream_error(data message)
    data ptrgerr#1
    setcall ptrgerr getptrgerr()
    data null=NULL
    call gst_message_parse_error(message,ptrgerr,null)
    call gerrtoerr(ptrgerr)
endfunction
function streamerror(data *bus,data message)
    call stream_error(message)
endfunction

function ldiv_lowdivisor(sd p,sd dividendlow,sd dividendhigh,sd divisor)
	sd n
	#20 and a null
	chars input#21
	vstr instr^input
	call sprintf(instr,"%llu",dividendlow,dividendhigh)
	sd size
	setcall size strlen(instr)
	# Find prefix of number that is larger than divisor.
	sd idx=0
	sd temp
	set temp instr#
	sub temp (_0)
	while temp<divisor
		inc instr
		inc idx
		set n instr#
		sub n (_0)
		mult temp 10
		add temp n
	endwhile
	# As result can be very large store it in string
	chars quotient#21
	vstr outstr^quotient
	# Repeatedly divide divisor with temp. After every division, update temp to include one more digit.
	set outstr# 0
	while size>idx
		# Store result in answer i.e. temp / divisor
		set n temp
		div n divisor
		add n (_0)
		set outstr# n
		inc outstr
		set outstr# 0
		# Take next digit of number
		rem temp divisor
		mult temp 10
		inc instr
		inc idx
		add temp instr#
		sub temp (_0)
	endwhile
	# If divisor is greater than number
	setcall size strlen(#quotient)
	if size==0
		set p# 0
		add p (DWORD)
		set p# 0
		add p (DWORD)
		set p# dividendlow
		return (void)
	endif
	# set quotient and remainder
	call sscanf(#quotient,"%llu",p)
	add p (2*DWORD)
	set p# temp
endfunction
function splitGstClockTime(data ptrclock,data ptrtime)
    data dword=4

    data clockLow#1
    data clockHigh#1
    data ptrH#1
    data ptrM#1
    data ptrS#1
    set clockLow ptrclock#
    add ptrclock dword
    set clockHigh ptrclock#
    set ptrH ptrtime
    add ptrtime dword
    set ptrM ptrtime
    add ptrtime dword
    set ptrS ptrtime

    data nomLow#1
    #data nomHigh=0
    data resLow#1
    data resHigh#1
    data remLow#1
    #data *remHigh#1
    data ptrresult^resLow

    data gstsec=GST_SECOND
    set nomLow gstsec
    call ldiv_lowdivisor(ptrresult,clockLow,clockHigh,nomLow) #,nomHigh

    data secinH=3600
    set nomLow secinH
    call ldiv_lowdivisor(ptrresult,resLow,resHigh,nomLow) #,nomHigh

    set ptrH# resLow

    data thenumber=60
    data x#1
    set x remLow
    div x thenumber
    set ptrM# x

    mult x thenumber
    sub remLow x
    set ptrS# remLow
endfunction

importx "_gst_element_query_position" gst_element_query_position
#false=stop timer,true=displayed
function streamtimer(data *data)
    data playbool#1
    const globalplaybool^playbool
    data true=1
    data false=0

    if playbool==true
        data duration64low#1
        data duration64high#1
        data ptrduration^duration64low
        const ptrduration^duration64low

        data current64low#1
        data *current64high#1
        data ptrcurrent^current64low

        data CLOCK_NONE=GST_CLOCK_TIME_NONE_lowhigh
        if duration64low!=CLOCK_NONE
            if duration64high!=CLOCK_NONE
                data bool#1
                data ptrplaybin#1
                data format=GST_FORMAT_TIME
                data ptrformat^format

                setcall ptrplaybin getplaybin2ptr()
                setcall bool gst_element_query_position(ptrplaybin#,ptrformat,ptrcurrent)
                if bool==false
                    str poserr="Could not query current position."
                    call texter(poserr)
                else
                    chars printduration#200
                    str print^printduration

                    data durH#1
                    data durM#1
                    data durS#1
                    data posH#1
                    data posM#1
                    data posS#1

                    data ptrdur^durH
                    data ptrpos^posH

                    call splitGstClockTime(ptrduration,ptrdur)
                    call splitGstClockTime(ptrcurrent,ptrpos)

                    str timeformat="%u:%02u:%02u / %u:%02u:%02u"
                    call sprintf(print,timeformat,posH,posM,posS,durH,durM,durS)
                    call texter(print)
                    return true
                endelse
            endif
        endif
    endif
    return false
endfunction

function unset_playbool()
    data ptr%globalplaybool
    data false=0
    set ptr# false
endfunction
function get_playbool()
    data ptr%globalplaybool
    return ptr#
endfunction

importx "_gst_message_parse_state_changed" gst_message_parse_state_changed
importx "_gdk_threads_add_timeout" gdk_threads_add_timeout
function statechanged(data *bus,data message)
    data newstate#1
    data ptrnewstate^newstate
    data null=0
    data true=1
    data ptrplaybool%globalplaybool

    call gst_message_parse_state_changed(message,null,ptrnewstate,null)

    data GST_STATE_PLAYING=GST_STATE_PLAYING
    data duration%ptrduration
    data clock_none=GST_CLOCK_TIME_NONE_lowhigh
    data quadword=8
    if newstate==GST_STATE_PLAYING
        set ptrplaybool# true
        data msec=1000
        data tm^streamtimer
        call gdk_threads_add_timeout(msec,tm,null)

        str playing="Playing..."
        call texter(playing)

        import "setmem" setmem
        call setmem(duration,quadword,clock_none)

        importx "_gst_element_query_duration" gst_element_query_duration
        data format=GST_FORMAT_TIME
        data ptrformat^format
        data ptrplaybin#1
        setcall ptrplaybin getplaybin2ptr()
        call gst_element_query_duration(ptrplaybin#,ptrformat,duration)
    endif
endfunction

import "rec_unset" rec_unset
function stop()
    call nullifyplaybin()
    call rec_unset()
    str stopped="Stopped"
    call texter(stopped)
endfunction

importx "_g_object_set" g_object_set
importx "_gst_element_set_state" gst_element_set_state
#void
function streamuri(data buffer)
    call nullifyplaybin()

    data playbin2ptr#1
    setcall playbin2ptr getplaybin2ptr()

    data null=0
    str uri="uri"
    call g_object_set(playbin2ptr#,uri,buffer,null)

    data GST_STATE_PLAYING=GST_STATE_PLAYING
    call gst_element_set_state(playbin2ptr#,GST_STATE_PLAYING)
endfunction

function play_click()
    import "editWidgetBufferForward" editWidgetBufferForward
    data forward^streamuri
    call editWidgetBufferForward(forward)
endfunction


