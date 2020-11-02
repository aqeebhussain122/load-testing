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
	echo "Number of requests made: $num_requests"
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
	#values=`cut -d , -f $column_number $filename | grep [0-9] | sort -n`
	values=`cut -d , -f $column_number $filename | grep [0-9] | sort -n` 

	# Calculate each value with second(s)
	#awk -v n="$values" 'BEGIN{ printf int(n*100) "%\n"}'	
	# Prints the values formatted
	#awk 'BEGIN {print ($values*100)}'  | tr " " "\n"
	#echo $values
	printf "Raw values: (Milliseconds) \n"
	for val in $values; do echo $val; done
	printf "Seconds: \n"
	for val in $values; do awk -v n="$val" 'BEGIN{ printf int(n*100+0.5) "\n"}'; done
	printf "\nLargest value extracted (Seconds): "
	# Extract the given column number from the filename and print out the exact decimal value using reverse sort and printing the first available value using the head command to print the top of the file
	largest=`cut -d , -f $column_number $filename | grep -Eo '[0]+\.[0-9]+' | sort -rn | head -n 1`
	awk -v n="$largest" 'BEGIN{ printf int(n*100+0.5) "\n"}'
	printf "Exact value: $largest\n"
}

# Find a page to perform some input and then input some random data
# Make a post request which connects to a page
# Caching which is happening because you're requesting the same page.
# Instead of constant GET requests we should instead generate POST requests adding values into the SQL DB via an HTTP form. Need the parameters for this
# https://endpoint.com?param1={first-data-random}&param2={second-data-random}
# Are we testing with normal sized packets or are we expected to use oversized packets?
# We're using normal sized packets to see 
# Stress is not showing on the machine but the network connection
# Run the curl script in the same region of the AWS network
# Running the script from a broadband does not generate enough traffic
# Use a couple of instances which are in the same region.
# Send some random values in the parameters. And these inputs will be
# Hit network as a bottleneck rather than system but it wasn't their network it was a broadband. 
# Have a lot of random combinations which are inserted into a file and then reading these requests one by one over the file
# What point does the response go down

usage "$@"
main "$@"
