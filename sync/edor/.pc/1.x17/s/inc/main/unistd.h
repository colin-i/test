
//sys/types.h
typedef long off_t;

//#include <bits/seek_constants.h>
#define SEEK_SET 0
#define SEEK_END 2

#include "inc/unistd.h"

#ifdef __cplusplus
extern "C" {
#endif

off_t lseek(int,off_t,int);
ssize_t read(int,void*,size_t);

#ifdef __cplusplus
}
#endif
