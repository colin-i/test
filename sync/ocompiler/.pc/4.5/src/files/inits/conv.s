
sd convention_64

if argc>2
	if argc>3
		call exitMessage("Too many arguments")
	endif


	const cross_convention_input=ignore_convention_input+1
	const last_convention_input=cross_convention_input

	#argv will be freed on windows
	set convention_64 argv;add convention_64 (2*:)
	ss argv2
	set argv2 convention_64#
	set convention_64 argv2#

	if convention_64==0
		call exitMessage("argv2 null")
	endif
	inc argv2
	if argv2#!=0
		call exitMessage("argv2 must have only one character")
	endif

	if convention_64<(asciizero)
		call exitMessage("argv2 must be greater than 0")
	endif

	sub convention_64 (asciizero)

	if convention_64>(last_convention_input)
		call exitMessage("argv2 must be 0,1 or 2")
	endif
else
	set convention_64 (no_convention_input)
endelse
