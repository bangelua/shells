#!/bin/sh
export PATH
COUNTER_T=0
while [[ $COUNTER_T -lt 12 ]]
do
	sh /Users/luliang/git/shells/qiang_pc.sh &
    COUNTER_T=`expr $COUNTER_T + 1`
    echo "thread $COUNTER_T"
done