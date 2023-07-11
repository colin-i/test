
from selenium import webdriver
from selenium.webdriver.common.by import By
import time

driver = webdriver.Firefox()
driver.get("http://miningpoolstats.stream")
coins = driver.find_element(By.ID, 'coins')
print(coins.text)
driver.close()
