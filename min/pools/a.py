
from selenium import webdriver
import time

driver = webdriver.Firefox()
driver.get("http://miningpoolstats.stream")
time.sleep(20)
driver.close()
