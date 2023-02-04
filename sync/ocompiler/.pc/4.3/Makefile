all: o

OB = obj
OBJ = $(OB).o
FULLOBJ = ./src/linux/$(OB)
FULLOBJS = $(FULLOBJ).s
FULLOBJO = $(FULLOBJ).o
OBT = $(OB).txt

%.o: ${FULLOBJS}
	if [ -s $(OBT) ];then base64 -d $(OBT) > $@;else o $<;fi

syms =-s
ATLDCOM = $(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc
#gcc -Wl,-melf_i386 -nostdlib "./src/linux/obj.o" -o "./buildg/o" -lc

o: $(OBJ)
	if [ -f ${OBJ} ];then $(ATLDCOM) $^;else $(ATLDCOM) ${FULLOBJO};fi

install: o
	install -D o \
		$(DESTDIR)$(prefix)/bin/o

clean-compile:
	-rm -f $(FULLOBJO)
	-rm -f $(OBJ)

clean-link:
	-rm -f o

clean: clean-compile clean-link
distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/o

test:
	echo "Nothing"

.PHONY: all install clean distclean uninstall test
