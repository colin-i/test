all: ounused

OB = ounused
OBJ = ${OB}.o
FULLOBJ = ./${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o

%.o: ${FULLOBJS}
	../src/o $<

syms =-s
ATLDCOM = $(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc -entry main

ounused: ${OBJ}
	${ATLDCOM} ${FULLOBJO}

install: ounused
	install -D ounused \
		$(DESTDIR)$(prefix)/bin/ounused

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${FULLOBJS}.log

clean-link:
	-rm -f ounused

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/ounused

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
