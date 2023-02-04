
platform = lin

items = ${platform} actioncode actionparse actionpool actionutil bits character file storage util
expitems = action swf tool ../shared/action_dllmain

exte=libexte.a

OCOMP=o
OFLAGS = conv_64 1
ifeq (${platform},win)
	OFLAGS += inplace_reloc 0 include_sec 1
else
	OFLAGS += underscore_pref 1
endif

syms =-s

projname=actionswf
name = ${projname}.so

all: ${items} ${expitems} ounused lnk

ounused:
	ounused ${logs}

lnk:
	if [ "${platform}" = "lin" ]; then \
		$(AR) cr ${exte} ${obs} && \
		$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${eobs} -shared -entry DllMain -o ${name} -lc -L. -l:${exte} --exclude-libs ${exte}; \
	else \
		i686-w64-mingw32-ld --no-leading-underscore ${syms} ${eobs} ${obs} -shared -entry=DllMain -lmsvcrt -o ${projname}.dll --exclude-modules-for-implib `printf ',%s' ${obs} | cut -c2-`; \
	fi
#noleadingunderscore for exporting symbols
#$(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 ${eobs} -shared -entry DllMain -o ${name} -lc -L. -l:libexte.a --exclude-libs ${exte}

logs :=
obs :=
eobs :=

%: %.s
	${OCOMP} $< ${OFLAGS}
	$(eval logs += $@.s.log)
	$(eval obs += $@.o)
%: %.es
	${OCOMP} $< ${OFLAGS}
	$(eval logs += $@.es.log)
	$(eval eobs += $@.o)

clean:
	-printf ' %s.s.log' ${items} | xargs rm -f
	-printf ' %s.es.log' ${expitems} | xargs rm -f
	-printf ' %s.o' ${items} ${expitems} | xargs rm -f
	-rm -f ${exte}
	-rm -f ${name}
	-rm -f ${projname}.dll

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

.NOTPARALLEL:
