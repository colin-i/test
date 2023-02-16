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
	if ! [ -f ./src/obj.o ];then cd ./src; ../ounused/ounused ./linux/obj.s.log; fi
	@echo

.NOTPARALLEL:
