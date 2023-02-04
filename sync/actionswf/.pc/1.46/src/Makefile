
platform = lin
OCOMP=o
OLINK=ounused
syms=-s
conv_64=0
#OFLAGSEXTRA=
#if modifying OFLAGS will lose inside data
OFLAGS=conv_64 ${conv_64} ${OFLAGSEXTRA}

items = ${platform} actioncode actionparse actionpool actionutil bits character file storage util
expitems = action swf tool ../shared/action_dllmain

exte=libexte.a

ifeq (${platform},win)
	OFLAGS += inplace_reloc 0 include_sec 1
else
	OFLAGS += underscore_pref 1
endif

projname=actionswf
name = ${projname}.so
xname = lib${name}
defname = ${projname}.def
items_prefix=
prefname=${items_prefix}${name}

logs :=
obs :=
eobs :=

all: compile lnk def

ounused:
	${OLINK} ${logs}

compile: ${items} ${expitems} ounused

lnk:
	if [ "${platform}" = "lin" ]; then \
		$(AR) cr ${exte} ${obs}; \
		if [ "${conv_64}" = "1" ]; then \
			$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${eobs} -shared -entry DllMain -o ${prefname} -lc -L${items_prefix}. -l:${exte} --exclude-libs ${exte}; \
		else \
			$(LD) ${syms} --dynamic-linker=/lib64/ld-linux-x86-64.so.2 ${eobs} -shared -entry DllMain -o ${name} -lc -L. -l:${exte} --exclude-libs ${exte}; \
		fi \
	else \
		if [ "${conv_64}" = "1" ]; then \
			i686-w64-mingw32-ld --no-leading-underscore ${syms} ${eobs} ${obs} -shared -entry=DllMain -lmsvcrt -o ${projname}.dll --exclude-modules-for-implib `printf ',%s' ${obs} | cut -c2-`; \
		else \
			x86_64-w64-mingw32-ld --no-leading-underscore ${syms} ${eobs} ${obs} -shared -entry=DllMain -lmsvcrt -o ${projname}.dll --exclude-modules-for-implib `printf ',%s' ${obs} | cut -c2-`; \
		fi \
	fi
#noleadingunderscore for exporting symbols

#obs =   :in case it is called after an object (make bits link)
#(make action link)
fast:
	$(eval obs = )
	$(eval eobs = )
	$(foreach var,$(items),$(eval obs += ${items_prefix}${var}.o))
	$(foreach var,$(expitems),$(eval eobs += ${items_prefix}${var}.o))

link: fast lnk

def:
	if [ "${platform}" = "win" ]; then \
		../fix/makedef ${defname}; \
	fi

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
	-rm -f ${defname}

distclean: clean

test:
	echo "Nothing"

install-lib:
	install -D ${name} \
		$(DESTDIR)$(prefix)/lib/${xname}

install: all install-lib

uninstall:
	-rm -f $(DESTDIR)$(prefix)/lib/${xname}

.PHONY: all install clean distclean uninstall test

.NOTPARALLEL:

#make compile && make link syms= items_prefix=/home/bc/s/actionswf-1/src/ LD=/home/bc/Desktop/out/LD-.glibc2.27-x86_64.AppImage
#make syms= conv_64=0
#make syms= conv_64=0 link
