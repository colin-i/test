

Const spacereq=1
Const spacenotreq=0

#with caution like elseif before else for getcommand comparations

Char cCOMMENT_c={commentascii,0}
Char cDATA_c="DATA";Char cSTR_c="STR";Char cCHAR_c="CHAR";Char cSD_c="SD";Char cSS_c="SS";Char cSV_c="SV"
	Char cVDATA_c="VDATA";Char cVSTR_c="VSTR";Char cVALUE_c="VALUE"
	Char cDATAX_c="DATAX";Char cSTRX_c="STRX";Char cCHARX_c="CHARX"
	Char cVDATAX_c="VDATAX";Char cVSTRX_c="VSTRX";Char cVALUEX_c="VALUEX"
	Char cCONST_c="CONST"
Char cSET_c="SET";Char cADD_c="ADD";Char cSUB_c="SUB";Char cMULT_c="MULT";Char cDIV_c="DIV";Char cREM_c="REM";Char cAND_c="AND";Char cOR_c="OR";Char cXOR_c="XOR"
Char cRETURN_c="RETURN";Char cINCST_c="INCST";Char cINC_c="INC";Char cDECST_c="DECST";Char cDEC_c="DEC";Char cNEG_c="NEG";Char cNOT_c="NOT";Char cSHL_c="SHL";Char cSHR_c="SHR";Char cSAR_c="SAR";Char cEXIT_c="EXIT"
Char cCALLX_c="CALLX";Char cCALL_c="CALL"
Char cIF_c="IF";Char cENDIF_c="ENDIF";Char cELSEIF_c="ELSEIF";Char cELSE_c="ELSE";Char cENDELSEIF_c="ENDELSEIF";Char cENDELSE_c="ENDELSE";Char cWHILE_c="WHILE";Char cENDWHILE_c="ENDWHILE";Char cBREAK_c="BREAK";Char cCONTINUE_c="CONTINUE"
Char cIMPORT_c="IMPORT";Char cIMPORTX_c="IMPORTX"
Char cFUNCTION_c="FUNCTION";Char cFUNCTIONX_c="FUNCTIONX";Char cENTRYRAW_c="ENTRYRAW";Char cENTRY_c="ENTRY"
Char cENDFUNCTION_c="ENDFUNCTION"
Char cRET_c="RET"
Char cINCLUDE_c="INCLUDE"
Char cFORMAT_c="FORMAT"
Char cIMPORTAFTERCALL_c="IMPORTAFTERCALL";Char cAFTERCALL_c="AFTERCALL"
Char cWARNING_c="WARNING"
Char cCALLEXX_c="CALLEXX";Char cCALLEX_c="CALLEX"
Char cOVERRIDE_c="OVERRIDE"
Char cLIBRARY_c="LIBRARY"
Char cHEX_c="HEX"
Char cI3_c="I3"

const not_a_subtype=-1

const coms_start=!
	Const cCOMMENT=!-coms_start
		data cCOMMENT_s^cCOMMENT_c
Const comsloc^cCOMMENT_s
		Data *=cCOMMENT
		Data *#1
		Data *=spacenotreq
const commandsvars_start=!
	Const cDECLARE=!-coms_start
	Const cDECLARE_top=!
		Const cDATA=!-cDECLARE_top
			data cDATA_s^cDATA_c
Const cdataloc^cDATA_s
			Data *=cDECLARE
			Data *=cDATA
			Data *=spacereq
		Const cSTR=!-cDECLARE_top
