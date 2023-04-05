
#include "top.h"

#ifdef HAVE_CURSES_H
#include<curses.h>
#else
#include"inc/main/curses.h"
#endif
#ifdef HAVE_FCNTL_H
#include<fcntl.h>
#else
#include"inc/main/fcntl.h"
#endif
#ifdef HAVE_POLL_H
#include<poll.h>
#else
#include"inc/main/poll.h"
#endif
#ifdef HAVE_STDLIB_H
#include<stdlib.h>
#else
#include"inc/main/stdlib.h"
#endif
#ifdef HAVE_STDIO_H
#include<stdio.h>
#else
#include"inc/main/stdio.h"
#endif
#ifdef HAVE_STRING_H
#include<string.h>
#else
#include"inc/main/string.h"
#endif
#ifdef HAVE_UNISTD_H
#include<unistd.h>
#else
#include"inc/main/unistd.h"
#endif
#ifdef HAVE_TIME_H
#include<time.h>
#else
#include"inc/main/time.h"
#endif

#include"sep.h"

#ifdef ARM7L
#ifdef HAVE_DLFCN_H
#include<dlfcn.h>
#else
#include"inc/main/armv7/dlfcn.h"
#endif
#ifdef HAVE_LIBUNWIND_H
#include<libunwind.h>
#else
#include"inc/main/armv7/libunwind.h"
#endif
#ifndef HAVE_STDLIB_H
#include"inc/main/armv7/stdlib.h"
#endif
#ifndef HAVE_STDIO_H
#include"inc/main/armv7/stdio.h"
#endif
#ifdef HAVE_SIGNAL_H
#include<signal.h>
#else
#include"inc/main/armv7/signal.h"
#endif
// This method can only be used on 32-bit ARM
static void AddAddress(unsigned long ip,int address_count) {
	Dl_info info;
	dladdr((void*)ip, &info);
	unsigned long relative_address = ip-(unsigned long)info.dli_fbase;
	char buf[100];
	int n=snprintf(buf,99,"  #%02zu:  0x%lx  %s\r\n", address_count, relative_address, info.dli_sname);
	write(STDOUT_FILENO,&buf,(size_t)n);
}
static void CaptureBacktraceUsingLibUnwind(void*ucontext) {
	// Initialize unw_context and unw_cursor.
	unw_context_t unw_context;// = {};
	unw_getcontext(&unw_context);
	unw_cursor_t  unw_cursor;// = {};
	unw_init_local(&unw_cursor, &unw_context);

	// Get more contexts.
	const mcontext_t* signal_mcontext = &(((const ucontext_t*)ucontext)->uc_mcontext);

	// Set registers.
	unw_set_reg(&unw_cursor, UNW_ARM_R0, signal_mcontext->arm_r0);
	unw_set_reg(&unw_cursor, UNW_ARM_R1, signal_mcontext->arm_r1);
	unw_set_reg(&unw_cursor, UNW_ARM_R2, signal_mcontext->arm_r2);
	unw_set_reg(&unw_cursor, UNW_ARM_R3, signal_mcontext->arm_r3);
	unw_set_reg(&unw_cursor, UNW_ARM_R4, signal_mcontext->arm_r4);
	unw_set_reg(&unw_cursor, UNW_ARM_R5, signal_mcontext->arm_r5);
	unw_set_reg(&unw_cursor, UNW_ARM_R6, signal_mcontext->arm_r6);
	unw_set_reg(&unw_cursor, UNW_ARM_R7, signal_mcontext->arm_r7);
	unw_set_reg(&unw_cursor, UNW_ARM_R8, signal_mcontext->arm_r8);
	unw_set_reg(&unw_cursor, UNW_ARM_R9, signal_mcontext->arm_r9);
	unw_set_reg(&unw_cursor, UNW_ARM_R10, signal_mcontext->arm_r10);
	unw_set_reg(&unw_cursor, UNW_ARM_R11, signal_mcontext->arm_fp);
	unw_set_reg(&unw_cursor, UNW_ARM_R12, signal_mcontext->arm_ip);
	unw_set_reg(&unw_cursor, UNW_ARM_R13, signal_mcontext->arm_sp);
	unw_set_reg(&unw_cursor, UNW_ARM_R14, signal_mcontext->arm_lr);
	unw_set_reg(&unw_cursor, UNW_ARM_R15, signal_mcontext->arm_pc);

	unw_set_reg(&unw_cursor, UNW_REG_IP, signal_mcontext->arm_pc);
	unw_set_reg(&unw_cursor, UNW_REG_SP, signal_mcontext->arm_sp);

	// unw_step() does not return the first IP.
	AddAddress(signal_mcontext->arm_pc,0);
	int address_count=1;
	// Unwind frames one by one, going up the frame stack.
	while (unw_step(&unw_cursor) > 0) {
		unw_word_t ip = 0;
		unw_get_reg(&unw_cursor, UNW_REG_IP, &ip);
		AddAddress(ip,address_count);
		if(address_count==29)break;
		address_count++;
	}
}
static void __attribute__((noreturn)) signalHandler(int sig,siginfo_t *info,void* ucontext){
(void)sig;(void)info;
	CaptureBacktraceUsingLibUnwind(ucontext);
	exit(EXIT_FAILURE);
}
//static void baz(int argc){int *foo = (int*)-1;if(argc==1)sprintf((char*)24,"%d\n", *foo);else free((void*)10);}
#endif

#include"base.h"

char ln_term[3]="\n";
size_t ln_term_sz=1;
char*textfile=nullptr;
row*rows=nullptr;
size_t rows_tot=1;
size_t ytext=0;
size_t xtext=0;
bool mod_flag=true;

#define Char_Escape 27
static char*mapsel=nullptr;
//static char*text_file=nullptr;
static size_t rows_spc=1;
static bool*x_right=nullptr;
static int*tabs=nullptr;
static int tabs_rsz;
static int yhelp;
static bool helpend;
static int phelp;
static char*helptext;
static time_t hardtime=0;
static char*restorefile=nullptr;
static char restorefile_buf[max_path_0];
static char restorefile_buf2[max_path_0];
static char*editingfile=nullptr;
static char editingfile_buf[max_path_0];
static char editingfile_buf2[max_path_0];
static mmask_t stored_mouse_mask;
static bool indent_flag=true;
#define mask_size 1
#define mask_mouse 1
#define mask_indent 2
#define mask_insensitive 4
static char prefs_file[max_path_0]={'\0'};//only the first byte is set

#define hel1 "USAGE\n"
// skip_unrestoredfilecheck_flag
#define hel2 " [filepath [line_termination: rn/r/n]]\
\nINPUT\
\nhelp: q(uit),up/down,mouse/touch v.scroll\
\n[Ctrl/Alt/Shift +]arrows/home/end/del,page up,page down,backspace,enter\
\np.s.: Ctrl+ left/right/del breaks at white-spaces and (),[]{}\
\nmouse/touch click and v.scroll\
\nCtrl+v = visual mode; Alt+v = visual line mode\
\n    c = copy\
\n    d = delete\
\n    x = cut\
\n    i = indent (I = flow indent)\
\n    u = unindent (U = flow unindent)\
\nCtrl+p = paste; Alt+p = paste at the beginning of the row\
\ncommand mode: left,right,home,end,ctrl+q\
\nCtrl+s = save file; Alt+s = save file as...\
\nCtrl+g = go to row[,column]; Alt+g = \"current_row,\" is entered\
\nCtrl+f = find text; Alt+f = refind text; Ctrl+c = word at cursor (alphanumerics and _); Alt+c = word from cursor\
\n    if found\
\n      Enter      = next\
\n      Space      = previous\
\n      Left Arrow = [(next/prev)&] replace\
\n      r          = reset replace text\
\n      R          = modify replace text\
\n    c = cancel\
\n    other key to return\
\nCtrl+u = undo; Alt+u = undo mode: left=undo,right=redo,other key to return\
\nCtrl+r = redo\
\nCtrl+e = disable/enable internal mouse/touch\
\nCtrl+n = disable/enable indentation\
\nCtrl+t = enable/disable insensitive search\
\nCtrl+q = quit"//32
static bool visual_bool=false;
static char*cutbuf=nullptr;
static size_t cutbuf_sz=0;
static size_t cutbuf_spc=0;
static size_t cutbuf_r=1;
static char*text_init_b=nullptr;
static char*text_init_e;
static int _rb;static int _cb;
static int _re;static int _ce;
static int topspace=1;
#define view_margin 8
#define known_stdin 0

