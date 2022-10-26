
#optional   1 bool for query last tar

prog=`cat debian/changelog | head -1 | grep -o -e "^[^ ]*"`

dist=`cat debian/changelog | head -1 | grep -o -e "[^ ]*;"`
dist=${dist::-1}

if [ "${dist}" = "xenial" ]; then
	tars="bionic focal jammy"
elif [ "${dist}" = "bionic" ]; then
	tars="focal jammy"
else
#if [ "${dist}" = "focal" ]; then
#if [ "${dist}" = "impish" ]; then
	tars="jammy"
fi

raw=`cat debian/control | grep -Poe "(?<=^Architecture: ).*"`
raw=( ${raw} )
for var in "${raw[@]}"
do
	if [ "${var}" = "all" ]; then
		var=amd64
	fi
	arhs+=" ${var}"
done

echo $prog $dist $tars $arhs

#1 prog     2 source dist     3 dists        4 archs
#                             bionic jammy   i386,amd64
#dests=( ${@:3} )
#arhs=${dests[-1]}
#unset dests[-1]
#arhs=${arhs//,/ }
#tars=
#for var in "${dests[@]}"
#do
#	tars+=" $var"
#done

#from launchpadlib.launchpad import Launchpad
#launchpad = Launchpad.login_with('My Application', 'production', version='devel')

# --launchpad-instance staging
#cannot login to staging and almost a year has gone

# --architectures   default is        ['i386', 'amd64']     i386 amd64

if [ -z "${1}" ]; then
	ppa-copy-packages -O colin-i -p ${prog} -s ${dist} -t ${tars} --architectures ${arhs}
else
	t=`echo -n ${tars} | grep -o '[^ ]*$'`
	~/test/publp2 ${t}
fi
