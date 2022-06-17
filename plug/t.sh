
while :
   do
   sensors -j coretemp-isa-0000 > ~/n/temp/a
   a=20
   echo ${a}
   sleep ${a}
done
