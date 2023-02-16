


format elfobj

include "../_include/include.h"

importx "_gtk_box_pack_start" gtk_box_pack_start

#########box
function boxpackstart(data box,data subwidget,data space,data padding)
    call gtk_box_pack_start(box,subwidget,space,space,padding)
endfunction
function packstart(sd box,sd widget,sd space)
    data null=NULL
    call boxpackstart(box,widget,space,null)
endfunction
function packstart_default(sd box,sd widget)
    data null=NULL
    call packstart(box,widget,null)
endfunction


importx "_gtk_alignment_new" gtk_alignment_new
##########alignment
function alignmentfield(data container)
    data gtkwidget#1
    data null=NULL
    data half=126*0x800000
    setcall gtkwidget gtk_alignment_new(half,null,null,null)
    call packstart(container,gtkwidget,null)
    return gtkwidget
endfunction



import "mainwidget" mainwidget

##########dialog
importx "_gtk_widget_destroy" gtk_widget_destroy

function non_modal_destroy(sd dialog,sd response_id,sd forward)
    if forward!=0
        call forward(response_id)
    endif
    call gtk_widget_destroy(dialog)
endfunction

#dialog
function dialogfield_size_button_core(ss title,sd modal_flag,sd forward_init,sd width,sd height,sd button,sd bresponse)
    importx "_gtk_dialog_new_with_buttons" gtk_dialog_new_with_buttons
    sd window
    setcall window mainwidget()

    data end=0
    sd dialog

    sd flags=GTK_DIALOG_DESTROY_WITH_PARENT
    or flags modal_flag
    setcall dialog gtk_dialog_new_with_buttons(title,window,flags,button,bresponse,end)

    importx "_gtk_window_set_default_size" gtk_window_set_default_size
    call gtk_window_set_default_size(dialog,width,height)

    importx "_gtk_dialog_get_content_area" gtk_dialog_get_content_area
    sd vbox
    setcall vbox gtk_dialog_get_content_area(dialog)
    call forward_init(vbox,dialog)

    importx "_gtk_widget_show_all" gtk_widget_show_all
    call gtk_widget_show_all(dialog)

    return dialog
endfunction

function dialog_handle(sd action,sd value)
    data dialog#1
    if action==(value_set)
        set dialog value
    else
        return dialog
    endelse
endfunction

#return: dialog(nonmodal case)
function dialogfield_size_button(ss title,sd modal_flag,sd forward1,sd forward2,sd width,sd height,sd button,sd bresponse)
    sd dialog
    setcall dialog dialogfield_size_button_core(title,modal_flag,forward1,width,height,button,bresponse)
    call dialog_handle((value_set),dialog)

    if modal_flag==(GTK_DIALOG_MODAL)
    #modal dialog
        importx "_gtk_dialog_run" gtk_dialog_run
        sd response
        setcall response gtk_dialog_run(dialog)

        if response==(GTK_RESPONSE_OK)
            if forward2!=0
                call forward2()
            endif
        endif
        call gtk_widget_destroy(dialog)
    else
    #non-modal dialog
        sd fn^non_modal_destroy
        import "connect_signal_data" connect_signal_data
        str resp="response"
        call connect_signal_data(dialog,resp,fn,forward2)
        return dialog
    endelse
endfunction

#return: dialog(nonmodal case)
function dialogfield_size(ss title,sd modal_flag,sd forward1,sd forward2,sd width,sd height)
    str GTK_STOCK_OK="gtk-ok"
    data responseok=GTK_RESPONSE_OK
    sd dialog
    setcall dialog dialogfield_size_button(title,modal_flag,forward1,forward2,width,height,GTK_STOCK_OK,responseok)
    return dialog
endfunction

function dialogfield(ss title,sd modal_flag,sd forward1,sd forward2)
    data default=-1
    sd dialog
    setcall dialog dialogfield_size(title,modal_flag,forward1,forward2,default,default)
    return dialog
endfunction
#true to not propagate
function dialogfield_modal_texter_expose(sd widget)
    import "draw_expose_text" draw_expose_text
    sd txt
    setcall txt dialogfield_modal_texter_drawtext((value_get))
    call draw_expose_text(widget,txt)
    return (TRUE)
