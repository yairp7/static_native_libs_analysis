#!/bin/sh


LIB_FILE=$1
COMMAND=$2
SUSPICIOUS_KEYWORDS_FILES='./report/suspicious_keywords_files.txt'
SUSPICIOUS_SYMBOLS_FILES='./report/suspicious_symbols_files.txt'

# Load suspicious keywords from file

declare -a SUSPICIOUS_KEYWORDS
printf "[+] Getting suspicious keywords - "
if [[ -f "suspicious_keywords.dat" ]]; then
    IFS=$'\n' read -d '' -r -a SUSPICIOUS_KEYWORDS < "suspicious_keywords.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

# Load suspicious symbols from file

declare -a SUSPICIOUS_SYMBOLS
printf "[+] Getting suspicious symbols - "
if [[ -f "suspicious_symbols.dat" ]]; then
    IFS=$'\n' read -d '' -r -a SUSPICIOUS_SYMBOLS < "suspicious_symbols.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

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

start_section "Linked Libraries"
rabin2 -l $LIB_FILE
end_section

start_section "Symbols"
is_suspicious=0
for index in ${!SUSPICIOUS_SYMBOLS[*]}
do
	echo "[+] Looking for symbol: ${SUSPICIOUS_SYMBOLS[$index]}"
    result=$(rabin2 -s $LIB_FILE | grep "${SUSPICIOUS_SYMBOLS[$index]}")
    if [[ ! -z $result ]]; then
    	echo result
    	is_suspicious=1
    fi 
done
if [[ is_suspicious -eq 1 ]]; then
	echo $LIB_FILE >> $SUSPICIOUS_SYMBOLS_FILES
fi
end_section

start_section "Urls"
./tools/extract_urls/extract_urls.sh $LIB_FILE
end_section

start_section "Keywords"
is_suspicious=0
for index in ${!SUSPICIOUS_KEYWORDS[*]}
do
	echo "[+] Looking for keyword: ${SUSPICIOUS_KEYWORDS[$index]}"
    result=$(strings $LIB_FILE | grep "${SUSPICIOUS_KEYWORDS[$index]}")
    if [[ ! -z $result ]]; then
    	echo result
    	is_suspicious=1
    fi 
done
if [[ is_suspicious -eq 1 ]]; then
	echo $LIB_FILE >> $SUSPICIOUS_KEYWORDS_FILES
fi
end_section