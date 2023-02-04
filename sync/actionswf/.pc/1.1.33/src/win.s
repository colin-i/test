
format elfobj64

importx "__iob_func" iob_func

function platform_iob()
#    const STDIN_FILENO=0
#    const STDOUT_FILENO=1
    const STDERR_FILENO=2
    #typedef struct FILE{
        #char *_ptr
        #int _cnt
        #char *_base;
        #int _flag;#int _file;
        #int _charbuf;#int _bufsiz;
        #char *_tmpfname;
    #}
    setcall stderr iob_func()
    const size_of_FILE_noPad=:+DWORD+:+DWORD+DWORD+DWORD+DWORD+:
    const pad_align_calc1=:-1;const pad_align_calc2=~pad_align_calc1;const pad_align_calc3=size_of_FILE_noPad+pad_align_calc1
    const size_of_FILE=pad_align_calc3&pad_align_calc2
    #call add64(#stderr,(STDERR_FILENO*size_of_FILE))
    add stderr (STDERR_FILENO*size_of_FILE)

    return stderr
endfunction
