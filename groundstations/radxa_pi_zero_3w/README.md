# Radxa


[Use gpiod to control GPIO pins](https://wiki.radxa.com/Gpiod)

Pin25 GND
Pin27 GPIO4_B2

example
```bash
gpio_chip="gpiochip3"
gpio_offset="8"

$ sudo gpioget $gpio_chip $gpio_offset
```

```
gpio_chip="gpiochip4"
gpio_offset="10"

$ gpiofind PIN_27
gpiochip4 10
```

RubyFPV Quick Action 1 is on pin 32 which I think is record (default)
edit /home/radxa/scripts/stream.sh
```
$ gpiofind PIN_32
gpiochip3 18
```
