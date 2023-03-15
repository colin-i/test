





#File Structures

Const dossize=0x1e*wsz+dwsz
#Const alldossize=dossize+0x40

Const pe_fileheadersstart=!

Chars dos_header#dossize
Const stublength=0x40
Chars stub#stublength

Chars *coffmagic="PE"
#IMAGE_FILE_HEADER
Chars *align={0}
Chars fileheader#4*wsz+dwsz+dwsz+dwsz

#IMAGE_OPTIONAL_HEADER
#Standard fields.
####set later
Chars Magic#2
####system linker i think
Chars *MajorLinkerVersion={1}
Chars *MinorLinkerVersion={0x45}
####hard (file pad)
Data SizeOfCode=0x1000
Data SizeOfInitializedData=0x2000
Data *SizeOfUninitializedData=0
####completed later
Data AddressOfEntryPoint#1
####virtual base code section
Data BaseOfCode=0x3000
####virtual base data section
Data *BaseOfData=0x1000
#NT additional fields.
Const pe_imagebase=0x00400000
Data *ImageBase=pe_imagebase
Data SectionAlignment=page_sectionalignment
Data FileAlignment=0x200
#Const VersionsSize=6*wsz
Chars *MajorOperatingSystemVersion={1,0}
Chars *MinorOperatingSystemVersion={0,0}
Chars *MajorImageVersion={0,0}
Chars *MinorImageVersion={0,0}
Chars *MajorSubsystemVersion={5,0}
Chars *MinorSubsystemVersion={1,0}
Data *Win32VersionValue=0
	#all virtuals(sec pad)
Data SizeOfImage=0x4000
	#hard (file align)
Data SizeOfHeaders#1
Data *CheckSum=0

#Const IMAGE_SUBSYSTEM_WINDOWS_GUI=2
Const IMAGE_SUBSYSTEM_WINDOWS_CUI=3
Chars *Subsystem={IMAGE_SUBSYSTEM_WINDOWS_CUI,0}
Chars DllCharacteristics#2
Data *SizeOfStackReserve=0x10000
Data *SizeOfStackCommit=0x1000
Data *SizeOfHeapReserve=0x10000
Data *SizeOfHeapCommit=0x1000
Data *LoaderFlags=0
Const IMAGE_NUMBEROF_DIRECTORY_ENTRIES=16
Data *NumberOfRvaAndSizes=IMAGE_NUMBEROF_DIRECTORY_ENTRIES
Const img_dir_entry=2
Const imgdirsInts=img_dir_entry*IMAGE_NUMBEROF_DIRECTORY_ENTRIES
Data directoryentries#imgdirsInts
#IMAGE_DATA_DIRECTORY
	#DWORD   VirtualAddress
    #DWORD   Size
#Const IMAGE_DIRECTORY_ENTRY_EXPORT=0
Const IMAGE_DIRECTORY_ENTRY_IMPORT=1
Const img_dir_entry_sz=img_dir_entry*dwsz
#Const im_d_entry_export_offset=IMAGE_DIRECTORY_ENTRY_EXPORT*img_dir_entry_sz
Const im_d_entry_import_offset=IMAGE_DIRECTORY_ENTRY_IMPORT*img_dir_entry_sz

#IMAGE_SECTION_HEADERs
Const IMAGE_SCN_CNT_INITIALIZED_DATA=0x00000040
Const IMAGE_SCN_MEM_READ=0x40000000
Const IMAGE_SCN_MEM_WRITE=0x80000000
Const IMAGE_SCN_CNT_CODE=0x00000020
Const IMAGE_SCN_MEM_EXECUTE=0x20000000

Chars *datasection=".data"
#IMAGE_SIZEOF_SHORT_NAME=8
Chars *alignmenttoEight_data_name={0,0}
Data dVirtualSize=0x1000
Const pe_data_offset=0x1000
Data *dVirtualAddress=pe_data_offset
Data dSizeOfRawData=0x1000
Data *dPointerToRawData=0x1000
#DWORD   PointerToRelocations;
#DWORD   PointerToLinenumbers;
#WORD    NumberOfRelocations;
#WORD    NumberOfLinenumbers;
Data *moreatdata={0,0,0}
Data *datasectionCharacteristics=IMAGE_SCN_CNT_INITIALIZED_DATA|IMAGE_SCN_MEM_READ|IMAGE_SCN_MEM_WRITE

Chars *codesection=".code"
Chars *alignmenttoEight_code_name={0,0}
Data cVirtualSize#1
Data cVirtualAddress#1
Data cSizeOfRawData#1
Data cPointerToRawData#1
Data *moreatcode={0,0,0}
Data *codesectionCharacteristics=IMAGE_SCN_CNT_CODE|IMAGE_SCN_MEM_EXECUTE|IMAGE_SCN_MEM_READ

Const sizefileheadercodedata=!

Const idatasectionstart=!

Chars *idatasection=".idata"
Chars *alignmenttoEight_idata_name={0}
Data *iVirtualSize=0x1000
Data iVirtualAddress#1
Data iSizeOfRawData=0x1000
Data iPointerToRawData#1
Data *moreatidata={0,0,0}
Data *idatasectionCharacteristics=IMAGE_SCN_CNT_INITIALIZED_DATA|IMAGE_SCN_MEM_READ

Const idatasectionend=!
