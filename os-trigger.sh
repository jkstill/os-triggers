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
globals[conf]=~/.os-trigger.conf

declare -A triggerActions
declare -A triggerChecks
declare -A triggerTests
declare -A runCmds


stub () {
	echo "STUB ==>>  $1"
}

# actions to perform if triggered
triggerActions[loadAvg]=loadActions
triggerActions[oraAAS]=aasActions
# evaluate if a value exceeds a threshold
triggerChecks[loadAvg]=loadChk
triggerChecks[oraAAS]=aasChk
# return the value to be tested
triggerTests[loadAvg]=loadTest
triggerTests[oraAAS]=aasTest


#################################
## load average subroutines
#################################

loadActions () {
	#stub loadActions	

	for key in ${!runCmds[@]}
	do

		if [[ ${globals[dryRun]} == true ]]; then
			echo "DRY RUN: ${runCmds[$key]}"
		else
			echo loadActions key: $key
			eval "${runCmds[$key]}";
		fi 
	done

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
	#loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
	loadVal=$( eval ${runCmds[test]} )
}


#################################
## oracle AAS  subroutines
#################################

aasActions () {
	#stub loadActions	

	for key in ${!runCmds[@]}
	do

		if [[ ${globals[dryRun]} == true ]]; then
			echo "DRY RUN: ${runCmds[$key]}"
		else
			echo loadActions key: $key
			eval "${runCmds[$key]}";
		fi 
	done

}

aasChk () {
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

aasTest () {
	declare -n loadVal=$1
	#loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
	loadVal=$( eval ${runCmds[test]} )
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

loadConf () {

	while read line
	do

		triggerType=$(echo $line | cut -f1 -d: )
		key=$(echo $line | cut -f2 -d: )
		cmd=$(echo $line | cut -f3 -d: )

		if [[ $triggerType == ${globals[triggerType]} ]]; then
			echo "loadConf key: $key"
			echo "loadConf cmd: $cmd"
			runCmds[$key]="$cmd"
		fi

	done < <(grep -v '^#' ${globals[conf]}) 
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

  triggerType=[loadAvg|oraAAS|?]
    loadAvg: trigger when load average exceed triggerThreshold - defaults to loadAvg
	 oraAASS: trigger when the value for oracle average active sessions exceeds the triggerThreshold

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
if [[ $dryRun -eq 0 ]]; then
	globals[dryRun]=${globals[boolFailRetval]}
else
	globals[dryRun]=${globals[boolSuccessRetval]}
fi

globals[triggerType]=${triggerType:-loadAvg}
globals[triggerThreshold]=${triggerThreshold:-10}
globals[iterations]=${iteration:-100}
# exit after this many triggering events
globals[maxTriggerEvents]=${maxTriggerEvents:-5}
globals[interval]=${interval:-10}

loadConf
#exit

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
declare triggerEventCount=0
declare currentIteration=0

while [[ $currentIteration -lt ${globals[iterations]} ]] 
do

	if (( triggerEventCount >= globals[maxTriggerEvents] )); then
		echo 
		echo Max Triggering Events of ${globals[maxTriggerEvents] } reached - exiting
		echo
		exit 0
	fi

	${triggerTests[${globals[triggerType]}]} currTriggerVal
	echo "Trigger Val: $currTriggerVal"

	#if [[ $(loadChk 22.3) == true ]]; then
	if [[ $(${triggerChecks[${globals[triggerType]}]} $currTriggerVal ) == true ]]; then
		echo "     Trigger Type: ${globals[triggerType]}"
		echo "Trigger Threshold: ${globals[triggerThreshold]}"
		echo "Trigger Value of $currTriggerVal is excessive"
		${triggerActions[${globals[triggerType]}]} 
		(( triggerEventCount++ ))
	fi

	echo current interation: $currentIteration
	(( currentIteration++ ))

	sleep  ${globals[interval]}

done



