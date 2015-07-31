#!/bin/bash
# check out untranslated string
# usage: run this shell script at the root directory of your android project
#

export PATH

function check_translation_in_other_file(){
	#echo -e "\nstart search $1"	
	ANDROID_STRING="res/$2/strings.xml"
	SMARTISAN_STRING="res/$2/smartisan_strings.xml"
	#echo $ANDROID_STRING

	if [ ! -f $ANDROID_STRING ]; then
	echo "input file $ANDROID_STRING not exists, operation failed!!!"
	
	fi

	COUNT_ANDROID=`grep -v '!--' "$ANDROID_STRING"  | grep -c "$1" `
	COUNT_SMARTISAN=`grep -v '!--' "$SMARTISAN_STRING" | grep -c "$1" `

	if (( $COUNT_ANDROID==0 )) && (( $COUNT_SMARTISAN==0 )); then
		#echo -e "not found $1"
		return 0
	fi
	return 1
}

#main()
TARGET_STRING=( values-zh-rCN values )
echo -e "finding untranslated strings...\n"
for target in ${TARGET_STRING[@]}
	do
		TMPFILE=$target
		INPUT_FILE=res/$target/smartisan_strings.xml
		echo -e "\n~~~~~~~~~~~\nstart checking file $INPUT_FILE\n-----------------------------------------"
		echo -e "Untranslated in\t\t\t\t\t\t\t\t\tKEY"
		while read -r line || [ -n "$line" ]
			do
				#echo $line 
				#echo -e "\n"
				PREFIX="<string"
				if [[ $line =~ ^$PREFIX ]]; then
					#echo "start with $line"	
					KEY=`echo $line | cut -d '"' -f 2`
					KEY="\"${KEY}\""
					#echo $KEY
					RESULT=""
					ARRAY_STRINGS=( values values-zh-rCN values-zh-rTW values-ja values-ko )	
					for dir in ${ARRAY_STRINGS[@]}
						do
							if [ $dir == $target ]; then
								#echo "same dir"
								continue
							fi
							#echo "start check dir: $dir"
							check_translation_in_other_file "$KEY" $dir
							#echo $?
							if [[ $? -eq 0 ]]; then
								RESULT="${RESULT}${dir}&"
								
							fi
						done

					if [[ -n $RESULT ]]; then						
						touch $TMPFILE
						#echo "touch $TMPFILE"
						echo -e "${RESULT%&}\t\t\t\t\t\t\t\t\t${KEY}" >> $TMPFILE
					fi

				else
					#echo "not valid, continue"
					continue
				fi
			done < $INPUT_FILE
			
			test -f $TMPFILE && sort -k 1 $TMPFILE && rm $TMPFILE
	done

echo -e "\ndone"
exit 0