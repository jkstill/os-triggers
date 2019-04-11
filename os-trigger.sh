#!/usr/bin/env bash


# referencing undeclared variables is fatal
set -u

# channel where STDOUT is saved

declare -A globals
# define but do not initialize
globals[internalDebug]=''
globals[boolSuccessRetval]=true
globals[boolFailRetval]=false
globals[dryRun]=false

declare -A triggerActions
declare -A triggerChecks
declare -A triggerTests


stub () {
	echo "STUB ==>>  $1"
}

# actions to perform if triggered
triggerActions[loadAvg]=loadActions
# evaluate if a value exceeds a threshold
triggerChecks[loadAvg]=loadChk
# return the value to be tested
triggerTests[loadAvg]=loadTest


#################################
## load average subroutines
#################################

loadActions () {
	stub loadActions	
}

loadChk () {
	declare currLoad=$1
	# should be numeric
	#if [[ ! $currLoad =~ /[[:alnum:]]+/ ]]; then
	if [[ ! $currLoad =~ [\.|0-9]+ ]]; then
		echo "currload $currLoad not numeric"
		exit 1
	fi

	#echo "loadChk: $currLoad"

	if (( $( echo "$currLoad >= ${globals[triggerThreshold]} " | bc ) )); then
		# load exceeded threshold
		echo ${globals[boolSuccessRetval]}
	else
		echo ${globals[boolFailRetval]}
	fi

}

loadTest () {
	declare -n loadVal=$1
	loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
}

disableDebug () {
	globals[internalDebug]=$boolFailRetval
}

enableDebug () {
	globals[internalDebug]=$boolSuccessRetval
}

## use the actual values, not the logical ones
## used for getting/setting state such as when we do not want debug to run

getDebug () {
	echo ${globals[internalDebug]}
}

setDebug () {
	declare debugStateIn=$1

	# bash builtin test cannot do or
	if [ $debugStateIn == true  -o  $debugStateIn -eq 1  ]; then
		globals[internalDebug]=${globals[boolSuccessRetval]}
	else
		globals[internalDebug]=${globals[boolFailRetval]}
	fi
}


# debug is to STDERR
printDebug () {
	declare msg="$@"

	if [[ ${globals[internalDebug]} == true ]]; then
			echo 1>&2 "$msg"
	fi
}

help () {

	 basename $0
 
cat <<-EOF
  Set Variables on the CLI to control
  ( getopts not used)

  debug=[0|1]
    0: do not print debug statements (default)
    1: print debug statements

  dryRun=[0|1]
    0: run all tests (default)
    1: do not run tests - print the CMDs to be run

  triggerType=[loadAvg|?]
    loadAvg: trigger when load average exceed triggerThreshold - defaults to loadAvg

  triggerThreshold=[N|?]
    loadAvg: Action taken when the load average exceeds this value - defaults to 10
	 ?      : add to this as needed

  help=[0|1]
    0: do not show help (default)
    1: show help and exit

EOF

}

###################################
## get/set CLI values
###################################

declare help=${help:-0}

[[ $help -eq 0 ]] || { help; exit 0; }

declare debug=${debug:-0}
setDebug $debug

declare dryRun=${dryRun:-0}
globals[dryRun]=${dryRun}

globals[triggerType]=${triggerType:-loadAvg}
globals[triggerThreshold]=${triggerThreshold:-10}
globals[iterations]=${iteration:-100}
globals[interval]=${interval:-10}

# debug tests configured for loadAvg
if [[ $( getDebug ) == true ]]; then
	globals[iterations]=3
	globals[interval]=2
	globals[triggerThreshold]=0
fi

# print all globals
if [[ $(getDebug) == true ]]; then
	for key in ${!globals[@]}
	do
		echo 1>&2 global - $key : ${globals[$key]}
	done
fi

(( totalRuntime = globals[iterations] * globals[interval] ))

cat << EOF 1>&2

Running for ${globals[iterations]} iterations at an interval  of ${globals[interval]} seconds.

Total runtime is approximately $totalRuntime seconds

EOF

declare currTriggerVal
declare currentIteration=0

while [[ $currentIteration -lt ${globals[iterations]} ]] 
do

	${triggerTests[${globals[triggerType]}]} currTriggerVal
	echo "Trigger Val: $currTriggerVal"

	#if [[ $(loadChk 22.3) == true ]]; then
	if [[ $(${triggerChecks[${globals[triggerType]}]} $currTriggerVal ) == true ]]; then
		echo "     Trigger Type: ${globals[triggerType]}"
		echo "Trigger Threshold: ${globals[triggerThreshold]}"
		echo "Trigger Value of $currTriggerVal is excessive"
		${triggerActions[${globals[triggerType]}]} 
	fi

	echo current interation: $currentIteration
	(( currentIteration++ ))

	sleep  ${globals[interval]}

done









