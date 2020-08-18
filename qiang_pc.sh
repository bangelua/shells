#!/bin/sh
export PATH
COUNTER=0
while [[ $COUNTER -lt 20 ]]
do
	adb shell input tap 540 1693
    COUNTER=`expr $COUNTER + 1`
    echo $COUNTER
done