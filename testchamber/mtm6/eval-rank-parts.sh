#!/bin/bash

#
# given a manually annotated file and an automatically annotated file, print a table row with
# error counts and Spearman's rank correlations between them
#
# input: manual_file automatic_file
#
# required format for both files:
# 
# 1::ref-err-cats: the reord~~total reord~~amount miss~~designated for assistance to reord~~the reord~~system is to be divided into two parts .  
# 1::hyp-err-cats: the for reord~~the reord~~system to help ext~~certain reord~~total reord~~amount will be divided into two parts .  
# 
# 2::ref-err-cats: lex~~there infl~~are price lex~~and qualitative categories here reord~~as reord~~well .  
# 2::hyp-err-cats: lex~~here too there infl~~is price and quality categories .  
# ...
#

manfile=$1
autofile=$2
idx=$3

if [[ $idx == 1 ]]
then
	sysname=jane
elif [[ $idx == 2 ]]
then
	sysname=pbt
elif [[ $idx == 3 ]]
then
	sysname=rpbt
else
	sysname=tmp-system-$idx
fi

tmpman=$( tempfile )
tmpauto=$( tempfile )

if [[ -z "$manfile" || -z "$autofile" || -z $idx ]]
then
	echo "Usage: eval-rank-parts.sh manual_file automatic_file idx" 1>&2
	exit 1
fi

head -$[ $idx * 180 ] "$manfile" | tail -180 > $tmpman
head -$[ $idx * 180 ] "$autofile" | tail -180 > $tmpauto

./eval-rank.sh $tmpman $tmpauto $sysname

rm $tmpman $tmpauto