Const com_size=cSTR-cDATA
			data *^cSTR_c
			Data *=cDECLARE
			Data *=cSTR
			Data *=spacereq
		Const cCHAR=!-cDECLARE_top
			data *^cCHAR_c
			Data *=cDECLARE
			Data *=cCHAR
			Data *=spacereq
		Const cSD=!-cDECLARE_top
			data *^cSD_c
			Data *=cDECLARE
			Data *=cSD
			Data *=spacereq
		Const cSS=!-cDECLARE_top
			data *^cSS_c
			Data *=cDECLARE
			Data *=cSS
			Data *=spacereq
		Const cSV=!-cDECLARE_top
			data *^cSV_c
			Data *=cDECLARE
			Data *=cSV
			Data *=spacereq
		Const cVDATA=!-cDECLARE_top
			data *^cVDATA_c
			Data *=cDECLARE
			Data *=cVDATA
			Data *=spacereq
		Const cVSTR=!-cDECLARE_top
			data *^cVSTR_c
			Data *=cDECLARE
			Data *=cVSTR
			Data *=spacereq
		Const cVALUE=!-cDECLARE_top
			data *^cVALUE_c
			Data *=cDECLARE
			Data *=cVALUE
			Data *=spacereq
		Const cDATAX=!-cDECLARE_top
			data *^cDATAX_c
			Data *=cDECLARE
			Data *=cDATAX
			Data *=spacereq
		Const cSTRX=!-cDECLARE_top
			data *^cSTRX_c
			Data *=cDECLARE
			Data *=cSTRX
			Data *=spacereq
		Const cCHARX=!-cDECLARE_top
			data *^cCHARX_c
			Data *=cDECLARE
			Data *=cCHARX
			Data *=spacereq
		Const cVDATAX=!-cDECLARE_top
			data *^cVDATAX_c
			Data *=cDECLARE
			Data *=cVDATAX
			Data *=spacereq
		Const cVSTRX=!-cDECLARE_top
			data *^cVSTRX_c
			Data *=cDECLARE
			Data *=cVSTRX
			Data *=spacereq
		Const cVALUEX=!-cDECLARE_top
			data *^cVALUEX_c
			Data *=cDECLARE
			Data *=cVALUEX
			Data *=spacereq