endfunction
const modal_texter_draw_data_size=100
import "cpymem" cpymem
import "slen" slen
function dialogfield_modal_texter_drawtext(sd procedure,sd text)
    chars text_data#modal_texter_draw_data_size
    str strtext^text_data
    if procedure==(value_set)
        sd len
        setcall len slen(text)
        inc len
        call cpymem(strtext,text,len)
    else
        return strtext
    endelse
endfunction
#
const modal_texter_parentdialog_width=500
#dialogfield_modal_texter
data forward_init#1
const p_forward_init^forward_init
function dialogfield_modal_texter_init(sd vbox,sd dialog)
    #Text
    import "drawfield" drawfield
    import "connect_signal" connect_signal
    sd draw
    setcall draw drawfield(vbox)
    ss txt
    setcall txt dialogfield_modal_texter_drawtext((value_get))
    #it's not ok to access at the same time txt[modal_texter_draw_data_size] by threads but it's no problem
    import "setmemzero" setmemzero
    call setmemzero(txt,(modal_texter_draw_data_size))
    call dialog_modal_texter_drawwidget((value_set),draw)
    #
    str expose="expose-event"
    data exp^dialogfield_modal_texter_expose
    call connect_signal(draw,expose,exp)
    #
    importx "_gtk_widget_set_size_request" gtk_widget_set_size_request
    call gtk_widget_set_size_request(draw,(modal_texter_parentdialog_width-20),40)

    #call the main init
    sd p%p_forward_init
    if p#!=0
        sd forward_init
        set forward_init p#
        call forward_init(vbox,dialog)
    endif

    #add the new texter
    import "new_texter_modal" new_texter_modal
    call new_texter_modal(vbox,dialog)
endfunction
function dialog_modal_texter_drawwidget(sd action,sd value)
    data drawwidget#1
    if action==(value_set)
        set drawwidget value
    else
        return drawwidget
    endelse
endfunction
function dialog_modal_texter_draw(ss text)
    sd widget
    setcall widget dialog_modal_texter_drawwidget((value_get))
    if widget!=0
        call dialogfield_modal_texter_drawtext((value_set),text)
        importx "_gdk_threads_add_timeout" gdk_threads_add_timeout
        #the drawing commands must be called from the main thread or sometimes will crash
        data f^dialog_modal_texter_draw_main_thread
        call gdk_threads_add_timeout(0,f,0)
    endif
endfunction
#FALSE=stop timeout
function dialog_modal_texter_draw_main_thread(sd *data)
    sd widget
    setcall widget dialog_modal_texter_drawwidget((value_get))
    if widget!=0
        import "widget_redraw" widget_redraw
        importx "_gtk_widget_get_window" gtk_widget_get_window
        call widget_redraw(widget)
        sd window
        setcall window gtk_widget_get_window(widget)
        if window!=0
            importx "_gdk_window_process_updates" gdk_window_process_updates
            call gdk_window_process_updates(window,(FALSE))
        endif
    endif
    return (FALSE)
endfunction

#void
function dialogfield_modal_texter_core(ss title,sd forward_init,ss buttontext)
    sd p%p_forward_init
    set p# forward_init
    data init^dialogfield_modal_texter_init
    sd dialog
    setcall dialog dialogfield_size_button_core(title,(GTK_DIALOG_MODAL),init,(modal_texter_parentdialog_width),-1,buttontext,(GTK_RESPONSE_CANCEL))
    return dialog
endfunction
#void
#function dialogfield_modal_texter(ss title,sd forward_init,ss buttontext)
#    sd dialog
#    setcall dialog dialogfield_modal_texter_core(title,forward_init,buttontext)
#    call gtk_dialog_run(dialog)
#    call gtk_widget_destroy(dialog)
#endfunction
function dialogfield_modal_texter_sync(ss title,sd forward_init,ss buttontext,sd global_flag,sd stop_flag)
    sd dialog
    setcall dialog dialogfield_modal_texter_core(title,forward_init,buttontext)
    call gtk_dialog_run(dialog)
    while global_flag#==1
        import "sleepMs" sleepMs
        set stop_flag# 1
        call sleepMs(500)
    endwhile
    call gtk_widget_destroy(dialog)
