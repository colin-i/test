all: ounused

OB = ounused
OBJ = ${OB}.o
FULLOBJ = ./${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o
FULLOBJLOG = ${FULLOBJS}.log

%.o: ${FULLOBJS}
	../src/o $< exit_end 1

syms =-s
ATLDCOM = $(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc -entry main

ounused: ${OBJ}
	${ATLDCOM} ${FULLOBJO}
	./${OB} ${FULLOBJLOG}
	@echo

install: ounused
	install -D ounused \
		$(DESTDIR)$(prefix)/bin/ounused

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${FULLOBJLOG}

clean-link:
	-rm -f ounused

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/ounused

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
