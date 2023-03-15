


If openfilenamemethod==true
	Data timeatend#1
	SetCall timeatend GetTickCount()
	Sub timeatend timeatbegin
	Data MillisecperSec=1000
	Data seconds#1
	Set seconds timeatend
	Div seconds MillisecperSec
	Data SectoMil#1
	Set SectoMil seconds
	Mult SectoMil MillisecperSec
	Sub timeatend SectoMil
	Const sizeofouttime=100
	Chars outtime#sizeofouttime
	Str ptrouttime^outtime
	Chars outtimeformat="Done. %u.%u seconds"
	Str ptrouttimeformat^outtimeformat

	Call sprintf(ptrouttime,ptrouttimeformat,seconds,timeatend)
	Call MessageBox(null,ptrouttime,"Time",null)
EndIf
