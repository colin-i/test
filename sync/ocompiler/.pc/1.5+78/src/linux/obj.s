
#linux elf rel format

Format ElfObj

Include "./files/xcomimports.h"

Function Message(str text)
#binutils-x86-64-linux-gnu:amd64 (2.37.50.20220106-2ubuntu1, 2.37.90.20220126-0ubuntu1)
#ld will take stderr in data through rel.dyn only with another presence in text
#	data stderrorobject_init^stderr
#	data stderrorobject#1
	sd stderrorobject^stderr
	set stderrorobject stderrorobject#

	Chars visiblemessagedata={0x0a,0}
	Str visiblemessage^visiblemessagedata

	Call fprintf(stderrorobject,visiblemessage)
	Call fprintf(stderrorobject,text)
	Call fprintf(stderrorobject,visiblemessage)
EndFunction

Include "./head.h"

Include "./text.s"


