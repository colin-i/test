
value scopesbag#1
data scopesbag_size#1
const scopesbag_ptr^scopesbag
const scopesbag_size_ptr^scopesbag_size
function scopes_free()
	sv s%scopesbag_ptr
	if s#!=(NULL)
		sv start;set start s#
		add s :
		sv pointer;set pointer s#d^
		add pointer start
		if start!=pointer
			sub pointer :
			sd scps%ptrscopes
			if pointer#!=scps
				add pointer :
			endif
			#else let named entry like it was
			while start!=pointer
				sub pointer :
				sv cursor_first;set cursor_first pointer#
				sv cursor=sizeofscope
				add cursor cursor_first
				while cursor_first!=cursor
				#the order is reversed but it is not a work more if all mallocs are ok
					sub cursor (sizeofcontainer)
					call enumbags_free(cursor)
				endwhile
				call free(cursor_first)
			endwhile
		endif
		call free(start)
	endif
endfunction

#err
function scopes_alloc(sd has_named_entry)
	sv ptrfunctions%ptrfunctions
	sd i=0
	sd fns
	sv last
	call getcontandcontReg(ptrfunctions,#fns,#last)
	add last fns
	while fns!=last
		add fns (nameoffset)
		addcall fns strlen(fns)
		inc fns
		inc i
	endwhile
	mult i :
	sv s%scopesbag_ptr
	setcall s# memcalloc(i)
	sv start;set start s#
	if start!=(NULL)
		add s :
		set s# i
		sv pointer;set pointer start
		add pointer i
		if has_named_entry==(TRUE)
			#entry tag is, and is last, entry. can be used in functions
			sub pointer :
			sd scps%ptrscopes
			set pointer# scps
		endif
		#alloc some dummy values
		while start!=pointer
			sub pointer :
			setcall pointer# memcalloc((sizeofscope)) #is calloc, needing reg 0, in case it is searched , and at freeings
		endwhile
		return (noerror)
	endif
	return (error)
endfunction

function scopes_get_scope(sd i)
	sv s%scopesbag_ptr
	set s s#
	mult i :
	add s i
	return s#
endfunction

function scopes_store(sv scope)
	sv s%scopesbag_ptr
	mult scope :
	add scope s#
	set scope scope#
	sd last=sizeofscope
	sv pointer%ptrfnscopes
	add last pointer
	while pointer!=last
		sd cont;sd contReg;call getcontandcontReg(pointer,#cont,#contReg)
		#add new cont at fns
		call setcontMax(pointer,(subscope))
		sd err;setcall err enumbags_alloc(pointer)
		if err!=(noerror)
			return err
		endif
		# reg is zero outside (was from when there was only one scope)
		#transfer cont to store
		# max is not used
		call setcont(scope,cont)
		call setcontReg(scope,contReg)
		#next
		add scope (sizeofcontainer)
		add pointer (sizeofcontainer)
	endwhile
	return (noerror)
endfunction

function scopes_searchinvars(sd p_err,sv p_name)
	sd psz%scopesbag_size_ptr
	#there are imports after fns with the two pass, and now can get number of local fns, but importbit can be rethinked for something else
	sd sz;set sz psz#
	div sz :
	sd i=0

	sv ptrfunctions%ptrfunctions
	sd fns
	call getcont(ptrfunctions,#fns)
	while i!=sz
		add fns (nameoffset)
		sd data
		sd scope
		setcall scope scopes_get_scope(i)
		setcall data searchinvars_scope_warn(p_err,scope)
		if data!=(NULL)
			set p_name# fns
			return data
		endif
		addcall fns strlen(fns)
		inc fns
		inc i
	endwhile
	return (NULL)
endfunction
