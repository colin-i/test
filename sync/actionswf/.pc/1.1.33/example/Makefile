
OFLAGS = conv_64 1
syms=-s

name=example

all: ${name} uns lnk exe

uns:
	ounused ${name}.s.log

lnk:
	$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${name}.o -entry example_main -o ${name} -lc -L../src -l:actionswf.so
	#$(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 ${name}.o -entry example_main -o ${name} -lc -L../src -l:actionswf.so

exe:
	export LD_LIBRARY_PATH=../src; ./example

%: %.s
	o $< ${OFLAGS}

clean:
	-rm -f ${name}.s.log
	-rm -f ${name}.o
	-rm -f ${name}

.PHONY: all clean
# install distclean uninstall test
