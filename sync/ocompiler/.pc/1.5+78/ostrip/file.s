
include "mem.s"

#Data sh64_name#1
#Data sh64_type#1
#Data sh64_flags#1;data *=0
#Data sh64_addr#1;data *=0
#Data sh64_offset#1;data *=0
#Data sh64_size#1;data *=0
#Data sh64_link#1
#Data sh64_info#1
#Data sh64_addralign#1;data *=0
#Data sh64_entsize#1;data *=0
const sh64_to_addr=4+4+:	   ;#flags :?on 32 is ok
const sh64_addr_to_offset=:
const sh64_addr_to_size=sh64_addr_to_offset+:

#data size
function get_file(sd name,sv p_file,sv secN,sv p_secN,sd pnrsec,sd psecond_sec,sd only_at_exec)
	setcall p_file# fopen(name,"rb")
	sd file;set file p_file#
	if file!=(NULL)
		#at frees will check next
		#set p_secN# (NULL)

		chars elf64_ehd_e_ident_sign={asciiDEL,asciiE,asciiL,asciiF}
#chars *elf64_ehd_e_ident_class={ELFCLASS64}
#chars *elf64_ehd_e_ident_data={ELFDATA2LSB}
#chars *elf64_ehd_e_ident_version={EV_CURRENT}
#chars *elf64_ehd_e_ident_osabi={ELFOSABI_NONE}
#chars *elf64_ehd_e_ident_abiversion={EI_ABIVERSION}
#chars *elf64_ehd_e_ident_pad={0,0,0,0,0,0,0}
#Chars *elf64_ehd_e_type={ET_REL,0}
		const after_sign_to_machine=1+1+1+1+1+7+2
		Chars elf64_ehd_e_machine={EM_X86_64,0}
#data *elf64_ehd_e_version=EV_CURRENT
#data *elf64_ehd_e_entry={0,0}
#data *elf64_ehd_e_phoff={0,0}
		const after_machine_to_shoff=4+8+8
#data elf64_ehd_e_shoff#1;data *=0
#data *elf64_ehd_e_flags=0
#chars *elf64_ehd_e_ehsize={64,0}
#chars *elf64_ehd_e_phentsize={0,0}
#chars *elf64_ehd_e_phnum={0,0}
		const after_shoff_to_shentsize=4+2+2+2
