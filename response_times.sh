#!/bin/bash

usage() {
	# If the number of given arguments aren't equal to 3
	if [ $# -ne 3 ]
	then
		printf "Incorrect number of arguments given\n Usage: <URL> <Number of requests> <Name of results file>"
		# Error exit code
		exit 1
	fi
}

# Main function where all of the functions are added
main() {
	local url=$1
	local num_requests=$2
	local test_filename=$3

	print_header | tee -a $test_filename
	for i in `seq 1 $num_requests`; do printf "Request: $i\n"; make_request $url | tee -a $test_filename; done;

	extract_contents $test_filename
	exit 0
}

# Header of csv file to give each file a feature to be extracted
print_header() {
	echo "code,time_total,time_connect,time_appconnect,time_starttransfer"
}

# Making the request to target url
make_request() {
	local target_url=$1
	curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" --silent --output /dev/null "$target_url"
}

# Extracting the selected columns from the file which has all of the curl output written to it
extract_contents() {
	local test_file=$1
	printf "\n\nExtracting total_time(s)\n\n"
	# From the second column of the test file, extract the values
	feature_extract $test_file 2

	printf "\n\nExtracting time taken to connect\n\n"
	# From the third column of the test file, extract the values
	feature_extract $test_file 3
}

feature_extract() {
	local filename=$1
	local column_number=$2

	# Full extraction of selected column 
	cut -d , -f $column_number $filename | grep [0-9] | sort -n

	printf "\nLargest value extracted: "
	# Extract the given column number from the filename and print out the exact decimal value using reverse sort and printing the first available value using the head command to print the top of the file
	largest=`cut -d , -f $column_number $filename | grep -Eo '[0]+\.[0-9]+' | sort -rn | head -n 1`
	awk -v n="$largest" 'BEGIN{ printf int(n*100+0.5) "%\n"}'
}


usage "$@"
main "$@"
