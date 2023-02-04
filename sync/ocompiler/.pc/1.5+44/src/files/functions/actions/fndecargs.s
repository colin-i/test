

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
	sd vartype
	setcall vartype commandSubtypeDeclare_to_typenumber(subtype)
	sd datasize=dwsz
	sd long_mask=0
	sd b;setcall b is_for_64()
	if vartype>=(vnumbers)
		sub vartype (vnumbers)
		if vartype==(valuesinnernumber)
			set vartype (integersnumber)
			if b==(TRUE)
				set long_mask (valueslongmask)
				set datasize (qwsz)
			endif
		elseif b==(TRUE)
			set long_mask (datapointbit)
			set datasize (qwsz)
		endelseif
	elseif vartype==(charsnumber)
		set datasize (bsz)
	endelseif

	#substract from the big size the parsed size
	Sub len sz
	Data length#1
	Set length ptrsize#
	Sub length len
	Set ptrsize# length

	Chars stacktransfer1#1;chars *={0x84,0x24}
	Data stackoff#1
	Chars stacktransfer2#1
	Data memoff#1

	Data dwrdsz=dwsz
	Set stackoff ptr_stackoffset#
	AddCall stackoff stack64_add(dwrdsz)
	Set ptr_stackoffset# stackoff

	data stackindex#1
	set stackindex stackoff
	addcall stackindex stack64_add((stackinitpush))

	setcall err addvarreferenceorunref(ptrcontent,ptrsize,sz,vartype,stackindex,long_mask)
	If err!=noerr
		Return err
	EndIf

	data stack#1
	data ptrstack^stack
	call stackfilter(vartype,ptrstack)

	if stack!=zero
		return noerr
	endif

	Chars stackt1ini=moveatprocthemem
	Chars stackt2ini=0xA3

	Set stacktransfer1 stackt1ini
	Set stacktransfer2 stackt2ini

	setcall memoff get_img_vdata_dataReg()

	If datasize==(bsz)
		Dec stacktransfer1
		Dec stacktransfer2
	endIf

	Data null={NULL,NULL}
	Data ptrnull^null
	Data _datasec%ptrdatasec
	SetCall err addtosec(ptrnull,datasize,_datasec)
	If err!=noerr
		Return err
	EndIf

	if long_mask!=0
		call rex_w(#err)
		If err!=noerr;Return err;EndIf
	endif

	data p_is_object%ptrobject
	if p_is_object#==(TRUE)
		Const fndecargs_offend^memoff
		Const fndecargs_offstart^stacktransfer1
		Data ptrextra%ptrextra
		Data dataind=dataind
		sd reloff=fndecargs_offend-fndecargs_offstart
		if long_mask!=0
			inc reloff
		endif
		SetCall err adddirectrel_base(ptrextra,reloff,dataind,memoff)
		If err!=noerr
			Return err
		EndIf
		call inplace_reloc(#memoff)
	endif

	Data _codesec%ptrcodesec

	SetCall err addtosec(#stacktransfer1,(3*bsz+dwsz),_codesec);If err!=noerr;Return err;EndIf
	if long_mask!=0
		call rex_w(#err)
		If err!=noerr;Return err;EndIf
	endif
	SetCall err addtosec(#stacktransfer2,(bsz+dwsz),_codesec);If err!=noerr;Return err;EndIf

	if b==(TRUE)
		#at 64 code:
		#A3 XX.XX.XX.XX_XX.XX.XX.XX
		sd z=i386_obj_default_reloc_rah
		SetCall err addtosec(#z,(dwsz),_codesec)
		return err
	endif

	Return (noerror)
EndFunction