#numberofcommandsvars to set these commands to search for them at function parameter declare
Const numberofcommandsvars=(!-commandsvars_start)/com_size
		Const cCONST=!-cDECLARE_top
			data *^cCONST_c
			Data *=cDECLARE
			Data *=cCONST
			Data *=spacereq
	Const cPRIMSEC=!-coms_start
	Const cPRIMSEC_top=!
		Const cSET=!-cPRIMSEC_top
			data *^cSET_c
			Data *=cPRIMSEC
			Data *=cSET
			Data *=spacereq
		Const cADD=!-cPRIMSEC_top
			data *^cADD_c
			Data *=cPRIMSEC
			Data *=cADD
			Data *=spacereq
		Const cSUB=!-cPRIMSEC_top
			data *^cSUB_c
			Data *=cPRIMSEC
			Data *=cSUB
			Data *=spacereq
		Const cMULT=!-cPRIMSEC_top
			data *^cMULT_c
			Data *=cPRIMSEC
			Data *=cMULT
			Data *=spacereq
		Const cDIV=!-cPRIMSEC_top
			data *^cDIV_c
			Data *=cPRIMSEC
			Data *=cDIV
			Data *=spacereq
		Const cREM=!-cPRIMSEC_top
			data *^cREM_c
			Data *=cPRIMSEC
			Data *=cREM
			Data *=spacereq
		Const cAND=!-cPRIMSEC_top
			data *^cAND_c
			Data *=cPRIMSEC
			Data *=cAND
			Data *=spacereq
		Const cOR=!-cPRIMSEC_top
			data *^cOR_c
			Data *=cPRIMSEC
			Data *=cOR
			Data *=spacereq
		Const cXOR=!-cPRIMSEC_top
			data *^cXOR_c
			Data *=cPRIMSEC
			Data *=cXOR
			Data *=spacereq
	Const cONEARG=!-coms_start
	Const cONEARG_top=!
		Const cRETURN=!-cONEARG_top
			data *^cRETURN_c
			Data *=cONEARG
			Data *=cRETURN
			Data *=spacereq
		Const cINCST=!-cONEARG_top
			data *^cINCST_c
			Data *=cONEARG
			Data *=cINCST
			Data *=spacereq
		Const cINC=!-cONEARG_top
			data *^cINC_c
			Data *=cONEARG
			Data *=cINC
			Data *=spacereq
		Const cDECST=!-cONEARG_top
			data *^cDECST_c
			Data *=cONEARG
			Data *=cDECST
			Data *=spacereq
		Const cDEC=!-cONEARG_top
			data *^cDEC_c
			Data *=cONEARG
			Data *=cDEC
			Data *=spacereq
		Const cNEG=!-cONEARG_top
			data *^cNEG_c
			Data *=cONEARG
			Data *=cNEG
			Data *=spacereq
		Const cNOT=!-cONEARG_top
			data *^cNOT_c
			Data *=cONEARG
			Data *=cNOT
			Data *=spacereq
		Const cSHL=!-cONEARG_top
			data *^cSHL_c
			Data *=cONEARG
			Data *=cSHL
			Data *=spacereq
		Const cSHR=!-cONEARG_top
			data *^cSHR_c
			Data *=cONEARG
			Data *=cSHR
			Data *=spacereq
		Const cSAR=!-cONEARG_top
			data *^cSAR_c
			Data *=cONEARG
			Data *=cSAR
			Data *=spacereq
		Const cEXIT=!-cONEARG_top
			data *^cEXIT_c
			Data *=cONEARG
			Data *=cEXIT
			Data *=spacereq
	Const cCALL=!-coms_start
		data *^cCALLX_c
		Data *=cCALL
		Data *=x_callx_flag
		Data *=spacereq
		data *^cCALL_c
		Data *=cCALL
		Data *=0
		Data *=spacereq
	Const cCONDITIONS=!-coms_start
	Const cCONDITIONS_top=!
		Const cIF=!-cCONDITIONS_top
			data *^cIF_c
			Data *=cCONDITIONS
			Data *=cIF
			Data *=spacereq
		Const cENDIF=!-cCONDITIONS_top
			data *^cENDIF_c
			Data *=cCONDITIONS
			Data *=cENDIF
			Data *=spacenotreq
		Const cELSEIF=!-cCONDITIONS_top
			data *^cELSEIF_c
			Data *=cCONDITIONS
			Data *=cELSEIF
			Data *=spacereq
		Const cELSE=!-cCONDITIONS_top
			data *^cELSE_c
			Data *=cCONDITIONS
			Data *=cELSE
			Data *=spacenotreq
		Const cENDELSEIF=!-cCONDITIONS_top
			data *^cENDELSEIF_c
			Data *=cCONDITIONS
			Data *=cENDELSEIF
			Data *=spacenotreq
		Const cENDELSE=!-cCONDITIONS_top
			data *^cENDELSE_c
			Data *=cCONDITIONS
			Data *=cENDELSE
			Data *=spacenotreq
		Const cWHILE=!-cCONDITIONS_top
			data *^cWHILE_c
			Data *=cCONDITIONS
			Data *=cWHILE
			Data *=spacereq
		Const cENDWHILE=!-cCONDITIONS_top
			data *^cENDWHILE_c
			Data *=cCONDITIONS
			Data *=cENDWHILE
			Data *=spacenotreq
		Const cBREAK=!-cCONDITIONS_top
			data *^cBREAK_c
			Data *=cCONDITIONS
			Data *=cBREAK
			Data *=spacenotreq
		Const cCONTINUE=!-cCONDITIONS_top
			data *^cCONTINUE_c
			Data *=cCONDITIONS
			Data *=cCONTINUE
			Data *=spacenotreq
	Const cIMPORTLINK=!-coms_start
	Const cIMPORTLINK_top=!
		const cIMPORT=!-cIMPORTLINK_top
			data *^cIMPORT_c
			Data *=cIMPORTLINK
			Data *=cIMPORT
			Data *=spacereq
		const cIMPORTX=!-cIMPORTLINK_top
			data *^cIMPORTX_c
			Data *=cIMPORTLINK
			Data *=cIMPORTX
			Data *=spacereq
	Const cSTARTFUNCTION=!-coms_start
	Const cSTARTFUNCTION_top=!
		Const cFUNCTION=!-cSTARTFUNCTION_top
			data *^cFUNCTION_c
			Data *=cSTARTFUNCTION
			Data *=cFUNCTION
			Data *=spacereq
		Const cFUNCTIONX=!-cSTARTFUNCTION_top
			data *^cFUNCTIONX_c
			Data *=cSTARTFUNCTION
			Data *=cFUNCTIONX
			Data *=spacereq
		Const cENTRYRAW=!-cSTARTFUNCTION_top
			data *^cENTRYRAW_c
			Data *=cSTARTFUNCTION
			Data *=cENTRYRAW
			Data *=spacereq
		Const cENTRY=!-cSTARTFUNCTION_top
			data *^cENTRY_c
			Data *=cSTARTFUNCTION
			Data *=cENTRY
			Data *=spacereq
	Const cENDFUNCTION=!-coms_start
		data *^cENDFUNCTION_c
		Data *=cENDFUNCTION
		Data *#1
		Data *=spacenotreq
	Const cRET=!-coms_start
		data *^cRET_c
		Data *=cRET
		Data *#1
		Data *=spacenotreq
	Const cINCLUDE=!-coms_start
		data *^cINCLUDE_c
		Data *=cINCLUDE
		Data *#1
		Data *=spacereq
	Const cFORMAT=!-coms_start
		data *^cFORMAT_c
		Data *=cFORMAT
		Data *#1
		Data *=spacereq
