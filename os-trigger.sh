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
#globals[conf]=~/.os-trigger.conf
globals[conf]=./.os-trigger.conf

declare -a triggerValidCompType=(int chr)
declare -A triggerActions
declare -A triggerChecks
declare -A triggerTests
declare -A runCompType
declare -A runCompVal
declare -A runCmds


stub () {
	echo "STUB ==>>  $1"
}

# actions to perform if triggered
triggerActions[int]=intActions
triggerActions[chr]=chrActions
# evaluate if a value exceeds a threshold
triggerChecks[int]=intChk
triggerChecks[chr]=chrChk
# return the value to be tested
triggerTests[int]=intTest
triggerTests[chr]=chrTest


#################################
## intger subroutines
#################################

intActions () {
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

intChk () {
	declare val2chk=$1
	# should be numeric
	#if [[ ! $currLoad =~ /[[:alnum:]]+/ ]]; then
	if [[ ! $val2chk =~ [\.|0-9]+ ]]; then
		echo "val2chk $val2chk not numeric"
		exit 1
	fi

	#echo "loadChk: $currLoad"

	if (( $( echo "$val2chk >= ${globals[triggerThreshold]} " | bc ) )); then
		# load exceeded threshold
		echo ${globals[boolSuccessRetval]}
	else
		echo ${globals[boolFailRetval]}
	fi

}

intTest () {
	declare -n retVal=$1
	#loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )
	retVal=$( eval ${runCmds[test]} )
}


#################################
## oracle AAS  subroutines
#################################

chrActions () {
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

chrChk () {
	declare val2chk=$1

	# not checking type of input - can be anything

	# in this case the threshold is a regex to compare	
	if (( $( echo "$val2chk >= ${globals[triggerThreshold]} " | bc ) )); then
		# load exceeded threshold
		echo ${globals[boolSuccessRetval]}
	else
		echo ${globals[boolFailRetval]}
	fi

}

chrTest () {
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

: << 'COMMENT'
declare -A runCompType
declare -A runCompVal
COMMENT

validateType () {
	declare val2chk=$1
	# either of these will work
	printf -- '%s\n' "${triggerValidCompType[@]}" | grep "^$val2chk$" >/dev/null
	#echo "${triggerValidCompType[@]}" | perl -ne 'print join("\n",split(/\s+/,$_))' > /dev/null
	return $?
}

chk4Test () {
	printf -- '%s\n' "${!runCmds[@]}" | grep "^test$" >/dev/null
	return $?
}


loadConf () {

	declare triggerClass
	declare testName
	declare compType
	declare compVal
	declare cmd

	while read line
	do

		triggerClass=$(echo $line | cut -f1 -d: )
		testName=$(echo $line | cut -f2 -d: )
		compType=$(echo $line | cut -f3 -d: )
		compVal=$(echo $line | cut -f4 -d: )
		cmd=$(echo $line | cut -f5 -d: )

		if [[ $testName == 'test' ]]; then 
			if [[ -z $compVal ]]; then
				echo
				echo "line: $line"
				echo 
				echo Test lines must have a comparison value 
				echo
				exit 1
			else
				globals[triggerThreshold]=$compVal
			fi
		fi

		if ! validateType $compType  ; then
			echo
			echo "line: $line"
			echo 
			echo "Comparision type of '$compType' is not valid"
			echo
			echo "Valid Types:"
			printf -- '%s\n' "${triggerValidCompType[@]}" 
			echo
			exit 1
		fi

		if [[ $triggerClass == ${globals[triggerClass]} ]]; then
			echo "loadConf  triggerClass: $triggerClass"
			echo "loadConf      testName: $testName"
			echo "loadConf      compType: $compType"
			echo "loadConf      compVal:  $compVal"
			echo "loadConf           cmd: $cmd"
			echo

			runCmds[$testName]="$cmd"
			runCompType[$testName]="$compType"
			runCompVal[$testName]="$compVal"


		fi

	done < <(grep -v '^#' ${globals[conf]}) 

	if ! chk4Test; then
		echo
		echo "No test named 'test' found"
		echo "Each group of checks must have a 'test'"
		echo
		exit 1
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

  triggerClass=[loadAvg|oraAAS|?]
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

globals[triggerClass]=${triggerClass:-loadAvg}

globals[iterations]=${iteration:-100}
# exit after this many triggering events
globals[maxTriggerEvents]=${maxTriggerEvents:-5}
globals[interval]=${interval:-10}

loadConf
#exit

# override threshold from CLI
if [[ -n $triggerThreshold ]]; then
	globals[triggerThreshold]=$triggerThreshold
fi

# override threshold from CLI
if [[ -n $triggerThreshold ]]; then
	globals[triggerThreshold]=$triggerThreshold
fi


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

echo Triggers: ${!triggerActions[@]}
echo Triggers: ${triggerActions[@]}

echo runCompType: ${!runCompType[@]}
echo runCompType: ${runCompType[@]}

while [[ $currentIteration -lt ${globals[iterations]} ]] 
do

	if (( triggerEventCount >= globals[maxTriggerEvents] )); then
		echo 
		echo Max Triggering Events of ${globals[maxTriggerEvents] } reached - exiting
		echo
		exit 0
	fi

	#${triggerTests[${globals[triggerClass]}]} currTriggerVal
	echo class: ${globals[triggerClass]}
	echo type: ${runCompType[test]}

	${triggerTests[${runCompType[test]}]} currTriggerVal

	#${globals[triggerClass]}
			
	echo "Trigger Val: $currTriggerVal"

	#if [[ $(loadChk 22.3) == true ]]; then
	if [[ $(${triggerChecks[${runCompType[test]}]} $currTriggerVal ) == true ]]; then
		echo "     Trigger Type: ${globals[triggerClass]}"
		echo "Trigger Threshold: ${globals[triggerThreshold]}"
		echo "Trigger Value of $currTriggerVal is excessive"
		#${triggerActions[${globals[triggerClass]}]} 
		${triggerActions[${runCompType[test]}]} 
		(( triggerEventCount++ ))
	fi

	echo current interation: $currentIteration
	(( currentIteration++ ))

	sleep  ${globals[interval]}

done


