

Const spacereq=1
Const spacenotreq=0

Chars cDATA_c="DATA";Chars cSTR_c="STR";Chars cCHARS_c="CHARS";Chars cSD_c="SD";Chars cSS_c="SS";Chars cSV_c="SV"
	Chars cCONST_c="CONST"
	Chars cVDATA_c="VDATA"
Chars cAFTERCALL_c="AFTERCALL";Chars cIMPORTAFTERCALL_c="IMPORTAFTERCALL"
Chars cFORMAT_c="FORMAT"
Chars cRETURN_c="RETURN";Chars cNOT_c="NOT";Chars cINC_c="INC";Chars cDEC_c="DEC";Chars cINCST_c="INCST";Chars cDECST_c="DECST";Chars cEXIT_c="EXIT";Chars cNEG_c="NEG";Chars cSHL_c="SHL";Chars cSHR_c="SHR";Chars cSAR_c="SAR"
Chars cSET_c="SET";Chars cADD_c="ADD";Chars cSUB_c="SUB";Chars cMULT_c="MULT";Chars cDIV_c="DIV";Chars cREM_c="REM";Chars cAND_c="AND";Chars cOR_c="OR";Chars cXOR_c="XOR"
Chars cLIBRARY_c="LIBRARY";
Chars cIMPORT_c="IMPORT";Chars cIMPORTX_c="IMPORTX";
Chars cFUNCTION_c="FUNCTION";Chars cFUNCTIONX_c="FUNCTIONX";Chars cENTRY_c="ENTRY";Chars cENTRYLINUX_c="ENTRYLINUX"
Chars cENDFUNCTION_c="ENDFUNCTION"
Chars cCALL_c="CALL"
Chars cCALLEX_c="CALLEX"
Chars cIF_c="IF";Chars cELSE_c="ELSE";Chars cWHILE_c="WHILE";Chars cELSEIF_c="ELSEIF";Chars cENDIF_c="ENDIF";Chars cENDELSE_c="ENDELSE";Chars cENDWHILE_c="ENDWHILE";Chars cENDELSEIF_c="ENDELSEIF"
Chars cINCLUDE_c="INCLUDE"
Chars cI3_c="I3"
Chars cHEX_c="HEX"
Chars cWARNING_c="WARNING"
Chars cCOMMENT_c={commentascii,0}

const not_a_subtype=-1

const coms_start=!
const commandsvars_start=!
	Const cDECLARE=!-coms_start
	Const cDECLARE_top=!
		Const cDATA=!-cDECLARE_top
			data cDATA_s^cDATA_c
			Data *=cDECLARE
			Data *=cDATA
			Data *=spacereq
		Const cSTR=!-cDECLARE_top
Const com_size=cSTR-cDATA
			data *^cSTR_c
			Data *=cDECLARE
			Data *=cSTR
			Data *=spacereq
		Const cCHARS=!-cDECLARE_top
			data *^cCHARS_c
			Data *=cDECLARE
			Data *=cCHARS
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
#numberofcommandsvars to set these commands to search for them at function parameter declare
Const numberofcommandsvars=!-commandsvars_start/com_size
		Const cCONST=!-cDECLARE_top
			data *^cCONST_c
			Data *=cDECLARE
			Data *=cCONST
			Data *=spacereq
		Const cVDATA=!-cDECLARE_top
			data *^cVDATA_c
			Data *=cDECLARE
			Data *=cVDATA
			Data *=spacereq