bool no_char(char z){return z<32||z>=127;}
static void tab_grow(WINDOW*w,int r,char*a,size_t sz,int*ptr){
	x_right[r]=xtext<sz;
	if(x_right[r]==false)return;
	int c=0;int cr=0;
	int max=getmaxx(w);
	size_t i=xtext;size_t j=i;
	for(;i<sz&&cr<max;i++){
		cr++;
		char z=a[i];
		if(z=='\t'){
			int n=(int)(i-j);
			waddnstr(w,a+j,n);
			c+=n;
			ptr[ptr[0]+1]=c;ptr[0]++;
			j=i+1;
			cr+=tab_sz-1;
			//wmove(w,r,c);
			int k;if(cr>max)k=max;
			else k=cr;
			for(;c<k;c++){
				waddch(w,' ');
			}
		}else if(no_char(z)/*true*/){
			a[i]='?';char aux=a[i+1];a[i+1]='\0';
			waddstr(w,a+j);a[i+1]=aux;a[i]=z;
			c+=i-j+1;j=i+1;
		}
	}
	if(c<max){
		char aux=a[i];
		a[i]='\0';waddstr(w,a+j);a[i]=aux;
	}
}
void refreshrowsbot(WINDOW*w,int i,int maxy){
	size_t maxx=xtext+(size_t)getmaxx(w);
	do{
		size_t j=ytext+(size_t)i;
		int*ptr=&tabs[tabs_rsz*i];ptr[0]=0;
		wmove(w,i,0);
		if(j<rows_tot){
			size_t sz=rows[j].sz;
			if(sz>maxx)sz=maxx;
			tab_grow(w,i,rows[j].data,sz,ptr);
			if(getcury(w)==i)wclrtoeol(w);
		}else{x_right[i]=false;wclrtoeol(w);}
		i++;
	}while(i<maxy);
}
static void bmove(WINDOW*w,int r,int c,bool back){
	wmove(w,r,c);
	char chr=(char)winch(w);
	if(chr==' '){
		int*ptr=&tabs[tabs_rsz*r];
		int n=ptr[0];
		for(int i=1;i<=n;i++){
			int t=ptr[i];
			if((c<(t+tab_sz))&&(t<c)){
				if(back/*true*/)wmove(w,r,t);
				else{
					c=t+tab_sz;
					int max=getmaxx(w);
					if(c<max)wmove(w,r,c);
					else{
						int t1=ptr[1];
						int j=0;
						while(c>=max){
							xtext++;c--;
							if(j==t1){
								c-=tab_sz-1;
								break;
							}
							j++;
						}
						refreshpage(w);
						wmove(w,r,c);
				//		return false;
					}
				}
				//return true;
			}
		}
	}
	//return true;
}
static void amove(WINDOW*w,int r,int c){
	bmove(w,r,c,true);
}
static void vumove(WINDOW*w,int len){
	int y=getcury(w);
	if(y>len-1)amove(w,y-len,getcurx(w));
	else if(ytext!=0){
		int x=getcurx(w);
		ytext=(size_t)len>ytext?0:ytext-(size_t)len;
		refreshpage(w);
		amove(w,y,x);
	}
}
static void vdmove(WINDOW*w,int len){
	int y=getcury(w);
	if(y+len<getmaxy(w))amove(w,y+len,getcurx(w));
	else if(ytext+1<rows_tot){
		int x=getcurx(w);
		ytext=ytext+(size_t)len>=rows_tot?rows_tot-1:ytext+(size_t)len;
		refreshpage(w);
		amove(w,y,x);
	}
}
static void vuNmove(WINDOW*w,int y,size_t n){
	if(ytext!=0){
		if(ytext<n)ytext=0;
		else ytext-=n;
		int x=getcurx(w);
		refreshpage(w);
		amove(w,y,x);
	}
}
#define vu1move(w,y) vuNmove(w,y,1)
static void vdNmove(WINDOW*w,int y,size_t n){
	if(rows_tot-1!=ytext){
		if(ytext+n>=rows_tot)ytext=rows_tot-1;
		else ytext+=n;
		int x=getcurx(w);
		refreshpage(w);
		amove(w,y,x);
	}
}
#define vd1move(w,y) vdNmove(w,y,1)
static void printinverted(const char*s){
	attrset(COLOR_PAIR(1));
	addstr(s);
	//attr set here,cause,print"   "
	attrset(0);
}
static void helpposition(){
	move(getmaxy(stdscr)-2,0);
	if(helpend/*true*/)printinverted("BOT");
	else if(yhelp==0)printinverted("TOP");
	else addstr("---");
}
static int helpmanag(int n){
	int max=getmaxx(stdscr);
	int i=phelp;
	if(yhelp<n){
		int z=i+max;
		if(i!=0&&helptext[i-1]!='\n')z--;
		do{
			if(helptext[i]=='\n'){i++;break;}
			if(helptext[i]==0)break;
			i++;
		}while(i<z);
		if(helptext[i]=='\n')return i+1;
		return i;
	}
	if(helptext[i-1]=='\n'){
		i--;int j=i;do{
			i--;
		}while(helptext[i]!='\n'&&i!=0);
		if(i!=0)i++;
		int sz=j-i;
		if(sz<=max)return i;
		sz-=max;i+=max;
		max--;int k=-1;
		while(sz>0){sz-=max;k++;}
		return k*max+i;
	}
	i-=max;
	if(i!=0&&helptext[i-1]=='\n')return i;
	return i+1;
}
static int helpshow(int n){
	int max=getmaxx(stdscr);
	int i=phelp;int j=i;
	yhelp=n;int y=0;
	int cstart;
	if(i!=0&&helptext[i-1]!='\n')cstart=1;
	else cstart=0;
	int c=cstart;
	do{
		helpend=helptext[i]==0;
		bool newl=helptext[i]=='\n';
		c++;i++;
		bool is_max=c==max;
		if(newl/*true*/||helpend/*true*/||is_max/*true*/){
			move(y,0);
			int sum=i-j+cstart;
			if(cstart!=0){addch(' ');cstart=0;}
			char aux=helptext[i];helptext[i]='\0';
			addstr(&helptext[j]);
			helptext[i]=aux;
			if(sum<max)clrtoeol();
			y++;
			if(getmaxy(stdscr)-3<y)break;
			j=i;
			if(newl==false){
				if(helptext[i]=='\n'){j++;i=j;}
				else cstart=1;
			}
			c=cstart;
		}
	}while(helpend==false);
	helpposition();
	return y;
}
static void hmove(int n){
	if(helpend/*true*/&&(n>0))return;
	n+=yhelp;
	if(n<0)return;
	phelp=helpmanag(n);
	helpshow(n);
}
static void topspace_clear(){
	//first write is not here
	move(0,0);//is not here
	clrtoeol();//if name is shorter will let text
}
#define write_the_title(a) printinverted(a)
static void write_title(){
	write_the_title(textfile);
}
//Button 2 is the middle one
static bool helpin(WINDOW*w){
	int c;
	do{
		c=getch();
		if(c==KEY_MOUSE){
			MEVENT e;
			getmouse(&e);
			if((e.bstate&BUTTON4_PRESSED)!=0)hmove(-1);
			else
		#ifdef BUTTON5_PRESSED
			if((e.bstate&BUTTON5_PRESSED)!=0)
		#else
			if(e.bstate==0)     // at wheel down (ncurses 6.1 at bionic)
		#endif
			hmove(1);
		}else if(c==KEY_DOWN)hmove(1);
		else if(c==KEY_UP)hmove(-1);
		else if(c==KEY_RESIZE)return true;
	}while(c!='q');
	//helpclear();wnoutrefresh(stdscr);

	//need to clear first line anyway
	topspace_clear();
	if(textfile!=nullptr)write_title();
	wnoutrefresh(stdscr);//doupdate is not enough

	refreshpage(w);
	return false;
}
static void printhelp(){
	move(getmaxy(stdscr)-1,0);
	printinverted(bar_init());
}
static void slmove(WINDOW*w,int x,bool notabs){
	int y=getcury(w);
	if(xtext>0){
		xtext--;
		refreshpage(w);
		if(notabs/*true*/)wmove(w,y,x);
		else{
			amove(w,y,x);
			int newx=getcurx(w);
			if(newx<x&&newx+tab_sz<getmaxx(w))wmove(w,y,newx+tab_sz);
		}
	}
}
static void srmove(WINDOW*w,int x,bool back){
	int y=getcury(w);
	if(x_right[y]/*true*/){
		if(back/*true*/){
			xtext++;
			refreshpage(w);
			amove(w,y,x);
		}else{
			if(rows[ytext+(size_t)y].data[xtext]=='\t')x-=tab_sz-1;
			xtext++;
			refreshpage(w);
			bmove(w,y,x,false);
		}
	}
}
static int endmv(WINDOW*w,size_t r,bool minusone){
	size_t sz=rows[r].sz;
	if(minusone/*true*/&&sz>0)sz--;
	if(xtext>=sz){xtext=sz;return 0;}
	char*b=rows[r].data;
	char*s=b+sz;
	int n=getmaxx(w)-1;int m=0;
	do{
		s--;m+=s[0]=='\t'?tab_sz:1;
		if((size_t)(s-b)==xtext)break;
	}while(m<n);
	if(m>n){
		s++;m-=tab_sz;
	}
	xtext=(size_t)(s-b);
	return m;
}
#define end(w,r) endmv(w,r,false)
static void endmov(WINDOW*w,bool minusone){
	int y=getcury(w);
	size_t r=ytext+(size_t)y;
	size_t xcare=xtext;
	int x;if(r<rows_tot)x=endmv(w,r,minusone);
	else{xtext=0;x=0;}
	if(xtext!=xcare)refreshpage(w);
	wmove(w,y,x);
}
static int home(WINDOW*w,size_t r){
	char*d=rows[r].data;
	size_t sz=rows[r].sz;
	size_t i=0;
	while(i<sz){
		if(d[i]!='\t')break;
		i++;
	}
	if(i<xtext){xtext=i;return 0;}
	else if(i==xtext)return 0;
	int max=getmaxx(w);
	int c=0;while(xtext<i){
		if(c+tab_sz<max){
			i--;c+=tab_sz;
		}else xtext++;
	}
	return c;
}
static int xc_to_c(size_t col,int r){
	int*p=&tabs[tabs_rsz*r];
	int n=p[0];
	for(int i=0;i<n;i++){
		p++;
		if((size_t)p[0]<col)col+=tab_sz-1;
		else break;
	}
	return(int)col;
}
size_t c_to_xc(int c,int r){
	int*p=&tabs[tabs_rsz*r];
	int n=p[0];int x=c;
	for(int i=0;i<n;i++){
		p++;
		//cright can be in tab
		if((p[0]+(tab_sz-1))<c)x-=tab_sz-1;
		else break;
	}
	return (size_t)x;
}
void fixmembuf(size_t*y,size_t*x){
	if(y[0]>=rows_tot){
		y[0]=rows_tot-1;
		x[0]=rows[y[0]].sz;
		return;
	}
	size_t sz=rows[y[0]].sz;
	if(x[0]>sz)x[0]=sz;
}
static bool is_wordchar(char a){
	return is_word_char(a);
}
static bool is_textchar(char a){
	return a!='\t'&&a!=' '&&a!='('&&a!=')'&&a!=','&&a!='['&&a!=']'&&a!='{'
	&&a!='}';
}
static void left(WINDOW*w,int c){
	if(c>0)amove(w,getcury(w),c-1);
	else slmove(w,c,true);
}
static void left_move(WINDOW*w,bool(*f)(char)){
	int r=getcury(w);
	int c=getcurx(w);
	size_t y=ytext+(size_t)r;
	size_t x=xtext+c_to_xc(c,r);
	fixmembuf(&y,&x);
	size_t sz=rows[y].sz;
	char*d=rows[y].data;
	if(x==sz||f(d[x])==false||x==0||f(d[x-1])==false){left(w,c);return;}
	size_t prevx=x;
	x--;
	for(;;){
		if(x==0)break;
		x--;
		if(f(d[x])==false){x++;break;}
	}
	if(x<xtext){xtext=x;refreshpage(w);c=0;}
	else c-=prevx-x;
	wmove(w,r,c);
}
#define left_wordmove(w) left_move(w,is_wordchar)
#define left_textmove(w) left_move(w,is_textchar)
static void right(WINDOW*w,int c){
	if(c+1<getmaxx(w))bmove(w,getcury(w),c+1,false);
	else srmove(w,c,false);
}
#define right_short(f,x,d,sz) x==sz||f(d[x])==false||x+1==sz||f(d[x+1])==false
static size_t right_long(size_t x,char*d,size_t sz,bool(*f)(char)){
	x++;
	for(;;){
		if(x+1==sz)break;
		x++;
		if(f(d[x])==false){x--;break;}
	}
	return x;
}
static void right_move(WINDOW*w,bool(*f)(char)){
	int r=getcury(w);
	int c=getcurx(w);
	size_t y=ytext+(size_t)r;
	size_t x=xtext+c_to_xc(c,r);
	fixmembuf(&y,&x);
	size_t sz=rows[y].sz;
	char*d=rows[y].data;
	if(right_short(f,x,d,sz)){
		right(w,c);return;}
	size_t prevx=x;
	x=right_long(x,d,sz,f);
	c+=x-prevx;
	int max=getmaxx(w);
	if(c>=max){
		do{
			size_t val=d[xtext]=='\t'?tab_sz:1;
			xtext++;c-=val;
		}while(c>=max);
		refreshpage(w);
	}
	wmove(w,r,c);
}

