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
# WARNING: the string value embraced by blank space will be trimmed.

export PATH

function addstring(){
	KEY="\"$2\""
	VALUE=$3
	#echo "start add string key: ${KEY} , value: ${VALUE}"
	COUNT=`grep -n $KEY $1 | grep -c $KEY`
	TARGET_STRING="\    <string name=${KEY}>$VALUE</string>"
	#echo "find key count lines: ${COUNT}"
	LINE_NUM=`grep -n $KEY $1 | grep -v "!--" | cut -d ':' -f 1`

	if [ -z "$LINE_NUM" ]; then
		LINE_NUM=`grep -n '</resources>' $1 | cut -d ':' -f 1`
		let LINE_NUM-=1
		#echo "NOT FOUND KEY: ${KEY}, get file last line num: ${LINE_NUM}"
		CMD="${LINE_NUM}a\\${TARGET_STRING}"
		sed -i "${CMD}" $1
		return 0
	elif (( $COUNT > 1 )); then
		echo "find not only one KEY: ${KEY}, please exam the file ${1}!"
		return -1
	fi
	if [ -z $LINE_NUM ]; then
		echo "failed to find a place to insert the key: ${KEY}"
		return -2
	fi
	CMD="${LINE_NUM}c\\${TARGET_STRING}"
	#echo "find string at line $LINE_NUM"
	#echo "exec cmd: ${CMD}"
	sed -i "${CMD}" $1
	return 0
}

#main 
if(($#<1)); then
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

SUCCESS_COUNT=0
FAILED_COUNT=0

while read -r line || [ -n "$line" ]
do
	#echo "$line"
	STRING_FILE="res/${VALUE_DIR}/smartisan_strings.xml"
	KEY=`echo "$line" | cut -d ' ' -f 1`

	case $KEY in
	"#values") VALUE_DIR=values
		echo -e "\n$KEY"
		continue
		;;
	"#values-zh-rTW") VALUE_DIR=values-zh-rTW
		echo -e "\n$KEY"
		continue
		;;
	"#values-ja") VALUE_DIR=values-ja
		echo -e "\n$KEY"
		continue
		;;
	"#values-ko") VALUE_DIR=values-ko
		echo -e "\n$KEY"
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
	#echo "$line"
	VALUE=`echo "$line" | cut -d ' ' -f 2-`
	#echo "value: ${VALUE}"
	
	if [ -z "$KEY" -o -z "$VALUE" ]; then
		#echo "empty char, just continue"
		continue
	fi

	#echo "-------------add string"	
	addstring $STRING_FILE $KEY "${VALUE}"
	if(( $? == 0)); then
		let SUCCESS_COUNT++
		
		TARGET_STRING="    <string name=${KEY}>"${VALUE}"</string>"
		echo "${TARGET_STRING}"
	else
		let FAILED_COUNT++
		echo "failto insert $VALUE"
	fi
done < $1

echo -e "\nResult: success: ${SUCCESS_COUNT} , failed: ${FAILED_COUNT}"
exit 0