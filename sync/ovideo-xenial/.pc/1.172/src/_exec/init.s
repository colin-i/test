
format elfobj

include "../_include/include.h" #files/olang.h
include "../_include/lin.h" "../_include/win.h"

const F_OK=0

importx "_strlen" strlen
importx "_access" access
importx "_mkdir" mkdir
importx "_getcwd" getcwd
importx "_free" free
importx "_open" open
importx "_write" write
importx "_close" close
importx "_sprintf" sprintf

import "capture_location" capture_location
import "sys_folder" sys_folder
import "chdr" chdr
import "move_to_home" move_to_home

#err
function init_user()
	sd err
	setcall err move_to_home()
	if err==(noerror)
		sd d
		setcall d capture_location()
		setcall err init_dir(d)
		if err==(noerror)
			setcall d sys_folder()
			setcall err init_dir(d)
			if err==(noerror)
				sd p
				setcall p getcwd((NULL),0)
				if p!=(NULL)
					vstr cerr="chdir error at init user"
					sd x
					setcall x chdr(d)
					if x==0
						setcall err init_user_sys()
						setcall x chdr(p)
						if x!=0
							set err cerr
						endif
					else
						set err cerr
					endelse
					call free(p)
				else
					set err "getcwd error at init user"
				endelse
			endif
		endif
	endif
	return err
endfunction
#e
function init_user_sys()
	const start=!
	chars a="capture"
	const biggest_string=7
	const d1=!
	chars *={0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00}
	const d11=!-d1
	chars *="jpeg"
	const d2=!
	chars *={0x20,0x03,0x00,0x00}
	const d22=!-d2
	chars *="mpeg"
	const d3=!
	chars *={0x03,0x00,0x00,0x00,0x03,0x00,0x00,0x00}
	const d33=!-d3
	chars *="search"
	const d4=!
	chars *={0x73,0x72,0x63,0x3d,0x22,0x00,0x22,0x00,0x00,0x00}
	const d44=!-d4
	chars *="sound"
	const d5=!
	chars *={0x02,0x00,0x00,0x00,0x80,0xbb,0x00,0x00,0x10,0x00,0x00,0x00}
	const d55=!-d5
	chars *="stage"
	const d6=!
	chars *={0x0a,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00}
	const d66=!-d6
	chars *="update"
	const d7=!
	chars *={0x01,0x00,0x00,0x00}
	const d77=!-d7
	sd b=!-start
	sd c^a
	add b c
	chars e={d11,d22,d33,d44,d55,d66,d77}
	ss f^e
	sd err=noerror
	while c!=b
		setcall c init_sys(c,f#,#err)
		if err!=(noerror)
			return err
		endif
		inc f
	endwhile
	return (noerror)
endfunction

function init_sys(sd c,sd sz,sd perr)
	sd len
	setcall len strlen(c)
	sd f
	set f c
	add c len
	inc c
	call init_sys_file(f,c,sz,perr)
	add c sz
	return c
endfunction

#er
function init_dir(sd f)
	sd is
	setcall is access(f,(F_OK))
	#this looks useless check but we want mkdir to return success, then, it is ok, ignoring mkdir by others between these calls
	if is==-1
		setcall is mkdir(f,(flag_dmode))
		if is!=0
			return "mkdir error"
		endif
	endif
	return (noerror)
endfunction

function init_sys_file(sd f,sd data,sd sz,sv perr)
	chars buf#biggest_string+1+4+1
	call sprintf(#buf,"%s.data",f)
	sd is
	setcall is access(#buf,(F_OK))
	if is==-1
		#open
		const O_WRONLY=0x0001
		sd fd
		setcall fd open(#buf,(O_WRONLY|flag_O_BINARY|flag_O_CREAT),(flag_fmode))
		#write
		sd len
		setcall len write(fd,data,sz)
		#close
		call close(fd)
		if len!=sz
			set perr# "write error at init user"
		endif
	endif
endfunction
