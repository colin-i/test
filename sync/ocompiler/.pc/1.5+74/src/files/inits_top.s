

#files
Set fileout negative
set logfile negative

#containers initialisations
Data containersptr%containersbegin
Data containerssize=containerssize

#for reg and for freeings
Call memset(containersptr,null,containerssize)

Set allocerrormsg null

set safecurrentdirtopath (NULL)

call initpreferences()

set stackalign (NULL)
set scopesbag (NULL)
