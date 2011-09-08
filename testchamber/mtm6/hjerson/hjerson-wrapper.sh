#!/bin/bash

#
# produces error flagged output in Hjerson's format, given as input:
#    the reference file, (format: word|pos|lemma word|pos|lemma ...)
#    the hypothesis file, (format: word|pos|lemma word|pos|lemma ...)
#
# prints to stdout
#

ref=$1
hyp=$2

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
$location/generic-wrapper.sh raw_hjerson.py "$ref" "$hyp"
