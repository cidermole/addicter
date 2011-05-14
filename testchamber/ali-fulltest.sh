#!/bin/bash

ali=$1

if [[ -z $ali ]]
then
	echo "Usage: ./ali-fulltest.sh alignment-id"
	exit 1
fi

echo find errors
./finderrs.pl dt/corps/srcX4 dt/corps/hyp-all dt/corps/refX4 dt/ali/all.$ali > dt/errs/all.$ali

echo convert to flagged format
cat dt/errs/all.$ali | ./err2flags.pl > dt/flagged/all.$ali

echo compare to manual tags
./evalflagged.pl dt/flagged/all.man dt/flagged/all.$ali dt/corps/refX4 > dt/eval/all.$ali

echo 'done!'
