
#in case is month:  1 year  2 month

from=`cat prevdate`
to=`cat date`

#with / for multiple cd later
start=`pwd`/

cd $(dirname $(readlink date))

commits=`cat hh2`
totalplus=`cat hh3`
totalminus=`cat hh4`
total=`cat hh5`

readarray -t data <<<"$(cat h6 | head -n3)"

cd ${start}


#bold text
#https://mothereff.in/twitalics
#They may not even show up at all, depending on your operating system and the fonts you have installed

out=message

datecalc () {
	time=${1}
	tm=`date -u -d @${time} +%_S`
	if [ ${tm} != "0" ]; then
		time=$(date -u -d @${time} -Is)
		return
	fi
	tm=`date -u -d @${time} +%_M`
	if [ ${tm} != "0" ]; then
		time=$(date -u -d @${time} -Im)
		return
	fi
	tm=`date -u -d @${time} +%_H`
	if [ ${tm} != "0" ]; then
		time=$(date -u -d @${time} -Ih)
		return
	fi
	tm=`date -u -d @${time} +%_d`
	if [ ${tm} != "1" ]; then
		time=$(date -u -d @${time} -I)
		return
	fi
	tm=`date -u -d @${time} +%_m`
	if [ ${tm} != "1" ]; then
		time=$(LANG=en_us_88591; date -u -d @${time} '+%B %Y')
		return
	fi
	time=$(date -u -d @${time} '+%Y')
}

echo -e "https://github.com/colin-i\n">${out}

if [ $((to-from)) -gt 31622400 ]; then  #greater than 366 days, this is all time
	echo -n "From ">>${out}
	datecalc ${from}
	echo -n "${time} until ">>${out}
	datecalc ${to}
	echo -n "${time} ">>${out}
else
	#month
	echo -n "In $(LANG=en_us_88591; date -u -d @${from} '+%B %Y') ">>${out}
	more_data=1
fi
echo "I made $(echo -n ${commits}) commits.">>${out}
echo -n "The number of rows was">>${out}
echo -n " increased by">>${out}
echo " ${total} (${totalplus} added, ${totalminus} removed).">>${out}
echo "Projects' top 3:">>${out}
n="${#data[@]}"
i=1
for var in "${data[@]}"
do
	ar=( ${var} )
	if [ ${n} != ${i} ]; then
		#at the moment, tabs are displaying in tweet editor but not on the final tweet, and are counted in tweet editor
		#echo -e "\t"
		echo " ${ar[0]} ${ar[1]} (+${ar[2]} -${ar[3]})">>${out}
		i=$((i+1))
	else
		echo -n " ${ar[0]} ${ar[1]} (+${ar[2]} -${ar[3]})">>${out}
	fi
done

if [ "${more_data}" != "" ]; then
	y=${1}
	m=${2}

	#store current state in case something bad happens
	if [ "${m}" = "1" ]; then
		cd $((y-1))/12
	else
		cd ${y}/$((m-1))
	fi
	#mkdir arh
	#if [ "$?" = "0" ]; then
	if ! [ -f "arh" ]; then
		touch arh
		#to allow message modifications without concat
		#cd arh
		#cp ${start}h .
		#cp ${start}h2 .
		#cp ${start}h3 .
		#cp ${start}h4 .
		#cd ..
		#add at commit time git add arh
		cd ${start}
		./concat ${y}/${m}
	else
		echo no concat
		cd ${start}
	fi

	./gh .
	echo -ne "\n\nAll time: `cat hh2` commits, `cat hh5` rows (+`cat hh3`, -`cat hh4`).">>${out}
fi

cat ${out}
cat ${out} | xclip -selection clipboard
#twitter will see \n (maybe \r too) like one or two rows in a strange algorithm, must edit there
rm ${out}
