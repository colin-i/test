

#sectionalignment
Const elf_startofdata=0x400
Data elf_startofdata=elf_startofdata
Const elf_imagebase=0x8048000


const ELFMAG0=0x7f
const ELFMAG1=asciiE
const ELFMAG2=asciiL
const ELFMAG3=asciiF

const ELFCLASS32=1
const ELFCLASS64=2
const EM_386=3
const EM_X86_64=62
const ET_REL=1

chars elf32_ehd_e_ident_sign={ELFMAG0,ELFMAG1,ELFMAG2,ELFMAG3}

#32-bit objects
chars *elf32_ehd_e_ident_class={ELFCLASS32}

#2's complement, little endian
const ELFDATA2LSB=1
chars *elf32_ehd_e_ident_data={ELFDATA2LSB}

#Current version
const EV_CURRENT=1
chars *elf32_ehd_e_ident_version={EV_CURRENT}

#EI_OSABI
const ELFOSABI_NONE=0
chars *elf32_ehd_e_ident_osabi={ELFOSABI_NONE}

#If no values are specified for the EI_OSABI field by the processor supplement or no version values are specified for the ABI determined by a particular value of the EI_OSABI byte, the value 0 shall be used for the EI_ABIVERSION byte; it indicates unspecified.
const EI_ABIVERSION=0
chars *elf32_ehd_e_ident_abiversion={EI_ABIVERSION}

#pad to 0x10
chars *elf32_ehd_e_ident_pad={0,0,0,0,0,0,0}


#Object file type
Chars elf32_ehd_e_type#2
#Architecture,Intel 80386
Chars *elf32_ehd_e_machine={EM_386,0}

data *elf32_ehd_e_version=EV_CURRENT
#entry point
data elf32_ehd_e_entry#1
#Start of program headers
data elf32_ehd_e_phoff#1
#Start of section headers
data elf32_ehd_e_shoff#1
data *elf32_ehd_e_flags=0
#Size of this header
chars *elf32_ehd_e_ehsize={52,0}
#Program header table entry size
Const elf32_ehd_e_phentsize=32
chars *elf32_ehd_e_phentsize={elf32_ehd_e_phentsize,0}
#Program header table entry count
chars elf32_ehd_e_phnum#2
#Section header table entry size
Const elf32_ehd_e_shentsize=40
chars *elf32_ehd_e_shentsize={elf32_ehd_e_shentsize,0}
#Section header table entry count
chars elf32_ehd_e_shnum#2
#Section header string table index
chars elf32_ehd_e_shstrndx#2


Const elf_fileheaders_start^elf32_ehd_e_ident_sign
Const elf_fileheaders_lastdata^elf32_ehd_e_shstrndx
Const elf_fileheaders_end=elf_fileheaders_lastdata+wsz
Data elf_fileheaders%elf_fileheaders_start
Data elf_fileheaders_size=elf_fileheaders_end-elf_fileheaders_start

Data ptrelf32_ehd_e_type^elf32_ehd_e_type
data ptrelf32_ehd_e_shoff^elf32_ehd_e_shoff
data ptrelf32_ehd_e_phnum^elf32_ehd_e_phnum
data ptrelf32_ehd_e_shnum^elf32_ehd_e_shnum
data ptrelf32_ehd_e_shstrndx^elf32_ehd_e_shstrndx


#64 bit objects
Const elf64_fileheaders_start=!
chars elf64_ehd_e_ident_sign={ELFMAG0,ELFMAG1,ELFMAG2,ELFMAG3}
chars *elf64_ehd_e_ident_class={ELFCLASS64}
chars *elf64_ehd_e_ident_data={ELFDATA2LSB}
chars *elf64_ehd_e_ident_version={EV_CURRENT}
chars *elf64_ehd_e_ident_osabi={ELFOSABI_NONE}
chars *elf64_ehd_e_ident_abiversion={EI_ABIVERSION}
chars *elf64_ehd_e_ident_pad={0,0,0,0,0,0,0}
Chars *elf64_ehd_e_type={ET_REL,0}
Chars *elf64_ehd_e_machine={EM_X86_64,0}
data *elf64_ehd_e_version=EV_CURRENT
data *elf64_ehd_e_entry={0,0}
data *elf64_ehd_e_phoff={0,0}
data elf64_ehd_e_shoff#1;data *=0
data *elf64_ehd_e_flags=0
chars *elf64_ehd_e_ehsize={64,0}
chars *elf64_ehd_e_phentsize={0,0}
chars *elf64_ehd_e_phnum={0,0}
chars *elf64_ehd_e_shentsize={64,0}
chars elf64_ehd_e_shnum#2
chars elf64_ehd_e_shstrndx#2
chars *pad={0,0}
Const elf64_fileheaders_size=!-elf64_fileheaders_start


#program headers

const PF_X=1
const PF_W=2
const PF_R=4
const PT_LOAD=1

#Program data section
const elf_data_voff=elf_imagebase+elf_startofdata
data elf32_phdr_p_type_data=PT_LOAD
#Segment file offset
data elf32_phdr_p_offset_data=elf_startofdata
#Segment virtual address
data elf32_phdr_p_vaddr_data=elf_data_voff
#Segment physical address
data *elf32_phdr_p_paddr_data=elf_data_voff
#Segment size in file
data elf32_phdr_p_filesz_data#1
#Segment size in memory
data elf32_phdr_p_memsz_data#1
#Segment flags
data *elf32_phdr_p_flags_data=PF_R|PF_W
#Segment align
data *elf32_phdr_p_align_data=page_sectionalignment

