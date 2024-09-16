# OpenIPC Sandbox

A place to put stuff that I find interesting or things I learn



* It is also possible to execute custom commands from the SD card 
after mounting. Place the files in the root of the SD card, which is prepared. [Telegram Link](https://t.me/c/1809358416/28287/108056)

    * autoconfig.sh - will be run once and then deleted
    * autostart.sh - will be run every time



Files

/home/radxa/scripts

stream.sh  - kicks off fpvue, configure osd elements, recording
screen-mode - default 1920x1080@60
```
FPVue Rockchip 0.10
Available modes:
0 : 1920x1080@60
1 : 1920x1080@120    ; Segmentation fault
2 : 1920x1080@120
3 : 1920x1080@60
4 : 1920x1080@60
5 : 1920x1080@50
6 : 1680x1050@60
7 : 1600x900@60
8 : 1280x1024@75
9 : 1280x1024@60
10 : 1280x800@60
11 : 1280x720@60
12 : 1280x720@60
13 : 1280x720@60
14 : 1280x720@50
15 : 1024x768@75
16 : 1024x768@60
17 : 800x600@75
18 : 800x600@60
19 : 720x576@50
20 : 720x480@60
21 : 720x480@60
22 : 640x480@75
23 : 640x480@60
24 : 640x480@60
25 : 640x480@60
```

### MSP OSD
curl -L -o /usr/bin/msposd https://raw.githubusercontent.com/openipc/msposd/main/release/star6e/msposd



### Wifi cards

#### RTL8812BU

git clone https://github.com/fastoe/RTL8812BU.git

cd RTL8812BU/

edit Makefile:
sed -i 's/CONFIG_80211W = n/CONFIG_80211W = y/' Makefile
sed -i 's/CONFIG_WIFI_MONITOR = n/CONFIG_WIFI_MONITOR = y/' Makefile
make
sudo make install


Copy 88x2bu.ko to /lib/modules/$(uname -r)/kernel/drivers/net/wireless

Add kernel/drivers/net/wireless/88x2bu.ko: entry in /lib/modules/$(uname -r)/modules.dep
sudo depmod
sudo modprobe 88x2bu


#### 8812eu
8812eu driver for radxa.
https://t.me/c/1809358416/63019/86714

$ sudo modprobe cfg80211
$ sudo insmod 8812eu_radxa.ko rtw_tx_pwr_by_rate=0 rtw_tx_pwr_lmt_enable=0

$ lsusb 
would shows 
"Bus 00* Device 00*: ID 0bda:a81a Realtek Semiconductor Corp. 802.11ac NIC" this is 8812eu.

$ nmcli
would shows 8812eu as wlan0 module.

$ sudo systemctl restart wifibroadcast@gs
$ wfb-cli gs 


create file:
/etc/modprobe.d/8812eu_radxa.conf




/home/home/wfb/wfb-ng/wfb_rx -p 0 -i 7669206 -u 5666 -K /etc/gs.key 14550 wlx00127b217d10 wlx00127b217c4c

options 8812eu_radxa rtw_tx_pwr_by_rate=0 rtw_tx_pwr_lmt_enable=0


