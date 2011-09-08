#!/bin/bash

#
# produces error flagged output in Hjerson's format, given as input:
#    the reference file, (format: word|pos|lemma word|pos|lemma ...)
#    the hypothesis file, (format: word|pos|lemma word|pos|lemma ...)
#
# prints to stdout
#

hjerson=$1
ref=$2
hyp=$3

# check for mandatory arguments
if [[ -z "$ref" || -z "$hyp" ]]
then
	echo "Usage: $0 (raw_hjerson.py|raw_hjerson_lemma-wer.py) reference-file hypothesis-file" 1>&2
	exit 1
fi

#safety function
function ordie {
	if [[ $? -ne 0 ]]
	then
		echo "latest command execution failed: $0 $@; at $( date )"
		exit 1
	fi
}

#function for finding the location of this script
function wherearewe {
	prefix=$( pwd )
	suffix=$( dirname $0 )
	firstchar=$( echo $suffix | cut -c 1 )

	if [[ $firstchar == "/" ]]
	then
		scriptdir=$suffix
	else
		scriptdir="$prefix/$suffix"
	fi

	echo $scriptdir
}

location=$( wherearewe )

$location/splitfactors.pl "$ref" 0 > .tmp-ref-sform; ordie
$location/splitfactors.pl "$ref" 2 > .tmp-ref-lemma; ordie
$location/splitfactors.pl "$hyp" 0 > .tmp-hyp-sform; ordie
$location/splitfactors.pl "$hyp" 2 > .tmp-hyp-lemma; ordie

$location/$hjerson -R .tmp-ref-sform -B .tmp-ref-lemma -H .tmp-hyp-sform -b .tmp-hyp-lemma -c .tmp-hjerson-output 1>/dev/null; ordie
$location/reverse-flags.pl < .tmp-hjerson-output; ordie

rm .tmp-hjerson-output .tmp-ref-sform .tmp-ref-lemma .tmp-hyp-sform .tmp-hyp-lemma