#aftercall can be at function parameters but the get_img_vdata_dataReg() is set inside and codding must be done for not a big deal
	Const cDECLAREAFTERCALL=!-coms_start
	Const cDECLAREAFTERCALL_top=!
		Const cAFTERCALL=!-cDECLAREAFTERCALL_top
			data *^cAFTERCALL_c
			Data *=cDECLAREAFTERCALL
			Data *=cAFTERCALL
			Data *=spacereq
		Const cIMPORTAFTERCALL=!-cDECLAREAFTERCALL_top
			data *^cIMPORTAFTERCALL_c
			Data *=cDECLAREAFTERCALL
			Data *=cIMPORTAFTERCALL
			Data *=spacereq
	Const cFORMAT=!-coms_start
		data *^cFORMAT_c
		Data *=cFORMAT
		Data *#1
		Data *=spacereq
	Const cONEARG=!-coms_start
	Const cONEARG_top=!
		Const cRETURN=!-cONEARG_top
			data *^cRETURN_c
			Data *=cONEARG
			Data *=cRETURN
			Data *=spacereq
		Const cNOT=!-cONEARG_top
			data *^cNOT_c
			Data *=cONEARG
			Data *=cNOT
			Data *=spacereq
		Const cINC=!-cONEARG_top
			data *^cINC_c
			Data *=cONEARG
			Data *=cINC
			Data *=spacereq
		Const cDEC=!-cONEARG_top
			data *^cDEC_c
			Data *=cONEARG
			Data *=cDEC
			Data *=spacereq
		Const cINCST=!-cONEARG_top
			data *^cINCST_c
			Data *=cONEARG
			Data *=cINCST
			Data *=spacereq
		Const cDECST=!-cONEARG_top
			data *^cDECST_c
			Data *=cONEARG
			Data *=cDECST
			Data *=spacereq
		Const cEXIT=!-cONEARG_top
			data *^cEXIT_c
			Data *=cONEARG
			Data *=cEXIT
			Data *=spacereq
		Const cNEG=!-cONEARG_top
			data *^cNEG_c
			Data *=cONEARG
			Data *=cNEG
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
	Const cLIBRARY=!-coms_start
		data *^cLIBRARY_c
		Data *=cLIBRARY
		Data *#1
		Data *=spacenotreq
	Const cIMPORTLINK=!-coms_start;Const cIMPORTLINK_top=!
		const cIMPORT=!-cIMPORTLINK_top
			data *^cIMPORT_c
			Data *=cIMPORTLINK
			Data *=cIMPORT
			Data *=spacenotreq
		const cIMPORTX=!-cIMPORTLINK_top
			data *^cIMPORTX_c
			Data *=cIMPORTLINK
			Data *=cIMPORTX
			Data *=spacenotreq
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
		Const cENTRY=!-cSTARTFUNCTION_top
			data *^cENTRY_c
			Data *=cSTARTFUNCTION
			Data *=cENTRY
			Data *=spacereq
		Const cENTRYLINUX=!-cSTARTFUNCTION_top
			data *^cENTRYLINUX_c
			Data *=cSTARTFUNCTION
			Data *=cENTRYLINUX
			Data *=spacereq
	Const cENDFUNCTION=!-coms_start
		data *^cENDFUNCTION_c
		Data *=cENDFUNCTION
		Data *#1
		Data *=spacenotreq
	Const cCALL=!-coms_start
		data *^cCALL_c
		Data *=cCALL
		Data *#1
		Data *=spacereq
	Const cCALLEX=!-coms_start
		data *^cCALLEX_c
		Data *=cCALLEX
		Data *#1
		Data *=spacereq
	Const cCONDITIONS=!-coms_start
	Const cCONDITIONS_top=!
		Const cIF=!-cCONDITIONS_top
			data *^cIF_c
			Data *=cCONDITIONS
			Data *=cIF
			Data *=spacereq
		Const cELSE=!-cCONDITIONS_top
			data *^cELSE_c
			Data *=cCONDITIONS
			Data *=cELSE
			Data *=spacenotreq
		Const cWHILE=!-cCONDITIONS_top
			data *^cWHILE_c
			Data *=cCONDITIONS
			Data *=cWHILE
			Data *=spacereq
		Const cELSEIF=!-cCONDITIONS_top
			data *^cELSEIF_c
			Data *=cCONDITIONS
			Data *=cELSEIF
			Data *=spacereq
		Const cENDIF=!-cCONDITIONS_top
			data *^cENDIF_c
			Data *=cCONDITIONS
			Data *=cENDIF
			Data *=spacenotreq
		Const cENDELSE=!-cCONDITIONS_top
			data *^cENDELSE_c
			Data *=cCONDITIONS
			Data *=cENDELSE
			Data *=spacenotreq
		Const cENDWHILE=!-cCONDITIONS_top
			data *^cENDWHILE_c
			Data *=cCONDITIONS
			Data *=cENDWHILE
			Data *=spacenotreq
		Const cENDELSEIF=!-cCONDITIONS_top
			data *^cENDELSEIF_c
			Data *=cCONDITIONS
			Data *=cENDELSEIF
			Data *=spacenotreq
	Const cINCLUDE=!-coms_start
		data *^cINCLUDE_c
		Data *=cINCLUDE
		Data *#1
		Data *=spacenotreq
	Const cI3=!-coms_start
		data *^cI3_c
		Data *=cI3
		Data *#1
		Data *=spacenotreq
	Const cHEX=!-coms_start
		data *^cHEX_c
		Data *=cHEX
		Data *#1
		Data *=spacereq
	Const cWARNING=!-coms_start
		data *^cWARNING_c
		Data *=cWARNING
		Data *#1
		Data *=spacereq
	Const cCOMMENT=!-coms_start
		data *^cCOMMENT_c
		Data *=cCOMMENT
		Data *#1
		Data *=spacenotreq
