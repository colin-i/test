
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys

driver = webdriver.Firefox()
driver.get("http://miningpoolstats.stream")
coins = driver.find_element(By.ID, 'coins')

#sort by pools
elem=coins.find_element(By.TAG_NAME,'thead').find_element(By.TAG_NAME,'tr').find_element(By.CLASS_NAME,'show1150')
elem.send_keys(Keys.RETURN)

with open("a.txt","w") as f:
	f.write(coins.text)
driver.close()
