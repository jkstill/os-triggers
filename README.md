
# OS Triggers

These are scripts that perform an action when triggered by some external event.

For instance, if the system load goes above N , then collect some metrics and send an email

## os-trigger.sh

There are two basic types of tests:

- those that return an integer
- those that return a string

Integer based tests are checked by comparing the value returned by the test to a threshold value

For instance if the test was on the current load average

  threshold=10
  loadavg=12

  if loadavg >= threshold
     perform actions
  fi

The string based tests are somewhat different.

Suppose the test returns a value of 'PASS' when everything is OK.

This can be tested with the regular expression ^PASS$

Anything that does not match this regex will trigger actions

  if [[ $retVal =~ $regex ]]
     do nothing
  else
     perform actions
  fi

### Example using integer based tests

```bash

>  iterations=3 interval=2 triggerThreshold=0  triggerClass=loadAvg  help=0 dryRun=0 debug=0 ./os-trigger.sh
loadConf  triggerClass: loadAvg
loadConf      testName: sardisk
loadConf      compType: int
loadConf      compVal:
loadConf           cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-disk-${d}; LC_TIME=POSIX /usr/bin/sar -d > $f)

loadConf  triggerClass: loadAvg
loadConf      testName: sarmem
loadConf      compType: int
loadConf      compVal:
loadConf           cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-mem-${d}; LC_TIME=POSIX /usr/bin/sar -r > $f)

loadConf  triggerClass: loadAvg
loadConf      testName: sarload
loadConf      compType: int
loadConf      compVal:
loadConf           cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-load-${d}; LC_TIME=POSIX /usr/bin/sar -u > $f)

loadConf  triggerClass: loadAvg
loadConf      testName: test
loadConf      compType: int
loadConf      compVal:  1
loadConf           cmd: ( cut -f1 -d' ' /proc/loadavg | cut -f1 -d. )


Running for 3 iterations at an interval  of 2 seconds.

Total runtime is approximately 6 seconds

Triggers: int chr
Triggers: intActions chrActions
runCompType: sarmem sarload sardisk test
runCompType: int int int int
class: loadAvg
type: int
Trigger Val: 0
     Trigger Type: loadAvg
Trigger Threshold: 0
Trigger Value of 0 is excessive
intActions key: sarmem
intActions key: sarload
intActions key: sardisk


```

Files produced as per .os-trigger.conf

```bash
>  ls -l ~/sardump/*
-rw-r--r-- 1 jkstill dba 609417 Apr 10 18:05 /home/jkstill/sardump/sar-disk-2019-04-10_18-05-15
-rw-r--r-- 1 jkstill dba  43589 Apr 10 18:05 /home/jkstill/sardump/sar-load-2019-04-10_18-05-15
-rw-r--r-- 1 jkstill dba  60997 Apr 10 18:05 /home/jkstill/sardump/sar-mem-2019-04-10_18-05-15
```

### Example using string based tests

```bash
 iterations=3 interval=2  triggerClass=oraRegex  help=0 dryRun=0 debug=0 ./os-trigger.sh
loadConf  triggerClass: oraRegex
loadConf      testName: aasload
loadConf      compType: chr
loadConf      compVal:
loadConf           cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/aas-dump; f=~/aas-dump/aas-load-${d}; $HOME/linux/os-triggers/aas-rpt.sh > $f )

loadConf  triggerClass: oraRegex
loadConf      testName: test
loadConf      compType: chr
loadConf      compVal:  ^PASS$
loadConf           cmd: ( $HOME/linux/os-triggers/regex-test.sh )


Running for 3 iterations at an interval  of 2 seconds.

Total runtime is approximately 6 seconds

Triggers: int chr
Triggers: intActions chrActions
runCompType: aasload test
runCompType: chr chr
class: oraRegex
type: chr
Trigger Val: PASS
current interation: 0
#################################################
class: oraRegex
type: chr
Trigger Val: PASS
current interation: 1
#################################################
class: oraRegex
type: chr
Trigger Val: FAIL
     Trigger Type: oraRegex
Trigger Threshold: ^PASS$
Trigger Value of FAIL is excessive
chrActions key: aasload
current interation: 2
```

## ~/.os-trigger.conf

Place this file in your home directory


```bash
# configuration for the os-trigger.sh script
# currently this is just a colon separated list of commands to execute
# format:
# testclass : testname : comparison type [int|chr] : comparison value : ( test commands )
# breakdown of fields
#
#         testclass: grouping of the test and actions
#
#          testname: a name that is unique within the testclass group
#                    exactly one must be named 'test'
#
#   comparison type: does the test return an integer or a character string?
#                    integers will be compared to the threshold value with '>='
#                    strings will be matched with a regular expression
#
#  comparison value: When the comparison type is 'chr' this is a regular expression used to match  the test results
#                    For a type of 'int' this  is just an integer value
#                    This field is required only for the 'test' cmd lines, and may be otherwise empty
#                   
#               cmd: This are the commands to run for each action or test
#                    Exactly one of these lines for each testclass must be 'test'
#                    The parantheses may not be necessary, but I like them for visual effect I find it easier to see the entire command string this way
# 
# loadAvg:sardisk:int::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-disk-${d}; LC_TIME=POSIX /usr/bin/sar -d > $f)
# provide a key name and the script or executable
loadAvg:sardisk:int::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-disk-${d}; LC_TIME=POSIX /usr/bin/sar -d > $f)
loadAvg:sarmem:int::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-mem-${d}; LC_TIME=POSIX /usr/bin/sar -r > $f)
loadAvg:sarload:int::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-load-${d}; LC_TIME=POSIX /usr/bin/sar -u > $f)
loadAvg:test:int:1:( cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
oraAAS:aasload:int::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/aas-dump; f=~/aas-dump/aas-load-${d}; $HOME/linux/os-triggers/aas-rpt.sh > $f  )
oraAAS:test:int:1:( $HOME/linux/os-triggers/aas-test.sh )
oraRegex:aasload:chr::( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/aas-dump; f=~/aas-dump/aas-load-${d}; $HOME/linux/os-triggers/aas-rpt.sh > $f  )
oraRegex:test:chr:^PASS$:( $HOME/linux/os-triggers/regex-test.sh )
```



