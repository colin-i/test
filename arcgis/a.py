
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from pdb import set_trace
from readchar import readchar
import os

service = Service('/usr/bin/geckodriver')
opts = Options()
opts.add_argument("--width=1333")
opts.add_argument("--height=777")

driver = webdriver.Firefox(service=service,options=opts)
action = ActionBuilder(driver)

driver.get("https://cestrin.maps.arcgis.com/apps/webappviewer/index.html?id=210f9dcdbeaf48349e3ed19e92ee2f19")
info=driver.find_element(By.TAG_NAME, 'body')

def bp(): #breakpoint still is a stop for some threads
	readchar()
	if os.path.isfile(breakmark):
		os.remove(breakmark)
		set_trace()

root=os.environ["HOME"]+"/measures/"
breakmark=root+"break"
bp() #next is async

info.find_element(By.ID,"jimu_dijit_CheckBox_0").click()
#this was working at first try: By.CLASS_NAME,"jimu-checkbox" ele.click()
#now: Element  is not clickable at point  because another element  obscures it ? driver.execute_script("arguments[0].click();", element) . but is another checkbox
# for searching: with open('q','w') as f: f.write(driver.page_source)
info.find_element(By.CLASS_NAME,"jimu-btn").click()

#turn of additional map markers
info.find_element(By.ID,"jimu_dijit_CheckBox_1").click()

def click(x,y,pages):
	action.pointer_action.move_to_location(x,y);action.pointer_action.click();action.perform()
	bp() #async
	if pages>0:
		el=info.find_element(By.CSS_SELECTOR,".titleButton.next")
		ActionChains(driver).move_to_element(el).perform()
		while pages>0:
			action.pointer_action.click();action.perform()
			bp()
			pages=pages-1
import time
def pack(type):
	with open(root+"recs"+type,"rb") as file:
		rd=file.read()
		print(rd.decode())
		recs=eval(rd)
	for r in recs:
		p=0
		if len(r)>3:
			p=r[3]
			if len(r)>4:
				extra=root+"ex"+type+"/"+r[2]
				if not os.path.isfile(extra):
					with open(extra,"w") as file:
						file.write(r[4])
		click(r[0],r[1],p) #to load for write
		with open(root+"new"+type+"/"+r[2],"wb") as file: file.write(info.text.encode())
		action.pointer_action.move_to_location(500,500);action.pointer_action.click();action.perform()
		time.sleep(5) #sometimes next click seems to be on undestroyed previous
pack("0")
pack("_new")
pack("")

bp()
#bottom-left switch for watermark
# !q=[];action.pointer_action.move_to_location(q[0],q[1]);action.pointer_action.click();action.perform()
# with open(root+"new_new/"+"","wb") as file: file.write(info.text.encode())
#and don't add to recs_new now, it is after from new to normal check
