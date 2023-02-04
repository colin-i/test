




##############################################
Set SizeOfImage SectionAlignment
##############################################

##############################################
#datasection VirtualSize
Set dVirtualSize datasecReg
#######################
Set dSizeOfRawData datasecMax
#######################
Set SizeOfInitializedData dSizeOfRawData
#######################
Add SizeOfImage dSizeOfRawData
##############################################


##############################################
Set BaseOfCode SizeOfImage
#######################
Set SizeOfCode codesecMax
#######################
Add programentrypoint BaseOfCode
Set AddressOfEntryPoint programentrypoint
#######################
#codesection VirtualSize
Set cVirtualSize codesecReg
#######################
Set cVirtualAddress BaseOfCode
#######################
Set cPointerToRawData SizeOfImage
#######################
Set cSizeOfRawData SizeOfCode
#######################
Add SizeOfImage cSizeOfRawData
#######################
Const pe_fileheadersstart^dos_header
Const codesectionCharacteristicsoff^codesectionCharacteristics
Const sizefileheadercodedata=codesectionCharacteristicsoff+dwsz
Const codedatasizefileheaders=sizefileheadercodedata-pe_fileheadersstart
Data codedatasizefileheaders=codedatasizefileheaders

Set SizeOfHeaders codedatasizefileheaders
##############################################


###################resolve commons###################
Data pe_fileheaders%pe_fileheadersstart
Set fileheaders pe_fileheaders
Set sizefileheaders SizeOfHeaders

set virtuallocalsoffset cVirtualAddress
add virtuallocalsoffset imagebaseoffset
###################resolve commons###################

Data directoriesaddress^directoryentries
Data destdir#1
If implibsstarted==true
	##############################################
	Set iVirtualAddress SizeOfImage
	#######################
	Set iPointerToRawData SizeOfImage
	#######################
	#OPTIONAL_HEADER\Directories\Import table rva
	Set destdir directoriesaddress
	Data idiroffset=im_d_entry_import_offset
	Add destdir idiroffset
	Set destdir# iVirtualAddress
	#######################

	#OPTIONAL_HEADER\Directories\Import table size
	Add destdir dwordsize

	Data itabentrysize=IMAGE_IMPORT_DESCRIPTORsize
	Data itabloc#1
	Set itabloc tableReg
	SetCall errormsg addtosec(0,itabentrysize,ptrtable)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf
	Add itabloc table
	Call memset(itabloc,null,itabentrysize)

	Set destdir# tableReg

	#######################
	Add SizeOfInitializedData iSizeOfRawData
	#######################
	Add SizeOfImage iSizeOfRawData
	#######################
	Inc ptrNumberOfSections#
	#######################
	Const idatasectionCharacteristicsoff^idatasectionCharacteristics
	Const idatasectionstart^idatasection
	Const idatasectionsize=idatasectionCharacteristicsoff+dwsz-idatasectionstart
	Data idatasectionstart%idatasectionstart
	Data idatasectionsize=idatasectionsize

	Add SizeOfHeaders idatasectionsize
	#without this "There is an import table, but the section containing it could not be found"
	add sizefileheaders idatasectionsize
	##############################################

	Const iaddressesoffset=itablesize
	Const inamesoffset=itablesize+iaddressessize
	Data iaddressesoffset=iaddressesoffset
	Data inamesoffset=inamesoffset

	###################resolve commons###################
	Set importfileheaders idatasectionstart
	Set sizeimportfileheaders idatasectionsize

	Set virtualimportsoffset iVirtualAddress
	Add virtualimportsoffset iaddressesoffset
	add virtualimportsoffset imagebaseoffset
	###################resolve commons###################

	#resolve idata section
	Add iaddressesoffset iVirtualAddress
	Add inamesoffset iVirtualAddress

	Data resolveitab#1
	Set resolveitab table
	Add resolveitab tableReg

	Sub resolveitab itabentrysize
	Data resolvevalue#1
	While table!=resolveitab
		Sub resolveitab dwordsize
		Set resolvevalue resolveitab#
		Add resolvevalue iaddressesoffset
		Set resolveitab# resolvevalue
		Sub resolveitab dwordsize
		Set resolvevalue resolveitab#
		Add resolvevalue inamesoffset
		Set resolveitab# resolvevalue
		Sub resolveitab dwordsize
		Sub resolveitab dwordsize
		Sub resolveitab dwordsize
		Set resolvevalue resolveitab#
		Add resolvevalue iaddressesoffset
		Set resolveitab# resolvevalue
	EndWhile

	Data resolveiadr#1
	Set resolveiadr addresses
	Add resolveiadr addressesReg

	While addresses!=resolveiadr
		Sub resolveiadr dwordsize
		Set resolvevalue resolveiadr#
		#offset 0 can be wrong but is not because there it is the first library name and these are functions names
		If resolvevalue!=zero
			Add resolvevalue inamesoffset
			Set resolveiadr# resolvevalue
		EndIf
	EndWhile
EndIf

Data padtheheaders#1
SetCall padtheheaders requiredpad(SizeOfHeaders,FileAlignment)
Add SizeOfHeaders padtheheaders