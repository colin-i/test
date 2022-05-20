

#from launchpadlib.launchpad import Launchpad
#launchpad = Launchpad.login_with('My Application', 'production', version='devel')
ppa-copy-packages -O colin-i -s {2} -t ${@:3} -p ${1}

# --launchpad-instance staging
#cannot login to staging and almost a year has gone

# --architectures   default is        ['i386', 'amd64']     i386 amd64
