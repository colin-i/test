
#ifdef __cplusplus
extern "C" {
#endif



#define StateMoveTo 1
#define StateFillStyle0 2*StateMoveTo
#define StateFillStyle1 2*StateFillStyle0
#define StateLineStyle 2*StateFillStyle1
#define StateNewStyles 2*StateLineStyle
#pragma pack(push,4)
typedef struct ButtonData_str{
    unsigned int def_fill;
    int def_line_sz;
	unsigned int def_line;
	unsigned int ov_fill;
    int ov_line_sz;
	unsigned int ov_line;
	unsigned int dn_fill;
	int dn_line_sz;
	unsigned int dn_line;
    int xcurve;
    int ycurve;
    char* text;
    int font_id;
    int font_height;
    int font_vertical_offset;
    int font_color;
    char* actions;
}ButtonData;
#pragma pack(pop)
#define HasText 0x80
#define WordWrap 0x40
#define Multiline 0x20
#define Password 0x10
#define ReadOnly 0x8
#define HasTextColor 0x4
#define HasMaxLength 0x2
#define HasFont 0x1
#define HasFontClass 0x8000
#define AutoSize 0x4000
#define HasLayout 0x2000
#define NoSelect 0x1000
#define Border 0x800
#define WasStatic 0x400
#define HTML 0x200
#define UseOutlines 0x100
typedef struct EditText_str
{
    int fontid;
    int font_height;
    char* fontclassname;
    int rgba;
    int maxlength;
    char* initialtext;
    int layout_align;
    int layout_leftmargin;
    int layout_rightmargin;
    int layout_indent;
    int layout_leading;
} EditText;
#define FontFlagsHasLayout 0x80
#define FontFlagsShiftJIS 0x40
#define FontFlagsSmallText 0x20
#define FontFlagsANSI 0x10
#define FontFlagsWideOffsets 8
#define FontFlagsWideCodes 4
#define FontFlagsItalic 2
#define FontFlagsBold 1


//swf


//button

//id
int swf_button(int width,int height,ButtonData* b);
//id
int swf_button_last(char* newtext,char* actions);

//font

//id
int swf_font(char* fontname,int font_flags);
//id
int swf_font_basic(char* fontname);

//text

//id
int swf_text(int bound_width,int bound_height,char* variablename,int flags,EditText* structure);

//shape

//id
int swf_shape(int width,int height,int* args);
//id
int swf_shape_basic(int width,int height,int fillcolor,int linecolor);
//id
int swf_shape_bitmap(int bitmapId,int width,int height);
//id
int swf_shape_border(int width,int height,int linesize,int linecolor);
//id
int swf_image(char* imagepath);
//id
int swf_image_ex(char* imagepath,int wh[2]);

//dbl

//id
int swf_dbl(char* imagepath);
//id
int swf_dbl_ex(char* imagepath,int wh[2]);
//width
int swf_dbl_width(char* imagepath);
//height
int swf_dbl_height(char* imagepath);

//back at generic swf functions

void swf_done();
void swf_new(char* path,int width,int height,int backgroundcolor,int fps);
void swf_placeobject(int refid,int depth);
void swf_placeobject_coords(int refid,int depth,int x,int y);
void swf_removeobject(int depth);
void swf_showframe();

//sprite

//id
int swf_sprite_done(int spriteid);
//pre-id
int swf_sprite_new();
void swf_sprite_placeobject(int spriteid,int object,int depth);
void swf_sprite_placeobject_coords(int spriteid,int object,int depth,int x,int y);
void swf_sprite_removeobject(int spriteid,int depth);
void swf_sprite_showframe(int spriteid);

//exports

void swf_exports_add(int id,char* name);
void swf_exports_done();


//action


//this/an action

void action(char* ac);
void actionf(char* buffer,char* format,...);

//action at sprite

void action_sprite(int sprite,char* ac);
void actionf_sprite(int sprite,char* buffer,char* format,...);



//tool

char erbool_get();
void erbool_reset();
void freereset();



#ifdef __cplusplus
}
#endif
