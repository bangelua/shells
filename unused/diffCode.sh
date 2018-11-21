#!/bin/bash
export PATH

#main
file1=`readlink -f $1`
echo "fileA: $file1"
file2=${file1/T1/T2}
echo "fileB: $file2"
echo -e "diff result:\n--------------------------------------"
diff $file1 $file2
echo "--------------------------------------"
exit 0
