
while :
 do
 if [ -n "${3}" ]; then
  sensors -j | jq '."${1}"."${2}"."temp${3}_input"' > ~/n/temp/a
 else
  sensors -j | jq '."${1}"."temp${2}_input"' > ~/n/temp/a
 fi
 a=20
 echo ${a}
 sleep ${a}
done
