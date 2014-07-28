ab-multipath
============

Load test multiple paths on a domain with Apache Benchmark (ab)... a crappy but quick way to generate load.

Original work by Alain Kelder: http://giantdorks.org/alain/simple-script-to-test-website-performance/

Script needs four arguments, where:

* 1. Number of times to repeat test (e.g. 10)
* 2. Total number of requests per run (e.g. 100)
* 3. How many requests to make at once (e.g. 50)
* 4. URL of the site to test (e.g. http://giantdorks.org/)

Example:

./load.sh 10 100 50 http://giantdorks.org/

The above will send 100 GET requests (50 at a time) to http://giantdorks.org. The test will be repeated 10 times.

### @todo

* add run start time so it's easy to trace back in logs and newrelic 
* make paths configurable, currently hardcoded in for loop
* more useful output?
* quick benchtesting tips in readme?