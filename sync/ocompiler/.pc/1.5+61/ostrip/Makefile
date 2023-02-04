
all: ostrip

OB = ostrip
OBJ = ${OB}.o
OBT = ${OB}.txt
FULLOBJ = ./${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o
FULLOBJLOG = ${FULLOBJS}.log
OCOMP=../src/o

%.o: ${FULLOBJS}
	${OCOMP} $< ${OFLAGS}

syms =-s
ATCCCOM = $(CC) ${syms} -o ${OB}
#ld build is failing, must do pie at bionic

ostrip: compile strip
	@echo
#without this echo will do a strange cc command

compile: ${OBJ}
	../ounused/ounused ${FULLOBJLOG}
	@echo
	${ATCCCOM} ${FULLOBJO}

#xenial do wrong access somehow, bionic and focal do extra code at text and need to extra code at realoffset for .text
strip:
	if [ "$(shell lsb_release -cs)" = "jammy" ]; then \
		${FULLOBJ} ${FULLOBJ} ${FULLOBJLOG} ${FULLOBJO}; \
		if [ "$$?" = "0" ]; then \
			python3 strip.py ${FULLOBJ} ${FULLOBJ}; \
		fi; \
	fi

install: ostrip
	install -D ostrip \
		$(DESTDIR)$(prefix)/bin/ostrip

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${FULLOBJLOG}
	-rm -f .data
	-rm -f .text
	-rm -f .rela.dyn

clean-link:
	-rm -f ostrip

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/ostrip

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
