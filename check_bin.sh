#!/bin/sh

LIB_FILE=$1
SUSPICIOUS_KEYWORDS=("ptrace" "/bin" "root" "dex" "/proc" "")

declare -a SUSPICIOUS_KEYWORDS
printf "[+] Getting suspicious keywords - "
if [[ -f "suspicious_keywords.dat" ]]; then
    IFS=$'\n' read -d '' -r -a SUSPICIOUS_KEYWORDS < "suspicious_keywords.dat"
    printf "Done.\n"
else
    printf "Not exist.\n"
fi

declare -a SUSPICIOUS_SYMBOLS
printf "[+] Getting suspicious symbols - "
if [[ -f "suspicious_keywords.dat" ]]; then
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
rabin2 -s $LIB_FILE
end_section

start_section "Urls"
./tools/extract_urls/extract_urls.sh $LIB_FILE
end_section

start_section "Keywords"
for index in ${!SUSPICIOUS_KEYWORDS[*]}
do
	echo "[+] Looking for keyword: ${SUSPICIOUS_KEYWORDS[$index]}"
    strings $LIB_FILE | grep "${SUSPICIOUS_KEYWORDS[$index]}"
done
end_section