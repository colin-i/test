

#the local calls (finalized)
#data local calls (prepared)
call localResolve(unresLocal,unresLocalReg)








#resolve import at code, import at data, local at data
data unresstruct#1
Data unresoff#1
data unresadd#1

data unresstructure#1
data ptrunresstructure^unresstructure

Data unresptr#1
Data unresptrlastpoint#1
Set unresptrlastpoint unresolvedcallsReg
Set unresptr unresolvedcalls
add unresptrlastpoint unresolvedcalls
While unresptr!=unresptrlastpoint
	Set unresstruct unresptr#
	call getcont(unresstruct,ptrunresstructure)

	add unresptr dwordsize
	Set unresoff unresptr#
	add unresstructure unresoff
	
	add unresptr dwordsize
	set unresadd unresptr#
	set unresadd unresadd#

	add unresstructure# unresadd

	Add unresptr dwordsize
EndWhile


