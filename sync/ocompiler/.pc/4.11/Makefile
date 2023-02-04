TOPTARGETS := all install clean distclean uninstall test

SUBDIRS := src srcres

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
.PHONY: $(TOPTARGETS) $(SUBDIRS)

all:
	./srcres/ounused ./srcres/ounused.s.log
	./srcres/ounused ./src/linux/obj.s.log
