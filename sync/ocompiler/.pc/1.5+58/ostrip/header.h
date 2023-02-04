
include "../src/files/headers/strip.h"

const EXIT_SUCCESS=0
const EXIT_FAILURE=1
const NULL=0

Const SEEK_SET=0
Const SEEK_CUR=1
Const SEEK_END=2

const ET_REL=1
const ET_EXEC=2
const EM_X86_64=62

const F_OK=0


Importx "stderr" stderr
Importx "stdout" stdout

Importx "fprintf" fprintf
Importx "fopen" fopen
Importx "fread" fread
importx "fclose" fclose
Importx "fseek" fseek
Importx "ftell" ftell
Importx "fwrite" fwrite

Importx "memcmp" memcmp
importx "malloc" malloc
importx "free" free
importx "access" access

importx "strcmp" strcmp
importx "strlen" strlen
importx "sscanf" sscanf
importx "sprintf" sprintf


const asciiE=0x45
const asciiF=0x46
const asciiL=0x4C
const asciiDEL=0x7F

const section_nr_of_values=2    ;#*2 for size

const charsize=1

const verbose_count=0
const verbose_flush=-1
