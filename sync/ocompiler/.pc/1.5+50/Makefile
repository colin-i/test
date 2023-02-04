TOPTARGETS := all install clean distclean uninstall test

SUBDIRS := src srcres

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
.PHONY: $(TOPTARGETS) $(SUBDIRS)


all:
	cd ./srcres; ./ounused ./ounused.s.log
	if ! [ -f ./src/obj.o ];then cd ./src; ../srcres/ounused ./linux/obj.s.log; fi

.NOTPARALLEL:
