

Chars allfiles="All Files (*.*)"
Str ptrallfiles^allfiles
Chars filter2="*.*"
Str ptrfilter2^filter2
chars nullstr=""

Data ofnfiltersize#1
Data str1sz#1
Data filter2sz#1

SetCall str1sz strlen(ptrallfiles)
SetCall filter2sz strlen(ptrfilter2)
Set ofnfiltersize str1sz
Add ofnfiltersize bytesize
Add ofnfiltersize filter2sz
Add ofnfiltersize bytesize
Add ofnfiltersize bytesize
SetCall ofnfiltermemvalue memalloc(ofnfiltersize)
If ofnfiltermemvalue==null
	Call errexit()
EndIf
Str cursor#1
Set cursor ofnfiltermemvalue
Set cursor# nullstr
Call strcat(cursor,ptrallfiles)
Add cursor str1sz
Set cursor# nullstr
Add cursor bytesize
Set cursor# nullstr
Call strcat(cursor,ptrfilter2)
Add cursor filter2sz
Set cursor# nullstr
Add cursor bytesize
Set cursor# nullstr

