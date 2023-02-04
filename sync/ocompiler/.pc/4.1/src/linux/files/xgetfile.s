



Chars cmdfileformpathdata="/proc/%u/cmdline"
Str cmdfilepathform^cmdfileformpathdata
Chars cmdfilepathdata#32
Str cmdfilepath^cmdfilepathdata

Data pid#1
SetCall pid getpid()

Call sprintf(cmdfilepath,cmdfilepathform,pid)

Data cmdfile#1
Data openno=openno
Chars fopenreaddata="rb"
Str fopenread^fopenreaddata
SetCall cmdfile fopen(cmdfilepath,fopenread)
If cmdfile==openno
	Chars cmdopenerr="Cannot open command line file."
	Str ptrcmdopenerr^cmdopenerr
	Call msgerrexit(ptrcmdopenerr)
EndIf

Str script#1
Data argumentssize#1

Data ptrscript^script
Data ptrargumentssize^argumentssize

Data qwordsize=qwsz

Call memset(ptrscript,zero,qwordsize)

Data getdelimreturn#1
Data getdelimreturnerr=-1

#returns the argument+nullbyte size
SetCall getdelimreturn getdelim(ptrscript,ptrargumentssize,null,cmdfile)
If getdelimreturn==getdelimreturnerr
	Chars cmdscripterr="Cannot parse to input file name."
	Str ptrcmdscripterr^cmdscripterr
	Call msgerrexit(ptrcmdscripterr)
EndIf

#if the file was executed from the PATH, then the root folder it is searched
str scriptfullname#1
set scriptfullname null
chars slash=asciislash
data accessresult#1
data slashtest#1

set accessresult negative
setcall slashtest valinmem(script,argumentssize,slash)
if slashtest!=argumentssize
	set scriptfullname script
else
	str envpath#1
	str pathstr="PATH"
	setcall envpath getenv(pathstr)
	if envpath==null
		str enverr="Getenv error on PATH."
		call Message(enverr)
	endif
	data sizeofpath#1
	setcall sizeofpath strlen(envpath)
	while sizeofpath!=zero
		chars pathdelim=":"
		data sizeoffolder#1
		setcall sizeoffolder valinmem(envpath,sizeofpath,pathdelim)

		data sizetocreate#1
		set sizetocreate sizeoffolder
		#this one is if '/' needs to be added after the folder
		inc sizetocreate
		add sizetocreate argumentssize
		inc sizetocreate
		setcall scriptfullname memalloc(sizetocreate)
		if scriptfullname==null
			set sizeofpath zero
		else
			#do not work on null PATH parts
			if sizeoffolder!=null
				str scrpointer#1
				set scrpointer scriptfullname
				call memtomem(scrpointer,envpath,sizeoffolder)
				add scrpointer sizeoffolder
				dec scrpointer

				chars slashcompare#1
				set slashcompare scrpointer#
				inc scrpointer
				if slashcompare!=slash
					set scrpointer# slash
					inc scrpointer
				endif
				call memtomem(scrpointer,script,argumentssize)
				add scrpointer argumentssize
				set scrpointer# null

				data runaccess=X_OK
				setcall accessresult access(scriptfullname,runaccess)
			endif
			if accessresult==zero
				#continue with this path to preferences
				set sizeofpath zero
				Call free(script)
				set script scriptfullname
			else
				call free(scriptfullname)
				set scriptfullname null
				add envpath sizeoffolder
				sub sizeofpath sizeoffolder
				if envpath#==pathdelim
					inc envpath
					dec sizeofpath
				endif
			endelse
		endelse
	endwhile
endelse

if scriptfullname==false
	str patherr="Pathfind error."
	call Message(patherr)
else
	call setpreferences(scriptfullname)
endelse

Call free(script)

Data ptrpath%ptrpath
Set argumentssize flag_max_path
SetCall getdelimreturn getdelim(ptrpath,ptrargumentssize,null,cmdfile)

If getdelimreturn==getdelimreturnerr
	Chars cmdnoinput="Enter the input file. O Compiler - usage: o \"filename.o\""
	Str ptrcmdnoinput^cmdnoinput
	Call msgerrexit(ptrcmdnoinput)
EndIf

Call fclose(cmdfile)