#aftercall can be at function parameters but the get_img_vdata_dataReg() is set inside and codding must be done for not a big deal
	Const cDECLAREAFTERCALL=!-coms_start
	Const cDECLAREAFTERCALL_top=!
		Const cIMPORTAFTERCALL=!-cDECLAREAFTERCALL_top
			data *^cIMPORTAFTERCALL_c
			Data *=cDECLAREAFTERCALL
			Data *=cIMPORTAFTERCALL
			Data *=spacereq
		Const cAFTERCALL=!-cDECLAREAFTERCALL_top
			data *^cAFTERCALL_c
			Data *=cDECLAREAFTERCALL
			Data *=cAFTERCALL
			Data *=spacereq
	Const cWARNING=!-coms_start
		data *^cWARNING_c
		Data *=cWARNING
		Data *#1
		Data *=spacereq
	Const cCALLEX=!-coms_start
		data *^cCALLEXX_c
		Data *=cCALLEX
		Data *=x_callx_flag
		Data *=spacereq
		data *^cCALLEX_c
		Data *=cCALLEX
		Data *=0
		Data *=spacereq
	Const cOVERRIDE=!-coms_start
		data *^cOVERRIDE_c
		Data *=cOVERRIDE
		Data *#1
		Data *=spacereq
	Const cLIBRARY=!-coms_start
		data *^cLIBRARY_c
		Data *=cLIBRARY
		Data *#1
		Data *=spacereq
	Const cHEX=!-coms_start
		data *^cHEX_c
		Data *=cHEX
		Data *#1
		Data *=spacereq
	Const cI3=!-coms_start
		data *^cI3_c
		Data *=cI3
		Data *#1
		Data *=spacenotreq
Const numberofcommands=(!-coms_start)/com_size

Data pointers#numberofcommands+1
Const compointersloc^pointers

Data pointersvars#numberofcommandsvars+1
Const compointersvarsloc^pointersvars

const x_call_flag=0x80000000
const x_func_flag=0x80000000
const x_callx_flag=0x40000000

