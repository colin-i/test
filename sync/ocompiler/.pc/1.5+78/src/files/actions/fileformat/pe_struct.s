



#IMAGE_DOS_HEADER
#00    WORD   e_magic;                     // Magic number
#02    WORD   e_cblp;                      // Bytes on last page of file
#04    WORD   e_cp;                        // Pages in file
#06    WORD   e_crlc;                      // Relocations
#08    WORD   e_cparhdr;                   // Size of header in paragraphs
#      WORD   e_minalloc;                  // Minimum extra paragraphs needed
#      WORD   e_maxalloc;                  // Maximum extra paragraphs needed
#      WORD   e_ss;                        // Initial (relative) SS value
#10    WORD   e_sp;                        // Initial SP value
#      WORD   e_csum;                      // Checksum
#      WORD   e_ip;                        // Initial IP value
#      WORD   e_cs;                        // Initial (relative) CS value
#      WORD   e_lfarlc;                    // File address of relocation table
#      WORD   e_ovno;                      // Overlay number
#1c    WORD   e_res[4];                    // Reserved words
#      WORD   e_oemid;                     // OEM identifier (for e_oeminfo)
#      WORD   e_oeminfo;                   // OEM information; e_oemid specific
#      WORD   e_res2[10];                  // Reserved words
#2c    LONG   e_lfanew;                    // File address of new exe header

Data pdoscrs^dos_header
Data pdos^dos_header
Data dos_size=dossize
Call memset(pdos,null,dos_size)

Chars mz="MZ"
Str pmz^mz
Call memtomem(pdos,pmz,wordsize)

Add pdos wordsize
Data e_cblp=128
Set pdos# e_cblp

Add pdos wordsize
Data e_cp=1
Set pdos# e_cp

Add pdos wordsize
Add pdos wordsize
Data e_cparhdr=4
Set pdos# e_cparhdr

Add pdoscrs dos_size
Sub pdoscrs dwordsize
Data e_lfanew=0x80
Set pdoscrs# e_lfanew

Chars stubcode={0x0e,0x1f,0xba,0x0e,0x00,0xb4,0x09,0xcd,0x21,0xb8,0x01,0x4c,0xcd,0x21}
Chars stubstr="This program cannot be run in DOS mode."
Chars stubstrend={0xd,0xa,0x24,0,0,0,0,0,0,0,0}
Data pstub^stub
Data stubsz^stubstr
Data pstubcode^stubcode

Sub stubsz pstubcode
Call memtomem(pstub,pstubcode,stubsz)
Add pstub stubsz
Data stubsz2#1
Data pstubstr^stubstr
SetCall stubsz2 strlen(pstubstr)
Call memtomem(pstub,pstubstr,stubsz2)
Add pstub stubsz2
Data stubsz3#1
Data stublength=stublength
set stubsz3 stublength
Sub stubsz3 stubsz2
Sub stubsz3 stubsz
Data pstubstrend^stubstrend
Call memtomem(pstub,pstubstrend,stubsz3)

Const fileheaderoffset^fileheader
#IMAGE_FILE_HEADER
#    WORD    Machine;
#    WORD    NumberOfSections;
#    DWORD   TimeDateStamp;
#    DWORD   PointerToSymbolTable;
#    DWORD   NumberOfSymbols;
#    WORD    SizeOfOptionalHeader;
#    WORD    Characteristics;

Data pfileheader%fileheaderoffset

Const IMAGE_FILE_MACHINE_I386=0x014C
Data Machine=IMAGE_FILE_MACHINE_I386
Set pfileheader# Machine

Add pfileheader wordsize
Const defaultNumberOfSections=2
Data defaultNumberOfSections=defaultNumberOfSections
Data ptrNumberOfSections#1
Set ptrNumberOfSections pfileheader
Set pfileheader# defaultNumberOfSections

#TimeDateStamp
Add pfileheader wordsize
Set pfileheader# null

#PointerToSymbolTable
Add pfileheader dwordsize
Set pfileheader# null

#NumberOfSymbols
Add pfileheader dwordsize
Set pfileheader# null

#SizeOfOptionalHeader
Add pfileheader dwordsize
Data SizeOfOptionalHeader=0xE0
Set pfileheader# SizeOfOptionalHeader

#Characteristics
Add pfileheader wordsize
Const IMAGE_FILE_DEBUG_STRIPPED=0x0200
Const IMAGE_FILE_32BIT_MACHINE=0x0100
Const IMAGE_FILE_LOCAL_SYMS_STRIPPED=0x0008
Const IMAGE_FILE_LINE_NUMS_STRIPPED=0x0004
Const IMAGE_FILE_EXECUTABLE_IMAGE=0x0002
#exe specific
Const IMAGE_FILE_RELOCS_STRIPPED=0x0001
#dll specific
#Const IMAGE_FILE_DLL=0x2000

Const coffChrsGeneral=IMAGE_FILE_DEBUG_STRIPPED|IMAGE_FILE_32BIT_MACHINE|IMAGE_FILE_LOCAL_SYMS_STRIPPED|IMAGE_FILE_LINE_NUMS_STRIPPED|IMAGE_FILE_EXECUTABLE_IMAGE
Const coffexeCharacteristics=coffChrsGeneral|IMAGE_FILE_RELOCS_STRIPPED
Data coffexeCharacteristics=coffexeCharacteristics

Data Characteristics#1
Set Characteristics coffexeCharacteristics
Data pchrctrs^Characteristics
Call memtomem(pfileheader,pchrctrs,wordsize)

#IMAGE_OPTIONAL_HEADER
Data popthd^Magic
Const IMAGE_NT_OPTIONAL_HDR32_MAGIC=0x10b
Data nt_opt_hd_magic=IMAGE_NT_OPTIONAL_HDR32_MAGIC
Data ohm^nt_opt_hd_magic
Call memtomem(popthd,ohm,wordsize)


Data ptrtodllcharacteristics^DllCharacteristics
Call memtomem(ptrtodllcharacteristics,ptrnull,wordsize)

Data patdirs^directoryentries
Data imgdirsSize=dwsz*imgdirsInts
Call memset(patdirs,null,imgdirsSize)