#Code section
data *elf32_phdr_p_type_code=PT_LOAD
#Segment file offset
data elf32_phdr_p_offset_code#1
#Segment virtual address
data elf32_phdr_p_vaddr_code#1
#Segment physical address
data elf32_phdr_p_paddr_code#1
#Segment size in file
data elf32_phdr_p_filesz_code#1
#Segment size in memory
data elf32_phdr_p_memsz_code#1
#Segment flags
data *elf32_phdr_p_flags_code=PF_X|PF_R
#Segment align
data elf32_phdr_p_align_code=page_sectionalignment

Const elf_progdeffileheaders_start^elf32_phdr_p_type_data
Const elf_progdeffileheaders_lastdata^elf32_phdr_p_align_code
Const elf_progdeffileheaders_end=elf_progdeffileheaders_lastdata+dwsz
Data elf_progdeffileheaders%elf_progdeffileheaders_start
Data elf_progdeffileheaders_size=elf_progdeffileheaders_end-elf_progdeffileheaders_start

#Imports
const PT_DYNAMIC=2
const PT_INTERP=3

#Interpreter section
data elf32_phdr_p_type_interp=PT_INTERP
#Segment file offset
data elf32_phdr_p_offset_interp#1
#Segment virtual address
data elf32_phdr_p_vaddr_interp#1
#Segment physical address
data elf32_phdr_p_paddr_interp#1
#Segment size in file
data elf32_phdr_p_filesz_interp#1
#Segment size in memory
data elf32_phdr_p_memsz_interp#1
#Segment flags
data *elf32_phdr_p_flags_interp=PF_R
#Segment align
data *elf32_phdr_p_align_interp=0x1

#Dynamic section
data *elf32_phdr_p_type_dyn=PT_DYNAMIC
#Segment file offset
data elf32_phdr_p_offset_dyn#1
#Segment virtual address
data elf32_phdr_p_vaddr_dyn#1
#Segment physical address
data elf32_phdr_p_paddr_dyn#1
#Segment size in file
data elf32_phdr_p_filesz_dyn#1
#Segment size in memory
data elf32_phdr_p_memsz_dyn#1
#Segment flags
data *elf32_phdr_p_flags_dyn=PF_R
#Segment align
data elf32_phdr_p_align_dyn=0x1

#Library section
data *elf32_phdr_p_type_lib=PT_LOAD
#Segment file offset
data elf32_phdr_p_offset_lib#1
#Segment virtual address
data elf32_phdr_p_vaddr_lib#1
#Segment physical address
data elf32_phdr_p_paddr_lib#1
#Segment size in file
data elf32_phdr_p_filesz_lib#1
#Segment size in memory
data elf32_phdr_p_memsz_lib#1
#Segment flags
data *elf32_phdr_p_flags_lib=PF_R|PF_W
#Segment align
data elf32_phdr_p_align_lib=page_sectionalignment

Const elf_importfileheaders^elf32_phdr_p_type_interp
Const elf_importfileheaders_lastdata^elf32_phdr_p_align_lib
Const elf_importfileheaders_end=elf_importfileheaders_lastdata+dwsz

Data elf_importfileheaders%elf_importfileheaders
Data elf_importfileheaders_size=elf_importfileheaders_end-elf_importfileheaders

Chars interpreter="/lib/ld-linux.so.2"
Str ptrinterpreter^interpreter
Data interpretersize#1

Data DT_HASH=0x4
Data elf32_dyn_d_ptr_hash#1
Data *DT_SYMTAB=6
Data elf32_dyn_d_ptr_symtab#1
Data *DT_SYMENT=11
Const elf32_dyn_d_val_syment=16
Data elf32_dyn_d_val_syment=elf32_dyn_d_val_syment
Data *DT_STRTAB=5
Data elf32_dyn_d_ptr_strtab#1
Data *DT_STRSZ=10
Data elf32_dyn_d_val_strsz#1
Data *DT_RELA=7
Data elf32_dyn_d_ptr_rel#1
Data *DT_RELASZ=8
Data elf32_dyn_d_val_relsz#1
Data *DT_RELAENT=9
Const elf32_dyn_d_val_relent=12
Data elf32_dyn_d_val_relent=elf32_dyn_d_val_relent
Data *DT_NULL=0
Data elf32_dyn_d_val_null=0

Const elf_dynfix_start^DT_HASH
Const elf_dynfix_lastdata^elf32_dyn_d_val_null
Const elf_dynfix_end=elf_dynfix_lastdata+dwsz
Data elf_dynfix_size=elf_dynfix_end-elf_dynfix_start

Data sizeofbucket=1
Data sizeofchain#1
Data fakebucket=0

Const elf_hash_start^sizeofbucket
Const elf_hash_lastdata^fakebucket
Const elf_hash_end=elf_hash_lastdata+dwsz
Data elf_hash_minsize=elf_hash_end-elf_hash_start


Data sizeofElf32_Dyn=2*dwsz

## import command linked
Data hash_var_size#1
Data rel_var_size#1
Data elf_rel_entries_size#1
##


const SHT_STRTAB=3

Const elf64_dyn_d_val_syment=0x18
Const elf64_dyn_d_val_relent=0x18
