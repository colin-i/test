


Importx "realloc" realloc
Importx "free" free
Importx "sprintf" sprintf
Importx "memcpy" memtomem
Importx "memset" memset
Importx "exit" exit

Importx "_open" open
Importx "_close" close
Importx "_read" read
Importx "_write" write
Importx "_chdir" chdir
Importx "_getcwd" getcwd

Importx "_lseek" lseek
Importx "strcat" strcat

#kernel32
Importx "GetCommandLineW" GetCommandName
Importx "GetTickCount" GetTickCount
Importx "GetModuleFileNameA" GetModuleFileName

#user32
Importx "MessageBoxA" MessageBox

#comdlg32
Importx "GetOpenFileNameA" GetOpenFileName

#shell32
ImportX "CommandLineToArgvW" CommandLineToArgvW
