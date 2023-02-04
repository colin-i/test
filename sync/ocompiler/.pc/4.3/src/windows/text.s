

#main

Include "../files/inits.s"

Data openfilenamemethod#1
Set openfilenamemethod false
Include "./files/wingetfile.s"

Include "../files/actions.s"

Include "./files/winend.s"

Call exit(zero)