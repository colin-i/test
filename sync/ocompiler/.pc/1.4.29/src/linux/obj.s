
#linux elf rel format

Format ElfObj

Include "./files/xcomimports.h"

Function Message(str text)
	data stderrorobject_init^stderr
	data stderrorobject#1
	set stderrorobject stderrorobject_init#

	Chars visiblemessagedata={0x0a,0}
	Str visiblemessage^visiblemessagedata

	Call fprintf(stderrorobject,visiblemessage)
	Call fprintf(stderrorobject,text)
	Call fprintf(stderrorobject,visiblemessage)
EndFunction

Include "./head.h"

Include "./text.s"


