


#fileformat#
#file format variable

Set fileformat pe_exec
Set formatdefined 0

#set default imagebase for data
Data default_imagebase=pe_imagebase
Set imagebaseoffset default_imagebase

#start of data, here and at format command
Set startofdata page_sectionalignment

Set object false
#fileformat#

#for function in function rule
Set innerfunction false

Set programentrypoint zero

#include or not include for applying after command parse
Set includebool zero

#files
Set fileout negative
set logfile negative


#containers initialisations
Data containersptr%containersbegin
Data containerssize=containerssize

Call memset(containersptr,null,containerssize)

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

#sort the commands
Call sortallcommands()


#the detailed functions and entry point informations
#main alloc error msg
Chars entrystartfile#shortstrsize
Str ptrentrystartfile^entrystartfile
Data entrylinenumber#1

Set fnavailable one

Set allocerrormsg null

#implibsstarted for closing at the end and for import parts; is here because 0 bytes src is something and asking for this at end
Set implibsstarted false

#fn info text is at preferences

#pref
sd prefix
setcall prefix prefix_bool()
set prefix# 0

set dummyEntryReg 0
call add_ref_to_sec(ptrdummyEntry,0,(dummy_mask),"",0)

sd var
setcall var function_in_code()
set var# 0

#64bit
#is init , is tested at any import and is set TRUE/FALSE only at elfobj... syntax
sd p_is_for_64_value;setcall p_is_for_64_value p_is_for_64();set p_is_for_64_value# (FALSE)
call stack64_op_set_get((TRUE),(FALSE))
call val64_init()

#afterCall
data g_e_b_p#1;setcall g_e_b_p global_err_pBool();set g_e_b_p# (FALSE)

#entrylinux bool
data el_b_p#1;setcall el_b_p entrylinux_bool_p();set el_b_p# (FALSE)

set warn_hidden_whitespaces_times 0

set safecurrentdirtopath (NULL)

sd convention_64
setcall convention_64 p_neg_is_for_64()

call initpreferences()
