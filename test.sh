#!/bin/sh
export PATH
MID_V="0"
if [ "$MID_V" -gt 9 ]; then
	echo "multi $MID_V"
else
	echo "one $MID_V"
fi
