

Data implibsstarted#1

#er
Function openlib()
	Data addressesReg#1
	Data namesReg#1
	Data ptraddressesReg^addressesReg
	Data ptrnamesReg^namesReg
	Data iaddresses%ptraddresses
	Data inames%ptrnames
	Call getcontReg(iaddresses,ptraddressesReg)
	Call getcontReg(inames,ptrnamesReg)

	Data OriginalFirstThunk#1
	Data *TimeDateStamp=0
	Data *ForwarderChain=0
	Data Name#1
	Data FirstThunk#1

	Set Name namesReg
	Set FirstThunk addressesReg

	Data iid^OriginalFirstThunk
	Data iid_size=IMAGE_IMPORT_DESCRIPTORsize
	Data itable%ptrtable
	Data err#1
	SetCall err addtosec(iid,iid_size,itable)
	Return err
EndFunction

#er
Function closelib()
	Data itable%ptrtable
	Data itab#1
	Data tabsize#1
	Data ptritab^itab
	Data ptrtabsize^tabsize
	Call getcontandcontReg(itable,ptritab,ptrtabsize)

	Data iaddresses%ptraddresses

	Data null=NULL
	Data ptrnull^null
	Data dsz=dwsz
	Data err#1
	SetCall err addtosec(ptrnull,dsz,iaddresses)
	Data noerr=noerror
	If err!=noerr
		Return err
	EndIf

	Data iadr#1
	Data adrsize#1
	Data ptriadr^iadr
	Data ptradrsize^adrsize
	Call getcontandcontReg(iaddresses,ptriadr,ptradrsize)

	Add itab tabsize
	Data ptrfirstthunk#1
	Set ptrfirstthunk itab
	Sub ptrfirstthunk dsz
	Data firstthunk#1
	Set firstthunk ptrfirstthunk#

	Data iidsize=IMAGE_IMPORT_DESCRIPTORsize
	Sub itab iidsize

	Set itab# adrsize

	Data src#1
	Set src iadr
	Add src firstthunk

	Sub adrsize firstthunk

	SetCall err addtosec(src,adrsize,iaddresses)
	Return err
EndFunction