#define right_wordmove(w) right_move(w,is_wordchar)
#define right_textmove(w) right_move(w,is_textchar)
#define alt_jump 2
#define ctrl_jump 3

#define click (BUTTON1_CLICKED|BUTTON1_PRESSED|BUTTON1_DOUBLE_CLICKED|BUTTON1_TRIPLE_CLICKED \
|BUTTON2_CLICKED|BUTTON2_PRESSED|BUTTON2_DOUBLE_CLICKED|BUTTON2_TRIPLE_CLICKED \
|BUTTON3_CLICKED|BUTTON3_PRESSED|BUTTON3_DOUBLE_CLICKED|BUTTON3_TRIPLE_CLICKED)

//1resize,0diff key,-1processed
static int movment(int c,WINDOW*w){
	if(c==KEY_MOUSE){
		MEVENT e;
		getmouse(&e);//==OK is when mousemask is 0, but then nothing at getch
		if((e.bstate&BUTTON4_PRESSED)!=0)vu1move(w,getcury(w));
		else
	#ifdef BUTTON5_PRESSED
		if((e.bstate&BUTTON5_PRESSED)!=0)
	#else
		if(e.bstate==0)     // at wheel down (ncurses 6.1 at bionic)
	#endif
		vd1move(w,getcury(w));
		else if((e.bstate&click)!=0)amove(w,e.y-topspace,e.x);//return -2;}
	}else if(c==KEY_LEFT)left(w,getcurx(w));
	else if(c==KEY_RIGHT)right(w,getcurx(w));
	else if(c==KEY_UP){
		int y=getcury(w);
		if(y>0)amove(w,y-1,getcurx(w));
		else vu1move(w,y);
	}else if(c==KEY_DOWN){
		int y=getcury(w);
		if(y+1<getmaxy(w))amove(w,y+1,getcurx(w));
		else vd1move(w,y);
	}else if(c==KEY_HOME){
		int y=getcury(w);
		if(xtext!=0){
			xtext=0;
			refreshpage(w);
		}
		wmove(w,y,0);
	}else if(c==KEY_END)endmov(w,false);
	else if(c==KEY_PPAGE){
		if(ytext!=0){
			int y=getcury(w);int x=getcurx(w);
			size_t my=(size_t)getmaxy(w);
			ytext=my>=ytext?0:ytext-my;
			refreshpage(w);
			amove(w,y,x);
		}
	}else if(c==KEY_NPAGE){
		if(ytext<rows_tot-1){
			int y=getcury(w);int x=getcurx(w);
			ytext+=(size_t)getmaxy(w);
			if(ytext>rows_tot-1)ytext=rows_tot-1;
			refreshpage(w);
			amove(w,y,x);
		}
	}else if(c==KEY_SLEFT)slmove(w,getcurx(w),false);
	else if(c==KEY_SRIGHT)srmove(w,getcurx(w),true);
	else if(c==KEY_SHOME){
		int y=getcury(w);
		int x=getcurx(w);
		if(xtext!=0){
			xtext=0;
			refreshpage(w);
		}
		amove(w,y,x);
	}else if(c==KEY_SEND){
		int y=getcury(w);
		int x=getcurx(w);
		size_t r=ytext+(size_t)y;
		size_t xcare=xtext;
		if(r<rows_tot)endmv(w,r,false);
		else xtext=0;
		if(xtext!=xcare)refreshpage(w);
		amove(w,y,x);
	}else if(c==KEY_SR)vu1move(w,getcury(w));
	else if(c==KEY_SF)vd1move(w,getcury(w));
	else if(c==KEY_RESIZE){
		return 1;
	}
	else{
		const char*s=keyname(c);
		if(strcmp(s,"kLFT5")==0)left_textmove(w);
		else if(strcmp(s,"kRIT5")==0)right_textmove(w);
		else if(strcmp(s,"kLFT3")==0)left_wordmove(w);
		else if(strcmp(s,"kRIT3")==0)right_wordmove(w);
		else if(strcmp(s,"kHOM3")==0){
			int y=getcury(w);
			size_t r=ytext+(size_t)y;
			size_t xcare=xtext;
			int x;if(r<rows_tot)x=home(w,r);
			else{xtext=0;x=0;}
			if(xcare!=xtext)refreshpage(w);
			wmove(w,y,x);
		}else if(strcmp(s,"kEND3")==0)endmov(w,true);
		else if(strcmp(s,"kUP5")==0)vumove(w,ctrl_jump);
		else if(strcmp(s,"kDN5")==0)vdmove(w,ctrl_jump);
		else if(strcmp(s,"kUP3")==0)vumove(w,alt_jump);
		else if(strcmp(s,"kDN3")==0)vdmove(w,alt_jump);
		else if(strcmp(s,"kHOM5")==0){
			if(ytext!=0||xtext!=0){
				ytext=0;xtext=0;
				refreshpage(w);
			}
			wmove(w,0,0);
		}else if(strcmp(s,"kEND5")==0){
			bool ycare;size_t xcare=xtext;
			int val=(int)rows_tot-getmaxy(w);
			if((int)ytext<val){ytext=(size_t)val;ycare=true;}
			else ycare=false;
			size_t a=rows_tot-1;
			int y=(int)(a-ytext);
			int x=end(w,a);
			if(ycare||xtext!=xcare)refreshpage(w);
			//moved by curses, but no add str for line breaks
			wmove(w,y,x);
		}else if(strcmp(s,"kUP6")==0)vuNmove(w,getcury(w),ctrl_jump);
		else if(strcmp(s,"kDN6")==0)vdNmove(w,getcury(w),ctrl_jump);
		else if(strcmp(s,"kUP4")==0)vuNmove(w,getcury(w),alt_jump);
		else if(strcmp(s,"kDN4")==0)vdNmove(w,getcury(w),alt_jump);
		else return 0;
	}
	return -1;
}
size_t sizemembuf(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel){
	if(ybsel==yesel)return xesel-xbsel;
	size_t size=rows[ybsel].sz-xbsel+ln_term_sz;
	for(size_t i=ybsel+1;i<yesel;i++){
		size+=rows[i].sz+ln_term_sz;
	}
	return size+xesel;
}
void cpymembuf(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel,char*buf){
	row*b=&rows[ybsel];
	if(ybsel==yesel){
		memcpy(buf,b->data+xbsel,xesel-xbsel);
		return;
	}
	size_t sz1=b->sz-xbsel;
	memcpy(buf,b->data+xbsel,sz1);
	memcpy(buf+sz1,ln_term,ln_term_sz);
	size_t sz=sz1+ln_term_sz;
	for(size_t i=ybsel+1;i<yesel;i++){
		size_t s=rows[i].sz;
		memcpy(buf+sz,rows[i].data,s);
		sz+=s;
		memcpy(buf+sz,ln_term,ln_term_sz);
		sz+=ln_term_sz;
	}
	memcpy(buf+sz,rows[yesel].data,xesel);
}
static bool writemembuf(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel){
	fixmembuf(&ybsel,&xbsel);
	fixmembuf(&yesel,&xesel);
	if(xesel==rows[yesel].sz){if(yesel<rows_tot-1){yesel++;xesel=0;}}
	else xesel++;
	size_t size=sizemembuf(ybsel,xbsel,yesel,xesel);
	if(cutbuf_spc<size){
		void*v=realloc(cutbuf,size);
		if(v==nullptr)return false;
		cutbuf=(char*)v;cutbuf_spc=size;
	}
	cpymembuf(ybsel,xbsel,yesel,xesel,cutbuf);
	cutbuf_sz=size;cutbuf_r=yesel-ybsel+1;
	return true;
}
static int mid(int r,int max){
	size_t y=ytext+(size_t)r;
	if(y<rows_tot){
		size_t sz=rows[y].sz;
		if(sz<xtext)return 0;
		sz-=xtext;
		int w=tabs[r*tabs_rsz]*(tab_sz-1)+(int)sz;
		if(w<max){
			return w;
		}
		return max;
	}
	return 0;
}
static void printpart(WINDOW*w,int p,int n){
	wattrset(w,COLOR_PAIR(p));
	winnstr(w,mapsel,n);
	waddstr(w,mapsel);
}
static void printrow(WINDOW*w,int r,int b,int e,int c1,int c2){
	int m=mid(r,getmaxx(w));
	if(m<=b){
		printpart(w,c2,e-b);
		return;
	}
	if(e<=m){
		printpart(w,c1,e-b);
		return;
	}
	printpart(w,c1,m-b);
	printpart(w,c2,e-m);
}
static void sel(WINDOW*w,int c1,int c2,int rb,int cb,int re,int ce){
	wmove(w,rb,cb);
	int wd=getmaxx(w);
	if(rb==re){
		printrow(w,rb,cb,ce,c1,c2);
	}else{
		printrow(w,rb,cb,wd,c1,c2);
		for(int r=rb+1;r<re;r++){
			int m=mid(r,wd);
			printpart(w,c1,m);
			printpart(w,c2,wd-m);
		}
		printrow(w,re,0,ce,c1,c2);
	}
}
static size_t v_l_x(size_t y,size_t x,size_t rmax,WINDOW*w){
	if(y<rmax){
		size_t ok=xtext+(size_t)getmaxx(w)-1;
		if(ok<rows[y].sz)return rows[y].sz;
		return ok;
	}else if(y==rmax){
		size_t sz=rows[y].sz;
		if(sz!=0&&x<sz-1)return sz-1;
	}
	return x;
}
static void setmembuf(size_t y,size_t x,bool*orig,size_t*yb,size_t*xb,size_t*ye,size_t*xe,WINDOW*w,bool v_l){
	size_t rmax=rows_tot-1;
	if(orig[0]/*true*/){
		if(y<yb[0]){
			if(v_l/*true*/){
				if(y<=rmax)x=0;
				xb[0]=v_l_x(yb[0],xb[0],rmax,w);
			}else{
				if(y<rmax&&x>rows[y].sz)x=rows[y].sz;
				if(yb[0]<rmax&&xb[0]==rows[yb[0]].sz){
					size_t max=(size_t)getmaxx(w)-1;
					if(rows[yb[0]].sz<xtext+max)xb[0]=xtext+max;
				}
			}
			ye[0]=yb[0];yb[0]=y;
			xe[0]=xb[0];xb[0]=x;
			orig[0]=false;
		}
		else if(y>yb[0]||xb[0]<=x){
			if(v_l/*true*/)x=v_l_x(y,x,rmax,w);
			else if(y<rmax&&x>=rows[y].sz)x=xtext+(size_t)getmaxx(w)-1;
			ye[0]=y;xe[0]=x;
		}
		else{
			if(yb[0]<rmax&&xb[0]==rows[yb[0]].sz){
				size_t max=(size_t)getmaxx(w)-1;
				if(rows[yb[0]].sz<xtext+max)xb[0]=xtext+max;
			}
			ye[0]=yb[0];
			xe[0]=xb[0];xb[0]=x;
			orig[0]=false;
		}
	}else{
		if(ye[0]<y){
			if(v_l/*true*/){
				if(ye[0]<=rmax)xe[0]=0;
				x=v_l_x(y,x,rmax,w);}
			else{
				if(ye[0]<rmax&&xe[0]>rows[ye[0]].sz)xe[0]=rows[ye[0]].sz;
				if(y<rmax&&x>=rows[y].sz)x=xtext+(size_t)getmaxx(w)-1;}
			yb[0]=ye[0];ye[0]=y;
			xb[0]=xe[0];xe[0]=x;
			orig[0]=true;
		}
		else if(ye[0]>y){
			if(v_l/*true*/){if(y<=rmax)x=0;}
			else if(y<rmax&&x>rows[y].sz)x=rows[y].sz;
			if(ye[0]<rmax&&xe[0]>=rows[ye[0]].sz){
				size_t max=(size_t)getmaxx(w)-1;
				if(rows[ye[0]].sz<xtext+max)xe[0]=xtext+max;
			}
			yb[0]=y;xb[0]=x;
		}
		else if(xe[0]<x){
			if(y<rmax&&x>=rows[y].sz)x=xtext+(size_t)getmaxx(w)-1;
			yb[0]=ye[0];
			xb[0]=xe[0];xe[0]=x;
			orig[0]=true;
		}
		else{
			if(v_l/*true*/){if(y<=rmax)x=0;}
			else if(y<rmax&&x>rows[y].sz)x=rows[y].sz;
			yb[0]=y;xb[0]=x;
		}
	}
}
static void unsel(WINDOW*w){
	sel(w,0,0,_rb,_cb,_re,_ce);
}
static void difsel(WINDOW*w,int rb,int cb,int re,int ce){
	bool a;bool b;
	if(_rb<rb||(_rb==rb&&_cb<cb)){
		if(re==_re&&ce==_ce)b=false;else b=true;
		_re=rb;_ce=cb;a=true;
	}else if(re<_re||(re==_re&&ce<_ce)){
		if(rb==_rb&&cb==_cb)b=false;else b=true;
		if(ce==getmaxx(w)){_cb=0;_rb=re+1;}
		else{_rb=re;_cb=ce;}
		a=true;
	}else if(rb<_rb||cb<_cb){
		re=_rb;ce=_cb;b=true;
		a=false;
	}else{// if(_re<re||_ce<ce){
		if(_ce==getmaxx(w)&&_re<re){cb=0;rb=_re+1;}
		else{rb=_re;cb=_ce;}
		b=true;
		a=false;
	}
	if(a/*true*/)unsel(w);
	if(b/*true*/)sel(w,1,2,rb,cb,re,ce);
}
static void printsel(WINDOW*w,size_t ybsel,size_t xbsel,size_t yesel,size_t xesel,bool care){
	int wd=getmaxx(w);
	int cright=wd-1;
	int rb;int cb;
	if(ybsel<ytext){
		rb=0;cb=0;}
	else{
		rb=(int)(ybsel-ytext);
		if(xbsel<=xtext)cb=0;
		else if(xbsel<=xtext+c_to_xc(cright,rb))cb=xc_to_c(xbsel-xtext,rb);
		else{rb++;cb=0;}
	}
	int re;int ce;
	int rdown=getmaxy(w)-1;
	size_t ydown=ytext+(size_t)rdown;
	if(yesel>ydown){
		re=rdown;ce=cright;}
	else{
		re=(int)(yesel-ytext);
		if(xtext+c_to_xc(cright,re)<=xesel)ce=cright;
		else if(xtext<=xesel)ce=xc_to_c(xesel-xtext,re);
		else{re--;ce=cright;}
	}
	int*t=&tabs[re*tabs_rsz];
	for(int i=t[0];i>0;i--){
		if(t[i]<=ce){
			if(t[i]==ce){
				ce+=tab_sz-1;
				if(ce>=wd)ce=wd-1;
			}
			break;
		}
	}
	ce++;
	if(care/*true*/)sel(w,1,2,rb,cb,re,ce);
	else difsel(w,rb,cb,re,ce);
	wattrset(w,0);
	_rb=rb;_cb=cb;
	_re=re;_ce=ce;
}
void visual(char a){
	mvaddch(getmaxy(stdscr)-1,getmaxx(stdscr)-2,a);
	wnoutrefresh(stdscr);
}
static void refreshrowscond(WINDOW*w,size_t y,size_t x,size_t r,size_t n){
	if(y!=ytext||x!=xtext)refreshpage(w);
	else refreshrowsbot(w,(int)r,n!=0?getmaxy(w):(int)r+1);
}
static void pasted(size_t r,size_t x,WINDOW*w){
	size_t z1=ytext;size_t z2=xtext;size_t z3=r;
	size_t rws=cutbuf_r-1;
	r+=rws;size_t maxy=(size_t)getmaxy(w);
	if(maxy<=r){
		ytext+=r-maxy+1;
		r=maxy-1;
	}
	//
	int c=0;
	if(x<=xtext)xtext=x;
	else{
		char*d=rows[ytext+r].data;
		char*b=d+xtext;
		char*s=d+x;int maxx=getmaxx(w)-1;
		do{
			s--;c+=s[0]=='\t'?tab_sz:1;
			if(b==s)break;
		}while(c<maxx);
		if(c>maxx){s++;c-=tab_sz;}
		xtext=(size_t)(s-d);
	}
	refreshrowscond(w,z1,z2,z3,rws);
	wmove(w,(int)r,c);
}
static bool rows_expand(size_t n){
	size_t rowssize=rows_tot+n;
	if(rowssize>rows_spc){
		row*m=(row*)realloc(rows,rowssize*sizeof(row));
		if(m==nullptr)return true;
		rows=m;rows_spc=rowssize;
	}
	return false;
}
static void text_free(size_t b,size_t e){
	for(size_t i=b;i<e;i++){
		char*d=rows[i].data;
		if(d<text_init_b||text_init_e<=d)free(d);
	}
}
static size_t row_pad_sz(size_t sz){
	sz++;//[i]=0;addstr;=aux
	size_t dif=sz&row_pad;
	if(dif!=0)return sz+((dif^row_pad)+1);
	return sz;
}
bool row_alloc(row*rw,size_t l,size_t c,size_t r){
	size_t sz=l+c+r;
	if(sz>=rw->spc){//[i]=0;addstr;=aux
		char*src=rw->data;char*dst;
		size_t size=row_pad_sz(sz);
		if(text_init_b<=src&&src<text_init_e){
			dst=(char*)malloc(size);
			if(dst==nullptr)return true;
			memcpy(dst,src,l);
			memcpy(dst+l,src+l,r);
		}else{
			dst=(char*)realloc(src,size);
			if(dst==nullptr)return true;
			//src=dst;
		}
		rw->data=dst;
		rw->spc=size;
	}//else dst=src;
	return false;
}
void row_set(row*rw,size_t l,size_t c,size_t r,const char*mid){
	char*d=rw->data;
	size_t j=l+c;size_t i=j+r;size_t k=rw->sz;
	rw->sz=i;
	while(j<i){
		i--;k--;d[i]=d[k];
	}
	d+=l;
	while(c>0){
		d[0]=mid[0];
		d++;mid++;c--;
	}
}
static void deleted(size_t ybsel,size_t xbsel,int*r,int*c,WINDOW*w){
	if(ybsel<ytext){ytext=ybsel;r[0]=0;}
	else r[0]=(int)(ybsel-ytext);
	if(xbsel<=xtext){
		xtext=xbsel;c[0]=0;
		return;
	}
	char*d=rows[ybsel].data;
	int cl=0;
	int max=getmaxx(w);
	size_t x=xbsel;
	while(x>xtext){
		int n=d[x-1]=='\t'?tab_sz:1;
		if(cl+n>=max)break;
		x--;cl+=n;
	}
	xtext=x;
	c[0]=cl;
}
static void row_del(size_t a,size_t b){
	size_t c=b+1;
	text_free(a,c);
	row*j=&rows[a];
	for(size_t i=c;i<rows_tot;i++){
		memcpy(j,&rows[i],sizeof(row));
		j++;
	}
	rows_tot-=c-a;
}

