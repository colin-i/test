
#1 prog     2 source dist     3 dists        4 archs
#                             "bionic jammy" "i386 amd"

dists=
arr=(${3})
for var in "${arr[@]}"
do
	dists+=" ${var}"
done
arhs=
arr=(${4})
for var in "${arr[@]}"
do
	arhs+=" ${var}"
done

#from launchpadlib.launchpad import Launchpad
#launchpad = Launchpad.login_with('My Application', 'production', version='devel')
ppa-copy-packages -O colin-i -p ${1} -s ${2} -t ${dists} --architectures ${arhs}
#${@:3}

# --launchpad-instance staging
#cannot login to staging and almost a year has gone

# --architectures   default is        ['i386', 'amd64']     i386 amd64
