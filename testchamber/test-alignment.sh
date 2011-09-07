#!/bin/bash

ref=$1
hyp=$2
ali=$3

if [[ -z "$ref" || -z "$hyp" || -z "$ali" ]]
then
	echo "Usage: test-alignment.sh reference-file hypothesis-file alignment-file"
	exit 1
fi

./finderrs.pl <(cat "$hyp" | sed -e "s/^.*/(dummy text)/g") "$hyp" "$ref" "$ali" | ./err2hjerson.pl
