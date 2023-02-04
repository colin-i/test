
#e
function writevar(data ptrvalue,data unitsize,data relindex,data stack,data rightstackpointer,sd long_mask)
	data err#1
	data noerr=noerror
	Data ptrrelocbool%ptrrelocbool
	data true=TRUE
	data false=FALSE
	data ptrobject%ptrobject

	if stack==false
		data ptrdatasec%ptrdatasec
		if ptrobject#==1
			If ptrrelocbool#==true
				#data
				Data ptraddresses%ptraddresses
				Data relocoff=0
				SetCall err adddirectrel_base(ptraddresses,relocoff,relindex,ptrvalue#)
				If err!=noerr
					Return err
				EndIf
				sd inplacevalue
				#data^functionReloc
				set inplacevalue ptrvalue#
				if relindex==(dataind)
				#data a^dataB
					call inplace_reloc(#inplacevalue)
				endif
				SetCall err addtosec(#inplacevalue,(dwsz),ptrdatasec);If err!=(noerror);Return err;EndIf
				setcall err reloc64_post_base(ptrdatasec)
				return err
			endif
		endif
		SetCall err addtosec(ptrvalue,unitsize,ptrdatasec);If err!=noerr;Return err;EndIf
		if long_mask!=0
			data null=0
			SetCall err addtosec(#null,(dwsz),ptrdatasec)
			return err
		endif
		return (noerror)
	endif

	sd for_64;setcall for_64 is_for_64()
	if ptrobject#==1
		If ptrrelocbool#==true
			#code
			sd stackoff
			setcall stackoff reloc64_offset((rampadd_value_off))
			data ptrextra%ptrextra
			setcall err adddirectrel_base(ptrextra,stackoff,relindex,ptrvalue#)
			If err!=noerr
				Return err
			EndIf
			#s^dat
			call inplace_reloc(ptrvalue)
			setcall err addtocodefordata(ptrvalue#,for_64)
			return err
		EndIf
	endif
	if rightstackpointer!=(NULL)
		#s^s
		setcall err addtocodeforstack(rightstackpointer,for_64)
	else
		#s=consts
		setcall err addtocodefordata(ptrvalue#,for_64)
	endelse
	return err
endfunction

const fndecandgroup=1
#er
Function enumcommas(data ptrcontent,data ptrsize,data sz,data fndecandgroupOrpush,data typenumber,data stack,sd hex,sd long_mask)
	Data zero=0
	Data argsize#1
	Chars comma=","
	Data err#1
	Data noerr=noerror
	Data content#1
	Data csv#1
	Data csvloop=1

	Data true=TRUE
	Data false=FALSE
	Data sens#1
	Data forward=FORWARD
	Data backward=BACKWARD

	Set csv csvloop
	Set content ptrcontent#

	Data fnnr=functionsnumber
	If fndecandgroupOrpush==true
		If typenumber==fnnr
			Data stackoffset#1
			Set stackoffset zero
			Data ptrstackoffset^stackoffset
		Else
			Data bSz=bsz
			Data dwSz=dwsz
			Data unitsize#1
			Data charsnr=charsnumber
			If typenumber==charsnr
			#ignored at stack value   grep stackfilter2  1
				Set unitsize bSz
			Else
				Set unitsize dwSz
			EndElse
		EndElse
		Set sens forward
	Else
		Data storecontent#1
		Add content sz
		Set ptrcontent# content
		Set storecontent content
		Set sens backward
	EndElse
	While csv==csvloop
		If fndecandgroupOrpush==true
			SetCall argsize valinmemsens(content,sz,comma,sens)
			#allow (x,    y,   z) spaces
			sd sizeaux
			set sizeaux ptrsize#
			call spaces(ptrcontent,ptrsize)
			sub sizeaux ptrsize#
			sd argumentsize
			set argumentsize argsize
			sub argumentsize sizeaux
			#
			If typenumber==fnnr
				SetCall err fndecargs(ptrcontent,ptrsize,argumentsize,ptrstackoffset)
				If err!=noerr
					Return err
				EndIf
			Else
				Data value#1
				Data ptrvalue^value
				SetCall err parseoperations(ptrcontent,ptrsize,argumentsize,ptrvalue,(FALSE))
				If err!=noerr
					Return err
				EndIf
				if hex==(not_hexenum)
					data dataind=dataind
					setcall err writevar(ptrvalue,unitsize,dataind,stack,zero,long_mask)
					If err!=noerr
						Return err
					EndIf
				else
					sd ptrcodesec%ptrcodesec
					setcall err addtosec(ptrvalue,unitsize,ptrcodesec)
					If err!=noerr
						Return err
					EndIf
				endelse
			EndElse
		Else
			#push
			call nr_of_args_64need_count()
			sd delim
			set delim comma
			if sz!=0
				ss test
				set test content
				dec test
				chars d_quot=asciidoublequote
				if test#==d_quot
					set delim d_quot
					#look later at escapes, here only at the margins
					ss c
					sd s
					set c content
					set s sz
					set argsize s
					#case "abc,"
					dec test
					if test#==comma
						sub c 2
						sub s 2
					endif
					#
					sd len
					sd loop=1
					while loop==1
						#here the sens is backward and ," or (" represents the end of the string
						SetCall len valinmemsens(c,s,comma,sens)
						mult len -1
						Call advancecursors(#c,#s,len)
						if c#==d_quot
							set loop 0
						else
							#here the string ".." is in a good condition when quotes_forward was called at fn(...)
							Call advancecursors(#c,#s,-1)
						endelse
					endwhile
					sub argsize s
				endif
			endif
			if delim==comma
				SetCall argsize valinmemsens(content,sz,comma,sens)
			endif

			Data negvalue#1
			Set negvalue zero
			Sub negvalue argsize
			Call advancecursors(ptrcontent,ptrsize,negvalue)
			Data ptrargsize^argsize
			SetCall err argument(ptrcontent,ptrargsize,zero,backward)
			If err!=noerr
				Return err
			EndIf
		EndElse
		Sub sz argsize
		If sz!=zero
			Dec sz
			Call advancecursors(ptrcontent,ptrsize,sens)
			Set content ptrcontent#
		Else
			Set csv zero
		EndElse
	EndWhile
	If fndecandgroupOrpush==false
		Set ptrcontent# storecontent
	EndIf
	Return noerr
EndFunction
