
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.by import By

service = Service('/usr/bin/geckodriver')
opts = Options()
opts.add_argument("--width=1333")
opts.add_argument("--height=777")

driver = webdriver.Firefox(service=service,options=opts)
action = ActionBuilder(driver)

driver.get("https://cestrin.maps.arcgis.com/apps/webappviewer/index.html?id=210f9dcdbeaf48349e3ed19e92ee2f19")
info=driver.find_element(By.TAG_NAME, 'body')

info.find_element(By.CLASS_NAME,"jimu-checkbox").click()
info.find_element(By.CLASS_NAME,"jimu-btn").click()

#action.pointer_action.move_to_location(600, 500)
#action.pointer_action.click()
#action.perform()
#info.text
