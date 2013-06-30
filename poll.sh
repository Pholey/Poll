#!/bin/bash
#
# poll
#
# Author: Tamara Temple <tamouse@gmail.com>
# Created: 2013-06-30
# Time-stamp: <2013-06-30 16:54:19 tamara>
# Copyright (c) 2013 Tamara Temple Web Development
# License: GPLv3
#

# REQUIRES nc.traditional!! (not nc.openbsd)


poll_id='7215679'
answer_id='32748420'
session_host="polldaddy.com"
session_path="/n/f04601649c4e1a4b35354ba1a1bb6fdd/POLLID/TIMEINSECONDS"
polldaddy_host="polls.polldaddy.com"
polldaddy_path="/vote-js.php"
polldaddy_query="p=POLLID&b=0&a=ANSWERID&o=&va=0&cookie=0&n=SESSION&url=TARGETURLSESSION"
target_url='http%3A//forourgloriousleader.weebly.com/poll-testing.html'

time_epoc=$(date "+%s")
echo "***Time in seconds"
echo $time_epoc

session_path=$(echo "$session_path" | sed -e "s/POLLID/$poll_id/" -e "s/TIMEINSECONDS/$time_epoc/")
echo "***Session path"
echo $session_path

sed < request.txt -e "s#PATH#$session_path#" -e "s#HOST#$session_host#" > session_header.$$.txt
echo "***Session  Header"
cat session_header.$$.txt

echo "***Connecting to $session_host with netcat"
nc $session_host 80 < session_header.$$.txt| sed 's/[[:space:]*$]//' | tee session_response.$$.txt

echo "***Extracting Reponse Body"
sed < session_response.$$.txt -e '1,/^$/d' | sed -n -e '2p' | tee session_body.$$.txt

echo "***Extracting Session ID"
perl < session_body.$$.txt -p -e 's/^.*?'"'"'//;s/'"'"'.*$//' | tee session_id.$$.txt
session_id=$(cat session_id.$$.txt)
echo "***Session ID:"
echo $session_id

polldaddy_query=$(echo "$polldaddy_query" | sed -e "s#POLLID#$poll_id#g" -e "s#ANSWERID#$answer_id#g" -e "s#TARGETURL#$target_url#g" -e "s#SESSION#$session_id#g")
echo "***polldaddy_query"
echo $polldaddy_query

echo "***Poll Request"
sed < request.txt -e "s#PATH#$polldaddy_path?$polldaddy_query#" -e "s#HOST#$polldaddy_host#" | tee poll_request.$$.txt

echo "***Submitting Poll"
nc $polldaddy_host 80 < poll_request.$$.txt | tee poll_response.$$.txt
