
ifndef OCOMP
OCOMP=o
endif

ifndef linkerflags
linkerflags=-O1 -s
endif

OFLAGS = inplace_reloc 0

projname=soundrecorder
objname=${projname}.o
srcname=${projname}.s
logname=${srcname}.log
wprojname=${projname}.exe

all: compile link

compile: ${projname} ounused

ounused:
	ounused ${logname}

link:
	i686-w64-mingw32-ld ${linkerflags} ${objname} -o ${wprojname} -entry record \
		 -lmsvcrt -lkernel32 -lwinmm -luser32

%: %.s
	${OCOMP} $< ${OFLAGS}

clean:
	-rm -f ${logname}
	-rm -f ${objname}
	-rm -f ${wprojname}

distclean: clean

test:
	echo "Nothing"

.PHONY: all clean distclean test

