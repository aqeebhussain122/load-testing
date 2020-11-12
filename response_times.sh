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
	#for i in `seq 1 $num_requests`; do printf "Request: $i\n"; make_request $url | tee -a $test_filename; done;
	
	# For loop containing a parameter which goes with the URL, next step needs to be try getting this into an array so you can load as many parameters as you want
	for i in `seq 1 $num_requests`; do printf "Request: $i\n"; make_request_with_params $url 'title' 'body' | tee -a $test_filename; done

	extract_contents $test_filename
	echo "Number of requests made: $num_requests"
	# The test file is flushed after the requests are printed to prevent cross-contamination of other tests
	rm $test_filename

	#req=`make_request_with_params $url 'help' `
	#echo $req

	exit 0
}

# Header of csv file to give each file a feature to be extracted
print_header() {
	echo "code,time_total,time_connect,time_appconnect,time_starttransfer"
}

# Making the request to target url
make_request() {
	local target_url=$1
	# Needs the full URL with the params inside it
	curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" --silent --output /dev/null "$target_url"

	# Test call of curl which shows that the function generating the parameter data actually works	
	#curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" "$target_url?help=$(gen_param_data)"

	# Add two parameter variables which take the gen_data as data but the parameter needs to be the cli argument

	# Taking a parameter and appending the random data into a parameter
	#local param_1_data="$target_url?param1=$(gen_param_data)&param2=$(gen_param_data)"
	# The parameters need to be added into the 

	# Echo for testing purposes
	#echo $param_1_data
}

make_request_with_params() {
	local target_url=$1
	local params=("$@")

	# One parameter noisy
	#curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" "$target_url?${params[1]}=$(gen_param_data)"
	# Two parameters quiet
	curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" --silent --output /dev/null "$target_url?${params[1]}=$(gen_param_data)&${params[2]}=$(gen_param_data)"
	# Two parameters noisy
	#curl --write-out "%{http_code},%{time_total},%{time_connect},%{time_appconnect},%{time_starttransfer}\n" --silent /dev/null "$target_url?${params[1]}=$(gen_param_data)&${params[2]}=$(gen_param_data)"
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
	for val in $values; do awk -v n="$val" 'BEGIN{ printf int(n*10+0.5) "\n"}'; done
	printf "\nLargest value extracted (Seconds): "
	# Extract the given column number from the filename and print out the exact decimal value using reverse sort and printing the first available value using the head command to print the top of the file
	largest=`cut -d , -f $column_number $filename | grep -Eo '[0]+\.[0-9]+' | sort -rn | head -n 1`
	awk -v n="$largest" 'BEGIN{ printf int(n*10+0.5) "\n"}'
	printf "Exact value: $largest\n"
}

# Generates the data needed for the parameters
gen_param_data() {
	openssl rand -base64 20
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
# openssl rand -base64 10 - Can use this as a simpler solution which can then go into the ongoing requests
# grep "input type=" Login.aspx | cut -d = -f 3 | awk {'print $1'} | grep \" | sed 's/^"//' | sed 's/"$//

usage "$@"
main "$@"
