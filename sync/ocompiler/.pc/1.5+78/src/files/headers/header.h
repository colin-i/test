

#ref entry start
#bit offset 0: 1 means referenced
Const referencebit=0x01
#bit offset 1: 1 means idata function
Const idatabitfunction=0x02
#bit offset 2: 1 means stack variable
Const stackbit=0x04
#bit offset 3:
	#stackbit: 1 means ebp fn arguments          #was bit offset 3,4,5: stack ebx/ebp
Const stack_relative=0x08
	#nostackbit: datapointbit
Const datapointbit=0x08
#bit offset 4: 1 means is nobits
const expandbit=0x10
#bit offset 5: 1 means ignore aftercall
const aftercallthrowlessbit=0x20
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

#Const containersdataMaxoffset=0
Const containersdataoffset=4
Const containersdataRegoffset=8
Const sizeofcontainer=3*dwsz
#base containers
Const includesSize=50*includesetSz
#includesSize

#this, not yet at simple exec Const containersbegin=!x

Datax includesMax#1
Datax includes#1
Datax includesReg#1
Const ptr_includes^includesMax

#subscope
Datax miscbagMax#1
Datax miscbag#1
Datax miscbagReg#1
Const ptr_miscbag^miscbagMax

Const conditionssize=200*dwsz
#conditionssize
Datax conditionsloopsMax#1
Datax *conditionsloops#1
Datax *conditionsloopsReg#1
Const ptr_conditionsloops^conditionsloopsMax

Datax unresolvedcallsMax#1
Datax unresolvedcalls#1
Datax unresolvedcallsReg#1
Const ptr_unresolvedcalls^unresolvedcallsMax

#variables, constants and functions containers
Datax integerMax#1
Datax *#1
Datax *#1
Datax stringMax#1
Datax *#1
Datax *#1
Datax charsMax#1
Datax *#1
Datax *#1
Datax sdMax#1
Datax *#1
Datax *#1
Datax ssMax#1
Datax *#1
Datax *#1
Datax svMax#1
Datax *#1
Datax *#1

Datax integerfnscopeMax#1
Datax *#1
Datax *#1
Datax stringfnscopeMax#1
Datax *#1
Datax *#1
Datax charsfnscopeMax#1
Datax *#1
Datax *#1
Datax sdfnMax#1
Datax *#1
Datax *#1
Datax ssfnMax#1
Datax *#1
Datax *#1
Datax svfnMax#1
Datax *#1
Datax *#1

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
	const vintegersnumber=vnumbers+integersnumber
	const vstringsnumber=vnumbers+stringsnumber
	const valuesnumber=vnumbers+valuesinnernumber
const xnumbers=valuesnumber+1
const xvnumbers=xnumbers+totalmemvariables

#from numberofvars to afterscopes comes inner function local scopes
Const afterscopes=numberofvars*2
	Const constantsnumber=afterscopes+0
	Const functionsnumber=afterscopes+1
const sizeofscope=sizeofcontainer*numberofvars

Const constantssize=10*mainscope
#constantssize
Datax constantsMax#1
Datax *constants#1
Datax *constantsReg#1
Const ptr_constants^constantsMax

Datax functionsMax#1
Datax *functions#1
Datax *functionsReg#1
Const ptr_functions^functionsMax

Const ptr_scopes^integerMax
Const ptr_fnscopes^integerfnscopeMax

#file containers
Const sizeofsecdata=0x1000
Datax datasecMax#1
Datax datasec#1
Datax datasecReg#1
Const ptr_datasec^datasecMax
Const ptr_dataReg^datasecReg

Datax codesecMax#1
Datax codesec#1
Datax codesecReg#1
Const ptr_codesec^codesecMax

#table
Const sizeofiedataparts=sizeofsecdata/0x10
Const itablesize=sizeofiedataparts
Datax tableMax#1
Datax table#1
Datax tableReg#1
Const IMAGE_IMPORT_DESCRIPTORsize=dwsz*5
Const ptr_table^tableMax

