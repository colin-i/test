
#ifdef __cplusplus
extern "C"{
#endif

int* __errno(void) __attribute__((__const__));
#define errno (*__errno())

#ifdef __cplusplus
}
#endif
