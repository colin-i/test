
#1 prog     2 source dist     3 dists        4 archs
#                             "bionic jammy" "i386 amd"

#from launchpadlib.launchpad import Launchpad
#launchpad = Launchpad.login_with('My Application', 'production', version='devel')
ppa-copy-packages -O colin-i -p ${1} -s ${2} -t ${3} --architectures ${4}
#${@:3}

# --launchpad-instance staging
#cannot login to staging and almost a year has gone

# --architectures   default is        ['i386', 'amd64']     i386 amd64
