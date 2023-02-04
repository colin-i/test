
const cross_convention_input=ignore_convention_input+1
const last_convention_input=cross_convention_input

set convention_64 argv2#

if convention_64==0
	call msgerrexit("argv2 null")
endif
inc argv2
if argv2#!=0
	call msgerrexit("argv2 must have only one character")
endif

if convention_64<(asciizero)
	call msgerrexit("argv2 must be greater than 0")
endif

sub convention_64 (asciizero)

if convention_64>(last_convention_input)
	call msgerrexit("argv2 must be 0,1 or 2")
endif
