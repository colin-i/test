
#include "inc/stdio.h"

typedef struct __sFILE FILE;
extern FILE*stdin __attribute__((annotate("introduced_in=" "23")));

#ifdef __cplusplus
extern "C" {
#endif

int puts(const char*);
int putchar(int);
int getchar(void);
FILE* freopen(const char *filename, const char *mode, FILE *stream);
//int snprintf(char* __buf, size_t __size, const char* __fmt, ...);

#ifdef __cplusplus
}
#endif