Const numberofcommands=!-coms_start/com_size

Data pointers#numberofcommands+1
Const compointersloc^pointers

Data pointersvars#numberofcommandsvars+1
Const compointersvarsloc^pointersvars

Const cdataloc^cDATA_s

const x_call_flag=0x80000000

#declare coresp
function commandSubtypeDeclare_to_typenumber(sd subtype)
#these numbers will be used at getstruct directly
	if subtype==(cCONST)
		return (constantsnumber)
	endif
	div subtype (com_size)
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
		Chars calldata="CALL"
		Str call^calldata
		Str extstr#1
		Data extbooldata#1
		Data extbool^extbooldata

		If command==(cPRIMSEC)
			Set extstr call
		Else
			Set extstr zero
		EndElse

		SetCall result stringsatmemspc(pcontent,psize,offset,spacebool,extstr,extbool)
		If result==true
			If command==(cPRIMSEC)
				If extbooldata==true
					#or first byte at subcommand to recognize the xcall at two args
					or ptrsubtype# (x_call_flag)
				EndIf
			EndIf
			Return command
		EndIf
		Add pointercommands dsz
		Set cursor pointercommands#
	EndWhile

	Chars _unrecCom="Unrecognized command/declaration name."
	Str unrecCom^_unrecCom
	Set ptrerrormsg# unrecCom
EndFunction



Function sortcommands(data pointerscursor,data nrofcomms)
#used for endelseif (first search),endelse (second search);the reverse order will not get endelseif
	Data datacursor#1
	Data datacursorini%cdataloc
	Data i#1
	Data zero=0
	Data sz#1
	Data j#1
	Data dsize=dwsz
	Data szval#1
	Data ptrval#1
	Data ptrvalstand#1
	Data dataval#1

	Set datacursor datacursorini
	Set i zero
	While i<nrofcomms
		SetCall sz strlen(datacursor#)
		Set j i
		Set ptrval pointerscursor
		Set ptrvalstand pointerscursor
		While zero<j
			Sub ptrval dsize
			Set dataval ptrval#
			SetCall szval strlen(dataval#)
			If szval>=sz
				Set j zero
			Else
				Set ptrvalstand# dataval
				Sub ptrvalstand dsize
				Dec j
			EndElse
		EndWhile
		Set ptrvalstand# datacursor

		Add pointerscursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Add datacursor dsize
		Inc i
	EndWhile
	Set pointerscursor# zero
EndFunction

Function sortallcommands()
#put commands pointers at init
	Data pointerscursor%compointersloc
	Data comms=numberofcommands

	Call sortcommands(pointerscursor,comms)

	Data pointersvarscursor%compointersvarsloc
	Data variables=numberofcommandsvars
	Call sortcommands(pointersvarscursor,variables)
EndFunction
