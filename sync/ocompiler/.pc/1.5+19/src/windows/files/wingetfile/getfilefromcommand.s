

sd command_name
sd commname_size

SetCall command_name GetCommandName()

#this is so bugged but accepted , strlen is ansi, but no wide path in this program, so first XX00h will stop
SetCall commname_size strlen(command_name)
If commname_size!=zero
	setcall argv CommandLineToArgvW(command_name,#argc)
	if argv!=(NULL)
		#here is the start of mem worries for windows
		call argv_to_ansi(argc,argv)
		if argc>0 #is this logic?
			call setpreferences(argv#)
			if argc>1
				set path_nofree argv
				incst path_nofree
				set path_nofree path_nofree#
			endif
		endif
	endif
EndIf