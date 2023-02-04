
#include "inc/curses.h"

#define ALL_MOUSE_EVENTS 0xFffFFff
#define COLOR_BLACK 0
#define COLOR_CYAN 6
#define COLOR_WHITE 7
#define ERR -1
typedef unsigned long mmask_t;
typedef struct
{
	short id;// __attribute__((aligned(4)));
	int x,y,z;
	mmask_t bstate;
}
MEVENT;
//#define OK 0
#define BUTTON1_CLICKED 0x4
#define BUTTON4_PRESSED 0x10000
#define BUTTON5_PRESSED 0x200000
#define KEY_UP 0403
#define KEY_DOWN 0402
#define KEY_SF 0520
#define KEY_SR 0521
#define KEY_NPAGE 0522
#define KEY_PPAGE 0523
#define KEY_SDC 0577
#define KEY_SEND 0602
#define KEY_SHOME 0607
#define KEY_SLEFT 0611
#define KEY_SRIGHT 0622
#define KEY_MOUSE 0631

#ifdef __cplusplus
extern "C" {
#endif

WINDOW*initscr(void);
int endwin(void);
int ungetch(int);
chtype winch(WINDOW*);
int winnstr(WINDOW*,char*,int);
mmask_t mousemask(mmask_t,mmask_t*);
int noecho(void);
int raw(void);
int nonl(void);
int delwin(WINDOW*);
int waddstr(WINDOW*,const char*);
int waddnstr(WINDOW*,const char*,int);
int clrtoeol(void);
int wclrtoeol(WINDOW*);
int use_default_colors(void);
int start_color(void);
int init_pair(short,short,short);
int keypad(WINDOW*,bool);
int getmouse(MEVENT*);
int nodelay(WINDOW*,bool);

#ifdef __cplusplus
}
#endif
