#!/bin/sh

if [ -z "$1" ] 
then
	echo "[-] Must provide a library file/directory(.so)"
	echo "[-] Syntax: run.sh <library>"
	exit 1
fi

FILENAME=$1

if [[ -d "./report" ]]; then
    rm -rf ./report
fi

mkdir ./report

declare -a FILES_TO_IGNORE
printf "[+] Getting files to ignore - "
if [[ -f "files_to_ignore.dat" ]]; then
    IFS=$'\n' read -d '' -r -a FILES_TO_IGNORE < "files_to_ignore.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

function is_file_ok {
    for f in "${FILES_TO_IGNORE[@]}"; do
        if [[ $1 =~ $f ]]; then
            echo "ignore"
        fi
    done
    echo "ok"
}

function check_file {
    if [[ -f $2 ]]; then
        ./check_bin.sh $1 >> $2
    else
        ./check_bin.sh $1 > $2
    fi
}

function traverse_dir {
    REPORT="report_$(basename $1).txt"
    if [[ -f "${REPORT}" ]]; then
        rm ${REPORT}
    fi
    fileCount=0
    IFS=$'\n' files=( $(find $1 -type f) )
    for f in "${files[@]}"; do
        fileCount=$(( fileCount+1 ))
        printf "[+] Checking file: "$(basename $f)"[${fileCount} / ${#files[@]}] - "
        result=$(is_file_ok $f)
        if [[ $result == "ok" ]]; then
            check_file $f "./report/report_$(basename $1).txt"
            printf "Done.\n"
        else
            printf "Ignored.\n"
        fi
    done
}

if [[ $FILENAME == *"apk"* ]]; then
    echo "[+]" $(basename $FILENAME)" is an APK"
    echo "[+] extracting..."
    if [[ ! -d "./tmp" ]]; then
        mkdir ./tmp
    fi
    apktool --quiet -f d "${FILENAME}" -o "./tmp"
    traverse_dir "./tmp"
    rm -rf ./tmp
elif [[ -d $FILENAME ]]; then
    echo $(basename $FILENAME)" is a Directory"
    traverse_dir $f
	echo "[+] Done."
elif [[ -f $FILENAME ]]; then
    echo "[+]" $(basename $FILENAME)" is a File"
    echo "[+] Checking file: "$(basename $FILENAME)
    check_file $FILENAME "./report/report_$(basename $1).txt"
else
    echo "$FILENAME is not valid"
    exit 1
fi





