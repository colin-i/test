
bool no_char(char);
void refreshrowsbot(WINDOW*,int,int);
#define refreshrows(w,i) refreshrowsbot(w,i,getmaxy(w))
#define refreshpage(w) refreshrows(w,0)
size_t c_to_xc(int,int);
bool row_alloc(row*,size_t,size_t,size_t);
void row_set(row*,size_t,size_t,size_t,const char*);
bool deleting_init(size_t,size_t,size_t,size_t);
void deleting(size_t,size_t,size_t,size_t);
void mod_set_on();
void mod_set_off();
void mod_set_off_wrap();
size_t sizemembuf(size_t,size_t,size_t,size_t);
void cpymembuf(size_t,size_t,size_t,size_t,char*);
bool paste(size_t,size_t,size_t*,char*,size_t,size_t,bool);
void vis(char,WINDOW*);
void visual(char);
void fixmembuf(size_t*y,size_t*x);

const char*bar_init(void);
int save(void);
int saving_base(char*);
int question(const char*);
int command(char*);
void centering2(WINDOW*,size_t*,size_t*,bool);
WINDOW*position_init(void);
void position(int,int);
void position_reset(void);
bool undo_add(size_t,size_t,size_t,size_t);
bool undo_add_del(size_t,size_t,size_t,size_t);
bool undo_add_ind(size_t,size_t);
bool undo_add_ind_del(size_t,size_t);
void undo_free(void);
void undo(WINDOW*);
void redo(WINDOW*);
void undo_save(void);
bool undo_type(size_t,size_t,size_t,size_t);
bool undo_bcsp(size_t,size_t,size_t,size_t);
bool undo_delk(size_t,size_t,size_t,size_t);
void undo_loop(WINDOW*);
bool new_visual(char*);
bool bar_clear(void);
bool is_dir(int);
void err_set(WINDOW*);
int open_new(char*);

extern char ln_term[3];
extern size_t ln_term_sz;
extern char*textfile;
extern row*rows;
extern size_t rows_tot;
extern size_t ytext;
extern size_t xtext;
extern bool mod_flag;
extern bool insensitive;

#define centering(w,rw,cl) centering2(w,rw,cl,false)
