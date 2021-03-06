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
	TARGET_STRING="    "$3
	TARGET_STRING=${TARGET_STRING//\\/\\\\}
	CMD="$2c\\$TARGET_STRING"
	#echo "exec cmd: ${CMD}"
	sed -i "${CMD}" "$1"

}


#--------------------------------------------------------------------------------------
#	$1 file name
#	$2 text line to be appended at last of string file, e.g. <string name="static_ip_address">"固定IPアドレス"</string>
function appendString(){
	LINE_NUM=`grep -n '</resources>' $1 | cut -d ':' -f 1`
	let LINE_NUM-=1
	TARGET_STRING="    "$2
	TARGET_STRING=${TARGET_STRING//\\/\\\\}
	CMD="${LINE_NUM}a\\${TARGET_STRING}"
	#echo "execute appendString: $CMD"
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
	echo "$TEXT"
	#echo "-----------------$TEXT"
	COMMENT="<!--"${TEXT}"-->"
	updateLine $1 $2 "$COMMENT"
}

#--------------------------------------------------------------------------------------
#
#	$1: the line to be handled, e.g. <string name="static_ip_address">"固定IPアドレス"</string>
#
function updateString(){

	STRING_NAME=`echo "$1" | cut -d "\"" -f 2`
	STRING_NAME="\"${STRING_NAME}\""
	#echo "string name: $STRING_NAME"
	LINE_NUM=""
	if [ -f $SMARTISAN_STRING_FILE ]; then
		LINE_NUM=`grep -n $STRING_NAME $SMARTISAN_STRING_FILE | grep -v "!--" | cut -d ':' -f 1`
	fi
	echo "LINE_NUM: $LINE_NUM"
	if [ -z "$LINE_NUM" ]; then
		#echo "not found $STRING_NAME in file $SMARTISAN_STRING_FILE, try file $ANDROID_STRING_FILE..."
		LINE_NUM=`grep -n $STRING_NAME $ANDROID_STRING_FILE | grep -v "!--" | cut -d ':' -f 1`
		if [ -z "$LINE_NUM" ]; then
			#echo "not found in $ANDROID_STRING_FILE also!"
			if [ -f $SMARTISAN_STRING_FILE ]; then
				#echo "insert $1 to file $SMARTISAN_STRING_FILE"
				appendString $SMARTISAN_STRING_FILE "$1"
			else
				#echo "insert $1 to file $ANDROID_STRING_FILE"
				appendString $ANDROID_STRING_FILE "$1"
			fi

		else
			#echo "found $STRING_NAME at line $LINE_NUM in file $ANDROID_STRING_FILE"
			if [ -f $SMARTISAN_STRING_FILE ]; then
				commentLine $ANDROID_STRING_FILE $LINE_NUM
				appendString $SMARTISAN_STRING_FILE "$1"
			else
				updateLine $ANDROID_STRING_FILE $LINE_NUM "$1"
			fi
		fi
	else
		#echo "found $STRING_NAME at line: $LINE_NUM in file $SMARTISAN_STRING_FILE"
		updateLine $SMARTISAN_STRING_FILE $LINE_NUM "$1"
	fi


}


#--------------------------------------------------------------------------------------
#main 
if(( $# < 1 )); then
	echo "error: need translation input file. "
	exit -1
fi


if [ ! -f $1 ]; then
	echo "input file $1 not exists, operation failed!!!"
	exit -1
fi

VALUE_DIR=values


if [ ! -f $STRING_FILE ]; then
	echo "string xml file $STRING_FILE not exists, operation failed!!!"
	exit -1
fi

while read -r line || [ -n "$line" ]
do
	#echo "$line"
	if [ -z "$line" ]; then
		#echo "empty char, just continue"
		continue
	fi
	
	KEY=`echo "$line" | cut -d ' ' -f 1`

	case $KEY in
	"#values") VALUE_DIR=values
		#echo -e "\n$KEY"
		continue
		;;
	"#values-zh-rTW") VALUE_DIR=values-zh-rTW
		#echo -e "\n$KEY"
		continue
		;;
	"#values-ja") VALUE_DIR=values-ja
		#echo -e "\n$KEY"
		continue
		;;
	"#values-ko") VALUE_DIR=values-ko
		#echo -e "\n$KEY"
		continue
		;;
	"#values-zh-rCN") VALUE_DIR=values-zh-rCN
		continue
		;;
	"#"*)
		#echo "jump comment line $KEY"
		continue
		;;
	*)
	;;
	esac


	#echo "current line: $line"
	#echo "-------------add string"	


	ANDROID_STRING_FILE="res/$VALUE_DIR/strings.xml"
	SMARTISAN_STRING_FILE="res/$VALUE_DIR/smartisan_strings.xml"

	updateString "$line"
	
done < $1

echo "~~ Update Strings Done~~"
exit 0
#--------------------------------------------------------------------------------------