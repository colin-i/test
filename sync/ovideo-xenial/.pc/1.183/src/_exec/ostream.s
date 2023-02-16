
format elfobj

include "../_include/include.h"

importx "_gtk_init" gtk_init
importx "_gst_init" gst_init
importx "_gtk_main" gtk_main
#importx "_exit" exit

import "initfn" initfn

include "../_dif/difl.s" "../_dif/difw.s"

call gtk_init(0,0)
call gst_init(0,0)

importx "_setlocale" setlocale
call setlocale((LC_NUMERIC),"C") #"English" was ok
#there are 3 sscanf getting the '.'

importx "_g_thread_init" g_thread_init
call g_thread_init(0)

import "gstset" gstset
call gstset()
import "link_mass_remove" link_mass_remove
call link_mass_remove((value_set),0)
import "capture_terminal" capture_terminal
call capture_terminal((value_set),0)
import "sound_preview_bool" sound_preview_bool
sd sound_prev
setcall sound_prev sound_preview_bool()
set sound_prev# 0

call initfn()

call gtk_main()

import "gstunset" gstunset
import "search_clear_memory" search_clear_memory
import "prog_free" prog_free
call gstunset()
call search_clear_memory()
call prog_free()

#normal return no, gtk_main problems (in this context)
include "../_dif/lin.s" "../_dif/win.s"
