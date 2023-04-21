

format elfobj

include "ascii.h"
include "common.h"

include "util.s"
include "values.s"

const WAVE_FORMAT_PCM=1

#this program record sound from the default recording device and writes to the wav format

#the mechanism is simple:
#main thread:
#flag stop
#create event
    #create thread
        #openwav
            #buffer,prepare,add
                #buffer,prepare,add
                    #start
                        #flag ok,set event
                        #getch
                        #reset event,flag stop,wait event

#second thread:
    #wait event,verify flag ok
        #get buffers and write
        #verify flag stop
            #1. continue
            #2. finish all bufers and set event and return

import "_CloseHandle@4" CloseHandle
import "_fopen" fopen
import "_fclose" fclose

#bool
function record_options(sd file)
    import "_fseek" fseek
    import "_ftell" ftell
    str lengtherr="Options file length error"
    sd len
    sd fileresult

    setcall fileresult fseek(file,0,(SEEK_END))
    if fileresult!=0
        call errors(lengtherr)
        return 0
    endif
    setcall len ftell(file)
    if len<=0
        call errors(lengtherr)
        return 0
    endif
    setcall fileresult fseek(file,0,(SEEK_SET))
    if fileresult!=0
        call errors(lengtherr)
        return 0
    endif

    const max_options_length=100

    chars text#max_options_length
    ss options_text^text

    if len>=(max_options_length)
        call errors(lengtherr)
        return 0
    endif

    import "_fread" fread
    sd readed
    setcall readed fread(options_text,1,len,file)
    if readed!=len
        str readerr="Read error"
        call errors(readerr)
        return 0
    endif
    chars spc=" "

    ss safe
    set safe options_text
    add safe readed
    set safe# spc
    inc len

    sd count=0
    ss cursor
    set cursor options_text
    while len!=0
        if cursor#==spc
            import "_atoi" atoi
            set cursor# 0
            sd value
            setcall value atoi(options_text)
            if value<1
                str lowval="Wrong option"
                call errors(lowval)
                return 0
            endif
            if count==0
                call channels_value((value_set),value)
            elseif count==1
                call rate_value((value_set),value)
            else
                if value<8
                    str lowbps="Wrong bps"
                    call errors(lowbps)
                    return 0
                endif
                call bps_value((value_set),value)
            endelse
            set options_text cursor
            inc options_text
            inc count
        endif
        inc cursor
        dec len
    endwhile
    set cursor# 0

    if count!=3
        str index_expected="More options expected"
        call errors(index_expected)
        return 0
    endif

    return 1
endfunction

function record_sound()
    call record_flag((value_set),(flag_stop))

    import "_CreateEventA@16" CreateEvent
    #HANDLE WINAPI CreateEvent(
    #  __in_opt  LPSECURITY_ATTRIBUTES lpEventAttributes,
    #  __in      BOOL bManualReset,
    #  __in      BOOL bInitialState,
    #  __in_opt  LPCTSTR lpName);

    sd event
    setcall event CreateEvent(0,0,0,0)

    call record_event((value_set),event)

    call record_createthread()

    #in case we got errors, to stop the second thread
    #knowing that Resetting an event that is already reset has no effect
    import "_ResetEvent@4" ResetEvent
    call ResetEvent(event)

    call CloseHandle(event)

    import "_exit" exit
    call exit(1)
endfunction

function record_createthread()
    import "_CreateThread@24" CreateThread

    data f^record_second_thread

    sd thread_id
    sd p_thread_id^thread_id

    sd thread
    setcall thread CreateThread(0,0,f,0,0,p_thread_id)
    if thread==0
        return 0
    endif

    call record_fileandsizes(thread_id)

    call CloseHandle(thread)
endfunction

####################

function record_fileandsizes(sd thread_id)
    import "_time" time
    sd tm
    setcall tm time()
    import "_sprintf" sprintf
    chars filename_data#100
    str filename^filename_data
    str format="%u.wav"
    call sprintf(filename,format,tm)

    str wr="wb"
    sd file
    setcall file fopen(filename,wr)
    if file==0
        str err="Cannot open the output file."
        call errors(err)
        return 0
    endif

    call record_got_file(file,thread_id)

    call fclose(file)
endfunction

