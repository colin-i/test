

function imm_values(sd ptrcontent,sd ptrsize,sd sz,sd outvalue)
#parenthesis is already verified
	call stepcursors(ptrcontent,ptrsize)
	dec sz
	dec sz
	sd err
	setcall err parseoperations(ptrcontent,ptrsize,sz,outvalue)
	return err
endfunction

function canbeimm_orerror(sd ptrcontent,sd ptrsize,sd sz,sd outvalue)
#size is not 0(zero)
	ss content
	set content ptrcontent#

	sd err

	chars canbeconstantsnumbers="("
	if content#!=canbeconstantsnumbers
		setcall err numbersconstants(content,sz,outvalue)
		return err
	endif
	data f^imm_values
	setcall err restore_cursors_onok(ptrcontent,ptrsize,f,sz,outvalue)
	return err
endfunction

#err
function findimm(data ptrcontent,data ptrsize,data sz,data outvalue)
#size is not 0(zero)
	data canhaveimm#1
	const immpointer^canhaveimm
	data isimm#1
	const ptr_isimm^isimm

	Data noerr=noerror
	sd err
	setcall err canbeimm_orerror(ptrcontent,ptrsize,sz,outvalue)
	if err!=noerr
		return err
	endif

	data true=1
	set isimm true
	return noerr
endfunction


function setimm()
	data ptratimm%immpointer
	data true=1
	set ptratimm# true
endfunction
function unsetimm()
	data ptratimm%immpointer
	data false=0
	set ptratimm# false
endfunction
function getimm()
	data ptratimm%immpointer
	return ptratimm#
endfunction


function resetisimm()
	data ptr%ptr_isimm
	data false=0
	set ptr# false
endfunction
function getisimm()
	data ptr%ptr_isimm
	return ptr#
endfunction



#er
function writeop_immfilter(sd dataarg,sd op,sd intchar,sd sufix,sd regopcode,sd is_low)
	sd isimm
	setcall isimm getisimm()
	data false=0
	sd err
	if isimm==false
		setcall err writeop(dataarg,op,intchar,sufix,regopcode,is_low)
		return err
	endif
	chars immop#1
	data value#1
	data immadd^immop
	set immop op
	set value dataarg
	data sz=5
	data code%ptrcodesec
	setcall err addtosec(immadd,sz,code)
	return err
endfunction


function storefirst_isimm()
	data firstimm#1
	const ptr_first_isimm^firstimm
	data ptr%ptr_isimm
	set firstimm ptr#
endfunction

function restorefirst_isimm()
	data first%ptr_first_isimm
	data ptr%ptr_isimm
	set ptr# first#
endfunction

function switchimm()
	data ptr%ptr_isimm
	data true=1
	if ptr#==true
		data first%ptr_first_isimm
		set first# true
		data false=0
		set ptr# false
	endif
endfunction