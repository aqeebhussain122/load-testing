#!/bin/bash

usage() {
	if [ $# -ne 3 ]
	then
		printf "Incorrect number of arguments given\n Usage: <URL> <Number of requests> <Name of results file>"
		exit 1
	fi
}

main() {
	local url=$1
	local num_requests=$2
	local test_filename=$3

	print_header | tee -a $test_filename
	for i in `seq 1 $num_requests`; do printf "Request: $i\n"; make_request $url | tee -a $test_filename; done;

	extract_contents $test_filename
}

print_header() {
	echo "code,time_total,time_connect,time_appconnect,time_starttransfer"
}

make_request() {
	local url=$1
	curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" --silent --output /dev/null "$url"
}

extract_contents() {
	local test_file=$1
	printf "\n\nExtracting total_time(s)\n\n"
	feature_extract $test_file 2

	printf "\n\nExtracting time taken to connect\n\n"
	feature_extract $test_file 3
}

feature_extract() {
	local filename=$1
	local column_number=$2
	cut -d , -f $column_number $filename | grep [0-9] | sort -n
}


#usage $1 $2 $3
usage "$@"
main "$@"
