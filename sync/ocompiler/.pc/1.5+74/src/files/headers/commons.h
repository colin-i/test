
#Constants
Const TRUE=1
Const FALSE=0
Const NULL=0
Const No=FALSE
Const Yes=TRUE

#files
 #open
Const _O_RDONLY=0

Const openno=-1
Const _O_WRONLY=0x0001
Const _O_TRUNC=0x0200

 #seek
Const SEEK_SET=0
#Const SEEK_CUR=1
Const SEEK_END=2
 #write
Const writeno=-1
 #chdir
Const chdirok=0
data chdirok=chdirok

#more Constants
Const bsz=1
Const wsz=2
Const dwsz=4
Const qwsz=8
Const A_from_AZ=asciiA
#Const Z_from_AZ=asciiZ
Const a_from_az=asciia
Const z_from_az=asciiz
Const AZ_to_az=a_from_az-A_from_AZ


#Integers
Data null=NULL
Data true=TRUE
Data false=FALSE
Data flag_max_path=flag_MAX_PATH

#more values
Const noerror=0
Const error=-1 #is also for some windows
Const FORWARD=1
Const BACKWARD=-1
Const void=0

Data bytesize=bsz
Data wordsize=wsz
Data dwordsize=dwsz
Data qwordsize=qwsz
Data zero=0
Data one=1
data two=2
data three=3
Data negative=-1
Data i#1
Chars dot="."

const sym_with_size=dwsz