static void easytime(){
	hardtime=0;
}
static void mod_visual(chtype ch){
	mvaddch(getmaxy(stdscr)-1,getmaxx(stdscr)-1,ch);
	wnoutrefresh(stdscr);
}
static void mod_set(bool flag,chtype ch){
	mod_flag=flag;
	mod_visual(ch);
}
#define modif_visual '*'
void mod_set_off(){
	hardtime=time((time_t)nullptr);//cast only at non-header
	//cannot delete mod_flag, it has meanings at undo type/bk/del sum and quit without save
	mod_set(false,modif_visual);
}
void mod_set_on(){
	easytime();
	mod_set(true,' ');
}
void mod_set_off_wrap(){
	//if(mod_flag/*true*/){
	if(hardtime==0){
		mod_set_off();//with wrap
	}
}

#define restore_marker ".edorrestorefile"
#define restorefile_path(a) restorefile_path_base(a,restorefile_buf)
static bool restorefile_path_base(char*p,char*dest){
	size_t ln=strlen(p)+sizeof(restore_marker);
	if(ln>max_path_0)return false;//the path is too long
	sprintf(dest,"%s%s",p,restore_marker);
	return true;
}
#define editing_marker ".edoreditingfile"
#define editingfile_path(a) editingfile_path_base(a,editingfile_buf)
static bool editingfile_path_base(char*p,char*dest){
	size_t ln=strlen(p)+sizeof(editing_marker);
	if(ln>max_path_0)return false;//the path is too long
	sprintf(dest,"%s%s",p,editing_marker);
	return true;
}
static void editing_new(){
	int f=open_new(editingfile_buf);
	if(f!=-1){
		close(f);
		editingfile=editingfile_buf;
	}
}

static void restore_visual(){
	mod_visual('&');
}
static void hardtime_resolve_returner(WINDOW*w){//argument for errors
	if(textfile!=nullptr){
		if(restorefile==nullptr){
			//set restore file path
			if(restorefile_path(textfile)/*true*/){
				//save at path
				if(saving_base(restorefile_buf)==command_return_ok){
					restorefile=restorefile_buf;
					restore_visual();
				}else err_set(w);
			}
		}else{
			if(saving_base(restorefile)==command_return_ok)restore_visual();
			else err_set(w);
		}
	}
}
#define one_minute 60
//#define one_minute 1
static void hardtime_resolve(WINDOW*w){//argument for errors
	if(hardtime!=0){
		if((time((time_t)nullptr)-hardtime)>one_minute){//>1
			hardtime_resolve_returner(w);
			easytime();
		}
	}
}
//rename is better than delete+create, new disk cycles?
#define file_rebase(file,s,d,call)\
	char*src;char*dest;\
	if(file==s){\
		src=s;dest=d;\
	}else{\
		src=d;dest=s;\
	}\
	if(call(textfile,dest)/*true*/){\
		if(rename(src,dest)==0)file=dest;\
	}
void restore_rebase(){
	if(restorefile!=nullptr){
		file_rebase(restorefile,restorefile_buf,restorefile_buf2,restorefile_path_base)
	}
}
void editing_rebase(){
	if(editingfile!=nullptr){
		file_rebase(editingfile,editingfile_buf,editingfile_buf2,editingfile_path_base)
	}else if(editingfile_path(textfile)/*true*/)editing_new();
}

