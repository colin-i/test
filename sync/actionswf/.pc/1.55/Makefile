TOPTARGETS := all install clean distclean uninstall test

#ifndef test
#SUBDIRS := src
#else
SUBDIRS := src example
#endif

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
.PHONY: $(TOPTARGETS) $(SUBDIRS)

.NOTPARALLEL:
