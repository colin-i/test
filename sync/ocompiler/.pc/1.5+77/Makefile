TOPTARGETS := all install clean distclean uninstall test

ifeq ($(shell dpkg-architecture -qDEB_HOST_ARCH), amd64)
SUBDIRS := src ounused ostrip
else
SUBDIRS := src ounused
endif

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
.PHONY: $(TOPTARGETS) $(SUBDIRS)


all:
	#if ! [ -s ./src/obj.txt ];then
	cd ./src; ../ounused/ounused ./linux/obj.s.log
	#; fi
	@echo
	#in case i386, or make two .install files and tell debuild to select architecture
	if ! [ -e ./ostrip/ostrip ];then echo "#!/bin/bash\necho Not on i386\n" > ./ostrip/ostrip; chmod +x ./ostrip/ostrip;fi

.NOTPARALLEL:
