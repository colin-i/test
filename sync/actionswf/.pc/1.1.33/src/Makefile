
platform = lin

items = ${platform} actioncode actionparse actionpool actionutil bits character file storage util
expitems = action swf tool ../shared/action_dllmain

exte=libexte.a

OFLAGS = conv_64 1
syms =-s

name = actionswf.so

all: ${items} ${expitems}
	ounused ${logs}
	$(AR) cr ${exte} ${obs}
	$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${eobs} -shared -entry DllMain -o ${name} -lc -L. -l:libexte.a --exclude-libs ${exte}
	#$(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 ${eobs} -shared -entry DllMain -o ${name} -lc -L. -l:libexte.a --exclude-libs ${exte}

logs :=
obs :=
eobs :=

%: %.s
	o $< ${OFLAGS}
	$(eval logs += $@.s.log)
	$(eval obs += $@.o)
%: %.es
	o $< ${OFLAGS}
	$(eval logs += $@.es.log)
	$(eval eobs += $@.o)

clean:
	-printf ' %s.s.log' ${items} | xargs rm -f
	-printf ' %s.es.log' ${expitems} | xargs rm -f
	-printf ' %s.o' ${items} ${expitems} | xargs rm -f
	-rm -f ${exte}
	-rm -f ${name}

distclean: clean

test:
	echo "Nothing"

install-lib:
	install -D ${name} \
		$(DESTDIR)$(prefix)/lib/${name}

install: all install-lib

uninstall:
	-rm -f $(DESTDIR)$(prefix)/lib/${name}

.PHONY: all install clean distclean uninstall test
