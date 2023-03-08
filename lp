
#optional   1 (bool for query last tar)/0   2 tars

if [ -z "${2}" ] ||  [ "${1}" = "0" ]; then
	dist=`cat debian/changelog | head -1 | grep -o -e "[^ ]*;"`
	dist=${dist::-1}
fi

if [ -z "${2}" ]; then
	if [ "${dist}" = "xenial" ]; then
		tars="bionic focal jammy kinetic lunar"
	elif [ "${dist}" = "bionic" ]; then
		tars="focal jammy kinetic lunar"
	elif [ "${dist}" = "focal" ]; then
	#impish
		tars="jammy kinetic lunar"
	elif [ "${dist}" = "jammy" ]; then
		tars="kinetic lunar"
	elif [ "${dist}" = "kinetic" ]; then
		tars="lunar"
	else
		exit 0
	fi
else
	tars=${2}
fi

echo $tars

if [ -z "${1}" ] || [ "${1}" = "0" ]; then
	prog=( `cat debian/control | grep "^Package" | grep -o [^\ ]*$ | xargs`)

	i=1
	for p in "${prog[@]}"; do
		raw=( `cat debian/control | grep -Poe "(?<=^Architecture: ).*" | sed -n ${i}p` )
		arhs=
		for var in "${raw[@]}"
		do
			if [ "${var}" = "all" ]; then
				var=amd64
			fi
			arhs+=" ${var}"
		done
		echo $p $dist $arhs
		ppa-copy-packages -O colin-i -p ${p} -s ${dist} -t ${tars} --architectures ${arhs}
		i=$((i+1))
	done
else
	#if [ "${1}" = "x" ]; then
	t=`echo -n ${tars} | grep -o '[^ ]*$'`
	~/test/publp2 ${t}
fi




#1 prog     2 source dist     3 dists        4 archs
#                             a b            a,b
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
