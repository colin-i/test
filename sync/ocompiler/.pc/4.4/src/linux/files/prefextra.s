
const variable_convention=lin_convention

#err
function prefextra(ss prefpath,sd ptrpreferencessize,sd ptrpreferencescontent)
	sd err
	setcall err prefextra_helper(prefpath,ptrpreferencessize,ptrpreferencescontent)
	if err!=(noerror)
		Call safeMessage(err)
	endif
	return err
endfunction
#err
function prefextra_helper(ss prefpath,sd ptrpreferencessize,sd ptrpreferencescontent)
	ss homestr="HOME"
	ss envhome
	sd err
	setcall envhome getenv(homestr)
	if envhome!=(NULL)
		sd s1;sd s2;sd s3=2
		setcall s1 strlen(envhome);setcall s2 strlen(prefpath);add s3 s1;add s3 s2
		sd mem
		setcall err memoryalloc(s3,#mem)
		if err==(noerror)
			call memtomem(mem,envhome,s1)
			ss p;set p mem;add p s1;set p# (asciislash);inc p
			call memtomem(p,prefpath,s2);add p s2;set p# (NULL)
			sd a;setcall a access(mem,(F_OK))
			if a==0
				SetCall err file_get_content_ofs(mem,ptrpreferencessize,ptrpreferencescontent,(NULL))
				call free(mem)
				return err
			endif
			str er="No preferences file found in HOME. The file is here: https://raw.githubusercontent.com/colin-i/o/master/.ocompiler.txt"
			return er
		endif
		return err
	endif
	str enverr="Getenv error on HOME."
	return enverr
endfunction
