
Data includebool#1

Str contentoffile#1
Data sizeoffile#1
Data offsetoffile#1
Data lineoffile#1
Data nameofstoffile#1

Const contentoffileoff=2*dwsz
Const lineoffile_offset=contentoffileoff+dwsz

Const includestructure^contentoffile

function offsetoffile_value()
	sd offsetoffl
	data null=NULL
	data true=TRUE
	set offsetoffl null
	data ptrincludedir%ptrincludedir
	data flag_max_path=flag_MAX_PATH
	if ptrincludedir#==true
		add offsetoffl flag_max_path
	endif
	return offsetoffl
endfunction

#err
Function include(ss path,sd both)
	Data zero=0
	Data one=1

	Str contentoffl#1
	Data sizeoffl#1
	Data offsetoffl#1
	Data *lineoffl=0
	Char nameoffl#shortstrsize

	Data err#1
	Data noerr=noerror

	Const includeset^contentoffl
	Data includeset%includeset

	Data psizeoffl^sizeoffl
	Data pcontentoffl%includeset

	setcall offsetoffl offsetoffile_value()

	SetCall err file_get_content_ofs(path,psizeoffl,pcontentoffl,offsetoffl)
	If err!=noerr
		Return err
	EndIf

	Str folders#1
	SetCall folders endoffolders(path)

	data ptrincludedir%ptrincludedir
	if ptrincludedir#==(TRUE)
		data charpointer#1
		setcall charpointer getcwd(pcontentoffl#,(flag_MAX_PATH))
		if charpointer==(NULL)
			str getcwderr="Getcdw error."
			return getcwderr
		endif

		setcall err addtolog_withchar_parses(pcontentoffl#,(log_pathfolder),both)
		If err!=noerr;Return err;EndIf

		char storechar#1
		set storechar folders#
		set folders# 0

		data int#1
		data chdirok=chdirok
		setcall int changedir(path)
		#0 success
		if int!=chdirok
			str chdirerr="Chdir error."
			return chdirerr
		endif

		set folders# storechar
	endif

	setcall err addtolog_withchar_parses(path,(log_pathname),both)
	If err!=noerr;Return err;EndIf

	Data strsz#1
	SetCall strsz strlen(path)
	Data fnamesize#1
	Set fnamesize path
	Add fnamesize strsz
	Sub fnamesize folders

	Data allowedforsize=shortstrsize
	Data allowedsize#1

	Set allowedsize allowedforsize
	Sub allowedsize one

	Data moresize#1
	Set moresize zero

	If fnamesize>allowedsize
		Set fnamesize allowedsize
		Sub fnamesize one
		Set moresize one
	EndIf

	Str dest#1
	Str initialdest^nameoffl
	Set dest initialdest
	Call memtomem(dest,folders,fnamesize)

	Add dest fnamesize
	If moresize==one
		Char morestr="~"
		Set dest# morestr
		Add dest one
	EndIf

	Set dest# 0


	Data pincludes%%ptr_includes
	Data isetsize=includesetSz

	SetCall err addtosec(includeset,isetsize,pincludes)
	If err!=noerr
		Return err
	EndIf

	Data pointers%includestructure
	Data sizeadd#1
	Set sizeadd isetsize
	Sub sizeadd allowedforsize
	Call memtomem(pointers,includeset,sizeadd)

	Data includespoint#1
	Data ptrincludespoint^includespoint
	Call getcontReg(pincludes,ptrincludespoint)
	Sub includespoint allowedforsize

	Data envinccursor#1
	Set envinccursor pointers
	Add envinccursor sizeadd
	Set envinccursor# includespoint

	Return noerr
EndFunction

#er
function include_sec_skip(sv pcontent,sd pcomsize)
	ss content;set content pcontent#
	sd size;set size pcomsize#
	call spaces(#content,#size)
	if content#==(asciidoublequote)
		sd err
		sd s;sd dummy
		SetCall err quotinmem(#content,#size,#s,#dummy)
		if err==(noerror)
			add content s;sub size s
			call stepcursors(#content,#size)
			set pcontent# content;set pcomsize# size
			return (noerror)
		endif
		return err
	endif
	return (noerror)
endfunction
