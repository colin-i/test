
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
	if [ ! -s ${OBT} ];then ${OCOMP} $< exit_end 1 ${OFLAGS};fi

syms =-s
ATLDCOM = $(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 -o $@ -lc -entry main

ostrip: ${OBJ}
	if [ -s ${OBT} ];then base64 -d ${OBT} > $@; chmod a+x $@; \
		else \
			../ounused/ounused ${FULLOBJLOG}; \
			echo; \
			${ATLDCOM} ${FULLOBJO}; \
			./${OB} ${OB} ${FULLOBJLOG} ${FULLOBJO}; \
			pip3 install lief; \
			python3 strip.py ./${OB} ./${OB}; \
		fi

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
