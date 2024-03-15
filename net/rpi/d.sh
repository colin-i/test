#sudo service dnsmasq start
#in loc de dhcpd
#sudo ifconfig wlan0 192.168.4.1 netmask 255.255.255.0
#sudo ip route add 192.168.4.0/24 dev wlan0 proto dhcp scope link src 192.168.4.1 metric 303
sudo ifconfig eth0 192.168.2.1 netmask 255.255.255.0
#ifconfig

sudo ip route add 192.168.2.0/24 dev eth0 proto dhcp scope link src 192.168.2.1 metric 303
#route -n

#sudo service hostapd start
sudo iptables -t nat -A POSTROUTING -o wwan0 -j MASQUERADE
#sudo iptables -t nat -L
#high cpu usage
#sudo service dnsmasq restart