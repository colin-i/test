

#files
Set fileout negative
set logfile negative

#containers initialisations
Data containersptr%containersbegin
Data containerssize=containerssize

Call memset(containersptr,null,containerssize)

Set allocerrormsg null

set safecurrentdirtopath (NULL)

call initpreferences()
