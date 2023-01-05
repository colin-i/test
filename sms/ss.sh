#!/bin/bash

if [ -n "$1" ]; then
sudo mmcli -s $1 --send
else
sudo mmcli -m 0 --messaging-create-sms="text='',number='+407'"
#Successfully created new SMS:
#    /org/freedesktop/ModemManager1/SMS/12 (unknown)
#retrieve sms id from output (here: 12)
fi
