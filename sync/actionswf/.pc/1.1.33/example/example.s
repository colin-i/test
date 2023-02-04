format elfobj64

importx "sprintf" sprintf

#a simple shape moving on the stage example

warning off
include "../dev/import.h"
warning on

const width=640
const height=480

const shape_lat=40

####################
entry example_main()

call swf_new("example.swf",(width),(height),0x001100,24)

sd shape
setcall shape swf_shape_basic((shape_lat),(shape_lat),0xffeeFEff,0x11FF22ff)

sd movie_preid
setcall movie_preid swf_sprite_new()

call swf_sprite_placeobject(movie_preid,shape,1)
call swf_sprite_showframe(movie_preid)

chars data#512
str ac^data
str vars="var move=20;var width=%u;var height=%u;var lat=%u;var left=move;var top=move;var right=width-lat-move;var bottom=height-lat-move"
call sprintf(ac,vars,(width),(height),(shape_lat))
call action_sprite(movie_preid,ac)

call action_sprite(movie_preid,"
if(this._x>=right)_root.x_coef=_root.x_coef*-1;
else if(this._x<=left)_root.x_coef=_root.x_coef*-1;
this._x=move*_root.x_coef+this._x;
if(this._y>=bottom)_root.y_coef=_root.y_coef*-1;
else if(this._y<=top)_root.y_coef=_root.y_coef*-1;
this._y=move*_root.y_coef+this._y;
")
call swf_sprite_showframe(movie_preid)
sd movie
setcall movie swf_sprite_done(movie_preid)

call swf_exports_add(movie,"movie")
call swf_exports_done()

call action("
var x_coef=1;
var y_coef=1;
this.attachMovie('movie','_movie',1);
_movie._x=100;
_movie._y=100;
")

call swf_showframe()
call swf_done()
exit 0
