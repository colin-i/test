sudo mbim-network /dev/cdc-wdm0 start
	#mbimcli -d /dev/cdc-wdm0 --query-subscriber-ready-status --no-close
#no-open porneste de la acest numar
	#mbimcli -d /dev/cdc-wdm0 --query-registration-state --no-open=3 --no-close
	#mbimcli -d /dev/cdc-wdm0 --attach-packet-service --no-open=4 --no-close
	#mbimcli -d /dev/cdc-wdm0 --connect=apn='' --no-open=5 --no-close
