#!/bin/bash
# insert or update strings.xml in batch, this script 
# should excuted in the root directory of Project, and
# the every line of input file must contains string name 
# and string value which seperated by empty space. 
# e.g. 
#	#values
#      lock_screen Lock Sreen
#      ...
#   #values-ja
#	   pulse_speed_very_fast 非常に速い
#      ...
#
# WARNING: 1. the string value embraced by blank space will be trimmed.
# 2. the string contains quotes will be ignore, you must add slash before it, e.g. \"

export PATH

#--------------------------------------------------------------------------------------
#
#	$1: file name
#	$2: line num
#	$3: one line text to be update to the $2 line in file $1
#
function updateLine(){
	#add four empty char at the front of line, just like tab
	MYSTRING="    "$3
	MYSTRING=${MYSTRING//\\/\\\\}
	CMD="$2c\\$MYSTRING"
	#echo "exec cmd: ${CMD}"
	sed -i "${CMD}" "$1"

}


#--------------------------------------------------------------------------------------
#	$1 file name
#	$2 text line to be appended at last of string file, e.g. <string name="static_ip_address">"固定IPアドレス"</string>
function appendString(){
	LINE_NUM=`grep -n '</resources>' $1 | cut -d ':' -f 1`
	let LINE_NUM-=1
	TARGET_STRING="   "$2
	TARGET_STRING=${TARGET_STRING//\\/\\\\}
	echo $TARGET_STRING
	#echo $LINE_NUM
	CMD="${LINE_NUM}a\\${TARGET_STRING}"
	echo "execute appendString: $CMD"
	sed -i "${CMD}" $1
}

#--------------------------------------------------------------------------------------
# this method try comment special line
#	$1 filename
#	$2 line num
function commentLine(){
	CMD=$2"p"
	#echo "------------cmd: $CMD"
	TEXT=`sed -n $CMD $1`
	#echo "$TEXT"
	#trim first
	TEXT=`echo "$TEXT" | cut -d ' ' -f 5-`
	#TEXT=`awk '{$TEST=$TEST;print}'`
	echo "$TEXT"
	echo "-----------------$TEXT"	
	COMMENT="<!--"${TEXT}"-->"
	updateLine $1 $2 "$COMMENT"
}

#--------------------------------------------------------------------------------------
#
#	$1: the line to be handled, e.g. <string name="static_ip_address">"固定IPアドレス"</string>
#
function updateString(){
	STRING_NAME=$1
	echo "string name: $STRING_NAME"
	LINE_NUM=`grep -n $STRING_NAME $ANDROID_STRING_FILE | grep -v "!--" | cut -d ':' -f 1`
	#echo $LINE_NUM
	if [ -z "$LINE_NUM" ]; then
		echo "not found $STRING_NAME in file $ANDROID_STRING_FILE..."
	else
		#echo "found $STRING_NAME at line: $LINE_NUM in file $SMARTISAN_STRING_FILE"
		grep -n "$STRING_NAME" $ANDROID_STRING_FILE | grep -v "!--" > ~/Desktop/temp.txt
		#RESULT=`grep -n $STRING_NAME $ANDROID_STRING_FILE | grep -v "!--"`
		
		#echo $RESULT
		while read -r DATA || [ -n "$DATA" ]
			do
				CURRENT=`echo $DATA | cut -d ':' -f 1`
				CONTENT=`echo $DATA | cut -d ':' -f 2-`			
				echo "------"
				commentLine $ANDROID_STRING_FILE $CURRENT
				echo "current: $CONTENT"
				appendString $SMARTISAN_STRING_FILE "$CONTENT"
			done < ~/Desktop/temp.txt
		
	fi

}


#--------------------------------------------------------------------------------------
#main 

VALUE_DIR=values-zh-rTW

ANDROID_STRING_FILE="res/$VALUE_DIR/strings.xml"
SMARTISAN_STRING_FILE="res/$VALUE_DIR/smartisan_strings.xml"

updateString "Wi‑Fi"

echo "~~ Update Strings Done~~"
exit 0
#--------------------------------------------------------------------------------------