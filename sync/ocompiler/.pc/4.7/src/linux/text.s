
EntryLinux main(sd argc,ss argv0,ss argv1)

#main
Include "../files/inits.s"

Include "./files/xgetfile.s"

sd argv
set argv #argv0

Include "../files/inits/conv.s"

Include "../files/actions.s"

Exit zero