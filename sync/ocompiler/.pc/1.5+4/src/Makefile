all: o

OB = obj
OBJ = ${OB}.o
FULLOBJ = ./linux/${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o
OBT = ${OB}.txt

OFLAGS=

%.o: ${FULLOBJS}
	if [ -s ${OBT} ];then base64 -d ${OBT} > $@;else o $< ${OFLAGS};fi

syms =-s
ATLDCOM = $(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc -entry main

o: ${OBJ}
	if [ -f ${OBJ} ];then ${ATLDCOM} $^;else ${ATLDCOM} ${FULLOBJO};fi

install: o
	install -D o \
		$(DESTDIR)$(prefix)/bin/o

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${OBJ}
	-rm -f ${FULLOBJS}.log

clean-link:
	-rm -f o

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/o

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
