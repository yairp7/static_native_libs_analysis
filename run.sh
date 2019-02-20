#!/bin/sh

if [ -z "$1" ] 
then
	echo "[-] Must provide a library file/directory(.so)"
	echo "[-] Syntax: run.sh <library>"
	exit 1
fi

LIB_FILE=$1

if [[ -d $LIB_FILE ]]; then
    echo $(basename $LIB_FILE)" is a directory"
    fileCount=0
	IFS=$'\n' files=( $(find $1 -name '*.so' -print) )
	for f in "${files[@]}"; do
		fileCount=$(( fileCount+1 ))
    	echo "[+] Checking file: "$(basename $f)"[${fileCount} / ${#files[@]}]"
    	./check_lib.sh $f > "report_$(basename $f).txt"
	done
	echo "[+] Done."
elif [[ -f $LIB_FILE ]]; then
    echo $(basename $LIB_FILE)" is a file"
    echo "[+] Checking file: "$(basename $LIB_FILE)
    ./check_lib.sh $LIB_FILE > "report_$(basename $LIB_FILE).txt"
else
    echo "$LIB_FILE is not valid"
    exit 1
fi





