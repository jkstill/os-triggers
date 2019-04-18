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


globals[conf]='';

# load config file
# current directory takes precedence
declare confFileName='.os-trigger.conf'

for dir in ~/ ./
do
	[[ -f ${dir}${confFileName} ]] && { globals[conf]=${dir}${confFileName}; }
done

echo "using configuration file: ${globals[conf]}"

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
	#stub intActions	

	for key in ${!runCmds[@]}
	do

		if [[ ${globals[dryRun]} == true ]]; then
			echo "DRY RUN: ${runCmds[$key]}"
		else
			if [[ $key != 'test' ]]; then
				echo intActions key: $key
				eval "${runCmds[$key]}";
			fi
		fi 
	done

}

intChk () {
	declare val2chk=$1

	# should be numeric
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

: << 'WORKAROUND'

There are still many systems with Bash that is too old to have 'declare -n'

So using a workaround with 'print -v'

WORKAROUND

intTest () {

	#declare -n retVal=$1
	#retVal=$( eval ${runCmds[test]} )

	# example of code that is executed
	#loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )

	declare varname=$1
	declare retVal=$( eval ${runCmds[test]} )
	printf -v "$varname" "%d" "$retVal"
}


#################################
## oracle AAS  subroutines
#################################

chrActions () {
	#stub chrActions	

	for key in ${!runCmds[@]}
	do

		if [[ ${globals[dryRun]} == true ]]; then
			echo "DRY RUN: ${runCmds[$key]}"
		else
			if [[ $key != 'test' ]]; then
				echo chrActions key: $key
				eval "${runCmds[$key]}";
			fi
		fi 
	done

}

chrChk () {
	declare val2chk=$1

	# not checking type of input - can be anything

	# in this case the threshold is a regex to compare	
	# logic is reversed from what is seen in intChk
	# we return succes only when the test fails
	# ie. if we are expecting 'PASS' to be returned as an indication that all is well
	# andthing that is not 'PASS' has failed
	#echo 1>&2 "Regex: |${globals[triggerThreshold]}|"
	if [[ $val2chk =~ ${globals[triggerThreshold]} ]]; then
		echo ${globals[boolFailRetval]}
	else
		echo ${globals[boolSuccessRetval]}
	fi

}

chrTest () {

	# search for 'WORKAROUND' comments
	#declare -n loadVal=$1
	#loadVal=$( eval ${runCmds[test]} )

	# example of command that might be run
	#loadVal=$(cut -f1 -d' ' /proc/loadavg | cut -f1 -d\. )

	declare varname=$1
	declare loadVal=$( eval ${runCmds[test]} )
	printf -v "$varname" "%d" "$loadVal"
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

		if [[ $triggerClass == ${globals[triggerClass]} ]]; then
			echo "loadConf  triggerClass: $triggerClass"
			echo "loadConf      testName: $testName"
			echo "loadConf      compType: $compType"
			echo "loadConf      compVal:  $compVal"
			echo "loadConf           cmd: $cmd"
			echo

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

			runCmds[$testName]="$cmd"
			runCompType[$testName]="$compType"
			runCompVal[$testName]="$compVal"


		fi

	done < <(grep -v '^#' ${globals[conf]}) 

	if [[ ${globals[internalDebug]} == true ]]; then
		echo "=== runCmds ===="
		echo "${!runCmds[@]}"
		echo "${runCmds[@]}"
		echo "=== runCompType ===="
		echo "${!runCompType[@]}"
		echo "${runCompType[@]}"
		echo "=== runCompVal ===="
		echo "${!runCompVal[@]}"
		echo "${runCompVal[@]}"
	fi

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
    This is the name of the group of tests - it is the first field in each line of the config file 

  triggerThreshold=[Integer|String]
    int: Action is taken when the test exceeds this value - defaults to 10
	 chr: Action is taken when the regex 

  iterations=[N]
    The number of iteretions to make in the main process loop
    Default = 100

  interval=[N]
    The number of seconds to pause at the end of each iteration of the loop
	 Default = 10

  maxTriggerEvent=[N]
    The maximum number of triggered events to process before exiting the loop
	 Default = 5

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

globals[iterations]=${iterations:-100}
# exit after this many triggering events
globals[maxTriggerEvents]=${maxTriggerEvents:-5}
globals[interval]=${interval:-10}

loadConf
#exit

# override threshold from CLI
#echo "Trigger Threshold 0: ${globals[triggerThreshold]}"

: ${triggerThreshold:=''}
if [[ -n $triggerThreshold ]]; then
	globals[triggerThreshold]=$triggerThreshold
fi

#echo "Trigger Threshold 1: ${globals[triggerThreshold]}"

# debug tests configured for loadAvg
# debug will override some values
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

#exit

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

	#echo "Test function: ${triggerChecks[${runCompType[test]}]}"
	#testVal=$(${triggerChecks[${runCompType[test]}]} $currTriggerVal)
	#echo "testVal: $testVal"

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

	echo "#################################################"

	sleep  ${globals[interval]}

done


