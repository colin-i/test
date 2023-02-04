
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

importx "_ulltoa" ulltoa

const u64bytes=20
#18,446,744,073,684,385,791

function ldiv_lowdivisor(sv p,sd dividendlow,sd dividendhigh,sd divisor)
	#sd input#(4/:*3)+3
	chars input#u64bytes+1
	ss instr^input

	#%llu linux ok
	#windows? %I64u this is not working
	#call sprintf(instr,"%llu",dividendlow,dividendhigh)
	#call texter(instr)
	call ulltoa(dividendlow,dividendhigh,instr,10)

	# As result can be very large store it in string
	#sd quotient#(4/:*3)+3
	chars quotient#u64bytes
	sd rem
	ss dest;set dest instr
	addcall dest strlen(instr)
	setcall dest ldiv_lowdivisor_s(#quotient,instr,dest,divisor,#rem)
	if instr!=dest
		# set quotient and remainder

		#set dest# 0;call sscanf(#quotient,"%llu",p) #same as above but _strtoull is problematic at libmingwex.a
		call memto64(#quotient,dest,p)

		add p (2*:)
		set p# rem
	else
		# If divisor is greater than number
		set p# 0
		add p :
		set p# 0
		add p :
		set p# dividendlow
	endelse
endfunction
function ldiv_lowdivisor_s(ss outstr,ss instr,ss dest,sd divisor,sd p_rem)
	sd start;set start instr
	if divisor>(0xcCCccCC) #(this-1)*10+9=0x7f...F7 +0xa=0x8...1
		#there will be troubles in two places without this
		dec dest
		if instr==dest
			return start
		endif
		set dest# 0
		div divisor 10
	endif
	# Find prefix of number that is larger than divisor.
	sd n
	sd temp
	set temp instr#
	sub temp (_0)
	while temp<divisor
		inc instr
		if instr==dest
			return start
		endif
		set n instr#
		sub n (_0)
		#sd test
		#...
		#dec instr
		#else
		mult temp 10
		add temp n
	endwhile
	# Repeatedly divide divisor with temp. After every division, update temp to include one more digit.
	while instr!=dest
		# Store result in answer i.e. temp / divisor
		set n temp
		div n divisor
		add n (_0)
		set outstr# n
		inc outstr
		# Take next digit of number
		rem temp divisor
		inc instr
		if instr!=dest
			mult temp 10
			add temp instr#
			sub temp (_0)
		endif
	endwhile
	set p_rem# temp
	return outstr
endfunction
function memto64(sd in,ss dest,sd out)
	const hconv64=16+1
	chars h#hconv64
	#sd h#(4/:*2)+3
	ss hex^h
	add hex (hconv64-1)
	sd sz;set sz hex
	set hex# 0
	chars quotient#u64bytes
	sd in2;set in2 #quotient
	sd rem

	sd prev
	set prev dest
	setcall dest ldiv_lowdivisor_s(in2,in,dest,16,#rem)
	while in!=dest
		dec hex
		setcall hex# inttohchar(rem)
		sd aux;set aux in2
		set in2 in;set in aux
		set prev dest
		setcall dest ldiv_lowdivisor_s(in2,in,dest,16,#rem)
	endwhile
	set prev# 0;call sscanf(in,"%u",#rem)
	dec hex;setcall hex# inttohchar(rem)

	sd high
	sub sz hex
	if sz>8
		set high hex
		sub sz 8
		add hex sz
	else
		set high (NULL)
	endelse
	call sscanf(hex,"%x",out)
	add out :
	if high!=(NULL)
		set hex# 0
		call sscanf(high,"%x",out)
		return (void)
	endif
	set out# 0
endfunction
function inttohchar(sd a)
	if a<10
		add a (_0)
	else
		add a (A-10)
	endelse
	return a
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
    sd resLow
    sd resHigh
    sd remLow
    #data *remHigh#1
    sd ptrresult^resLow

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
		data *duration64high#1
		data ptrduration^duration64low
		const ptrduration^duration64low

		data current64low#1
		data *current64high#1
		data ptrcurrent^current64low

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
			chars printduration#10+1+2+1+2+3+10+1+2+1+2+1
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
	data threadID=-1
	const p_threadID^threadID
	set threadID -1
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
	call gst_message_parse_state_changed(message,null,ptrnewstate,null)

	data GST_STATE_PLAYING=GST_STATE_PLAYING
	if newstate==GST_STATE_PLAYING
		data quadword=8

		sd duration%ptrduration

		import "setmem" setmem
		call setmem(duration,quadword,(GST_CLOCK_TIME_NONE_lowhigh))

		importx "_gst_element_query_duration" gst_element_query_duration
		data format=GST_FORMAT_TIME
		data ptrformat^format
		data ptrplaybin#1
		setcall ptrplaybin getplaybin2ptr()
		call gst_element_query_duration(ptrplaybin#,ptrformat,duration)

		if duration#!=(GST_CLOCK_TIME_NONE_lowhigh)
			add duration (DWORD)
			if duration#!=(GST_CLOCK_TIME_NONE_lowhigh)
				vdata p_threadID%p_threadID
				if p_threadID#<0

					data ptrplaybool%globalplaybool
					data true=1

					set ptrplaybool# true
					data msec=1000
					data tm^streamtimer
					setcall p_threadID# gdk_threads_add_timeout(msec,tm,null)

					str playing="Playing..."
					call texter(playing)
				endif
			endif
		endif
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
