
while :
 do
 if [ -n "${3}" ]; then
  a=`sensors -j | jq '."'${1}'"."'"${2}"'"."temp'${3}'_input"'`
 else
  a=`sensors -j | jq '."'${1}'"."temp'${2}'_input"'`
 fi
 echo ${a}
 sleep 20
done