void deleting(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel){
	row*r1=&rows[ybsel];
	if(ybsel==yesel){
		size_t sz=r1->sz;
		size_t dif=xesel-xbsel;
		char*d=rows[ybsel].data;
		for(size_t i=xesel;i<sz;i++){
			d[i-dif]=d[i];
		}
		r1->sz-=dif;
	}else{
		row_set(r1,xbsel,rows[yesel].sz-xesel,0,rows[yesel].data+xesel);
		row_del(ybsel+1,yesel);
	}
}
bool deleting_init(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel){
	if(ybsel!=yesel){
		size_t se=rows[yesel].sz-xesel;
		size_t sb=rows[ybsel].sz-xbsel;
		if(se>sb){//need deleting part at undo
			return row_alloc(&rows[ybsel],rows[ybsel].sz,se-sb,0);
		}
	}
	return false;
}
static bool deletin(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel,int*rw,int*cl,WINDOW*w,bool many){
	if(deleting_init(ybsel,xbsel,yesel,xesel)==false){
		if(undo_add_del(ybsel,xbsel,yesel,xesel)==false){
			deleting(ybsel,xbsel,yesel,xesel);
			size_t z1=ytext;size_t z2=xtext;
			deleted(ybsel,xbsel,rw,cl,w);
			refreshrowscond(w,z1,z2,ybsel-ytext,many);
			return true;
		}
	}
	return false;
}
static bool deleti(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel,int*rw,int*cl,WINDOW*w){
	fixmembuf(&ybsel,&xbsel);
	fixmembuf(&yesel,&xesel);
	if(xesel==rows[yesel].sz){if(yesel<rows_tot-1){yesel++;xesel=0;}}
	else xesel++;
	bool many=ybsel!=yesel;
	if(many/*true*/||xbsel!=xesel){
		if(deletin(ybsel,xbsel,yesel,xesel,rw,cl,w,many)/*true*/){
			mod_set_off_wrap();
			return true;
		}
	}
	return false;
}
static bool delet(size_t ybsel,size_t xbsel,size_t yesel,size_t xesel,int*rw,int*cl,WINDOW*w){
	size_t yend=yesel;
	size_t rend=rows_tot;
	size_t wasy=ytext;
	size_t wasx=xtext;
	bool b=deleti(ybsel,xbsel,yesel,xesel,rw,cl,w);
	//unselect all
	if(yend>=rend&&wasy==ytext&&wasx==xtext){
		rend-=ytext;
		size_t ymax=(size_t)getmaxy(w);
		if(rend<ymax){
			yend-=ytext;
			size_t to=yend<ymax?yend:ymax-1;
			while(rend<=to){
				wmove(w,(int)rend,0);wclrtoeol(w);rend++;
			}
		}
	}
	return b;
}
static char*memtrm(char*a){
	while(a[0]!=ln_term[0])a++;
	return a;
}
static void rows_insert(row*d,size_t sz,size_t off){
	size_t a=rows_tot-1;
	rows_tot+=sz;
	while(off<=a){
		memcpy(&rows[a+sz],&rows[a],sizeof(row));
		a--;
	}
	memcpy(rows+off,d,sz*sizeof(row));
}
static size_t pasting(row*d,size_t y,size_t x,size_t*xe,char*buf,size_t buf_sz,size_t buf_r,bool fromcopy){
	bool one=buf_r==1;
	size_t szc;size_t sz1r;size_t l;
	size_t szr=rows[y].sz-x;
	size_t max=buf_r-1;
	if(one/*true*/){
		szc=buf_sz;sz1r=szr;
		l=x+szc;
	}
	else{
		char*a=memtrm(buf)+ln_term_sz;
		sz1r=0;
		size_t sz=(size_t)(a-buf);
		szc=sz-ln_term_sz;
		size_t n=max-1;
		//inter
		for(size_t i=0;i<n;i++){
			char*b=memtrm(a)+ln_term_sz;
			size_t ln=(size_t)(b-a);
			size_t len=ln-ln_term_sz;
			size_t spc_sz=row_pad_sz(len);
			void*v=malloc(spc_sz);
			if(v==nullptr)return i+1;
			memcpy(v,buf+sz,len);
			d[i].data=(char*)v;
			d[i].sz=len;
			d[i].spc=spc_sz;
			sz+=ln;
			a=b;
		}
		//last
		l=buf_sz-sz;
		size_t sizen=l+szr;
		size_t spc_sz=row_pad_sz(sizen);
		char*rn=(char*)malloc(spc_sz);
		if(rn==nullptr)return max;
		memcpy(rn,buf+sz,l);
		memcpy(rn+l,rows[y].data+x,szr);
		d[n].data=rn;
		d[n].sz=sizen;
		d[n].spc=spc_sz;
		//mem
		if(rows_expand(max)/*true*/)return buf_r;
	}
	if(row_alloc(&rows[y],x,szc,sz1r)==false){
		if(fromcopy/*true*/)if(undo_add(y,x,one/*true*/?y:y+max,l)/*true*/)return buf_r;
		row_set(&rows[y],x,szc,sz1r,buf);
		if(one==false)rows_insert(d,max,y+1);
		xe[0]=l;
		return 0;
	}
	return buf_r;
}
bool paste(size_t y,size_t x,size_t*xe,char*buf,size_t buf_sz,size_t buf_r,bool fromcopy){
	row*d;
	if(buf_r>1){d=(row*)malloc((buf_r-1)*sizeof(row));
		if(d==nullptr)return false;}
	else d=nullptr;
	size_t n=pasting(d,y,x,xe,buf,buf_sz,buf_r,fromcopy);
	if(d!=nullptr){
		for(size_t i=1;i<n;i++){
			free(d[i-1].data);
		}
		free(d);
	}
	return n==0;
}
static void past(WINDOW*w){
	if(cutbuf_sz!=0){
		int r=getcury(w);
		size_t y=ytext+(size_t)r;
		size_t x=xtext+c_to_xc(getcurx(w),r);
		fixmembuf(&y,&x);
		size_t xe;
		if(paste(y,x,&xe,cutbuf,cutbuf_sz,cutbuf_r,true)/*true*/){
			pasted(y-ytext,xe,w);
			mod_set_off_wrap();
			position(getcury(w),getcurx(w));
		}
	}
}
void vis(char c,WINDOW*w){
	visual(c);
	wmove(w,getcury(w),getcurx(w));
}
static void delete_fast(WINDOW*w,int r,int c,char*data,size_t x,size_t sz){
	int*t=&tabs[tabs_rsz*r];int n=t[0];
	int i=1;
	while(i<=n){
		if(c<=t[i])break;
		i++;
	}
	t[0]=i-1;
	//
	int max=getmaxx(w);
	if(xtext==sz)x_right[r]=false;
	else{
		int k=0;
		while(x<sz){
			char ch=data[x];
			if(ch=='\t'){
				t[i]=c;t[0]=i;i++;
				int j=0;
				while(j<tab_sz){
					mapsel[k+j]=' ';
					j++;
					c++;if(c==max)break;
				}
				k+=j;
			}
			else{mapsel[k]=no_char(ch)/*true*/?'?':ch;c++;k++;}
			if(c==max)break;
			x++;
		}
		waddnstr(w,mapsel,k);
	}
	if(c<max)wclrtoeol(w);
}
static void rowfixdel(WINDOW*w,int r,int c,row*rw,size_t i){
	wmove(w,r,c);
	int wd=getmaxx(w);
	char*d=rw->data;
	int*t=&tabs[tabs_rsz*r];
	int a=t[0]+1;
	size_t mx=rw->sz;
	while(c<wd&&i<mx){
		char ch=d[i];
		if(ch!='\t'){
			c++;waddch(w,no_char(ch)/*true*/?'?':ch);
		}else{
			t[a]=c;t[0]++;a++;
			c+=tab_sz;wmove(w,r,c);
		}
		i++;
	}
	x_right[r]=mx!=0;
}
static bool del_key(size_t y,size_t x,int r,int*cc,WINDOW*w,bool reverse){
	row*r1=&rows[y];int maxx=getmaxx(w);int c=*cc;
	int margin_val=c+view_margin;
	bool margin=margin_val>maxx;
	if(margin/*true*/){while(c+view_margin>maxx){
			c-=r1->data[xtext]=='\t'?tab_sz:1;
			xtext++;
		}
		refreshpage(w);*cc=c;
	}
	size_t sz=r1->sz;
	if(x==sz){
		size_t yy=y+1;
		if(yy==rows_tot){
			//to not continue
			if(margin/*true*/)wmove(w,r,c);//this is after refreshpage, the pointer is at the last row
			return true;
		}
		row*r2=&rows[yy];
		if(row_alloc(r1,x,r2->sz,0)==false){
			if(undo_add_del(y,x,yy,0)==false){
				row_set(r1,x,r2->sz,0,r2->data);
				row_del(yy,yy);
				rowfixdel(w,r,c,r1,x);
				if(r+1<getmaxy(w))refreshrows(w,r+1);
				return false;
			}
		}
		return true;
	}
	if(undo_delk(y,x,y,x+1)==false){
		char*data=r1->data;
		for(size_t i=x+1;i<sz;i++){
			data[i-1]=data[i];
		}
		r1->sz--;
		if(margin/*true*/)wmove(w,r,c);
		else if(reverse/*true*/&&xtext>0&&margin_val<maxx){
			xtext--;refreshpage(w);*cc=c+1;
			return false;
		}
		delete_fast(w,r,c,data,x,r1->sz);
		return false;
	}
	return true;
}
#define delete_key(y,x,r,cc,w) del_key(y,x,r,cc,w,false)
static bool bcsp(size_t y,size_t x,int*rw,int*cl,WINDOW*w){
	int c=cl[0];
	if(xtext==0&&c==0){
		if(y==0)return true;//to not continue
		size_t yy=y-1;
		row*r0=&rows[yy];
		row*r1=&rows[y];
		size_t sz0=r0->sz;
		size_t xx=xtext;c=end(w,yy);
		if(row_alloc(r0,sz0,r1->sz,0)==false){
			if(undo_add_del(yy,sz0,y,0)==false){
				row_set(r0,sz0,r1->sz,0,r1->data);
				row_del(y,y);
				cl[0]=c;
				int r=rw[0];
				if(r==0){
					ytext--;refreshpage(w);
				}
				else{
					if(xtext!=xx)refreshpage(w);
					else{
						rowfixdel(w,r-1,c,r0,sz0);
						refreshrows(w,r);
					}
					rw[0]=r-1;
				}
				return false;
			}
		}
		return true;
	}
	if(undo_bcsp(y,x-1,y,x)==false){
		row*r=&rows[y];
		char*data=r->data;size_t sz=r->sz;
		c-=data[x-1]=='\t'?tab_sz:1;
		for(size_t i=x;i<sz;i++){
			data[i-1]=data[i];
		}
		r->sz--;
		if(xtext!=0){
			if(c<view_margin){
				if(c<0){c=0;xtext--;}
				if(xtext!=0){
					while(c<view_margin){
						xtext--;
						c+=data[xtext]=='\t'?tab_sz:1;
						if(xtext==0)break;
					}
				}
				refreshpage(w);
				cl[0]=c;
				return false;
			}
		}
		cl[0]=c;
		wmove(w,rw[0],c);//move for addstr
		delete_fast(w,rw[0],c,data,x-1,r->sz);
		return false;
	}
	return true;
}
static bool enter(size_t y,size_t x,int*r,int*c,WINDOW*w){
	if(rows_expand(1)/*true*/)return true;
	char*b=rows[y].data;
	char*d=b;
	if(indent_flag){
		char*e=b+x;
		while(d<e&&d[0]=='\t')d++;
	}
	size_t tb=(size_t)(d-b);
	size_t s=rows[y].sz-x;
	size_t sze=tb+s;
	size_t spc=row_pad_sz(sze);
	char*v=(char*)malloc(spc);
	if(v==nullptr)return true;
	if(undo_add(y,x,y+1,tb)==false){
		row rw;
		memset(v,'\t',tb);
		memcpy(v+tb,b+x,s);
		rows[y].sz-=s;
		rw.data=v;rw.sz=sze;rw.spc=spc;
		rows_insert(&rw,1,y+1);
		bool fix=tb>=xtext;
		int row=r[0];
		if(row==(getmaxy(w)-1))ytext++;
		else{
			r[0]++;
			if(fix/*true*/){
				int*t=&tabs[tabs_rsz*row];
				int a=t[0];
				int*p=t+a;
				int*z=p;int cprev=c[0];
				while(p!=t){
					if(p[0]<cprev)break;
					p--;
				}
				t[0]-=z-p;
				c[0]=(int)(tb-xtext)*tab_sz;
				wclrtoeol(w);
				x_right[row]=xtext<rows[y].sz;
				refreshrows(w,row+1);
				return false;
			}
		}
		if(fix/*true*/)c[0]=(int)(tb-xtext)*tab_sz;
		else{xtext=tb;c[0]=0;}
		refreshpage(w);
		return false;
	}
	return true;
}
#define multidel(fn,r,x,y,cl,rw,w)\
	char*d=r->data;size_t sz=r->sz;\
	if(right_short(fn,x,d,sz)){if(delete_key(y,x,rw,&cl,w)/*true*/)return;}\
	else if(deletin(y,x,y,right_long(x,d,sz,fn)+1,&rw,&cl,w,false)==false)return;
