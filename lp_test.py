

from launchpadlib.launchpad import Launchpad

import sys

PPAOWNER = "colin-i"
PPA = sys.argv[1]

cachedir = "~/.launchpadlib/cache/"
lp_ = Launchpad.login_anonymously('ppastats', 'production', cachedir)
owner = lp_.people[PPAOWNER]
archive = owner.getPPAByName(name=PPA)

bs=archive.getBuildRecords()
for b in bs:
	if b.source_package_name==sys.argv[2] and b.source_package_version==sys.argv[3]:
		print(b.buildstate)
		print(b.build_log_url)
		break
