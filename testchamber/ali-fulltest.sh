#!/bin/bash

ali=$1

if [[ -z $ali ]]
then
	echo "Usage: ./alitestfull.sh alignment-id"
	exit 1
fi

for corp in cu-bojar cu-tectomt google pctrans
do
	./finderrs.pl dt/corps/src dt/corps/$corp dt/corps/ref dt/ali/$corp.$ali > dt/errs/$corp.$ali
	cat dt/errs/$corp.$ali | ./err2flags.pl > dt/flagged/$corp.$ali
done

./evalflagged.pl <( cat dt/flagged/*.man ) <(cat dt/flagged/*.$ali) <( ./times4.sh dt/corps/ref ) > dt/eval/all.$ali