function record_got_file(sd file,sd thread_id)
#const _RIFF^riff
const _RIFF=!
    chars riff={R,I,F,F}
    data riffsize#1

    chars WAVE={W,A,V,E}
    chars *fmt={f,m,t,Space}
    data fmtsize#1
    #WAVEFORMATEX
    chars wFormatTag={WAVE_FORMAT_PCM,0}
    chars nChannels={1,0}
    data nSamplesPerSec#1
    data nAvgBytesPerSec#1
    chars nBlockAlign={2,0}
    chars wBitsPerSample={16,0}
    #EX
    #no extra data, simple PCM-format used
    chars *cbSize={0,0}

    chars datatag={d,a,t,a}
    data datasize#1

#const RIFF_^RIFF
const RIFF_=!

    data RIFF^riff
    const RIFF_size=RIFF_-_RIFF

    const _WAVEFORMATEX^wFormatTag
    const WAVEFORMATEX_^datatag
    set fmtsize (WAVEFORMATEX_-_WAVEFORMATEX)

    setcall nChannels channels_value((value_get))
    setcall nSamplesPerSec rate_value((value_get))
    setcall wBitsPerSample bps_value((value_get))
    setcall nBlockAlign blockalign_value()
    setcall nAvgBytesPerSec avgbytespersec_value()

    sd bool
    setcall bool file_write(RIFF,(RIFF_size),file)
    if bool==0
        return 0
    endif

    #store file for buffer write
    call record_file((value_set),file)

    sd hwi
    sd p_hwi^hwi
    str WAVEFORMATEX^wFormatTag

    import "_waveInOpen@24" waveInOpen
    sd wavecall
    setcall wavecall waveInOpen(p_hwi,0,WAVEFORMATEX,thread_id,0,(CALLBACK_THREAD))
    if wavecall!=(MMSYSERR_NOERROR)
        return 0
    endif

    call record_hwavein((value_set),hwi)

    call record_got_wavein()

    import "_waveInClose@4" waveInClose
    call waveInClose(hwi)

    #write riffsize and datasize
    sd position
    setcall position ftell(file)
    if position==(INVALID_HANDLE)
        str ertell="Get file position error"
        call errors(ertell)
        return 0
    endif

    set datasize position
    sub datasize (RIFF_size)

    sd even
    set even position
    and even 1
    if even==1
        str pad=""
        setcall bool file_write(pad,1,file)
        if bool!=1
            return 0
        endif
        inc position
    endif

    set riffsize position
    sub riffsize (4+4)

    str endseekerr="File seek error"

    sd seekint
    SetCall seekint fseek(file,4,(SEEK_SET))
    If seekint!=0
        call errors(endseekerr)
        return 0
    endif

    sd p_rifsz^riffsize
    setcall bool file_write(p_rifsz,4,file)
    if bool!=1
        return 0
    endif

    const _RIFF_block_start^WAVE
    const datasize_off^datasize

    SetCall seekint fseek(file,(datasize_off-_RIFF_block_start),(SEEK_CUR))
    If seekint!=0
        call errors(endseekerr)
        return 0
    endif

    sd p_datasize^datasize
    call file_write(p_datasize,4,file)
endfunction

#get two buffers, when one is full, write it to file, in the same time, the other one can record

function record_got_wavein()
    sd len
    setcall len BufferLength_value()
    sd buffer
    setcall buffer alloc(len)
    if buffer==0
        return 0
    endif
    import "_free" free

    call record_prepare_buffer(buffer)

    call free(buffer)
endfunction

function record_prepare_buffer(sd buffer)
    data lpData#1
    data dwBufferLength#1
    data *dwBytesRecorded#1
    data *dwUser#1
    data *dwFlags=0
    data *dwLoops#1
    data *lpNext#1
    data *reserved#1

    sd wavehd^lpData

#lpData, dwBufferLength, and dwFlags members must be set
    set lpData buffer

    setcall dwBufferLength BufferLength_value()

    sd wavein
    setcall wavein record_hwavein((value_get))

    sd bool
    setcall bool wavein_prepare(wavein,wavehd)
    if bool!=1
        return 0
    endif

    call record_prepare_add(wavein,wavehd)

    import "_waveOutUnprepareHeader@12" waveInUnprepareHeader
    call waveInUnprepareHeader(wavein,wavehd,(WAVEHDR_size))
endfunction

