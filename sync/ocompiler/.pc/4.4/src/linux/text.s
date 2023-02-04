
EntryLinux main(sd argc,ss *argv0,ss *argv1,ss argv2)

#main
Include "../files/inits.s"

Include "./files/xgetfile.s"

Include "../files/inits/conv_a.s"
Include "../files/inits/conv_b.s"
if argc==3
	#here on windows must take from argv
	Include "../files/inits/conv_c.s"
endif

Include "../files/actions.s"

Exit zero