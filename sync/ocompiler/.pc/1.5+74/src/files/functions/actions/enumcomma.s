
#e
function writevar(sd ptrvalue,sd unitsize,sd relindex,sd stack,sd rightstackpointer,sd long_mask,sd relocbool)
	data err#1
	data noerr=noerror
	data true=TRUE
	data false=FALSE
	data ptrobject%ptrobject

	sd for_64

	if stack==false
		data ptrdatasec%ptrdatasec
		if ptrobject#==1
			If relocbool==true
				#data
				Data ptraddresses%ptraddresses
				Data relocoff=0

				SetCall err adddirectrel_base(ptraddresses,relocoff,relindex,ptrvalue#)
				If err!=noerr;Return err;EndIf
				if relindex==(codeind)
					#data^functionReloc
					#this is at relocs not at data
					setcall err unresReloc(ptraddresses)
					If err!=noerr;Return err;EndIf
					#ptrvalue# it is an addresses value (nothing related to the real value)
					#	that will be resolved and overwritten at resolve.s
				endif
				#else data a^dataB

				call inplace_reloc(ptrvalue)

				#endif
				SetCall err addtosec(ptrvalue,(dwsz),ptrdatasec)
				If err==(noerror)
					setcall err reloc64_post_base(ptrdatasec)
				EndIf
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

	setcall for_64 is_for_64()
	if ptrobject#==1
		If relocbool==true
			#code
			sd stackoff
			setcall stackoff reloc64_offset((rampadd_value_off))
			data ptrextra%ptrextra
			setcall err adddirectrel_base(ptrextra,stackoff,relindex,ptrvalue#)
			If err!=noerr;Return err;EndIf
			if relindex==(codeind)
				#s^fn
				setcall err unresReloc(ptrextra)
				If err!=noerr;Return err;EndIf
			endif
			#else s^dat
			call inplace_reloc(ptrvalue)
			setcall err addtocodefordata(ptrvalue#,for_64,(NULL))
			return err
		EndIf
	endif
	if rightstackpointer!=(NULL)
		#s^s
		setcall err addtocodeforstack(rightstackpointer,for_64)
	else
		#s=consts
		sd test=~0x7fFFffFF
		and test ptrvalue#
		if test==0
			setcall err addtocodefordata(ptrvalue#,for_64,0)
		else
			#keep sign, for comparations
			setcall err addtocodefordata(ptrvalue#,for_64,-1)
		endelse
	endelse
	return err
endfunction

const fndecandgroup=1
#er
Function enumcommas(sv ptrcontent,sd ptrsize,sd sz,sd fndecandgroupOrpush,sd typenumberOrparses,sd punitsizeOrparses,sd hexOrunitsize,sd stack,sd long_mask,sd relocbool,sd relocindx)
	Data zero=0
	vstrx argsize#1
	Chars comma=","
	Data err#1
	Data noerr=noerror
	datax content#1
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
		If typenumberOrparses==fnnr
			Data stackoffset#1
			Set stackoffset zero
			Data ptrstackoffset^stackoffset
		Else
			Data bSz=bsz
			Data dwSz=dwsz
			Data unitsize#1   #ignored at stack
			Data charsnr=charsnumber
			if punitsizeOrparses==(NULL)
				If typenumberOrparses==charsnr
				#ignored at stack value   grep stackfilter2  1
					Set unitsize bSz    #used also at hex
				Else
					Set unitsize dwSz
				EndElse
			endif
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
			If typenumberOrparses==fnnr
				if punitsizeOrparses!=(pass_write0)
					#pass_init/pass_write
					SetCall err fndecargs(ptrcontent,ptrsize,argumentsize,ptrstackoffset,punitsizeOrparses)
					If err!=noerr
						Return err
					EndIf
				else
					inc hexOrunitsize#
					call advancecursors(ptrcontent,ptrsize,argumentsize)
				endelse
			Else
				if punitsizeOrparses==(NULL)
					Data value#1
					Data ptrvalue^value
					SetCall err parseoperations(ptrcontent,ptrsize,argumentsize,ptrvalue,(FALSE))
					If err!=noerr
						Return err
					EndIf
					if hexOrunitsize==(not_hexenum)
						setcall err writevar(ptrvalue,unitsize,relocindx,stack,zero,long_mask,relocbool)
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
				else
					add punitsizeOrparses# hexOrunitsize
					call advancecursors(ptrcontent,ptrsize,argumentsize)
				endelse
			EndElse
		Else
			#push
			if typenumberOrparses==(pass_calls) #for regs at call   and shadow space
				call nr_of_args_64need_count()
			endif

			if sz!=0
				set argsize content
				dec argsize
				chars d_quot=asciidoublequote
				if argsize#==d_quot
					#look later at escapes, here only at the margins
					#here the string ".." is in a good condition when quotes_forward was called at fn(...)
					sd last;set last content
					sub last sz
					dec argsize
					while argsize!=last
						if argsize#==d_quot
							dec argsize
							if argsize#!=(asciibs)
								inc argsize
								set last argsize
							else
								dec argsize
							endelse
						else
							dec argsize
						endelse
					endwhile
					sub argsize content
					neg argsize
				else
					SetCall argsize valinmemsens(content,sz,comma,sens)
				endelse
			else
				set argsize 0
			endelse

			Data negvalue#1
			Set negvalue zero
			Sub negvalue argsize
			Call advancecursors(ptrcontent,ptrsize,negvalue)
			Data ptrargsize^argsize
			if typenumberOrparses==(pass_init)
				setcall err getarg(ptrcontent,ptrargsize,argsize,(allow_later),sens) #there are 4 more arguments but are not used
				If err!=noerr
					Return err
				EndIf
			elseif typenumberOrparses==(pass_write)
				SetCall err argument(ptrcontent,ptrargsize,backward) #there is 1 more argument but is not used
				If err!=noerr
					Return err
				EndIf
			endelseif
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
