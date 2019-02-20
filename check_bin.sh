#!/bin/sh

LIB_FILE=$1
SUSPICIOUS_KEYWORDS=("ptrace" "/bin" "root" "dex" "/proc")

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