
#1 prog     2 source dist     3 dists        4 archs
#                             bionic jammy   i386,amd64

dests=( ${@:3} )
arhs=${dests[-1]}
unset dests[-1]
arhs=${arhs//,/ }
tars=
for var in "${dests[@]}"
do
	tars+=" $var"
done

#from launchpadlib.launchpad import Launchpad
#launchpad = Launchpad.login_with('My Application', 'production', version='devel')
ppa-copy-packages -O colin-i -p ${1} -s ${2} -t ${tars} --architectures ${arhs}
#

# --launchpad-instance staging
#cannot login to staging and almost a year has gone

# --architectures   default is        ['i386', 'amd64']     i386 amd64
