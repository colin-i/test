
#ifndef __cplusplus

#ifdef HAVE_STDBOOL_H
#include<stdbool.h>
#else
#ifdef _Bool
typedef typeof(_Bool) bool;
#else
typedef char bool;
#endif
enum{false=0!=0,true=1==1};
#endif

#include "null.h"

#endif

typedef struct{
	char*data;
	unsigned int spc;
	unsigned int sz;
}row;

#define Char_Return 0xd
#define row_pad 0xF
#define tab_sz 6
//can be 127(ascii Delete) or 263, note: Ctrl+h generates 263
#define is_KEY_BACKSPACE(a) a==KEY_BACKSPACE||a==0x7f

#define com_nr_save 0
#define com_nr_goto 1
#define com_nr_goto_alt 2
#define com_nr_find 3
#define com_nr_findagain 4
#define com_nr_findword 5
//#define com_nr_findwordfrom 6
//#define com_nr_is_find(a) *a>=com_nr_find
//#define com_nr_is_find_word(a) *a>=com_nr_findword

#define is_word_char(a) ('0'<=a&&(a<='9'||('A'<=a&&(a<='Z'||(a=='_'||('a'<=a&&a<='z'))))))
