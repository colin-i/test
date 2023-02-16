
platform = lin
OCOMP=o
syms=-s

ifeq (${platform},win)
	OFLAGS = inplace_reloc 0 include_sec 1
else
	OFLAGS = underscore_pref 1
endif

cap = _capture/capture
err = err/err
eve = event/event
e=_exec/
exe = ${e}capture/save ${e}help ${e}init ${e}mainhandles ${e}mediainfo ${e}mix ${e}ostream ${e}start ${e}uri ${e}uristream
f=file-folder/
ffl = ${f}file-base ${f}folder-base
gnu = gnu/gst
int = interface/buttons
m=media/
med = ${m}audiovideo ${m}mp4 ${m}mpeg-avc_data ${m}mpeg_code ${m}mpeg-mp3_bs ${m}mpeg-mp3_input ${m}mpeg-mp3_tables \
${m}jpeg_enc ${m}mpeg-avc_action ${m}mpeg-avc_encode ${m}mpeg_enc ${m}mpeg-mp3_data ${m}mpeg-mp3_iteration_code ${m}mpeg-mp3_wrap \
${m}jpeg ${m}mpeg-avc_block ${m}mpeg-avc_mb ${m}mpeg_init ${m}mpeg-mp3_encode ${m}mpeg-mp3_iteration ${m}mpeg_pred \
${m}mp4_data ${m}mpeg-avc_bs ${m}mpeg-avc_wrap ${m}mpeg_interframe ${m}mpeg-mp3_huffman ${m}mpeg-mp3_mdct ${m}mpeg
mem = mem/alloc mem/op
net = net/net-base
o=obj/
obj = ${o}containers ${o}images ${o}items ${o}tool
p=_prepare/
pe=${p}effect/
pf=${p}frame/
po=${p}output/
pre = ${pe}base ${pe}fade ${pe}move ${pe}reveal_diagonal ${pe}reveal ${pe}reveal_shape ${pe}scale_effect \
${pf}add ${pf}brightness ${pf}crop ${pf}frame ${pf}frametime ${pf}imagetools ${pf}overlay ${pf}pencil ${pf}remove ${pf}rotate ${pf}scale ${pf}screenshot \
${po}all ${po}avi ${po}mkv ${po}sound ${po}stagefileoptions \
${p}paint ${p}pipe ${p}prevw ${p}sel ${p}stagempeg ${p}view
s=_search/
sea = ${s}dialog_fns ${s}dialog ${s}parse ${s}previews
str = str/str
u=util/
uti = ${u}asm ${u}floating ${u}lists ${u}numbers ${u}update ${u}util
items = _dif/dif~${platform} ${cap} ${err} ${eve} ${exe} ${ffl} ${gnu} ${int} ${med} ${mem} ${net} ${obj} ${pre} ${sea} ${str} ${uti}
items_prefix=

projname=ovideo
wprojname=ovideo.exe
lshare=_dif/share.txt
logs :=
obs :=
sharefolderpackage=$(prefix)/share/ovideo
sharefolder=$(DESTDIR)${sharefolderpackage}

all: compile lnk

compile: share ${items} ounused

ounused:
	ounused ${logs}

share:
	if [ "${platform}" = "lin" ]; then \
		echo return \"${sharefolderpackage}\" > ${lshare}; \
	fi

#at jammy
#libgtk2.0-dev:i386	libgtk2.0-0:i386
#libjpeg8-dev:i386 is already	libjpeg8:i386 is already
#libgstreamer1.0-dev:i386	libgstreamer1.0-0:i386 is already
#	gst_implements_interface_cast	video_realize
#	gst_buffer_set_caps	stage_file_need_fn
#libgstreamer-plugins-base1.0-dev:i386	libgstreamer-plugins-base1.0-0:i386 is already
#	gst_app_buffer_new	stage_file_need_fn
#no apt-file search libgstinterfaces 0.10 in xenial
#	gst_x_overlay_get_type	video_realize
#	gst_x_overlay_set_window_handle	video_realize
#libsoup2.4-1:i386 is already
#libasound2-dev:i386	libasound2:i386 is already

#at xenial
#dev gtk libgstreamer-plugins-base0.10-dev  soup jpeg asound
#gtk gstreamer0.10-plugins-good
#for mxf, gstreamer0.10-plugins-bad was deleted at ubuntu

#		export PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig/:${PKG_CONFIG_PATH}; \
#		$(LD) ${syms} -melf_i386 --dynamic-linker=/lib/ld-linux.so.2 ${obs} -o ${projname} -lc -lm `pkg-config --libs gtk+-2.0 gstreamer-pbutils-1.0 gstreamer-app-1.0` -ljpeg -lsoup-2.4 -lasound -lgthread-2.0; \
#cc because -pthread not for ld
#nostdlib because is complaining about main
lnk:
	if [ "${platform}" = "lin" ]; then \
		$(CC) -nostdlib ${syms} ${obs} -o ${items_prefix}${projname} `pkg-config --libs gtk+-2.0 gstreamer-pbutils-0.10 gstreamer-interfaces-0.10 gstreamer-app-0.10` -lsoup-2.4 -ljpeg -lasound -lm -lpthread -lc; \
	else \
		i686-w64-mingw32-ld --large-address-aware ${syms} ${obs} -o ${wprojname} -entry _start --start-group \
		`dpkg -L mingw-w64-i686-dev | grep '\.a' | sed 's/..$$//' | grep -o '[^\/]*$$' | sed 's/^lib/-l/' | xargs echo` \
		--end-group -L`echo ~`/.wine/drive_c/gstreamer-sdk/0.10/x86/lib/ \
		-lgtk-win32-2.0 -lgdk-win32-2.0 -lgdk_pixbuf-2.0 -lglib-2.0 -lgobject-2.0 -lgio-2.0 -lgthread-2.0 \
		-lgstreamer-0.10 -lgstapp-0.10 -lgstinterfaces-0.10 -lgstpbutils-0.10 \
		-lcairo -lpango-1.0 -lsoup-2.4 -ljpeg; \
	fi
fast:
	$(eval obs = `printf ' ${items_prefix}%s.o' ${items}`)
link: fast lnk
#snprintf with circular unresolved requirements
#cos is in -lmingwex that will work with -lmingw32 -lmsvcrt
#on win msvcr100 is old and at here is from old java-i586

%: %.s
	${OCOMP} $< ${OFLAGS}
	$(eval logs += $@.s.log)
	$(eval obs += $@.o)

clean:
	-printf ' %s.s.log' ${items} | xargs rm -f
	-printf ' %s.o' ${items} | xargs rm -f
	-rm -f ${projname}
	-rm -f ${lshare}
	-rm -f ${wprojname}

distclean: clean

test:
	echo "Nothing"

install-proc:
	install -D ${projname} \
		$(DESTDIR)$(prefix)/bin/${projname}
	cd ../build; \
	find ./img -type f -exec install -Dm 664 {} ${sharefolder}/{} \;
	install -d ${sharefolder}/html
	cd ../html; \
	install -Dm 664 html/use.html ${sharefolder}/html/
	cd ..; \
	install -m 664 ./version.txt ${sharefolder}/

install: all install-proc

uninstall:
	-rm -f $(DESTDIR)$(prefix)/bin/${projname}
	-rm -r ${sharefolder}

.PHONY: all install clean distclean uninstall test

.NOTPARALLEL:

#make compile && make link syms= LD=/home/bc/Desktop/out/LD-.glibc2.27-x86_64.AppImage items_prefix=/home/bc/v/ovideo-1/src/
