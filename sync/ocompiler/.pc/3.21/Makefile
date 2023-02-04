all: o

OB = obj
OBJ = $(OB).o
FULLOBJ = ./src/linux/$(OB)
FULLOBJS = $(FULLOBJ).s
FULLOBJO = $(FULLOBJ).o

%.o: %.txt
	-if [ -s $< ];then base64 -d $< > $@;else o ${FULLOBJS};fi

ATLDCOM = $(LD) -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ -lc

o: $(OBJ)
	if [ -f ${OBJ} ];then $(ATLDCOM) ${OBJ};else $(ATLDCOM) ${FULLOBJO};fi

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

.PHONY: all install clean distclean uninstall
