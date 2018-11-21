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

function traverse_is_string_used_in_code(){
    for file in `ls $1`
    do  
    	filename="$1/$file"
        #echo $filename
        if [ -d $filename ];then  
            if [[ $file == "bin" ]]; then
                #echo "jump bin $filename"
                continue
            fi
                    #statements
                 traverse_is_string_used_in_code $filename
                if(( $? == 0)); then
                    return 0
                fi
             
        else     	
        	
        	if [[ ! $file =~ "strings.xml" ]]; then
        		#echo "check file $filename"
        		#\grep --color=auto -A 20 $KEY_WORLD $filename
        		count=`grep -c "$SIMPLE_KEY" $filename`
        		if (( $count > 0 )); then
        			#echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $filename has key $SIMPLE_KEY"
        			return 0
             	#else
             	#	echo "empty"
             	fi

            #else
            	#echo "not ASCII file: $filename"
            fi
        fi
    done
    return 108
}


#main()
TARGET_STRING=( values-zh-rCN values )
echo -e "finding untranslated strings..."
for target in ${TARGET_STRING[@]}
	do
		TMPFILE=$target
		INPUT_FILE=res/$target/smartisan_strings.xml
		echo -e "~~~~~~~~~~~\nstart checking file $INPUT_FILE\n-----------------------------------------"
		echo -e "KEY\t\t\t\t\t\t\t\t\tUntranslated in"
		while read -r line || [ -n "$line" ]
			do
				#echo $line 
				#echo -e "\n"
				PREFIX="<string"
				if [[ $line =~ ^$PREFIX ]]; then
					#echo "start with $line"	
					SIMPLE_KEY=`echo $line | cut -d '"' -f 2`
					KEY="\"${SIMPLE_KEY}\""
					#echo $KEY

					#check whitelist
					if (( $# > 0)); then
						#echo "second parm is: $1"
						COUNTINWHITELIST=`grep -c $KEY $1`
						if(( $COUNTINWHITELIST > 0)); then
							#echo "$KEY is white list, just continue"
							continue
						fi
					fi

					#check is string key used in code
					#traverse_is_string_used_in_code .
					#if(( $? > 0)); then
					#	echo "not found $KEY"
					#	continue
					#fi

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
						echo -e "${KEY}\t\t\t\t\t\t\t\t\t${RESULT%&}" >> $TMPFILE
					fi

				else
					#echo "not valid, continue"
					continue
				fi
			done < $INPUT_FILE
			
			test -f $TMPFILE && sort -k 2 $TMPFILE && rm $TMPFILE			
	done

echo -e "\ndone"
exit 0