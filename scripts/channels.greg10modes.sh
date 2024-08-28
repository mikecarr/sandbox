#!/bin/sh

	# Decide MCS, guard interval, FEC, bit-rate, gop size and power based on the range [1000,2000] from radio
	# Need > wfb_tx v24 (with -C 8000 added to /usr/bin/wifibroadcast) and wfb_tx_cmd v24
	# Need osd-star (osd-star6e in my case) to update local OSD - Not compatible with early versions of msposd

if [ -e /etc/txprofile ]; then
	. /etc/txprofile
fi

	oldProfile=$vidRadioProfile
	
	if [ $2 -lt 1100 ] ;then
				
		setGI=long
		setMCS=0
		setFecK=13
		setFecN=15
		setBitrate=3400
		setGop=1.0
		wfbPower=59		
		newProfile=1
		echo "vidRadioProfile=1" >/etc/txprofile
		
	elif [ $2 -gt 1099 ] && [ $2 -lt 1200 ];then
		
		setGI=long
		setMCS=1
		setFecK=13
		setFecN=15
		setBitrate=5100
		setGop=1.0
		wfbPower=59
		newProfile=2
		echo "vidRadioProfile=2" >/etc/txprofile
	

	elif [ $2 -gt 1199 ] && [ $2 -lt 1300 ];then

		setGI=long
		setMCS=1
		setFecK=13
		setFecN=15
		setBitrate=7000
		setGop=1.0
		wfbPower=59
		newProfile=3
		echo "vidRadioProfile=3" >/etc/txprofile


	elif [ $2 -gt 1299 ] && [ $2 -lt 1400 ];then
		
		setGI=long
		setMCS=2
		setFecK=13
		setFecN=15
		setGop=1.0
		setBitrate=8000
		wfbPower=58
		newProfile=4
		echo "vidRadioProfile=4" >/etc/txprofile

	elif [ $2 -gt 1399 ] && [ $2 -lt 1500 ];then

		setGI=long
		setMCS=2
		setFecK=13
		setFecN=15
		setBitrate=9000
		setGop=1.0
		wfbPower=58
		newProfile=5
		echo "vidRadioProfile=5" >/etc/txprofile

	elif [ $2 -gt 1499 ] && [ $2 -lt 1600 ];then
					
		setGI=long
		setMCS=2
		setFecK=13
		setFecN=15
		setBitrate=10500
		setGop=1.0
		wfbPower=58
		newProfile=6
		echo "vidRadioProfile=6" >/etc/txprofile

	elif [ $2 -gt 1599 ] && [ $2 -lt 1700 ];then
						
		setGI=short
		setMCS=2
		setFecK=13
		setFecN=15
		setBitrate=12000
		setGop=1.0
		wfbPower=58
		newProfile=7
		echo "vidRadioProfile=7" >/etc/txprofile


	elif [ $2 -gt 1699 ] && [ $2 -lt 1800 ];then
						
		setGI=short
		setMCS=3
		setFecK=13
		setFecN=15
		setBitrate=15000
		setGop=1.0
		wfbPower=56
		newProfile=8
		echo "vidRadioProfile=8" >/etc/txprofile

	elif [ $2 -gt 1799 ] && [ $2 -lt 1900 ];then

		setGI=long
		setMCS=4
		setFecK=13
		setFecN=15
		setBitrate=16500
		setGop=1.0
		wfbPower=50
		newProfile=9
		echo "vidRadioProfile=9" >/etc/txprofile


	elif [ $2 -gt 1899 ];then
			
		setGI=short
		setMCS=4
		setFecK=13
		setFecN=15
		setBitrate=18000
		setGop=1.0
		wfbPower=50
		newProfile=10
		echo "vidRadioProfile=10" >/etc/txprofile

					
	fi	

	
# Calculate driver power
setPower=$((wfbPower * 50))

# Display stats on local OSD
curl "localhost:9000/api/osd/2?font=UbuntuMono-Regular&size=32.0&color=green&text=Bitrate:$setBitrate%20MCS:$setMCS%20GI:$setGI%20FEC:$setFecK%2F$setFecN%20wfbPower:$wfbPower%20GOP:$setGop"

if [ $newProfile -gt $oldProfile ]; then
	
	
	# Lower power first
	iw dev wlan0 set txpower fixed $setPower 
	
	# Set gopSize
	curl localhost/api/v1/set?video0.gopSize=$setGop 
	
	# Raise MCS
	wfb_tx_cmd 8000 set_radio -B 20 -G $setGI -S 1 -L 1 -M $setMCS
	wfb_tx_cmd 8000 set_fec -k $setFecK -n $setFecN
	
	# Increase bit-rate
	curl -s "http://localhost/api/v1/set?video0.bitrate=$setBitrate"
	


elif [ $newProfile -lt $oldProfile ]; then
	
	# Decrease bit-rate first
	curl -s "http://localhost/api/v1/set?video0.bitrate=$setBitrate" 

	# Set gopSize
	curl localhost/api/v1/set?video0.gopSize=$setGop 
	
	# Lower MCS
	sleep 0.1
	wfb_tx_cmd 8000 set_radio -B 20 -G $setGI -S 1 -L 1 -M $setMCS
	wfb_tx_cmd 8000 set_fec -k $setFecK -n $setFecN
	
	# Increase power
	iw dev wlan0 set txpower fixed $setPower


fi

#any final commands


exit 1
