
const S_IROTH=0x4

const S_IRWXU=0x1C0
const S_IRWXG=0x38
const S_IXOTH=0x1
#at dir execute is search
const flag_dmode=S_IRWXU|S_IRWXG|S_IROTH|S_IXOTH

const flag_O_BINARY=0
const flag_O_CREAT=0x0040
const S_IRUSR=0x100;const S_IWUSR=0x80
const S_IRGRP=0x20;const S_IWGRP=0x10
const S_IWOTH=0x2
const flag_fmode=S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH
