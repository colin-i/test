
import os

recs=[[1087,554,"A0_3"]]
#bottom-left switch for watermark
# action.pointer_action.move_to_location(,);action.pointer_action.click();action.perform()
#with open(os.environ["HOME"]+"/measures/list","wb") as file:
#	for r in recs:
#		file.write(r[2])
#exit()

from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.by import By
import readchar

service = Service('/usr/bin/geckodriver')
opts = Options()
opts.add_argument("--width=1333")
opts.add_argument("--height=777")

driver = webdriver.Firefox(service=service,options=opts)
action = ActionBuilder(driver)

driver.get("https://cestrin.maps.arcgis.com/apps/webappviewer/index.html?id=210f9dcdbeaf48349e3ed19e92ee2f19")
info=driver.find_element(By.TAG_NAME, 'body')

readchar.readchar() #next is async

info.find_element(By.ID,"jimu_dijit_CheckBox_0").click()
#this was working at first try: By.CLASS_NAME,"jimu-checkbox" ele.click()
#now: Element  is not clickable at point  because another element  obscures it ? driver.execute_script("arguments[0].click();", element) . but is another checkbox
# for searching: with open('q','w') as f: f.write(driver.page_source)

info.find_element(By.CLASS_NAME,"jimu-btn").click()

def click(x,y):
	action.pointer_action.move_to_location(x,y);action.pointer_action.click();action.perform()
	readchar.readchar() #async

for r in recs:
	click(r[0],r[1]) #to load for write
	with open(os.environ["HOME"]+"/measures/"+r[2]+"x","wb") as file:
		file.write(info.text.encode())
	action.pointer_action.move_to_location(500,500);action.pointer_action.click();action.perform()
exit(0)