function record_prepare_add(sd wavein,sd wavehdr)
    sd bool
    setcall bool wavein_add(wavein,wavehdr)
    if bool!=1
        return 0
    endif
    call record_buffer_next()
endfunction

function record_buffer_next()
    sd len
    setcall len BufferLength_value()
    sd buffer_2
    setcall buffer_2 alloc(len)
    if buffer_2==0
        return 0
    endif
    call record_prepare_buffer_2(buffer_2)
    call free(buffer_2)
endfunction


function record_prepare_buffer_2(sd buffer)
    data lpData#1
    data dwBufferLength#1
    data *dwBytesRecorded#1
    data *dwUser#1
    data *dwFlags=0
    data *dwLoops#1
    data *lpNext#1
    data *reserved#1

    sd wavehd^lpData

#lpData, dwBufferLength, and dwFlags members must be set
    set lpData buffer

    setcall dwBufferLength BufferLength_value()

    sd wavein
    setcall wavein record_hwavein((value_get))

    sd bool
    setcall bool wavein_prepare(wavein,wavehd)
    if bool!=1
        return 0
    endif

    call record_start(wavein,wavehd)

    call waveInUnprepareHeader(wavein,wavehd,(WAVEHDR_size))
endfunction

function record_start(sd wavein,sd wavehdr)
    sd bool
    setcall bool wavein_add(wavein,wavehdr)
    if bool!=1
        return 0
    endif

    import "_waveInStart@4" waveInStart
    sd mm
    setcall mm waveInStart(wavein)
    if mm!=(MMSYSERR_NOERROR)
        return 0
    endif

    call record_dialog()

    import "_waveInStop@4" waveInStop
    call waveInStop(wavein)
#create an event
endfunction

function record_dialog()
    call record_buffers((value_set),2)

    call record_flag((value_set),(flag_recording))

    sd event
    setcall event record_event((value_get))

    import "_SetEvent@4" SetEvent
    call SetEvent(event)

    str info="Recording. Press any key to stop.."
    call printf(info)

    import "__getch" getch
    call getch()

    chars nl={0xa,0}
    str newline^nl

    call printf(newline)

    str done="Done"
    call printf(done)

    call printf(newline)

    call ResetEvent(event)
    call record_flag((value_set),(flag_stop))
    import "_WaitForSingleObject@8" WaitForSingleObject
    call WaitForSingleObject(event,(INFINITE))
endfunction

################







function record_second_thread(sd *data)
    sd event
    setcall event record_event((value_get))

    call WaitForSingleObject(event,(INFINITE))

    sd flag
    setcall flag record_flag((value_get))

    if flag==(flag_stop)
        return 0
    endif

    call record_loop_messages()

    call SetEvent(event)
endfunction

function record_loop_messages()
    #typedef struct tagMSG {
    data hwnd#1
    data message#1
    data wParam#1
    data lParam#1
    data *time#1
    #typedef struct tagPOINT {
    data *x#1
    data *y#1

    sd msg^hwnd

    import "_GetMessageA@16" GetMessage
    sd looper=1
    while looper!=-1
        setcall looper GetMessage(msg,0,0,0)
        if message==(MM_WIM_DATA)
            call record_newbuffer(lParam)
            sd flag
            setcall flag record_flag((value_get))
            if flag==(flag_stop)
                sd buffers
                setcall buffers record_buffers((value_get))
                dec buffers
                call record_buffers((value_set),buffers)
                if buffers==0
                    return 0
                endif
            else
                sd bool
                setcall bool wavein_add(wParam,lParam)
                if bool!=1
                    return 0
                endif
            endelse
        endif
    endwhile
endfunction

function record_newbuffer(sd waveinheader)
    #typedef struct wavehdr_tag {
      #LPSTR              lpData;
      #DWORD              dwBufferLength;
      #DWORD              dwBytesRecorded;
      #..
    sd buffer
    set buffer waveinheader#
    add waveinheader 8
    sd length
    set length waveinheader#

    sd file
    setcall file record_file((value_get))

    call file_write(buffer,length,file)
endfunction

#main thread
#entry
entry record()

str options="options.txt"
str r="rb"
sd file
setcall file fopen(options,r)
if file==0
    str err="Cannot open options file."
    call errors(err)
    return 0
endif

sd bool
setcall bool record_options(file)
if bool!=1
    return 0
endif

call record_sound()

call fclose(file)

return 0
