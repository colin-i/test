
platform = lin
OCOMP=o
OLINK=ounused
syms=-s
conv_64=0
OFLAGS=conv_64 ${conv_64}

ifeq (${platform},win)
	OFLAGS += inplace_reloc 0 include_sec 1
else
	OFLAGS += exit_end 1
	# underscore_pref 1   win32 with _, can go back to this later
endif

name=example
linkname=actionswf
linkfile=${linkname}.lib

all: build exe

build: ${name} uns lib lnk

uns:
	${OLINK} ${name}.s.log

lib:
	if [ "${platform}" = "win" ]; then \
		if [ "${conv_64}" = "1" ]; then \
			i686-w64-mingw32-dlltool --no-leading-underscore -d ../src/actionswf.def -l ${linkfile}; \
		else \
			x86_64-w64-mingw32-dlltool --no-leading-underscore -d ../src/actionswf.def -l ${linkfile}; \
		fi \
	fi

lnk:
	if [ "${platform}" = "lin" ]; then \
		if [ "${conv_64}" = "1" ]; then \
			$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${name}.o -entry example_main -o ${name} -lc -L../src -l:actionswf.so; \
		else \
			$(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 ${name}.o -entry example_main -o ${name} -lc -L../src -l:actionswf.so; \
		fi \
	else \
		if [ "${conv_64}" = "1" ]; then \
			i686-w64-mingw32-ld ${syms} ${name}.o -entry example_main -lmsvcrt -o ${name}.exe -L. -l${linkname}; \
		else \
			x86_64-w64-mingw32-ld ${syms} ${name}.o -entry example_main -lmsvcrt -o ${name}.exe -L. -l${linkname}; \
		fi \
	fi

exe:
	if [ "${platform}" = "lin" ]; then \
		export LD_LIBRARY_PATH=../src; ./example; \
	fi

%: %.s
	${OCOMP} $< ${OFLAGS}

clean:
	-rm -f ${name}.s.log
	-rm -f ${name}.o
	-rm -f ${name}
	-rm -f ${name}.exe
	-rm -f ${linkfile}

distclean: clean

install: test

uninstall: test

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test

.NOTPARALLEL:

#LD_LIBRARY_PATH=/home/bc/s/actionswf-1/src ./example
