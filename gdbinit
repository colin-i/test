#source /home/bc/test/gdbinit
set debuginfod enabled off
python
import os
if os.getenv("gef"):
	gdb.execute("source /home/bc/.gdbinit-gef.py")
else:
	print("no gef. gef can come in at 'sudo env gef=x'")
end
