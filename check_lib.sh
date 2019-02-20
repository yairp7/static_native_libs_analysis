#!/bin/sh

LIB_FILE=$1
SUSPICIOUS_KEYWORDS=("ptrace" "/bin" "root" "dex")

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

start_section "Urls"
./tools/extract_urls/extract_urls.sh $LIB_FILE
end_section

start_section "Keywords"
for index in ${!SUSPICIOUS_KEYWORDS[*]}
do
    strings $LIB_FILE | grep ${SUSPICIOUS_KEYWORDS[$index]}
done
end_section