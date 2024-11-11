#!/bin/bash

GPIO_PIN=17
WIFI_INTERFACE="wlan0"

# Export the GPIO pin and set it to input mode
echo "$GPIO_PIN" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio${GPIO_PIN}/direction

while true; do
    # Read GPIO value
    VALUE=$(cat /sys/class/gpio/gpio${GPIO_PIN}/value)

    if [ "$VALUE" -eq 1 ]; then
        echo "Disabling WiFi"
        sudo ifconfig $WIFI_INTERFACE down
    else
        echo "Enabling WiFi"
        sudo ifconfig $WIFI_INTERFACE up
    fi

    # Delay to prevent rapid toggling
    sleep 1
done
