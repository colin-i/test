


format elfobj

importx "_gst_discoverer_new" gst_discoverer_new
importx "_gst_discoverer_start" gst_discoverer_start
importx "_gst_discoverer_discover_uri_async" gst_discoverer_discover_uri_async
importx "_gst_discoverer_stop" gst_discoverer_stop
importx "_gst_discoverer_info_get_uri" gst_discoverer_info_get_uri
importx "_gst_discoverer_info_get_result" gst_discoverer_info_get_result

importx "_gst_object_unref" gst_object_unref

import "strstrdisp" strstrdisp

include "../_include/include.h"

#v/e
function on_discover(data *discoverer,data info,data gerror,data passdata)
    str uri#1
    setcall uri gst_discoverer_info_get_uri(info)

    data result#1
    setcall result gst_discoverer_info_get_result(info)

    data ok=GST_DISCOVERER_OK
    data invalid=GST_DISCOVERER_URI_INVALID
    data error=GST_DISCOVERER_ERROR
    data timeout=GST_DISCOVERER_TIMEOUT
    data busy=GST_DISCOVERER_BUSY
    data misses=GST_DISCOVERER_MISSING_PLUGINS

    if result==ok
        importx "_gst_discoverer_info_get_video_streams" gst_discoverer_info_get_video_streams
        importx "_gst_discoverer_info_get_audio_streams" gst_discoverer_info_get_audio_streams
        importx "_gst_discoverer_stream_info_list_free" gst_discoverer_stream_info_list_free
        importx "_g_list_first" g_list_first

        data videoinfo#1
        data audioinfo#1

        str video="Video"
        str audio="Audio"
        str both=" and "
        str nullstring=""

        setcall videoinfo gst_discoverer_info_get_video_streams(info)
        setcall audioinfo gst_discoverer_info_get_audio_streams(info)

        data videofirst#1
        data audiofirst#1
        setcall videofirst g_list_first(videoinfo)
        setcall audiofirst g_list_first(audioinfo)

        call gst_discoverer_stream_info_list_free(videoinfo)
        call gst_discoverer_stream_info_list_free(audioinfo)

        data flagV=video
        data flagA=audio
        data flagVA=audiovideo
        data streams#1
        str v#1
        str conjunction#1
        str a#1
        data null=0

        set streams flagVA
        if videofirst!=null
            set v video
        else
            set v nullstring
            xor streams flagV
        endelse
        if audiofirst!=null
            set a audio
        else
            set a nullstring
            xor streams flagA
        endelse
        if streams==null
            str nothingtodo="No video or audio discovered at: "
            call strstrdisp(nothingtodo,uri)
        else
            if streams==flagVA
                set conjunction both
            else
                set conjunction nullstring
            endelse

            importx "_sprintf" sprintf
            str infodispformat="%s%s%s %s: "
            chars infodisp#40
            str infotext^infodisp

            call sprintf(infotext,infodispformat,v,conjunction,a,passdata#)
            call strstrdisp(infotext,uri)

            data dword=4
            add passdata dword
            data forward#1
            set forward passdata#
            if forward!=null
                call forward(uri,streams)
            endif
        endelse
    elseif result==invalid
        str invuri="Invalid uri: "
        call strstrdisp(invuri,uri)
    elseif result==error
        import "view_gerror_message" view_gerror_message
        call view_gerror_message(gerror)
    elseif result==timeout
        str timeouterr="Timeout error. Uri: "
        call strstrdisp(timeouterr,uri)
    elseif result==busy
        str busyerr="Busy error. Uri: "
        call strstrdisp(busyerr,uri)
    elseif result==misses
        importx "_gst_discoverer_info_get_misc" gst_discoverer_info_get_misc
        importx "_gst_structure_to_string" gst_structure_to_string
        importx "_g_free" g_free
        data st#1
        setcall st gst_discoverer_info_get_misc(info)
        str message#1
        setcall message gst_structure_to_string(st)
        str missing="Missing plugins: "
        call strstrdisp(missing,message)
        call g_free(message)
    endelseif
endfunction

function on_finish(data discoverer)
    call gst_discoverer_stop(discoverer)
    call gst_object_unref(discoverer)
endfunction


function collect_info_got_src(str src,data discover)
    data bool#1
    setcall bool gst_discoverer_discover_uri_async(discover,src)
    data false=0
    if bool==false
        str discerr="Uri media discover failed: "
        call strstrdisp(discerr,src)
        call gst_object_unref(discover)
    endif
endfunction

function collect_info(str intrusion)
    data dsc#1
    data gstsec=GST_SECOND
    data timeoutsec=10

    import "mult64" mult64
    data high#1
    data low#1
    data ptrhigh^high

    setcall low mult64(gstsec,timeoutsec,ptrhigh)

    import "getptrgerr" getptrgerr
    import "gerrtoerr" gerrtoerr
    data ptrgerr#1
    setcall ptrgerr getptrgerr()
    setcall dsc gst_discoverer_new(low,high,ptrgerr)
    data n=0
    if dsc==n
        call gerrtoerr(ptrgerr)
    endif

    import "connect_signal_data" connect_signal_data
    data discoveredcallback^on_discover
    str discover="discovered"
    call connect_signal_data(dsc,discover,discoveredcallback,intrusion)

    import "connect_signal" connect_signal
    data finishedcallback^on_finish
    str finish="finished"
    call connect_signal(dsc,finish,finishedcallback)

    call gst_discoverer_start(dsc)

    import "editWidgetBufferForwardData" editWidgetBufferForwardData
    data f^collect_info_got_src
    call editWidgetBufferForwardData(f,dsc)
endfunction

function gather_info()
    chars detected="detected at"

    str discover^detected
    data *noforward=0
    data st^discover

    call collect_info(st)
endfunction
