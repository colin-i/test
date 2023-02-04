
if argc>2
	if argc>3
		call exitMessage("Too many arguments")
	endif

	sd convention_input

	#argv will be freed on windows
	set convention_input argv;add convention_input (2*:)
	ss argv2
	set argv2 convention_input#
	set convention_input argv2#

	if convention_input==0
		call exitMessage("argv2 null")
	endif
	inc argv2
	if argv2#!=0
		call exitMessage("argv2 must have only one character")
	endif

	if convention_input<(asciizero)
		call exitMessage("argv2 must be greater than 0")
	endif

	sub convention_input (asciizero)

	if convention_input>(last_convention_input)
		call exitMessage("argv2 must be 0,1 or 2")
	endif

	set convention_64# convention_input
endif
