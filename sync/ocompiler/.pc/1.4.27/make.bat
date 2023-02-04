
::use make_win32_fromLin_gnu
exit

md build
o.exe "src/windows/o.s"
move src\windows\o.exe build\
copy .ocompiler.txt build\