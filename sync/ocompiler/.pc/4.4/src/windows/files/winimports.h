Library "msvcrt.dll"

Include "../../files/_/cimports.h"

Import "_open" open
Import "_close" close
Import "_read" read
Import "_write" write
Import "_chdir" chdir
Import "_getcwd" getcwd

Import "_lseek" lseek
Import "strcat" strcat

Library "kernel32.dll"
Import "GetCommandLineA" GetCommandName
Import "GetTickCount" GetTickCount
Import "GetModuleFileNameA" GetModuleFileName

Library "user32.dll"
Import "MessageBoxA" MessageBox

Library "comdlg32.dll"
Import "GetOpenFileNameA" GetOpenFileName