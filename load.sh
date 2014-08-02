#!/bin/bash
 
if ! [ -x "$(type -P ab)" ]; then
  echo "ERROR: script requires apache bench"
  echo "For Debian and friends get it with 'apt-get install apache2-utils'"
  echo "If you have it, perhaps you don't have permissions to run it, try 'sudo $(basename $0)'"
  exit 1
fi
 
if [ "$#" -ne "5" ]; then
  echo "ERROR: script needs four arguments, where:"
  echo
  echo "1. Number of times to repeat test (e.g. 10)"
  echo "2. Total number of requests per run (e.g. 100)"
  echo "3. How many requests to make at once (e.g. 50)"
  echo "4. URL of the site to test (e.g. http://giantdorks.org/)"
  echo "5. File with paths to test, one path per line (e.g. ./test_paths) - optional"
  echo
  echo "Example:"
  echo "  $(basename $0) 10 100 50 http://giantdorks.org ./test_paths"
  echo 
  echo "The above will send 100 GET requests (50 at a time) to http://giantdorks.org for each path in test_paths. The test will be repeated 10 times."
  exit 1
else
  runs=$1
  number=$2
  concurrency=$3
  site=$4
  file=$5
fi

# Report test start event to newrelic.com
NEW_RELIC_API_KEY="7d78436d33a8106364ef06556bfb6ebd78361dc4ce2afac"
NEWRELIC_APP_ID="4766364"

curl -s -H "x-api-key:$NEW_RELIC_API_KEY" -d "deployment[application_id]=$NEWRELIC_APP_ID" -d "deployment[description]=Load test $site with $runs runs of -n $number -c $concurrency" -d "deployment[user]=Load Test" https://api.newrelic.com/deployments.xml > /dev/null
#curl -s -H "x-api-key:7d78436d33a8106364ef06556bfb6ebd78361dc4ce2afac" -d "deployment[application_id]=4766364" -d "deployment[description]=Load test site with 1 runs of -n 1x -c 1x" -d "deployment[user]=Load Test" https://api.newrelic.com/deployments.xml
 
log=ab.$(echo $site | sed -r 's|https?://||;s|/$||;s|/|_|g;').log
 
if [ -f $log ]; then
  echo removing $log
  rm $log
fi
 
echo "=================================================================="
echo " Results"
echo "=================================================================="
echo " site .......... $site"
echo " requests ...... $number"
echo " concurrency ... $concurrency"
echo "------------------------------------------------------------------"

#while read line; do
#  paths="$paths $line"
#done < $file

for run in $(seq 1 $runs); do
  #for path in $paths; do
  while read path; do
  #for path in / /js/iag_branch_locator/getgeo /iag_quotes/start /self-service-centre /claims /payments /contact-us /contact-us/branch /motorcycle-insurance /faq /help-information /insurance /home-insurance /home-buildings-insurance /quote-exit/ctp-insurance; do
    echo 'Load testing '$site$path
    ab -c$concurrency -n$number $site$path >> $log
    echo " run $run:"
    echo -e " Requests per second: \t $(grep "^Requests per second" $log | tail -1 | awk '{print$4}') reqs/sec"
    echo -e " Failed requests: \t $(grep "^Failed requests" $log | tail -1 | awk '{print$3}')"
    echo -e " Write errors: \t\t $(grep "^Write errors" $log | tail -1 | awk '{print$3}')"
    echo -e " Non-2xx: \t\t $(grep "^Non-2xx responses" $log | tail -1 | awk '{print$3}')"
    echo -e " Transfer rate: \t $(grep "^Transfer rate" $log | tail -1 | awk '{print$3}')"

  done < $file
done
 
avg=$(awk -v runs=$runs '/^Requests per second/ {avgsum+=$4; avg=avgsum/runs} END {print avg}' $log)
fail=$(awk -v runs=$runs '/^Failed requests/ {failsum+=$3; fail=failsum} END {print fail}' $log) 
non2xx=$(awk -v runs=$runs '/^Non-2xx responses/ {non2xxsum+=$3; non2xx=non2xxsum} END {print non2xx}' $log)

echo "------------------------------------------------------------------"
echo " average ....... $avg requests/sec"
echo " total ......... $fail Failed requests"
echo " total ......... $non2xx Non-2xx responses"
echo
echo "see $log for details"