#declare coresp
function commandSubtypeDeclare_to_typenumber(sd subtype,sd p_is_expand)
#these numbers will be used at getstruct directly
	if subtype==(cCONST)
		return (constantsnumber)
	endif
	div subtype (com_size)
	if subtype>=(xnumbers)
		if subtype>=(xvnumbers)
			sub subtype (xnumbers-totalmemvariables)
		else
			sub subtype (xnumbers)
		endelse
		set p_is_expand# (TRUE)
	else
		set p_is_expand# (FALSE)   #this, if typenumber is constant, atm is not used
	endelse
	return subtype
endfunction
#set errormsg to pointer error or return the find
Function getcommand(data pcontent,data psize,data ptrsubtype,data ptrerrormsg,data pointercommands)
	Data zero=0
	Data command#1
	Data result#1
	Data cursor#1
	Data true=TRUE

	Data dsz=dwsz

	Set cursor pointercommands#
	While cursor!=zero
		Data offset#1
		Set offset cursor#
		Add cursor dsz
		Set command cursor#
		Add cursor dsz
		Set ptrsubtype# cursor#

		Data spacebool#1
		Add cursor dsz
		Set spacebool cursor#

		#implement for SetCall...
		Char calldata="CALL"
		Str call^calldata

		ss extstr=NULL

		sd extbooldata=FALSE
		sv extbool^extbooldata

		If command==(cPRIMSEC)
			Set extstr call
		Elseif command==(cSTARTFUNCTION)
			sd is_x;setcall is_x is_funcx_subtype(ptrsubtype#)
			if is_x==(TRUE)
				Set extstr "X"
			endif
		endElseif

		SetCall result stringsatmemspc(pcontent,psize,offset,spacebool,extstr,extbool)
		If extbooldata==true
			If command==(cPRIMSEC)
				#or first byte at subcommand to recognize the xcall at two args
				or ptrsubtype# (x_call_flag)
				if result==(FALSE)
					setcall result stratmemspc(pcontent,psize,"X",spacebool)
					if result==(TRUE)
						or ptrsubtype# (x_callx_flag)
					else
						break
					endelse
				endif
			Else
			#funcx
				if result==(FALSE)
					break
				endif
				#allow the command at 64 but not consider it
				sd for64;setcall for64 is_for_64()
				if for64==(TRUE)
					or ptrsubtype# (x_func_flag)
				endif
			endElse
			return command
		elseIf result==true
			Return command
		endelseIf
		Add pointercommands dsz
		Set cursor pointercommands#
	EndWhile

	Char _unrecCom="Unrecognized command/declaration name."
	Str unrecCom^_unrecCom
	Set ptrerrormsg# unrecCom
EndFunction



Function sortcommands(sv pointerscursor,sd nrofcomms,sd datacursor)
#it's that old strategy elseif will be only else if let unsorted, endelseif/endelse, maybe more
	sd i=0
#	Data sz#1
#	Data j#1
	Data dsize=dwsz
#	Data szval#1
#	Data ptrval#1
#	Data ptrvalstand#1
#	Data dataval#1

	While i<nrofcomms
#		SetCall sz strlen(datacursor#)
#		Set j i
#		Set ptrval pointerscursor
#		Set ptrvalstand pointerscursor
#		While zero<j
#			Sub ptrval dsize
#			Set dataval ptrval#
#			SetCall szval strlen(dataval#)
#			If szval>=sz
#				Set j zero
#			Else
#				Set ptrvalstand# dataval
#				Sub ptrvalstand dsize
#				Dec j
#			EndElse
#		EndWhile
#		Set ptrvalstand# datacursor
		set pointerscursor# datacursor
		Add pointerscursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Inc i
	EndWhile
	Set pointerscursor# (NULL)
EndFunction

Function sortallcommands()
#put commands pointers at init
	vdata commandscursorini%comsloc
	vData pointerscursor%compointersloc
	Data comms=numberofcommands

	Call sortcommands(pointerscursor,comms,commandscursorini)

	vData datacursorini%cdataloc
	vData pointersvarscursor%compointersvarsloc
	Data variables=numberofcommandsvars
	Call sortcommands(pointersvarscursor,variables,datacursorini)
EndFunction
