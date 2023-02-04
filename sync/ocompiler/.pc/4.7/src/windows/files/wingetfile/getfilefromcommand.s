

sd command_name
sd commname_size

SetCall command_name GetCommandName()

#this is so bugged but accepted , strlen is ansi, but no wide path in this program, so first XX00h will stop
SetCall commname_size strlen(command_name)
If commname_size!=zero
	setcall argv CommandLineToArgvW(command_name,#argc)
	if argv!=(NULL)
		#here is the start of mem worries for windows
		if argc>1
			sd mirror
			set mirror argv;incst mirror
			sd aux_mirror;set aux_mirror mirror#
			call wide_to_ansi(aux_mirror)
			set path_nofree aux_mirror
			if argc>2
				incst mirror
				call wide_to_ansi(mirror#)
			endif
		endif
	endif
EndIf