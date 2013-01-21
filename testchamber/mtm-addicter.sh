#!/bin/bash

#
# produces error flagged output in Hjerson's format, given as input:
#    the reference file, (format: word|pos|lemma word|pos|lemma ...)
#    the hypothesis file, (format: word|pos|lemma word|pos|lemma ...)
#    optionally the alignment between them (format: hypidx-refidx hypidx-refidx ...)
#    optionally the source text (format: word word word ...)
#
# prints to stdout
#

ref=$1
hyp=$2
ali=$3
src=$4

#safety function
function ordie {
	if [[ $? -ne 0 ]]
	then
		echo "latest command execution failed: $0 $@; at $( date )"
		exit 1
	fi
}

# check for mandatory arguments
if [[ -z "$ref" || -z "$hyp" ]]
then
	echo "Usage: test-alignment.sh reference-file hypothesis-file [alignment-file] [source-file]" 1>&2
	exit 1
fi

# if source is not given, generate a dummy source file
if [[ -z "$src" ]]
then
	delsrc=yes
	src=$( tempfile )
	
	# generate a file with the same number of lines as the hypothesis, with "(dummy text)" on every line
	cat "$hyp" | sed -e "s/^.*/(dummy text)/g" > "$src"; ordie
fi

# if alignment is not given, apply Addicter's HMM alignment
if [[ -z "$ali" ]]
then
	echo "applying addicter's aligner" 1>&2
	delali=yes
	ali=$( tempfile )
	#./align-hmm.pl -n 2 "$ref" "$hyp" > "$ali"; ordie
	./align-greedy.pl "$ref" "$hyp" > "$ali"; ordie
fi

err=$( tempfile )

echo "finding errors" 1>&2

# find the errors, generate the ugly xml output
./finderrs.pl "$src" "$hyp" "$ref" "$ali" > "$err"; ordie

# transform the ugly xml into pretty error flags
./err2hjerson.pl < "$err"; ordie
#./err2flags.pl < "$err"; ordie

# delete the file with the ugly xml
echo "generated raw: $err" >&2
#rm "$err"

# if the source file was generated, delete it
if [[ ! -z "$delsrc" ]]
then
	echo "generated source: $src" >&2
	#rm $src
fi

# if alignment was generated, delete it
if [[ ! -z "$delali" ]]
then
	echo "generated alignment: $ali" >&2
	#rm $ali
fi
