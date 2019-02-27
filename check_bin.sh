#!/bin/sh


LIB_FILE=$1
SUSPICIOUS_KEYWORDS=$2
SUSPICIOUS_SYMBOLS=$3
REPORT_DIR=$4
SUSPICIOUS_KEYWORDS_FILES="${REPORT_DIR}/suspicious_keywords_files.txt"
SUSPICIOUS_SYMBOLS_FILES="${REPORT_DIR}/suspicious_symbols_files.txt"
URLS_FILES="${REPORT_DIR}/files_containing_urls.txt"

function join_by { local IFS="$1"; shift; echo "$*"; }

function start_section {
	echo "### ${1} ###"
}

function end_section {
	printf "\n\n"
}

start_section "File"
file $LIB_FILE
end_section

start_section "Binwalk"
binwalk $LIB_FILE
end_section

result=$(rabin2 -l $LIB_FILE)
if [[ ! -z $result ]]; then
	start_section "Linked Libraries"
	echo result
	end_section
fi

start_section "Symbols"
is_suspicious=0
echo "[+] Looking for symbols: ${SUSPICIOUS_SYMBOLS}"
result=$(rabin2 -s $LIB_FILE | egrep -e "${SUSPICIOUS_SYMBOLS}")
if [[ ! -z $result ]]; then
	echo $result
	is_suspicious=1
fi 
if [[ is_suspicious -eq 1 ]]; then
	echo $LIB_FILE >> $SUSPICIOUS_SYMBOLS_FILES
fi
end_section

result=$(./tools/extract_urls/extract_urls.sh $LIB_FILE)
echo $result
if [[ ! -z $result ]]; then
	start_section "Urls"
	printf "${LIB_FILE}:\n ${result}\n" >> $URLS_FILES 
	end_section
fi 

start_section "Keywords"
keywords_found=()
is_suspicious=0

echo "[+] Looking for keywords: ${SUSPICIOUS_KEYWORDS}"
result=$(strings $LIB_FILE | egrep -e "${SUSPICIOUS_KEYWORDS}" | tr '\n' '?')
if [[ ! -z $result ]]; then
	echo $result
	is_suspicious=1
fi 

# If suspicious keywords found in file, save the filename to output
if [[ is_suspicious -eq 1 ]]; then
	result=$(echo ${result} | rev | cut -c 2- | rev) # Remove last ?
	echo "${LIB_FILE}: ${result}" >> $SUSPICIOUS_KEYWORDS_FILES 
fi
end_section