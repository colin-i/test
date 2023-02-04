all: ostrip

OB = ostrip
OBJ = ${OB}.o
FULLOBJ = ./${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o
FULLOBJLOG = ${FULLOBJS}.log

%.o: ${FULLOBJS}
	../src/o $< exit_end 1 ${OFLAGS}

syms =-s
ATLDCOM = $(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 -o $@ -lc -entry main

ostrip: ${OBJ}
	../ounused/ounused ${FULLOBJLOG}
	@echo
	${ATLDCOM} ${FULLOBJO}

install: ostrip
	install -D ostrip \
		$(DESTDIR)$(prefix)/bin/ostrip

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${FULLOBJLOG}

clean-link:
	-rm -f ostrip

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/ostrip

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
