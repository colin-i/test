
#this is not right but is the only way to show gameplays
wget https://www.kongregate.com/accounts/bitplayer/favorites?sort=gameplays -O 1
wget "https://www.kongregate.com/accounts/bitplayer/favorites?sort=gameplays&srid=17" -O 2

./k2
if [ $? = 0 ]; then
	xmllint --html --xpath '/html/body/div[@id="primarywrap"]/table/tr/td[@class="maincontent"]/div[@id="feature"]/div[@class="browser_outer"]/div[@class="category_listing"]/div[@class="category_games_listing hasLayout"]/div/div/div/span/span[@class="gameplays"]/text()' 1 2>/dev/null 1>3
	xmllint --html --xpath '/html/body/div[@id="primarywrap"]/table/tr/td[@class="maincontent"]/div[@id="feature"]/div[@class="browser_outer"]/div[@class="category_listing"]/div[@class="category_games_listing hasLayout"]/div/div/div/span/span[@class="gameplays"]/text()' 2 2>/dev/null 1>4
	echo $((`paste -s -d+ 3 | bc`+`paste -s -d+ 4 | bc`)) > 5
	a=`cat kong`
	b=`cat 5`
	c=$((b-a))
	echo ${b} - ${a} = ${c}

	echo -e "\n\nok? y ?" && \
	read -n1 -t $((60*60*24)) ans && \
	if [ "${ans}" = "y" ]; then
		rm 1
		rm 2
		rm 3
		rm 4
		mv 5 kong
	else
		echo no
	fi
fi
