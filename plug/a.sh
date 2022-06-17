
python a.py ${1} &
lastpid=$!
$(dd bs=1 count=1 2>/dev/null)
kill -s 9 ${lastpid}
