#!/bin/bash
export PATH

#need three params,
# $1: filename
# $2: line num to be changed
# 
function changeFileLine(){

	CMD=$2"p"
	echo $CMD
	TEXT=`sed -n "$CMD" $1`
	echo $TEXT
	TEXT="<!--"$TEXT"-->"
	echo $TEXT
	CMD=”5c${TEXT}"
	echo $CMD
	sed -i "$CMD" $1

}
#main

changeFileLine $1 $2
