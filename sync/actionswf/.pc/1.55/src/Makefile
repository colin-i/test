
platform = lin

ifndef OCOMP
OCOMP=o
endif

OLINK=ounused
syms=-s
conv_64=0
#OFLAGSEXTRA=
#if modifying OFLAGS will lose inside data
OFLAGS=conv_64 ${conv_64} ${OFLAGSEXTRA}

#this is like ld is linking, reason: ostrip is not adapted for this, there is another solutin with ocompiler and NOBITS
#	maybe is a 0x1000 .o size rule only from libexte.a
items = actioncode actionparse actionutil bits character file storage util ${platform} actionpool
expitems = action swf tool ../shared/action_dllmain

exte=libexte.a

ifeq (${platform},win)
	OFLAGS += inplace_reloc 0 include_sec 1
else
	OFLAGS += underscore_pref 1
endif

debug=
debugstrip=
projname=actionswf${debug}
name = ${projname}.so
xname = lib${name}
defname = ${projname}.def
items_prefix=
prefname=${items_prefix}${name}
stripname=${debugstrip}${name}

$(eval obs = )
$(eval eobs = )
$(foreach var,$(expitems),$(eval eobs += ${items_prefix}${var}.o))
$(foreach var,$(items),$(eval obs += ${items_prefix}${var}.o))
$(eval logs = )
$(foreach var,$(expitems),$(eval logs += ${items_prefix}${var}.es.log))
$(foreach var,$(items),$(eval logs += ${items_prefix}${var}.s.log))

ATLDCOM = $(CC) ${syms} ${eobs} -shared -e DllMain -o ${name} -lc -L. -l:${exte} -Wl,--exclude-libs ${exte}

strippy=ostriputil

ifeq (${platform},win)
all: compile ounused link def
else ifeq (${conv_64},1)
all: compile ounused link
else
all: compile ${name}
${name}:
	${OLINK} ${logs}
	@echo
	$(AR) cr ${exte} ${obs}
	${ATLDCOM}
	$(eval strp = )
	$(foreach var,$(expitems),$(eval strp += ${items_prefix}${var}.es.log ${items_prefix}${var}.o))
	$(foreach var,$(items),$(eval strp += ${items_prefix}${var}.s.log ${items_prefix}${var}.o))
	ostrip ${name} ${strp}
	#if [ ! -e "./strip.py" ]; then wget https://raw.githubusercontent.com/colin-i/o/master/ostrip/strip.py; fi
	${strippy} ${name} ${stripname}
endif

%.o: %.s
	${OCOMP} $< ${OFLAGS}
%.o: %.es
	${OCOMP} $< ${OFLAGS}

ounused:
	${OLINK} ${logs}
	@echo

compile: ${obs} ${eobs}

link:
	if [ "${platform}" = "lin" ]; then \
		$(AR) cr ${exte} ${obs}; \
		if [ "${conv_64}" = "1" ]; then \
			$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${eobs} -shared -entry DllMain -o ${prefname} -lc -L${items_prefix}. -l:${exte} --exclude-libs ${exte}; \
		else \
			${ATLDCOM}; \
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

def:
	../fix/makedef ${defname}

clean:
	-printf ' %s.s.log' ${items} | xargs rm -f
	-printf ' %s.es.log' ${expitems} | xargs rm -f
	-printf ' %s.o' ${items} ${expitems} | xargs rm -f
	-rm -f ${exte}
	-rm -f ${stripname}
	-rm -f ${name}
	-rm -f ${projname}.dll
	-rm -f ${defname}
	-rm -f strip.py
	-rm -f .data
	-rm -f .text
	-rm -f .rela.dyn

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

#make debugstrip=lib strippy="python /home/bc/Desktop/ostriputil/ostriputil-1/ostriputil/main.py" OFLAGSEXTRA="function_name 1 nul_res_pref 1"
