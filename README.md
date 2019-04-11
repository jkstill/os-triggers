
# OS Triggers

These are scripts that perform an action when triggered by some external event.

For instance, if the system load goes above N , then collect some metrics and send an email

## os-trigger.sh

example

```bash

$ maxTriggerEvents=1 help=0 dryRun=0 debug=1 ./os-trigger.sh
loadConf key: sardisk
loadConf cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-disk-${d}; LC_TIME=POSIX /usr/bin/sar -d > $f)
loadConf key: sarmem
loadConf cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-mem-${d}; LC_TIME=POSIX /usr/bin/sar -r > $f)
loadConf key: sarload
loadConf cmd: ( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-load-${d}; LC_TIME=POSIX /usr/bin/sar -u > $f)
loadConf key: test
loadConf cmd: ( cut -f1 -d' ' /proc/loadavg | cut -f1 -d. )
global - interval : 2
global - boolFailRetval : false
global - maxTriggerEvents : 1
global - boolSuccessRetval : true
global - iterations : 3
global - conf : /home/jkstill/.os-trigger.conf
global - dryRun : false
global - internalDebug : true
global - triggerThreshold : 0
global - triggerType : loadAvg

Running for 3 iterations at an interval  of 2 seconds.

Total runtime is approximately 6 seconds

Trigger Val: 0
     Trigger Type: loadAvg
Trigger Threshold: 0
Trigger Value of 0 is excessive
loadActions key: sarmem
loadActions key: sarload
loadActions key: sardisk
loadActions key: test
0
current interation: 0

Max Triggering Events of 1 reached - exiting



```

Files produced as per .os-trigger.conf

```bash
>  ls -l ~/sardump/*
-rw-r--r-- 1 jkstill dba 609417 Apr 10 18:05 /home/jkstill/sardump/sar-disk-2019-04-10_18-05-15
-rw-r--r-- 1 jkstill dba  43589 Apr 10 18:05 /home/jkstill/sardump/sar-load-2019-04-10_18-05-15
-rw-r--r-- 1 jkstill dba  60997 Apr 10 18:05 /home/jkstill/sardump/sar-mem-2019-04-10_18-05-15
```

## ~/.os-trigger.conf

Place this file in your home directory


```bash

# configuration for the os-trigger.sh script
# currently this is just a colon separated list of commands to execute
# for instance
# loadAvg : sar : ( d=$(date '+%Y-%m-%d_%H-%M-%S'; mkdir -p ~/sardump; f=~/sardump/${d}; /usr/bin/sar -d > $f)
# provide a key name and the script or executable
loadAvg:sardisk:( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-disk-${d}; LC_TIME=POSIX /usr/bin/sar -d > $f)
loadAvg:sarmem:( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-mem-${d}; LC_TIME=POSIX /usr/bin/sar -r > $f)
loadAvg:sarload:( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/sardump; f=~/sardump/sar-load-${d}; LC_TIME=POSIX /usr/bin/sar -u > $f)
loadAvg:test:( cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
oraAAS:aasload:( d=$(date '+%Y-%m-%d_%H-%M-%S'); mkdir -p ~/aas-dump; f=~/aas-dump/aas-load-${d}; $HOME/linux/os-triggers/aas-rpt.sh > $f  )
oraAAS:test:( $HOME/linux/os-triggers/aas-test.sh )
```