static void type(int cr,WINDOW*w){
	int cl=getcurx(w);
	int rwnr=getcury(w);
	size_t x=xtext+c_to_xc(cl,rwnr);
	size_t y=ytext+(size_t)rwnr;
	size_t xx=x;fixmembuf(&y,&x);
	row*r=&rows[y];
	int rw=(int)(y-ytext);
	if(rw<rwnr){
		xtext=r->sz;
		cl=0;
		refreshpage(w);
	}else{
		size_t dif=xx-x;
		cl-=dif;
		if(cl<0){
			xtext=r->sz;
			cl=0;
			refreshpage(w);
		}
	}
	if(cr==Char_Return){
		if(enter(y,x,&rw,&cl,w)/*true*/)return;
		position(rw,cl);
	}
	else if(is_KEY_BACKSPACE(cr)){
		if(bcsp(y,x,&rw,&cl,w)/*true*/)return;
		position(rw,cl);
	}
	else if(cr==KEY_DC){if(delete_key(y,x,rw,&cl,w)/*true*/)return;}
	else if(cr==KEY_SDC){if(del_key(y,x,rw,&cl,w,true)/*true*/)return;}
	else{
		const char*knm=keyname(cr);
		if(strcmp(knm,"kDC5")==0){multidel(is_textchar,r,x,y,cl,rw,w)}
		else if(strcmp(knm,"kDC3")==0){multidel(is_wordchar,r,x,y,cl,rw,w)}
		else{
			char ch=cr&0xff;
			if(row_alloc(r,x,1,r->sz-x)/*true*/)return;
			if(undo_type(y,x,y,x+1)/*true*/)return;
			row_set(r,x,1,r->sz-x,&ch);
			bool is_tab=ch=='\t';
			int s=is_tab/*true*/?tab_sz:1;
			//
			int colmn=cl;
			cl+=s;
			int max=getmaxx(w);
			if(cl>=max){
				char*d=r->data;
				do{
					cl-=d[xtext]=='\t'?tab_sz:1;
					xtext++;
				}while(cl>=max);
				refreshpage(w);
			}else{
				wmove(w,rw,colmn);
				int n=max-cl;
				winnstr(w,mapsel,n);
				int*t=&tabs[tabs_rsz*rw];
				int a=t[0];
				if(a!=0)if(t[a]+s>=max){t[0]--;a--;}
				int i=1;
				for(;i<=a;i++){
					if(colmn<=t[i])break;
				}
				if(is_tab/*true*/){
					for(int k=tab_sz;k>0;k--){
						waddch(w,' ');
					}
					t[0]=a+1;
					for(int j=a;i<=j;j--){t[j+1]=t[j]+tab_sz;}
					t[i]=colmn;
				}else{
					waddch(w,no_char(ch)/*true*/?'?':ch);
					int j=a;
					while(i<=j){
						t[j]=t[j]+1;j--;
					}
				}
				waddstr(w,mapsel);
				x_right[rw]=true;
			}
			position(rw,cl);
		}
	}
	wmove(w,rw,cl);
	mod_set_off_wrap();
}
static void indent(bool b,size_t ybsel,size_t*xbsel,size_t yesel,size_t*xesel,WINDOW*w){
	if(ybsel>=rows_tot)return;
	size_t ye;
	if(yesel>=rows_tot)ye=rows_tot;
	else ye=yesel+1;
	if(b/*true*/){
		for(size_t i=ybsel;i<ye;i++){
			row*r=&rows[i];
			if(row_alloc(r,0,1,r->sz)/*true*/)return;
		}
		if(undo_add_ind(ybsel,ye)/*true*/)return;
		for(size_t i=ybsel;i<ye;i++){
			row*r=&rows[i];
			row_set(r,0,1,r->sz,"\t");
		}
		mod_set_off_wrap();
	}else{
		bool something=false;
		for(size_t i=ybsel;i<=ye;i++){
			if(rows[i].sz!=0){something=true;break;}
		}
		if(something/*true*/){
			if(undo_add_ind_del(ybsel,ye)/*true*/)return;
			for(size_t i=ybsel;i<ye;i++){
				row*r=&rows[i];size_t sz=r->sz;
				if(sz!=0){
					char*d=r->data;
					for(size_t j=1;j<sz;j++)d[j-1]=d[j];
					r->sz=sz-1;
				}
			}
			mod_set_off_wrap();
		}
	}
	int rb;if(ybsel<ytext)rb=0;
	else rb=(int)(ybsel-ytext);
	int re=(int)(yesel-ytext)+1;
	int max=getmaxy(w);
	if(re>max)re=max;
	if(b/*true*/){
		if(xbsel!=nullptr){
			xbsel[0]++;xesel[0]++;
			xtext++;
			if(rb!=0)refreshrowsbot(w,0,rb);
			if(re<max)refreshrowsbot(w,re,max);
		}else refreshrowsbot(w,rb,re);
	}else{
		if(xbsel!=nullptr){
			if(xtext!=0){
				xbsel[0]--;xesel[0]--;
				xtext--;
				if(rb!=0)refreshrowsbot(w,0,rb);
				if(re<max)refreshrowsbot(w,re,max);
			}else{
				xbsel[0]=0;xesel[0]=v_l_x(yesel,xesel[0],rows_tot-1,w);
				refreshrowsbot(w,rb,re);
				printsel(w,ybsel,0,yesel,xesel[0],true);
			}
		}else refreshrowsbot(w,rb,re);
	}
}
static bool visual_mode(WINDOW*w,bool v_l){
	visual('V');
	int rw=getcury(w);int cl=getcurx(w);
	size_t ybsel=ytext+(size_t)rw;
	size_t yesel=ybsel;
	size_t xbsel;size_t xesel;
	bool orig=true;
	size_t rmax=rows_tot-1;
	if(v_l/*true*/){
		if(ybsel<rmax){
			xbsel=0;
			xesel=xtext+(size_t)getmaxx(w)-1;
			if(xesel<rows[yesel].sz)xesel=rows[yesel].sz;
		}
		else{
			xesel=xtext+(size_t)cl;
			if(ybsel==rmax){
				xbsel=0;
				size_t sz=rows[yesel].sz;
				if(sz!=0&&xesel<sz-1)xesel=sz-1;
			}else xbsel=xesel;
		}
	}else{
		xbsel=xtext+c_to_xc(cl,rw);xesel=xbsel;
		if(yesel<rmax&&xesel>=rows[yesel].sz){
			xbsel=rows[ybsel].sz;
			xesel=xtext+(size_t)getmaxx(w)-1;
		}
	}
	printsel(w,ybsel,xbsel,yesel,xesel,true);
	wmove(w,rw,cl);
	int z;
	do{
		int b=wgetch(w);
		size_t ycare=ytext;size_t xcare=xtext;
		z=movment(b,w);
		if(z==1)return true;
		else{
			int r=getcury(w);int c=getcurx(w);
			if(z==0){
				if(b=='I'){z=-1;indent(true,ybsel,&xbsel,yesel,&xesel,w);}
				else if(b=='U'){
					z=-1;
					bool edge=xtext==0;
					indent(false,ybsel,&xbsel,yesel,&xesel,w);
					if(edge/*true*/){amove(w,r,c);continue;}
				}
				else{
					char v=' ';
					visual_bool=b=='c';
					if(visual_bool/*true*/){
						if(writemembuf(ybsel,xbsel,yesel,xesel)/*true*/){v='C';unsel(w);}
					}else if(b=='d'){
						if(delet(ybsel,xbsel,yesel,xesel,&r,&c,w)/*true*/)
							if(orig/*true*/)position(r,c);
					}else if(b=='x'){
						if(writemembuf(ybsel,xbsel,yesel,xesel)/*true*/){
							if(delet(ybsel,xbsel,yesel,xesel,&r,&c,w)/*true*/)
								if(orig/*true*/)position(r,c);
						}
					}else{
						if(b=='i'){
							indent(true,ybsel,nullptr,yesel,nullptr,w);
							amove(w,r,c);
							c=getcurx(w);
						}else if(b=='u'){
							indent(false,ybsel,nullptr,yesel,nullptr,w);
							amove(w,r,c);
							c=getcurx(w);
						}
						unsel(w);
					}
					visual(v);
				}
			}else{
				position(getcury(w),getcurx(w));
				size_t y=ytext+(size_t)r;size_t x=xtext+c_to_xc(c,r);
				setmembuf(y,x,&orig,&ybsel,&xbsel,&yesel,&xesel,w,v_l);
				printsel(w,ybsel,xbsel,yesel,xesel,ytext!=ycare||xtext!=xcare);
			}
			wmove(w,r,c);
		}
	}while(z!=0);
	return false;
}
#define quick_pack(nr,w) char*args[2];args[0]=(char*)nr;args[1]=(char*)w;
static bool find_mode(int nr,WINDOW*w){
	quick_pack(nr,w)
	int r=command((char*)args);
	if(r==-2)return true;
	else if(r!=0){
		wmove(w,getcury(w),getcurx(w));
	}
	return false;
}
static bool goto_mode(char*args,WINDOW*w){
	int r=command(args);
	if(r==1){
		centering(w,nullptr,nullptr);
	}
	else if(r>-2)wmove(w,getcury(w),getcurx(w));
	else return true;
	return false;
}
static bool savetofile(WINDOW*w,bool has_file){
	char*d=textfile;
	int ret;
	if(has_file){
		ret=save();
	}else{char aa=com_nr_save;ret=command(&aa);}
	if(ret!=0){
		if(ret==1){
			if(d!=textfile){
				//text_file=textfile;//now is a title
				topspace_clear();
				write_title();
			}

			if(mod_flag/*true*/){bar_clear();texter_macro("Saved");}
			//there are some cases here:
			//	open with forced new line and save
			//	open with std input and save
			//	save a blank New Path
			//	just save in case the file was erased

			mod_set_on();
			undo_save();
		}
		else if(ret==-2)return true;
	}else err_set(w);
	wmove(w,getcury(w),getcurx(w));
	return false;
}
static void setprefs(int flag,bool set){
	if(prefs_file[0]!='\0'){
		//can use O_RDWR and lseek SEEK_SET
		int f=open(prefs_file,O_RDONLY);
		if(f!=-1){
			char mask;
			if(read(f,&mask,mask_size)==mask_size){
				close(f);
				if(set/*true*/)mask|=flag;
				else mask&=~flag;
				f=open(prefs_file,O_WRONLY);
				if(f!=-1){
					#pragma GCC diagnostic push
					#pragma GCC diagnostic ignored "-Wunused-result"
					write(f,&mask,mask_size);
					close(f);
					#pragma GCC diagnostic pop
				}
			}
		}
	}
}
static time_t guardian=0;
static bool loopin(WINDOW*w){
	int c;
	for(;;){
		//wtimeout(w,1000);
		wtimeout(w,one_minute*1000);//it counts where wgetch is (example at visual)
		c=wgetch(w);
		hardtime_resolve(w);
		if(c==ERR){
			time_t test=time(nullptr);
			if(test==guardian)return false;//example: cc nothing.c | edor , will have errno 0, will loop.
				//reproducible? fprintf to stderr+something else, see cc source for answer
				//fprintf was tested and is separate from this, then why? at that cc is showing same time with edor
			guardian=test;

			//this was ok at hardtime_resolve but will be too often there, here will be wrong sometimes but still less trouble
			//doupdate();//noone will show virtual screen if without this

			//and the cursor is getting away, not right but ok
			wmove(w,getcury(w),getcurx(w));
			//same as doupdate+not moving the cursor

			continue;//timeout
		}
		wtimeout(w,-1);

		int a=movment(c,w);
		if(a==1)return true;
		if(a!=0){
			if(visual_bool/*true*/){
				visual_bool=false;
				visual(' ');
			}else if(bar_clear()/*true*/)wnoutrefresh(stdscr);
			position(getcury(w),getcurx(w));
		}else if(c==Char_Escape){
			nodelay(w,true);
			int z=wgetch(w);
			nodelay(w,false);
			if(z=='v'){if(visual_mode(w,true)/*true*/)return true;}
			else if(z=='p'){
				int y=getcury(w);
				if(xtext!=0){xtext=0;refreshpage(w);}
				wmove(w,y,0);past(w);
			}
			else if(z=='g'){
				quick_pack(com_nr_goto_alt,w)
				if(goto_mode((char*)args,w)/*true*/)return true;
			}
			else if(z=='f'){if(find_mode(com_nr_findagain,w)/*true*/)return true;}
			else if(z=='c'){if(find_mode(6,w)/*true*/)return true;}
			else if(z=='u'){vis('U',w);undo_loop(w);vis(' ',w);}
			else if(z=='s'){bool b=savetofile(w,false);if(b/*true*/)return true;}
		}else{
			const char*s=keyname(c);
			if(strcmp(s,"^V")==0){
				if(visual_mode(w,false)/*true*/)return true;
			}
			else if(strcmp(s,"^P")==0)past(w);
			else if((strcmp(s,"^S")==0)){
				bool b=savetofile(w,true);
				if(b/*true*/)return true;
			}
			else if(strcmp(s,"^G")==0){
				char aa=com_nr_goto;
				if(goto_mode(&aa,w)/*true*/)return true;
			}else if(strcmp(s,"^F")==0){
				if(find_mode(com_nr_find,w)/*true*/)return true;
			}else if(strcmp(s,"^C")==0){
				if(find_mode(com_nr_findword,w)/*true*/)return true;
			}else if(strcmp(s,"^U")==0){
				undo(w);
			}else if(strcmp(s,"^R")==0){
				redo(w);
			}else if(strcmp(s,"KEY_F(1)")==0){
				int cy=getcury(w);int cx=getcurx(w);
				phelp=0;
				int i=helpshow(0);
				int mx=getmaxy(stdscr)-2;
				for(;i<mx;i++){move(i,0);clrtoeol();}
				move(mx,3);clrtoeol();
				if(helpin(w)/*true*/){
					ungetch(c);
					return true;
				}
				wmove(w,cy,cx);
			}
			else if(strcmp(s,"^Q")==0){
				if(mod_flag==false){
					bar_clear();//errors
					int q=question("And save");
					if(q==1){
						q=save();
						if(q==0)err_set(w);
					}
					if(q==-2)return true;
					else if(q==0){
						wnoutrefresh(stdscr);
						wmove(w,getcury(w),getcurx(w));
						continue;
					}
				}
				if(restorefile!=nullptr)unlink(restorefile);//here restorefile is deleted
				return false;
			}
			else if(strcmp(s,"^E")==0){
				if(stored_mouse_mask!=0){stored_mouse_mask=mousemask(0,nullptr);setprefs(mask_mouse,false);}
				else{stored_mouse_mask=mousemask(ALL_MOUSE_EVENTS,nullptr);setprefs(mask_mouse,true);}
			}
			else if(strcmp(s,"^N")==0){
				if(indent_flag/*true*/)indent_flag=false;else indent_flag=true;
				setprefs(mask_indent,indent_flag);
			}
			else if(strcmp(s,"^T")==0){
				if(insensitive/*true*/){
					insensitive=false;
					visual('t');
				}else{
					insensitive=true;
					visual('T');
				}
				//doupdate();will change cursor
				wmove(w,getcury(w),getcurx(w));
				setprefs(mask_insensitive,insensitive);
			}
			else type(c,w);
			//continue;
		}
	}
}
//-1 to normalize, 0 errors, 1 ok
static int normalize(char**c,size_t*size,size_t*r){
	int ok=0;
	char*text_w=c[0];
	size_t sz=size[0];
	char*norm=(char*)malloc(2*sz+1);
	if(norm!=nullptr){
		size_t j=0;ok=1;
		for(size_t i=0;i<sz;i++){
			char a=text_w[i];
			if(a=='\n'){
				r[0]++;
				if(ln_term_sz==2){
					norm[j]='\r';j++;ok=-1;
				}
				else if(ln_term[0]=='\r'){a='\r';ok=-1;}
			}else if(a=='\r'){
				r[0]++;
				if(ln_term_sz==2){
					if(((i+1)<sz)&&text_w[i+1]=='\n'){
						norm[j]=a;j++;i++;
						a='\n';}
					else{norm[j]=a;j++;a='\n';ok=-1;}
				}
				else{
					if(((i+1)<sz)&&text_w[i+1]=='\n'){
						i++;
						if(ln_term[0]=='\n')a='\n';
						ok=-1;
					}else if(ln_term[0]=='\n'){
						a='\n';ok=-1;
					}
				}
			}
			norm[j]=a;j++;
		}
		norm[j]='\0';size[0]=j;
		free(text_w);c[0]=norm;
	}
	return ok;
}
static void rows_init(size_t size){
	char*b=&text_init_b[size];
	row*z=&rows[0];
	z->data=text_init_b;size_t sz;
	char*a=text_init_b;
	for(size_t i=1;i<rows_tot;i++){
		sz=(size_t)(memtrm(a)-a);
		z->sz=sz;z->spc=0;
		a+=sz+ln_term_sz;
		z=&rows[i];
		z->data=a;
	}
	z->sz=(size_t)(b-a);z->spc=0;
	rows_spc=rows_tot;
}
static bool grab_file(char*f,size_t*text_sz){
	bool fake=true;
	int fd=open(f,O_RDONLY);
	if(fd!=-1){
		if(is_dir(fd)/*true*/){
			putchar('\"');
			size_t n=strlen(f);
			for(size_t i=0;i<n;i++){
				putchar(f[i]);
			}
			//puts(f);
			puts("\" is a directory");
		}
		else{
			size_t size=(size_t)lseek(fd,0,SEEK_END);
			text_init_b=(char*)malloc(size);
			if(text_init_b!=nullptr){
				lseek(fd,0,SEEK_SET);
				read(fd,text_init_b,size);
				text_sz[0]=size;
				fake=false;
			}
		}
		close(fd);
	}
	return fake;
}
static bool grab_input(size_t*text_sz){
	size_t s=512;size_t d;
	do{
		void*v=realloc(text_init_b,*text_sz+s);
		if(v==nullptr)return true;
		text_init_b=(char*)v;
		char*c=text_init_b+*text_sz;
		d=(size_t)read(known_stdin,c,s);//zero indicates end of file
		//char*b=fgets(c,s,stdin);
		//if(b==nullptr)break;
		//d=strlen(c);
		*text_sz+=d;
	}while(d==s);
	freopen("/dev/tty","r",stdin);
	return false;
}

