
entrylinux _start(sd argc,sv argv)

#this is because fedora will wrong all plugin cache on 64 for 32
sd argv0
ss *argv1="--gst-disable-registry-fork"
set argv0 argv

import "init_args" init_args
call init_args(argc,#argv)

set argc 2
set argv #argv0

call gst_init(#argc,#argv)