endfunction

##########eventbox

importx "_gtk_container_add" gtk_container_add
import "container_add" container_add

importx "_gtk_event_box_new" gtk_event_box_new
function eventboxfield(sd box)
    sd wid
    setcall wid gtk_event_box_new()
    call packstart_default(box,wid)
    return wid
endfunction
function eventboxfield_cnt(sd box)
    sd wid
    setcall wid gtk_event_box_new()
    call container_add(box,wid)
    return wid
endfunction

##########file chooser
#file/null
function file_chooser_get_filename(sd dialog)
    import "file_chooser_get_fname" file_chooser_get_fname
    ss file
    setcall file file_chooser_get_fname(dialog)
    data z=0
    if file==z
        str er="Dialog file name representation error."
        import "texter" texter
        call texter(er)
        return z
    endif
    return file
endfunction

#dialog
function filechooserfield_core()
    str open_file="Open File"
    sd main
    setcall main mainwidget()
    data open=GTK_FILE_CHOOSER_ACTION_OPEN
    str GTK_STOCK_CANCEL="gtk-cancel"
    data responsecancel=GTK_RESPONSE_CANCEL
    str GTK_STOCK_OPEN="gtk-open"
    data null=0
    importx "_gtk_file_chooser_dialog_new" gtk_file_chooser_dialog_new
    sd dialog
    setcall dialog gtk_file_chooser_dialog_new(open_file,main,open,GTK_STOCK_CANCEL,responsecancel,GTK_STOCK_OPEN,(GTK_RESPONSE_ACCEPT),null)
    return dialog
endfunction

importx "_g_free" g_free

#0/filename, must be freed
function filechooserfield()
    sd dialog
    setcall dialog filechooserfield_core()
    sd filename
    setcall filename filechooserfield_dialog(dialog)
    return filename
endfunction

function filechooserfield_dialog(sd dialog)
    sd filename
    set filename 0

    sd resp
    setcall resp gtk_dialog_run(dialog)
    if resp==(GTK_RESPONSE_ACCEPT)
        ss file
        setcall file file_chooser_get_filename(dialog)
        if file!=0
            import "memrealloc" memrealloc
            sd len
            setcall len slen(file)
            inc len
            setcall filename memrealloc(0,len)
            if filename==0
                call g_free(file)
                return filename
            endif
            call cpymem(filename,file,len)

            call g_free(file)
        endif
    endif
    call gtk_widget_destroy(dialog)
    return filename
endfunction

function filechooserfield_forward(sd forward)
    sd dialog
    setcall dialog filechooserfield_core()
    sd resp
    setcall resp gtk_dialog_run(dialog)
    if resp==(GTK_RESPONSE_ACCEPT)
        ss file
        setcall file file_chooser_get_filename(dialog)
        if file!=0
            call forward(file)
            call g_free(file)
        endif
    endif
    call gtk_widget_destroy(dialog)
endfunction

#fchooserbuttonfield
function fchooserbuttonfield_open(sd container,ss dialogtext)
    importx "_gtk_file_chooser_button_new" gtk_file_chooser_button_new
    sd fchooser
    setcall fchooser gtk_file_chooser_button_new(dialogtext,(GTK_FILE_CHOOSER_ACTION_OPEN))
    call packstart(container,fchooser,(TRUE))
    return fchooser
endfunction

#fchooserbuttonfield
function fchooserbuttonfield_open_label(sd container,ss dialog_label_text)
    sd hbox
    setcall hbox hboxfield_label(container,dialog_label_text)
    sd fchooser
    setcall fchooser fchooserbuttonfield_open(hbox,dialog_label_text)
    return fchooser
endfunction

##########frame
function framefield(sd box,ss text)
    importx "_gtk_frame_new" gtk_frame_new
    sd frame
    setcall frame gtk_frame_new(text)
    if box!=0
        call packstart_default(box,frame)
    endif
    return frame
endfunction

importx "_gtk_hbox_new" gtk_hbox_new
##########hbox
function hboxfield_prepare()
    data gtkwidget#1
    data null=0
    setcall gtkwidget gtk_hbox_new(null,null)
    return gtkwidget
