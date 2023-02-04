

include "../../files/_/cimports.h"

Import "_open" open
Import "_close" close
Import "_read" read
Import "_write" write
Import "_chdir" chdir
Import "_getcwd" getcwd

Import "_lseek" lseek
Import "strcat" strcat

#kernel32
Import "GetCommandLineA" GetCommandName
Import "GetTickCount" GetTickCount
Import "GetModuleFileNameA" GetModuleFileName

#user32
Import "MessageBoxA" MessageBox

#comdlg32
Import "GetOpenFileNameA" GetOpenFileName