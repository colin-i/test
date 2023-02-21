
all: o

OB = obj
OBJ = ${OB}.o
FULLOBJ = ./linux/${OB}
FULLOBJS = ${FULLOBJ}.s
FULLOBJO = ${FULLOBJ}.o
OBT = ${OB}.txt

ifndef OCOMP
OCOMP=o
endif

#OFLAGS=

%.o: ${FULLOBJS}
	if [ -s ${OBT} ];then base64 -d ${OBT} > $@;else ${OCOMP} $< ${OFLAGS};mv ${FULLOBJO} .;fi

syms =-s
ATLDCOM = $(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc -entry main

o: ${OBJ}
	${ATLDCOM} $^

install: all
	install -D o \
		$(DESTDIR)$(prefix)/bin/o

clean-compile:
	-rm -f ${OBJ}
	-rm -f ${FULLOBJS}.log

clean-link:
	-rm -f o

clean-test:
	-rm -f ./linux/o
	-rm -f ./linux/o.s.log
	-rm -f ./linux/z

clean: clean-compile clean-link clean-test
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/o

test:
	echo "test"
	cd linux; ../o o.s nul_res_pref 1; mv o z; /lib/ld-linux.so.2 ./z o.s nul_res_pref 1; diff o z

.PHONY: all install clean distclean uninstall test
