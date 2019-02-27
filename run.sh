#!/bin/sh

if [ -z "$1" ] 
then
	echo "[-] Must provide a library file/directory(.so)"
	echo "[-] Syntax: run.sh <library>"
	exit 1
fi

FILENAME=$1

MAIN_REPORT_DIR="./report"
REPORT_DIR="${MAIN_REPORT_DIR}/$(basename $FILENAME)"

if [[ -d $REPORT_DIR ]]; then
    rm -rf $REPORT_DIR
fi

if [[ ! -d $MAIN_REPORT_DIR ]]; then
    mkdir $MAIN_REPORT_DIR
fi

mkdir $MAIN_REPORT_DIR
mkdir $REPORT_DIR

declare -a FILES_TO_IGNORE
printf "[+] Getting files to ignore - "
if [[ -f "files_to_ignore.dat" ]]; then
    IFS=$'\n' read -d '' -r -a FILES_TO_IGNORE < "files_to_ignore.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

# Load known libraries from file

declare -a KNOWN_LIBRARIES
printf "[+] Getting known libraries - "
if [[ -f "known_libraries.dat" ]]; then
    IFS=$'\n' read -d '' -r -a KNOWN_LIBRARIES < "known_libraries.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

# Load suspicious keywords from file

declare -a SUSPICIOUS_KEYWORDS
printf "[+] Getting suspicious keywords - "
if [[ -f "suspicious_keywords.dat" ]]; then
    declare -a TMP_SUSPICIOUS_KEYWORDS
    IFS=''
    while read data; do
        if [[ ! ${data:0:1} == *"#"* ]]; then
            TMP_SUSPICIOUS_KEYWORDS+=( "${data} " )
        fi
    done < suspicious_keywords.dat
    SUSPICIOUS_KEYWORDS=$(echo "${TMP_SUSPICIOUS_KEYWORDS[*]}" | sed 's/ /|/g')
    SUSPICIOUS_KEYWORDS=$(echo ${SUSPICIOUS_KEYWORDS} | rev | cut -c 2- | rev)
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

# Load suspicious symbols from file

declare -a SUSPICIOUS_SYMBOLS
printf "[+] Getting suspicious symbols - "
if [[ -f "suspicious_symbols.dat" ]]; then
    declare -a TMP_SUSPICIOUS_SYMBOLS
    IFS=''
    while read data; do
        if [[ ! ${data:0:1} == *"#"* ]]; then
            TMP_SUSPICIOUS_SYMBOLS+=( "${data} " )
        fi
    done < suspicious_symbols.dat
    SUSPICIOUS_SYMBOLS=$(echo "${TMP_SUSPICIOUS_SYMBOLS[*]}" | sed 's/ /|/g')
    SUSPICIOUS_SYMBOLS=$(echo ${SUSPICIOUS_SYMBOLS} | rev | cut -c 2- | rev)
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

LAST_KNOWN_LIBRARY=""
function is_known_library {
    if [[ ! -z $KNOWN_LIBRARIES ]]; then
        for lib in "${KNOWN_LIBRARIES[@]}"; do
            KEY="${lib%%:*}"
            VALUE="${lib##*:}"
            if [[ $1 == *$KEY* ]]; then
                if [[ "${KEY}" != "${LAST_KNOWN_LIBRARY}" ]]; then
                    LAST_KNOWN_LIBRARY=$KEY
                    echo "${VALUE}" >> "${REPORT_DIR}/libraries_found.txt"
                fi
                break
            fi
        done
    fi
}

function check_file {
    if [[ -f $2 ]]; then
        ./check_bin.sh $1 $SUSPICIOUS_KEYWORDS $SUSPICIOUS_SYMBOLS $REPORT_DIR >> $2
    else
        ./check_bin.sh $1 $SUSPICIOUS_KEYWORDS $SUSPICIOUS_SYMBOLS $REPORT_DIR > $2
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
        is_known_library $f
        result=$(is_file_ok $f)
        if [[ $result == "ok" ]]; then
            start=$(date +%s)
            check_file $f "${REPORT_DIR}/report_$(basename $1).txt"
            end=$(date +%s)
            runtime=$((end-start))
            printf "Done[${runtime}s].\n"
        else
            printf "Ignored.\n"
        fi
    done
}

if [[ $FILENAME == *"apk"* ]]; then
    echo "[+]" $(basename $FILENAME)" is an APK"
    echo "[+] Extracting..."
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
    echo "[+]" $(basename $FILENAME)" is a File."
    printf "[+] Checking file: "$(basename $FILENAME)" - "
    start=$(date +%s)
    check_file $FILENAME "${REPORT_DIR}/report_$(basename $1).txt"
    end=$(date +%s)
    runtime=$((end-start))
    printf "Done[${runtime}s].\n"
else
    echo "$FILENAME is not valid"
    exit 1
fi





