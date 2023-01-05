#!/bin/bash
if [ -n "$1" ]; then
a=`date '+%s'`
f=/home/bc/Desktop/sms/$a.txt
mmcli -m 0 -s $1 > ${f}
cat ${f}
read -n1 kbd
sudo mmcli -m 0 --messaging-delete-sms=$1
else
mmcli -m 0 --messaging-list-sms;
fi
