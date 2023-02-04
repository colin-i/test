
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
ATCCCOM = $(CC) ${syms} -o $@

ostrip: ${OBJ}
	../ounused/ounused ${FULLOBJLOG}
	@echo
	${ATCCCOM} ${FULLOBJO}
	#- because it is not ready for a PIE
	-./${OB} ${OB} ${FULLOBJLOG} ${FULLOBJO}
	-python3 strip.py ./${OB} ./${OB}

install: ostrip
	install -D ostrip \
		$(DESTDIR)$(prefix)/bin/ostrip

clean-compile:
	-rm -f ${FULLOBJO}
	-rm -f ${FULLOBJLOG}
	-rm -f .text
	-rm -f .data

clean-link:
	-rm -f ostrip

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/ostrip

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
