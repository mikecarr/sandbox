#!/bin/bash

GPIO_CHIP="gpiochip0"
GPIO_LINE=17
WIFI_INTERFACE="wlan0"

# Listen for changes on GPIO pin
gpiomon --rising-edge $GPIO_CHIP $GPIO_LINE | while read -r line; do
    echo "GPIO Rising Edge Detected. Toggling WiFi..."
    if [[ $(cat /sys/class/net/$WIFI_INTERFACE/operstate) == "up" ]]; then
        sudo ifconfig $WIFI_INTERFACE down
        echo "WiFi Disabled"
    else
        sudo ifconfig $WIFI_INTERFACE up
        echo "WiFi Enabled"
    fi
done