static bool valid_ln_term(char*input_term,bool*not_forced){
	if(strcmp(input_term,"rn")==0){ln_term[0]='\r';ln_term[1]='\n';ln_term[2]='\0';ln_term_sz=2;}
	else if(strcmp(input_term,"r")==0)ln_term[0]='\r';
	else if(strcmp(input_term,"n")==0){}
	else{
		puts("Line termination argument must be: \"rn\", \"r\" or \"n\".");
		return true;
	}
	*not_forced=false;
	return false;
}
//same as normalize
static int startfile(int argc,char**argv,size_t*text_sz,bool no_file,bool no_input){
	bool not_forced=true;
	if(no_file==false){
		char*f=argv[1];
		if(grab_file(f,text_sz)/*true*/)return 0;
		if(argc==3){
			if(valid_ln_term(argv[2],&not_forced)/*true*/)return 0;
		}
	}
	if(no_input==false){
		if(no_file/*true*/){
			text_init_b=(char*)malloc(0);
			if(text_init_b==nullptr)return 0;
			*text_sz=0;
		}
		//else will be appended to existing file
		if(grab_input(text_sz)/*true*/)return 0;
	}
	if(not_forced/*true*/){
		size_t i=*text_sz;
		while(i>0){
			i--;
			if(text_init_b[i]=='\n'){
				if(i!=0&&text_init_b[i-1]=='\r'){
					ln_term[0]='\r';
					ln_term[1]='\n';
					ln_term[2]='\0';
					ln_term_sz=2;
				}
				break;
			}else if(text_init_b[i]=='\r'){
				ln_term[0]='\r';
				break;
			}
		}
		return normalize(&text_init_b,text_sz,&rows_tot);
	}
	if(normalize(&text_init_b,text_sz,&rows_tot)==0)return 0;
	return 1;
}
static bool help_init(char*f,size_t szf){
	size_t sz1=sizeof(hel1)-1;
	size_t sz2=sizeof(hel2);
	char*a=(char*)malloc(sz1+szf+sz2);
	if(a!=nullptr){
		helptext=a;
		memcpy(a,hel1,sz1);
		a+=sz1;memcpy(a,f,szf);
		memcpy(a+szf,hel2,sz2);
		return true;
	}
	return false;
}
static void getfilebuf(char*cutbuf_file){//,size_t off){
	int f=open(cutbuf_file,O_RDONLY);
	if(f==-1)f=open_new(cutbuf_file);
	/*if(f==-1){
		char store=cutbuf_file[off];
		cutbuf_file[off]='.';
		f=open(cutbuf_file+off,O_RDONLY);
		cutbuf_file[off]=store;
	}*/
	if(f!=-1){
		size_t sz=(size_t)lseek(f,0,SEEK_END);
		if(sz!=0){
			char*v=(char*)malloc(sz);
			if(v!=nullptr){
				lseek(f,0,SEEK_SET);
				cutbuf_sz=(size_t)read(f,v,sz);
				if(normalize(&v,&cutbuf_sz,&cutbuf_r)!=0){
					cutbuf=v;cutbuf_spc=cutbuf_sz;
				}else free(v);
			}
		}
		close(f);
	}
}
static void getprefs(){
	char mask;
	int f=open(prefs_file,O_RDONLY);
	if(f!=-1){
		if(read(f,&mask,mask_size)==mask_size){
			if((mask&mask_mouse)==0)stored_mouse_mask=mousemask(0,nullptr);
			if((mask&mask_indent)==0)indent_flag=false;
			if((mask&mask_insensitive)!=0)insensitive=true;
		}
		close(f);
		return;
	}
	f=open_new(prefs_file);
	if(f!=-1){
		mask=mask_mouse|mask_indent/*|mask_insensitive*/;
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wunused-result"
		write(f,&mask,mask_size);
		#pragma GCC diagnostic pop
	}
}
static bool setfilebuf(char*s,char*cutbuf_file){
#if ((!defined(USE_FS)) && (!defined(USE__FS)))
	set_path_separator(s);
#endif
	size_t sz=strlen(s);size_t i=sz;
	do{
		i--;
		char a=s[i];
		if(a==path_separator){i++;break;}
	}while(i!=0);
	size_t exenamesize=sz-i;
	bool b=help_init(&s[i],exenamesize);
	char*h=getenv("HOME");
	if(h!=nullptr){
		size_t l=strlen(h);
		if(l!=0){
			size_t info_sz=l+exenamesize+7;//plus separator dot info and null
			if(info_sz<=max_path_0){
				sprintf(cutbuf_file,"%s%c.%sinfo",h,path_separator,&s[i]);
				getfilebuf(cutbuf_file);//l-1

				const char*conf=".config";
				size_t csz=strlen(conf)+1;//plus separator
				if(info_sz+csz<=max_path_0){
					sprintf(prefs_file,"%s%c%s%c.%sinfo",h,path_separator,conf,path_separator,&s[i]);
					getprefs();
				}
			}
		}
	}
	return b;
}
static void writefilebuf(char*cutbuf_file){
	if(cutbuf_file[0]!=0){
		int f=open(cutbuf_file,O_WRONLY|O_TRUNC);
		if(f!=-1){
			#pragma GCC diagnostic push
			#pragma GCC diagnostic ignored "-Wunused-result"
			write(f,cutbuf,cutbuf_sz);
			#pragma GCC diagnostic pop
			close(f);
		}
	}
}
static void color(){
	if(start_color()!=ERR){
		if(init_pair(1,COLOR_BLACK,COLOR_WHITE)!=ERR){//TERM vt100
			init_pair(2,COLOR_BLACK,COLOR_CYAN);
		}
	}
}

