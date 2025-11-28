#!/bin/bash

#1 text 2 nr

#Successfully created new SMS: /org/freedesktop/ModemManager1/SMS/0

a=`sudo mmcli -m 0 --messaging-create-sms="text='${1}',number='+40${2}'"` && \
echo ${a} && \
b=`echo ${a} | cut -d' ' -f5 | cut -d'/' -f6` && \
a=`date '+%s'` && \
f=/home/bc/Desktop/sms/$a.txt && \
mmcli -m 0 -s ${b} > ${f} && \
cat ${f} && \
read -n1 kbd && \
sudo mmcli -s ${b} --send && \
sudo mmcli -m 0 --messaging-delete-sms=${b}
