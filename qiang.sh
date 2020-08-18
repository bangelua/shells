#!/bin/sh
export PATH
COUNTER=0
while [[ $COUNTER -lt 100 ]]
do
	time input tap 540 1645
    COUNTER=`expr $COUNTER + 1`
    echo $COUNTER
done