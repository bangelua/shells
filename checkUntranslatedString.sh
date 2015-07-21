#!/bin/bash
# check out untranslated string
# usage: run this shell script at the root directory of your android project
#

export PATH

function check_translation_in_other_file(){
	#echo -e "\nstart search $1"	
	JAPAN_ANDROID_STRING=res/values-ja/strings.xml
	JAPAN_SMARTISAN_STRING=res/values-ja/smartisan_strings.xml
	#echo $1
	KEY=`echo $1 | cut -d '"' -f 2`
	#echo $KEY
	COUNT_ANDROID=`grep -v "!--" $JAPAN_ANDROID_STRING | grep -c $KEY`
	COUNT_SMARTISAN=`grep -v "!--" $JAPAN_SMARTISAN_STRING | grep -c $KEY `

	if (( $COUNT_ANDROID==0 )) && (( $COUNT_SMARTISAN==0 )); then
		echo -e "$1"		
	fi

	KOREA_STRING=res/values-ko/smartisan_strings.xml
	#COUNT=`grep -c $1 $KOREA_STRING`	
}

#main()
INPUT_FILE=res/values/smartisan_strings.xml
echo -e "finding untranslated strings...\n"
while read line
	do
		#echo $line
		#echo -e "\n"
		PREFIX="<string"
		if [[ $line =~ ^$PREFIX ]]; then
			#echo "start with $line"						
			check_translation_in_other_file "$line"
		else
			#echo "not valid, continue"
			continue
		fi
	done < $INPUT_FILE
echo -e "\ndone"
exit 0