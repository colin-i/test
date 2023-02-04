
#msvcrt

Import "_realloc" realloc
Import "_free" free
Import "_sprintf" sprintf
Import "_memcpy" memtomem
Import "_memset" memset
Import "_exit" exit

Import "_open" open
Import "_close" close
Import "_read" read
Import "_write" write
Import "_chdir" chdir
Import "_getcwd" getcwd

Import "_lseek" lseek
Import "_strcat" strcat

#kernel32
Import "_GetCommandLineW@0" GetCommandName
Import "_GetTickCount@0" GetTickCount
Import "_GetModuleFileNameA@12" GetModuleFileName

#user32
Import "_MessageBoxA@16" MessageBox

#comdlg32
Import "_GetOpenFileNameA@4" GetOpenFileName

#shell32
Import "_CommandLineToArgvW@8" CommandLineToArgvW
