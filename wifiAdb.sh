#!/bin/sh
export PATH
addr_line=`adb shell ifconfig | grep "inet addr:.* Bcast:"`
addr=`echo ${addr_line} | sed 's/.*inet addr:\(.*\) B.*/\1/g'`
port=5555
adb tcpip $port
adb connect ${addr}:${port}
