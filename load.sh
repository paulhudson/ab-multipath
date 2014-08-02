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
 
for run in $(seq 1 $runs); do
  while read path; do 

  #for path in /branches/feed; do
    echo 'Load testing '$site$path
    ab -c$concurrency -n$number $site$path >> $log
    echo " run $run:"
    echo -e " Requests per second: \t $(grep "^Requests per second" $log | tail -1 | awk '{print$4}') reqs/sec"
    echo -e " Failed requests: \t $(grep "^Failed requests" $log | tail -1 | awk '{print$3}')"
    echo -e " Write errors: \t\t $(grep "^Write errors" $log | tail -1 | awk '{print$3}')"
    echo -e " Non-2xx: \t\t $(grep "^Non-2xx responses" $log | tail -1 | awk '{print$3}')"
    echo -e " Transfer rate: \t $(grep "^Transfer rate" $log | tail -1 | awk '{print$3}')"
  #done
  done < FILE
done
 
avg=$(awk -v runs=$runs '/^Requests per second/ {avgsum+=$4; avg=avgsum/runs} END {print avg}' $log)
fail=$(awk -v runs=$runs '/^Failed requests/ {failsum+=$4; fail=failsum/runs} END {print fail}' $log) 

echo "------------------------------------------------------------------"
echo " average ....... $avg requests/sec"
echo " total fails ... $fail Failed requests"
echo
echo "see $log for details"
