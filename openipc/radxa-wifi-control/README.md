# Radxa Wifi Control

Using gpiomon is efficient because it waits for GPIO events instead of continuously polling. This reduces CPU usage and allows your script to respond immediately to GPIO changes.


* Add as service
    * /etc/systemd/system/wifi_control.service

* Enable and start the service:
    ```
    sudo systemctl enable toggle_wifi.service
    sudo systemctl start toggle_wifi.service
    ```