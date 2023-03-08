

#containers initialisations (bags alloc using Max)

Data mainscope=mainscope
Data subscope=subscope

##base containers
Data includesSize=includesSize
Data conditionssize=conditionssize
Set includesMax includesSize
Set miscbagMax subscope
Set conditionsloopsMax conditionssize
Set unresolvedcallsMax mainscope

##variables, constants and functions containers
Data constantssize=constantssize
Set integerMax mainscope
Set stringMax mainscope
Set charsMax mainscope
Set sdMax mainscope
Set ssMax mainscope
Set svMax mainscope

Set integerfnscopeMax subscope
Set stringfnscopeMax subscope
Set charsfnscopeMax subscope
Set sdfnMax subscope
Set ssfnMax subscope
Set svfnMax subscope

Set constantsMax constantssize
Set functionsMax mainscope

##file containers
Data ienamessize=sizeofienames

Set datasecMax page_sectionalignment
Set codesecMax page_sectionalignment

Data itablesize=sizeofiedataparts
Data iaddressessize=iaddressessize
Set tableMax itablesize
Set addressesMax iaddressessize
Set namesMax ienamessize

Set extraMax subscope

Set unresLocalMax mainscope



SetCall errormsg enumbags(true)
#here is the start of mem worries for linux
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf
