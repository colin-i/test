

Function fndecargs(data ptrcontent,data ptrsize,data sz,data ptr_stackoffset)
	Data zero=0
	If sz==zero
		Chars szexp="Variable declaration expected."
		Str szexpptr^szexp
		Return szexpptr
	EndIf

	Data noerr=noerror
	Data pointerset%compointersvarsloc
	Data err#1
	Data perr^err
	data subtype#1
	
	Data ptrsearchsize^sz
	Data len#1
	Set len sz
	Set err noerr

	Call getcommand(ptrcontent,ptrsearchsize,#subtype,perr,pointerset)
	If err!=noerr
		Return err
	EndIf
	Data vartype#1
	setcall vartype commandSubtypeDeclare_to_typenumber(subtype)
	
	#substract from the big size the parsed size
	Sub len sz
	Data length#1
	Set length ptrsize#
	Sub length len
	Set ptrsize# length


	Chars stacktransfer1={0,0x84,0x24}
	Data stackoff#1
	Chars stacktransfer2#1
	Data memoff#1
	Data sizeoftransfer=3*bsz+dwsz+bsz+dwsz

	Data dwrdsz=dwsz
	Set stackoff ptr_stackoffset#
	AddCall stackoff stack64_add(dwrdsz)
	Set ptr_stackoffset# stackoff

	data stackindex#1
	set stackindex stackoff
	addcall stackindex stack64_add((stackinitpush))

	setcall err addvarreferenceorunref(ptrcontent,ptrsize,sz,vartype,stackindex)
	If err!=noerr
		Return err
	EndIf

	data stack#1
	data ptrstack^stack
	call stackfilter(vartype,ptrstack)

	if stack!=zero
		return noerr
	endif

	Chars stackt1ini={moveatprocthemem}
	Chars stackt2ini={0xA3}

	Set stacktransfer1 stackt1ini
	Set stacktransfer2 stackt2ini

	setcall memoff get_img_vdata_dataReg()

	Data datasize#1
	Data btsz=bsz
	Data charsnr=charsnumber
	If vartype==charsnr
		Set datasize btsz
		Dec stacktransfer1
		Dec stacktransfer2
	Else
		Set datasize dwrdsz
	EndElse

	Data null=NULL
	Data ptrnull^null
	Data _datasec%ptrdatasec
	SetCall err addtosec(ptrnull,datasize,_datasec)
	If err!=noerr
		Return err
	EndIf

	Const offend^memoff
	Const offstart^stacktransfer1
	Data ptrextra%ptrextra
	Data reloff=offend-offstart
	Data dataind=dataind
	SetCall err adddirectrel(ptrextra,reloff,dataind)
	If err!=noerr
		Return err
	EndIf

	Str codeops^stacktransfer1
	Data _codesec%ptrcodesec
	SetCall err addtosec(codeops,sizeoftransfer,_codesec)
	If err!=noerr;Return err;EndIf
	
	sd b;setcall b is_for_64()
	if b==(TRUE)
		#at 64 code:
		#A3 XX.XX.XX.XX_XX.XX.XX.XX
		sd z=0
		SetCall err addtosec(#z,(dwsz),_codesec)
		If err!=noerr;Return err;EndIf
	endif
	
	Return err
EndFunction