endfunction
function hboxfield_pack_pad(data container,data padding)
    data gtkwidget#1
    setcall gtkwidget hboxfield_prepare()
    data null=0
    call boxpackstart(container,gtkwidget,null,padding)
    return gtkwidget
endfunction
function hboxfield_cnt(data container)
    data gtkwidget#1
    setcall gtkwidget hboxfield_prepare()
    call container_add(container,gtkwidget)
    return gtkwidget
endfunction

#hbox
function hboxfield_label(sd box,ss text)
    sd hbox
    setcall hbox hboxfield_cnt(box)
    import "labelfield_left_default" labelfield_left_default
    call labelfield_left_default(text,hbox)
    return hbox
endfunction


##############scroll
function scrollfield(sd container)
    importx "_gtk_scrolled_window_new" gtk_scrolled_window_new
    data null=0
    sd scroll
    setcall scroll gtk_scrolled_window_new(null,null)
    call gtk_container_add(container,scroll)
    return scroll
endfunction





importx "_gtk_table_new" gtk_table_new
##########table
function tablefield(sd bag,sd row,sd col)
    sd widget
    data false=0
    setcall widget gtk_table_new(row,col,false)
    call container_add(bag,widget)
    return widget
endfunction
importx "_gtk_table_attach_defaults" gtk_table_attach_defaults
function table_attach(sd table,sd cell,sd x,sd y)
    sd next_x
    sd next_y
    set next_x x
    set next_y y
    inc next_x
    inc next_y
    call gtk_table_attach_defaults(table,cell,x,next_x,y,next_y)
endfunction

importx "_gtk_table_resize" gtk_table_resize
importx "_gtk_table_get_size" gtk_table_get_size

#returns the row pointer for use at the next row, allCol false case use only
function table_add_row_allCol(sd table,sd row,sd allCol)
    sd rows
    sd columns
    sd ptr_rows^rows
    sd ptr_columns^columns

    call gtk_table_get_size(table,ptr_rows,ptr_columns)
    sd lastrow
    set lastrow rows
    inc rows
    call gtk_table_resize(table,rows,columns)

    data true=1
    data false=0
    data dword=4
    data firstcol=1

    sd c=0
    sd col
    if allCol==true
        set col columns
    else
        set col firstcol
    endelse
    sd add
    set add true
    while add==true
        if row#!=0
            call gtk_table_attach_defaults(table,row#,c,col,lastrow,rows)
        endif
        add row dword
        if col!=columns
            inc c
            inc col
        else
            set add false
        endelse
    endwhile
    return row
endfunction

function table_add_row(sd table,sd row)
    data true=1
    sd ptr_row^row
    call table_add_row_allCol(table,ptr_row,true)
endfunction

#returns the cells pointer that may points to the next block
function table_add_cells(sd table,sd row,sd cells)
    data false=0
    sd i=0
    while i!=row
        setcall cells table_add_row_allCol(table,cells,false)
        inc i
    endwhile
    return cells
endfunction

#first 3 arguments for tablefield, widgets arg has rows*cols child cell widgets
function tablefield_cells(sd bag,sd row,sd col,sd cells)
    sd widget
    #0,but goes 1, then first row is lost
    setcall widget tablefield(bag,0,col)
    call table_add_cells(widget,row,cells)
    return widget
endfunction

function tablefield_row(sd bag,sd col,sd cells)
    sd widget
    #0,but goes 1, then first row is lost
    setcall widget tablefield(bag,0,col)
    call table_add_row(widget,cells)
    return widget
endfunction





#############vbox
importx "_gtk_vbox_new" gtk_vbox_new
#gtkwidget
function vboxfield(data container)
    data gtkwidget#1
    data null=NULL

    setcall gtkwidget gtk_vbox_new(null,null)

    call gtk_container_add(container,gtkwidget)
    return gtkwidget
endfunction

function vboxfield_pack(sd container)
    data gtkwidget#1
    data null=NULL

    setcall gtkwidget gtk_vbox_new(null,null)

    call packstart(container,gtkwidget,null)
    return gtkwidget
endfunction
