



format elfobj

include "../_include/include.h"

importx "_soup_session_sync_new" soup_session_sync_new
importx "_soup_message_new" soup_message_new
importx "_soup_session_send_message" soup_session_send_message

#bool
function getSessionMessageBody(sv sessionMsg,sv ptrmsgmem,sv ptrmsgsize)
#    GObject             parent
#All the fields in the GObject structure are private to the GObject implementation and should never be accessed directly.
#		GTypeInstance g_type_instance; ulong at windows
#		guint ref_count;
#		GData *qdata;
#    const char         *method;

#    guint               status_code;
#    char               *reason_phrase;

#    SoupMessageBody    *request_body;
#    SoupMessageHeaders *request_headers;

#    SoupMessageBody    *response_body;
#    SoupMessageHeaders *response_headers;

	add sessionMsg (:+DWORD+:+          :)
	sd status
	set status sessionMsg#d^
	if status!=(HTTP_STATUS_OK)
		call uri_err(status)
		return (FALSE)
	endif
	add sessionMsg (DWORD+:+:+:)

	sd response_body#1
	set response_body sessionMsg#

#        const char *data;
#        goffset     length;  (gint64)
	set ptrmsgmem# response_body#
	data valuesize=4
	data greatest=8
	add response_body valuesize
	import "system_variables_alignment_pad" system_variables_alignment_pad
	addcall response_body system_variables_alignment_pad(valuesize,greatest)
	set ptrmsgsize# response_body#
	return (TRUE)
endfunction

importx "_soup_session_queue_message" soup_session_queue_message

function uri_queue_content(ss uri,sd callback)
	sd session
	setcall session soup_session_sync_new()
	sd msg
	setcall msg soup_message_new("GET",uri)
	call soup_session_queue_message(session,msg,callback,(NULL)) #msg transfer full
	#If after returning from this callback the message has not been requeued, msg will be unreffed.
	#call g_object_unref(session)
	#assertion `queue->head == NULL' failed
endfunction

function uri_err(sd status)
	vstr urierr="Error status code: "
	import "strvaluedisp" strvaluedisp
	data su=stringUinteger
	call strvaluedisp(urierr,status,su)
endfunction

importx "_g_object_unref" g_object_unref
#msg
function uri_get_content(ss uri)
	sd session
	setcall session soup_session_sync_new()

	vstr get="GET"
	sd msg
	setcall msg soup_message_new(get,uri)

	#setcall status soup_session_send_message(session,msg)
	call soup_session_send_message(session,msg)

	call g_object_unref(session)
	return msg
endfunction


#void
function uri_get_content_forward_data(ss uri,sd forward,sd data)
#                        forward body and size
	sd msg
	sd body
	sd size

	setcall msg uri_get_content(uri)
	sd bool
	setcall bool getSessionMessageBody(msg,#body,#size)
	if bool==(TRUE)
		call forward(body,size,data)
	endif
	call g_object_unref(msg)
endfunction

#function uri_get_content_forward(ss uri,sd forward)
#    data null=0
#    call uri_get_content_forward_data(uri,forward,null)
#endfunction
