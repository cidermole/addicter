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
sysname=$3

if [[ -z "$manfile" || -z "$autofile" || -z "$sysname" ]]
then
	echo "Usage: eval-rank.sh manual_file automatic_file auto_system_name" 1>&2
	exit 1
fi

#print header
output="|| $sysname ||"
table="evals man auto\n"

#print a row of numbers
for errtype in infl reord miss ext lex
do
	table="$table$errtype "
	
	if [[ $errtype == "ext" ]]
	then
		togrep=hyp
	else
		togrep=ref
	fi
	
	first=yes
	
	for analysisfile in $manfile $autofile
	do
		val=$( cat $analysisfile | grep "$togrep-err-cats" | grep -o "[^ ]\+" | grep -c "$errtype~~" )
		
		if [[ -z $first ]]
		then
			output="$output/$val ||"
		else
			first=""
			output="$output $val"
		fi
		
		table="$table$val "
	done
	
	table="$table\n"
done

rho=$( printf "$table" | ./auxx/spearmans-rank.perl | xargs echo | cut -d " " -f 5 )

output="$output $rho ||\n"

printf "$output";
