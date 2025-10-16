#source ~/test/gdbinit
set debuginfod enabled off
python
import os
if os.getenv("gef"):
	gdb.execute("source /home/bc/.gdbinit-gef.py")
end
