
#optional   1 (bool for query last tar)/0   2 tars

if [ -z "${2}" ] ||  [ "${1}" = "0" ]; then
	if [ -z "${dist}" ]; then
		dist=`cat debian/changelog | head -1 | grep -Poe "[^ ]*(?=;)"`
	fi
fi

if [ -z "${2}" ]; then
	if [ "${dist}" = "xenial" ]; then
	#2026-04-23
		tars="bionic focal jammy noble"
	elif [ "${dist}" = "bionic" ]; then
	#2023-05-31 Must run on the oldest still-supported Ubuntu LTS release
		tars="focal jammy noble"
	elif [ "${dist}" = "focal" ]; then
	#"impish is obsolete and will not accept new uploads."
		tars="jammy noble"
	elif [ "${dist}" = "jammy" ]; then
		tars="noble"
	#mantic 2024-07-11
	else
		exit 1
	fi
else
	tars=${2}
fi

echo $tars

if [ -z "${1}" ] || [ "${1}" = "0" ]; then
	p=`cat debian/changelog | head -1 | grep -o -e "^[^ ]*"`

#this will wrong, for example: lunar, jammy, jammy->kinetic, mantic will go with jammy, there is syncSources from 1.0 there
#ubuntu-archive-tools will use devel and will do right
#	#source name is enough
#	#prog=( `cat debian/control | grep "^Package" | grep -o [^\ ]*$ | xargs` )
#	i=1
#	#for p in "${prog[@]}"; do
#	raw=( `cat debian/control | grep -Poe "(?<=^Architecture: ).*" | sed -n ${i}p` )
#	arhs=
#	for var in "${raw[@]}"
#	do
#		if [ "${var}" = "all" ]; then
#			var=amd64
#		fi
#		arhs+=" ${var}"
#	done
#	echo $p $dist $arhs
#	ppa-copy-packages -O colin-i -p ${p} -s ${dist} -t ${tars} --architectures ${arhs}
#	#	i=$((i+1))
#	#done

	for destin in ${tars}; do
		# and with ubuntu-dev-tools
		~/u/desktop/ubuntu-archive-tools/copy-package -y --include-binaries --from ppa:colin-i/ubuntu/ppa -s ${dist} --to-suite ${destin} ${p} || exit 1
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

#find -name "*o" -exec echo {} \;
