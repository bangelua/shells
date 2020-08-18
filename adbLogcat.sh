#!/bin/sh
export PATH
count=`adb devices | grep -c "\tdevice"`
devices=`adb devices | grep "\tdevice" | cut -f 1`
#echo $devices
index=1
if [[ $count == 1 ]];then
	adb logcat -v time | grep $1
else
	for LINE in $devices; do
	    echo "$index: $LINE"
	    deviceArray[$index]=$LINE
	    index=$((index+1))
	done;
	read -p "choose which devices: " choose
	adb -s ${deviceArray[$choose]} logcat -v time | grep $1
fi
