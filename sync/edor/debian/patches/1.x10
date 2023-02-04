Description: <short summary of the patch>
 TODO: Put a short summary on the line above and replace this paragraph
 with a longer explanation of this change. Complete the meta-information
 with other relevant fields (see below for details). To make it easier, the
 information below has been extracted from the changelog. Adjust it or drop
 it.
 .
 edor (1-x10) focal; urgency=medium
 .
   * ctrl+e mousemask switch (only when was using termux can use system right click menu same time with mousemask); missing documentation for home/end at command and skip unrestored check
Author: bc <bc@bc-HP-Pavilion-x360-Convertible>

---
The information above should follow the Patch Tagging Guidelines, please
checkout http://dep.debian.net/deps/dep3/ to learn about the format. Here
are templates for supplementary fields that you might want to add:

Origin: <vendor|upstream|other>, <url of original patch>
Bug: <url in upstream bugtracker>
Bug-Debian: https://bugs.debian.org/<bugnumber>
Bug-Ubuntu: https://launchpad.net/bugs/<bugnumber>
Forwarded: <no|not-needed|url proving that it has been forwarded>
Reviewed-By: <name and email of someone who approved the patch>
Last-Update: 2023-01-24

--- edor-1.orig/arh/pub
+++ edor-1/arh/pub
@@ -10,7 +10,7 @@ last=$(curl https://api.github.com/repos
 ~/test/del && \
 ~/test/rel && \
 ~/test/pub appimage rpm rel && \
-~/test/upapp
+~/test/upapp && \
 ~/test/rerpm && \
 ~/test/uprpm && \
 ~/test/pub upapp && \
--- edor-1.orig/s/main.c
+++ edor-1/s/main.c
@@ -150,12 +150,13 @@ static char*helptext;
 static time_t hardtime=0;
 static char*restorefile=nullptr;
 static char restorefile_buf[max_path_0];
+static mmask_t stored_mouse_mask;
 
 #define hel1 "USAGE\n"
-#define hel2 " [filepath]\
+#define hel2 " [filepath] skip_unrestoredfilecheck_flag\
 \nINPUT\
 \nhelp: q(uit),up/down,mouse/touch v.scroll\
-\n[Ctrl/Alt/Shift +]arrows/home/end/del,page up/down,backspace,enter\
+\n[Ctrl/Alt/Shift +]arrows/home/end/del,page up,page down,backspace,enter\
 \np.s.: Ctrl+ left/right/del breaks at white-spaces and (),[]{}\
 \nmouse/touch click and v.scroll\
 \nCtrl+v = visual mode; Alt+v = visual line mode\
@@ -165,20 +166,21 @@ static char restorefile_buf[max_path_0];
 \n    i = indent (I = flow indent)\
 \n    u = unindent (U = flow unindent)\
 \nCtrl+p = paste; Alt+p = paste at the beginning of the row\
-\ncommand mode: left/right,ctrl+q\
+\ncommand mode: left,right,home,end,ctrl+q\
 \nCtrl+s = save file; Alt+s = save file as...\
 \nCtrl+g = go to row[,column]; Alt+g = \"current_row,\" is entered\
 \nCtrl+f = find text; Alt+f = refind text; Ctrl+c = word at cursor (alphanumerics and _); Alt+c = word from cursor\
 \n    if found\
-\n      Enter       = next\
-\n      Space       = previous\
+\n      Enter      = next\
+\n      Space      = previous\
 \n      Left Arrow = [(next/prev)&] replace\
-\n      r           = reset replace text\
-\n      R           = modify replace text\
+\n      r          = reset replace text\
+\n      R          = modify replace text\
 \n    c = cancel\
 \n    other key to return\
 \nCtrl+u = undo; Alt+u = undo mode: left=undo,right=redo,other key to return\
 \nCtrl+r = redo\
+\nCtrl+e = disable/enable internal mouse/touch\
 \nCtrl+q = quit"//29
 static bool visual_bool=false;
 static char*cutbuf=nullptr;
@@ -1868,6 +1870,10 @@ static bool loopin(WINDOW*w){
 				if(restorefile!=nullptr)remove(restorefile);//here restorefile is deleted
 				return false;
 			}
+			else if(strcmp(s,"^E")==0){
+				if(stored_mouse_mask!=0)stored_mouse_mask=mousemask(0,nullptr);
+				else stored_mouse_mask=mousemask(ALL_MOUSE_EVENTS,nullptr);
+			}
 			else type(c,w);
 			//continue;
 		}
@@ -2201,7 +2207,7 @@ static void action(int argc,char**argv,W
 			keypad(w1,true);
 			noecho();
 			nonl();//no translation,faster
-			mousemask(ALL_MOUSE_EVENTS,nullptr);//for error, export TERM=vt100
+			stored_mouse_mask=mousemask(ALL_MOUSE_EVENTS,nullptr);//for error, export TERM=vt100
 			proced(argv[0]);
 			delwin(pw);
 		}
