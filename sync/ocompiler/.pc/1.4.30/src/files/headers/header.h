

#ref entry start
#bit offset 0: 1 means referenced
Const referencebit=0x01
#bit offset 1: 1 means idata function
Const idatabitfunction=0x02
#bit offset 2: 1 means stack variable
Const stackbit=0x04
	#stackbit
	#bit offset 3,4,5: stack ebx/ebp
	#0x8,0x10,0x20
	Const tostack_relative=0x08
	#
	#nostackbit
	#bit offset 3: datapointbit
	Const datapointbit=0x08
#bit offset 6: is functionX/importX
const x86_64bit=0x40
#bit offset 7; pointer bit (sv# with rex, sd# without rex)
const pointbit=0x80

const dummy_mask=0
const valueslongmask=datapointbit|pointbit

Const maskoffset=dwsz
Const nameoffset=maskoffset+dwsz

const sizeof_minimumentry=nameoffset+1
#ref entry end


Data errormsg#1
Data _errormsg^errormsg
Data noerr=noerror


vdata path_nofree#1
Data fileout#1
Const ptrfileout^fileout
Data ptrfileout%ptrfileout

#alloc.o
Const mainscope=10*0x1000
Const subscope=2*0x1000
Const _open_read=_O_RDONLY|flag_O_BINARY
Const _open_write=_O_WRONLY|flag_O_BINARY|flag_O_CREAT|_O_TRUNC
Const shortstrsize=16
Const includesetSz=4*dwsz+shortstrsize

Const containersdataoffset=4
Const containersdataRegoffset=8
Const sizeofcontainer=3*dwsz
#base containers
Const includesSize=50*includesetSz
#includesSize
Data includesMax#1
Data includes#1
Data includesReg#1
Const ptrincludes^includesMax

#subscope
Data miscbagMax#1
Data miscbag#1
Data miscbagReg#1
Const ptrmiscbag^miscbagMax

Const conditionssize=200*dwsz
#conditionssize
Data conditionsloopsMax#1
Data *conditionsloops#1
Data *conditionsloopsReg#1
Const ptrconditionsloops^conditionsloopsMax

Data unresolvedcallsMax=mainscope
Data unresolvedcalls#1
Data unresolvedcallsReg#1
Const ptrunresolvedcalls^unresolvedcallsMax

#variables, constants and functions containers
Data integerMax#1
Data *#1
Data *#1
Data stringMax#1
Data *#1
Data *#1
Data charsMax#1
Data *#1
Data *#1
Data sdMax#1
Data *#1
Data *#1
Data ssMax#1
Data *#1
Data *#1
Data svMax#1
Data *#1
Data *#1

Data integerfnscopeMax#1
Data *#1
Data *#1
Data stringfnscopeMax#1
Data *#1
Data *#1
Data charsfnscopeMax#1
Data *#1
Data *#1
Data sdfnMax#1
Data *#1
Data *#1
Data ssfnMax#1
Data *#1
Data *#1
Data svfnMax#1
Data *#1
Data *#1

Const memvariablesnumber=0
	Const integersnumber=memvariablesnumber+0
	Const stringsnumber=memvariablesnumber+1
	Const charsnumber=memvariablesnumber+2
	const valuesinnernumber=charsnumber
Const totalmemvariables=charsnumber+1
	Const stackdatanumber=totalmemvariables+integersnumber
	Const stackstringnumber=totalmemvariables+stringsnumber
	Const stackvaluenumber=totalmemvariables+valuesinnernumber
	#that was +charsnumber because it is compared against 2. and more reasons
Const numberofvars=stackvaluenumber+1
const vnumbers=numberofvars
#from numberofvars to afterscopes comes inner function local scopes
Const afterscopes=numberofvars*2
	Const constantsnumber=afterscopes+0
	Const functionsnumber=afterscopes+1

Const constantssize=10*mainscope
#constantssize
Data constantsMax#1
Data *constants#1
Data *constantsReg#1
Const ptrconstants^constantsMax

Data functionsMax#1
Data *functions#1
Data *functionsReg#1
Const ptrfunctions^functionsMax

Const ptrscopes^integerMax

#file containers
Const sizeofsecdata=0x1000
Data datasecMax#1
Data datasec#1
Data datasecReg#1
Const ptrdatasec^datasecMax

Data codesecMax=sizeofsecdata
Data codesec#1
Data codesecReg#1
Const ptrcodesec^codesecMax

#table
Const sizeofiedataparts=sizeofsecdata/0x10
Const itablesize=sizeofiedataparts
Data tableMax#1
Data table#1
Data tableReg#1
Const IMAGE_IMPORT_DESCRIPTORsize=dwsz*5
Const ptrtable^tableMax

Const iaddressessize=3*sizeofiedataparts
#addressessize
Data addressesMax#1
Data addresses#1
Data addressesReg#1
Const ptraddresses^addressesMax

Const sizeofienames=sizeofsecdata-iaddressessize-itablesize
#Const inamessize=sizeofienames
#namessize
Data namesMax#1
Data names#1
Data namesReg#1
Const ptrnames^namesMax

Data extraMax#1
Data extra#1
Data extraReg#1
Const ptrextra^extraMax

