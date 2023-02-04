#prefix = /usr

#DEFS =  -DPLATFORM64=1\
#        -DHAVE_ERRNO_H=1

all: o
#compiler

OBJ = obj.o

%.o: %.txt
	base64 -d $< > $@

o: $(OBJ)
	$(LD) -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 -o $@ $^ -lc
# $(CPPFLAGS) $(CFLAGS) $(LDFLAGS)

install: o
	install -D o \
		$(DESTDIR)$(prefix)/bin/o

clean:
	-rm -f o

distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/o

.PHONY: all install clean distclean uninstall
