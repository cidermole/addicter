#!/bin/bash

#
# given a manually annotated file and an automatically annotaged one (Hjerson's or Addicter's),
# print a confusion matrix of the error flags
#
# input: manual_file automatic_file; both in Hjerson's output format (with flags reversed):
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

if [[ -z "$manfile" || -z "$autofile" ]]
then
	echo "Usage: eval-prec-rec.sh manual_file automatic_file" 1>&2
	exit 1
fi

sysname=$( echo $autofile | cut -d - -f 3- | cut -d . -f 1 | sed -e "s/-/ /g" )

echo -n '!!!'
echo " Evaluating $sysname (ref / hyp tables; left: auto / top: manual):"

for evaltype in ref hyp
do
	(
		./auxx/prec-rec-internal.pl \
			<( cat "$manfile" | grep "$evaltype-err-cats" | cut -d " " -f 2-) \
			<( cat "$autofile" | grep "$evaltype-err-cats" | cut -d " " -f 2-)
	) > .tmp-$evaltype
done

paste -d " " .tmp-ref .tmp-hyp | sed -e "s/||border=1 //"