Const iaddressessize=3*sizeofiedataparts
#addressessize
Datax addressesMax#1
Datax addresses#1
Datax addressesReg#1
Const ptr_addresses^addressesMax

Const sizeofienames=sizeofsecdata-iaddressessize-itablesize
#Const inamessize=sizeofienames
#namessize
Datax namesMax#1
Datax names#1
Datax namesReg#1
Const ptr_names^namesMax

Datax extraMax#1
Datax extra#1
Datax extraReg#1
Const ptr_extra^extraMax

Datax unresLocalMax#1
Datax unresLocal#1
Datax unresLocalReg#1
Const ptr_unresLocal^unresLocalMax

Datax debugsecMax#1
Datax debugsec#1
Datax debugsecReg#1
Const ptr_debug^debugsecMax

#not yet at simple exec Const containerssize=!x-containersbegin
const containersbegin^includesMax
const containersalmostend^debugsecReg
data containerssize=containersalmostend+dwsz-containersbegin
const containerssize^containerssize

chars dummyEntry_data#sizeof_minimumentry

Data dummyEntryMax=sizeof_minimumentry
Data *dummyEntry^dummyEntry_data
Data dummyEntryReg#1
data ptrdummyEntry^dummyEntryMax
Const ptrdummyEntry^dummyEntryMax

#data clownEntry#1
#data *#1
data nobitssecReg#1
const ptrnobitsReg^nobitssecReg
#used at !x offset

Data datasecSize#1
const ptrdataSize^datasecSize

#when taking offset at nobits
data nobitsDataStart#1
const ptr_nobitsDataStart^nobitsDataStart

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
Value ptrdatasec%%ptr_datasec
Value ptrcodesec%%ptr_codesec
Value ptrmiscbag%%ptr_miscbag
Value ptrtable%%ptr_table
Value ptrnames%%ptr_names
Value ptraddresses%%ptr_addresses
Value ptrextra%%ptr_extra
Value ptrconditionsloops%%ptr_conditionsloops
Value ptrdebug%%ptr_debug
Value ptrnull^null

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



data parses#1
const ptr_parses^parses



Const not_hexenum=0
Const hexenum=1


const val64_no=FALSE
const val64_willbe=TRUE

const direct_convention_input=0
const ignore_convention_input=1
#const cross_convention_input=2
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

#const max_uint64=20
chars uint32c#dw_chars_0
vstr uint32s^uint32c

data w_as_e#1
const p_w_as_e^w_as_e

data over_pref#1
const p_over_pref^over_pref

data hidden_pref#1
const p_hidden_pref^hidden_pref

Data safecurrentdirtopath#1
const p_safecurrentdirtopath^safecurrentdirtopath

const nr_of_prefs=21
const nr_of_prefs_jumper=nr_of_prefs*:

vdata nr_of_prefs_pointers#nr_of_prefs;vdata nr_of_prefs_strings#nr_of_prefs
const nr_of_prefs_pointers_p^nr_of_prefs_pointers;const nr_of_prefs_strings_p^nr_of_prefs_strings

data inplace_reloc_pref#1
const p_inplace_reloc_pref^inplace_reloc_pref
const zero_reloc=0
const addend_reloc=1

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

const pointersigndeclare=asciicirc
const assignsign=asciiequal
const relsign=asciipercent

const call_align_no=0
const call_align_yes_all=1
#const call_align_yes_arg_sha=2
const call_align_yes_arg=3
const last_call_align_input=call_align_yes_arg
data call_align#1
const ptr_call_align^call_align

const even_align=-1
#const no_align=0
const odd_align=1

data functionTagIndex#1  #need to be at call pass and last pass(scopes) and scopes alloc
const ptrfunctionTagIndex^functionTagIndex

const pass_init=3
const pass_calls=2
const pass_write0=2
const pass_write=1

const nosign=0

const allow_later_sec=-2
const allow_later=-1
const allow_no=0
const allow_yes=1

const getarg_str=asciidoublequote

data nobits_virtual#1
const ptr_nobits_virtual^nobits_virtual

data has_debug#1
const ptr_has_debug^has_debug