static void proced(char*comline){
	char cutbuf_file[max_path_0];
	cutbuf_file[0]='\0';
	if(setfilebuf(comline,cutbuf_file)/*true*/){
		bool loops=false;
		int cy=0;int cx=0;
		int r=getmaxy(stdscr)-1;
		int old_r=r-1;//set -1 because at first compare is erasing new_visual
		do{
			void*a=realloc(x_right,(size_t)r);
			if(a==nullptr)break;
			x_right=(bool*)a;
			int c=getmaxx(stdscr);
			tabs_rsz=1+(c/tab_sz);
			if((c%tab_sz)!=0)tabs_rsz++;
			void*b=realloc(tabs,sizeof(int)*(size_t)(r*tabs_rsz));
			if(b==nullptr)break;
			tabs=(int*)b;
			a=realloc(mapsel,(size_t)c+1);
			if(a==nullptr)break;
			mapsel=(char*)a;

			if(textfile!=nullptr){
				move(0,0);//no clear, only overwrite, can resize left to right then back right to left
				write_title();//this is also the first write
			}

			WINDOW*w=newwin(r-topspace,c,topspace,0);
			if(w!=nullptr){
				keypad(w,true);
				refreshpage(w);
				wmove(w,cy,cx);
				printhelp();
				if(r<=old_r)clrtoeol();//resize to up,is over text
				//or =, clear bar,visual and saves
				old_r=r;
				if(mod_flag==false){
					if(hardtime==0)restore_visual();
					else mod_visual(modif_visual);
				}
				else wnoutrefresh(stdscr);
				position_reset();
				position(cy,cx);
				loops=loopin(w);
				if(loops/*true*/){//is already resized and the cursor fits in the screen, not in the new size
					cy=getcury(w);
					r=getmaxy(stdscr)-1;
					if(cy==r){
						cy=r-1;
						if(ytext+1<rows_tot)ytext++;
					}
					cx=getcurx(w);
					//c=getmaxx(w1);never if(cx>=c)
				}
				delwin(w);
			}else break;
		}while(loops/*true*/);
		if(x_right!=nullptr){
			free(x_right);
			if(tabs!=nullptr){
				free(tabs);
				if(mapsel!=nullptr){
					free(mapsel);
					writefilebuf(cutbuf_file);
					undo_free();
				}
			}
		}
		free(helptext);
	}
	if(cutbuf!=nullptr)free(cutbuf);
}
static void action(int argc,char**argv,WINDOW*w1){
	size_t text_sz;
	bool no_file=argc==1;
	if(no_file==false){
		no_file=new_visual(argv[1])/*true*/;
		if(restorefile_path(argv[1])/*true*/){
			if(access(restorefile_buf,F_OK)==0){
				//if(argc==2){
				puts("There is an unrestored file, (c)ontinue?\r");
				int c=getchar();
				if(c!='c')return;
				//}
			}
		}
		if(editingfile_path(argv[1])/*true*/){
			if(access(editingfile_buf,F_OK)==0){
				puts("The file is already opened in another instance, (c)ontinue?\r");
				int c=getchar();
				if(c!='c')return;
			}else editing_new();
		}
	}
	struct pollfd fds[1];
	//typedef struct __sFILE FILE;
	//FILE* stdin __attribute__((annotate("introduced_in=" "23")));
	fds[0].fd = known_stdin;
	fds[0].events = POLLIN;
	bool no_input=poll(fds, 1, 0)<1;
	int ok=0;
	if(no_file/*true*/&&no_input/*true*/){
		text_init_b=(char*)malloc(1);
		if(text_init_b!=nullptr){
			rows=(row*)malloc(sizeof(row));
			if(rows!=nullptr){
				text_init_b[0]='\0';
				text_sz=0;
				rows[0].data=text_init_b;
				rows[0].sz=0;rows[0].spc=0;
				ok=1;
				text_init_e=text_init_b+1;
			}
		}
	}else{
		ok=startfile(argc,argv,&text_sz,no_file,no_input);
		if(ok!=0){
			if(ok<1){
				char txt[]={'N','o','r','m','a','l','i','z','e',' ','l','i','n','e',' ','e','n','d','i','n','g','s',' ','t','o',' ','\\','r',' ',' ','?',' ','n','=','n','o',',',' ','d','e','f','a','u','l','t','=','y','e','s','\r','\0'};
				//           0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26   27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49   50
				if(ln_term_sz==2){txt[28]='\\';txt[29]='n';}
				else if(ln_term[0]=='\n')txt[27]='n';
				puts(txt);
				int c=getchar();
				if(c=='n')ok=0;
			}
			if(ok!=0){
				rows=(row*)malloc(rows_tot*sizeof(row));
				if(rows!=nullptr){
					rows_init(text_sz);

					textfile=argv[1];

					text_init_e=text_init_b+text_sz+1;
				}
				else ok=0;
			}
		}
	}
	if(ok!=0){
		color();
		WINDOW*pw=position_init();
		if(pw!=nullptr){
			keypad(w1,true);
			noecho();
			nonl();//no translation,faster

			//if set 1press_and_4,5 will disable right press (for copy menu) anyway
			//on android longpress to select and copy is a gesture and is different from mouse events
			//the only difference with ALL_..EVENTS is that we want to speed up and process all events here (if there is a curses implementation like that)
			stored_mouse_mask=mousemask(ALL_MOUSE_EVENTS,nullptr);//for error, export TERM=vt100

			proced(argv[0]);
			delwin(pw);
		}
	}
	if(text_init_b!=nullptr){
		if(rows!=nullptr){
			text_free(0,rows_tot);
			free(rows);
			//puts(text_file
		}
		free(text_init_b);
	}
	if(editingfile!=nullptr)unlink(editingfile);//this can be before and after text_init_b
}
int main(int argc,char**argv){
	#ifdef ARM7L
	struct sigaction signalhandlerDescriptor;
	memset(&signalhandlerDescriptor, 0, sizeof(signalhandlerDescriptor));
	signalhandlerDescriptor.sa_flags = SA_SIGINFO;//SA_RESTART | SA_ONSTACK;
	signalhandlerDescriptor.sa_sigaction = signalHandler;
	sigaction(SIGSEGV, &signalhandlerDescriptor, nullptr);
	//baz(argc);
	#endif
	if(argc>3){puts("Too many arguments.");return EXIT_FAILURE;}
	WINDOW*w1=initscr();
	use_default_colors();//assume_default_colors(-1,-1);//it's ok without this for color pair 0 (when attrset(0))
	if(w1!=nullptr){
		raw();//stty,cooked;relevant for getchar at me
		action(argc,argv,w1);
		endwin();
		//if(text_file!=nullptr)puts(text_file);
	}
	return EXIT_SUCCESS;
}
