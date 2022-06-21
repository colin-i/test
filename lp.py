
from launchpadlib.launchpad import Launchpad

import sys

PPAOWNER = "colin-i"
PPA = sys.argv[1]
desired_dist_and_arch = "https://api.launchpad.net/devel/ubuntu/"+sys.argv[2]+"/"+sys.argv[3]

cachedir = "~/.launchpadlib/cache/"
lp_ = Launchpad.login_anonymously('ppastats', 'production', cachedir)
owner = lp_.people[PPAOWNER]
archive = owner.getPPAByName(name=PPA)

bs=archive.getPublishedBinaries(distro_arch_series=desired_dist_and_arch)
for b in bs:
	if b.binary_package_name==sys.argv[4] and b.binary_package_version==sys.argv[5]:
		if len(sys.argv)>6:
			print(b.status)
		#must not get  Superseded Deleted or Obsolete only Pending Published
		print(b.build_link)
		break
