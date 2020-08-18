#!/bin/sh
export PATH
devices=`adb devices | grep "\tdevice" | cut -f 1`
echo $devices

for LINE in $devices; do
    #Do some works on "${LINE}"
    echo "adb -s $LINE install -r $1"
    adb -s $LINE install -r $1 || exit 1
done;