#chars *elf64_ehd_e_shentsize={64,0}
#chars elf64_ehd_e_shnum#2
#chars elf64_ehd_e_shstrndx#2
#chars *pad={0,0}
		sd sz=4
		sd sign;call read(file,#sign,sz)
		sd c;setcall c memcmp(#sign,#elf64_ehd_e_ident_sign,sz)
		if c==0
			call seekc(file,(after_sign_to_machine))
			sd wsz=2
			sd w;call read(file,#w,wsz)
			setcall c memcmp(#w,#elf64_ehd_e_machine,wsz)
			if c==0
				call seekc(file,(after_machine_to_shoff))
				sd offset;call read(file,#offset,:)
				call seekc(file,(after_shoff_to_shentsize))
				data shentsize=0
				data shnum=0
				data shstrndx=0
				call read(file,#shentsize,wsz)
				call read(file,#shnum,wsz)
				call read(file,#shstrndx,wsz)

				sd return_value
				sd size

				#end for iterations
				sd end;set end shnum;mult end shentsize;add end offset

				if psecond_sec!=(NULL)
					#get sec indexes from section names table
					setcall return_value shnames(file,offset,shentsize,shstrndx,secN,pnrsec,psecond_sec)
					#get data size
					#set return_value 0    #0 can go right now(it is blank section at our objects), but that can be stripped, favorizing
					call get_section_item(file,offset,end,#return_value,(sh64_addr_to_size),shentsize)
					call get_section_item(file,offset,end,psecond_sec,(sh64_addr_to_size),shentsize)
				else
				#exec
					#get sec indexes from section names table
					sd reladyn
					sd dynsym
					sd dynstr
					setcall return_value shnames(file,offset,shentsize,shstrndx,secN,pnrsec,(NULL),#reladyn)
					call get_section_item(file,offset,end,#return_value,0,shentsize)
					call write_symtab_offset(file,offset,end,shentsize,only_at_exec)
					if reladyn!=-1
						setcall frees.execreladynsize get_section_many(file,offset,end,shentsize,reladyn,#frees.execreladyn)
					endif
					if dynsym!=-1
						if dynstr!=-1
							setcall frees.execdynsymsize get_section_many(file,offset,end,shentsize,dynsym,#frees.execdynsym)
							setcall frees.execdynstrsize get_section_many(file,offset,end,shentsize,dynstr,#frees.execdynstr)
						endif
					endif
				endelse

				#get sections
				while secN#!=(NULL)
					#next at frees
					set p_secN# (NULL)  #this is extra only at first
					setcall size get_section_many(file,offset,end,shentsize,pnrsec#,p_secN)
					if p_secN#==(NULL)
						return return_value
					endif
					add secN :
					add pnrsec (datasize)
					add p_secN :
					set p_secN# size
					add p_secN :
				endwhile
				return return_value
			endif
			call erMessages("wrong machine",name)
		endif
		call erMessages("not an elf",name)
	endif
	call fError(name)
endfunction
function fError(ss name)
	call erMessages("fopen error for",name)
endfunction

function rError()
	#pin that readed=size*1
	call erMessage("fread error")
endfunction
function read(sd file,sd buf,sd size)
	sd readed;setcall readed fread(buf,1,size,file)
	if readed!=size
		call rError()
	endif
endfunction

function seekc(sd file,sd offset)
	call seek(file,offset,(SEEK_CUR))
endfunction
function seeks(sd file,sd offset)
	call seek(file,offset,(SEEK_SET))
endfunction
function seek(sd file,sd offset,sd whence)
	sd return;SetCall return fseek(file,offset,whence)
	#at lseek:
	#	beyond seekable device limit is not our concerne, error check at seekc can go if seeks was not
	#	at section headers offset, error can be demonstrated (bad offset)
	if return!=0
		call erMessage("fseek error")
	endif
endfunction

#datasec
function shnames(sd file,sd offset,sd shentsize,sd shstrndx,sv secN,sd pnrsec,sd psecond_sec,sd only_at_exec)  #nrsec is int
	mult shstrndx shentsize
	add offset shstrndx

	sd mem;sd end;setcall end get_section(file,offset,#mem)
	add end mem
	#old remark:   count strings? safer than say it is the number of sections

	while secN#!=(NULL)
		setcall pnrsec# shnames_find(mem,end,secN#)
		add secN :
		add pnrsec (datasize)
	endwhile

	sd datasec;setcall datasec shnames_find(mem,end,".data")
	if psecond_sec!=(NULL)
		setcall psecond_sec# shnames_find(mem,end,".text")
	else
		setcall only_at_exec# shnames_find(mem,end,".rela.dyn")
		incst only_at_exec
		setcall only_at_exec# shnames_find(mem,end,".dynsym")
		incst only_at_exec
		setcall only_at_exec# shnames_find(mem,end,".dynstr")
	endelse
	#else set datasec firstnrsec

	call free(mem)

	return datasec
endfunction

#sz
function get_section_many(sd file,sd offset,sd end,sd shentsize,sd nrsec,sv p_sec)
	call seeks(file,offset)
	sd rest=-datasize
	add rest shentsize
	while offset!=end
		#the sh64_name is first
		datax offs#1;call read(file,#offs,(datasize))
		if offs==nrsec
			sd sz;setcall sz get_section(file,offset,p_sec)
			return sz   #it's in use at rels,syms and can verify errors at data/text . and also at data/text
		endif
		call seekc(file,rest)
		add offset shentsize
	endwhile
endfunction

function get_section_loc(sd file,sd offset,sv prequired_value_offset)
	sd off=sh64_to_addr
	add off prequired_value_offset#
	add off offset
	call seeks(file,off)
	call read(file,prequired_value_offset,:)
endfunction
#fread
function get_section(sd file,sd offset,sv pmem)
	sd off=sh64_addr_to_offset
	call get_section_loc(file,offset,#off)
	sd size=sh64_addr_to_size
	call get_section_loc(file,offset,#size)
	call seeks(file,off)
	sd mem;setcall mem alloc(size)
	sd readed;setcall readed fread(mem,1,size,file)
	if readed==size
		set pmem# mem
		return size
	endif
	call free(mem)
	call rError()
endfunction
function get_section_item(sd file,sd offset,sd end,sv p_in_out,sd itemoff,sd shentsize)
	call seeks(file,offset)
	sd rest=-datasize
	add rest shentsize
	while offset!=end
		#the sh64_name is first
		datax offs#1;call read(file,#offs,(datasize))
		if offs==p_in_out#d^
			set p_in_out# itemoff
			call get_section_loc(file,offset,p_in_out)
			ret
		endif
		call seekc(file,rest)
		add offset shentsize
	endwhile
endfunction
