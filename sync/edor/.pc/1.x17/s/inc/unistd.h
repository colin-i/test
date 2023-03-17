
#include "inc/stddef.h"

typedef int ssize_t;

#ifdef __cplusplus
extern "C" {
#endif

int close(int);
ssize_t write(int,const void*,size_t);

#ifdef __cplusplus
}
#endif