Data unresLocalMax#1
Data unresLocal#1
Data unresLocalReg#1
Const ptrunresLocal^unresLocalMax

Const containersbegin^includesMax
Const containersalmostend^unresLocalReg
Const containersend=containersalmostend+dwsz
Const containerssize=containersend-containersbegin

chars dummyEntry_data#sizeof_minimumentry

Data dummyEntryMax=sizeof_minimumentry
Data *dummyEntry^dummyEntry_data
Data dummyEntryReg#1
data ptrdummyEntry^dummyEntryMax
Const ptrdummyEntry^dummyEntryMax

#fileformat#
#file format variable
Data fileformat#1
Const ptrfileformat^fileformat
Const pe_exec=0
Const elf_unix=1
Data pe_exec=pe_exec
Data elf_unix=elf_unix
Data formatdefined#1

##section alignment for mem realloc and section padding
Const page_sectionalignment=0x1000
Data page_sectionalignment=page_sectionalignment
Const ptrpage_sectionalignment^page_sectionalignment
#Const ptrvirtualsectionalignment^virtualsectionalignment
##imagebase for both unresolved and data
Data imagebaseoffset#1
Const ptrimagebaseoffset^imagebaseoffset
##startofdata for data section
Data startofdata#1
Const ptrstartofdata^startofdata
##imports,locals offset for unresolved calls
Data virtualimportsoffset#1
Const ptrvirtualimportsoffset^virtualimportsoffset
Data virtuallocalsoffset#1
Const ptrvirtuallocalsoffset^virtuallocalsoffset
##file headers
Data fileheaders#1
Data sizefileheaders#1

Data importfileheaders#1
Data sizeimportfileheaders#1
##object at elf
Data object#1
Const ptrobject^object
#fileformat#


#functions
Const callfunction=0
Const declarefunction=1


#more values
Data ptrdatasec%ptrdatasec
Data ptrcodesec%ptrcodesec
Data ptrmiscbag%ptrmiscbag
Data ptrtable%ptrtable
Data ptrnames%ptrnames
Data ptraddresses%ptraddresses
Data ptrextra%ptrextra
Data ptrconditionsloops%ptrconditionsloops
Data ptrnull^null

Data relocbool#1
Const ptrrelocbool^relocbool

Data allocerrormsg#1
const ptrallocerrormsg^allocerrormsg

Data _open_write=_open_write


Data warningsbool#1
Const ptrwarningsbool^warningsbool

data logbool#1
const ptrlogbool^logbool
data logfile#1
data ptrlogfile^logfile
const ptrlogfile^logfile


data includedir#1
const ptrincludedir^includedir
chars fileendchar#1

const ignore_warn=0
#const show_warn=1
const log_warn=2

data codeFnObj#1
const ptrcodeFnObj^codeFnObj

#Data log_import_functions#1
#const ptr_log_import_functions^log_import_functions

const const_warn_get=0
const const_warn_get_init=1


#main alloc error msg
Data fnavailable#1
const ptrfnavailable^fnavailable

#entry point address for comparing for functions and entry point rule
#entry point address is compared at function declare
Data programentrypoint#1
const ptrprogramentrypoint^programentrypoint

#getcommand
Str commandset#1
Data subtype#1
Data ptrsubtype^subtype





##stack
#chars movtostack={0xc7,0x85}
#data rampindex#1
#data rampvalue#1
const rampadd_value_off=bsz



data twoparse#1
const cptr_twoparse^twoparse



Const not_hexenum=0
Const hexenum=1


const val64_no=0
const val64_willbe=1

const direct_convention_input=0
const ignore_convention_input=1
const cross_convention_input=2
const last_convention_input=cross_convention_input
#
const ms_convention=4
const lin_convention=6

const convdata_total=0
const convdata_call=1
const convdata_fn=2
const convdata_init=3

#this for i686-gcc at make... more info
#const i386_obj_default_reloc=-8
#const i386_obj_default_reloc_rah=-1
const i386_obj_default_reloc=0
const i386_obj_default_reloc_rah=0

const sd_as_sv_bool=0
const sd_as_sv_get=1

const commentascii=asciinumber
const reserveascii=asciinumber
const pointerascii=asciinumber

const max_uint64=20
chars uint64c#max_uint64+1
str uint64s^uint64c

data w_as_e#1
const p_w_as_e^w_as_e

data over_pref#1
const p_over_pref^over_pref

data hidden_pref#1
const p_hidden_pref^hidden_pref

Data safecurrentdirtopath#1
const p_safecurrentdirtopath^safecurrentdirtopath

const nr_of_prefs=17
const nr_of_prefs_jumper=nr_of_prefs*:

vdata nr_of_prefs_pointers#nr_of_prefs;vdata nr_of_prefs_strings#nr_of_prefs
const nr_of_prefs_pointers_p^nr_of_prefs_pointers;const nr_of_prefs_strings_p^nr_of_prefs_strings

data pref_reloc_64#1
const p_pref_reloc_64^pref_reloc_64

data underscore_pref#1
const p_underscore_pref^underscore_pref

#exit end preference
data exit_end#1
const p_exit_end^exit_end
data real_exit_end#1
const p_real_exit_end^real_exit_end

data include_sec#1
const p_include_sec^include_sec
