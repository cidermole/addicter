#!/bin/bash
for x in data/??-??; do ref=$x/*ref.factors; for hyp in $x/*-hyp; do out=$( basename $hyp ); echo $ref $hyp $out; ./mtm-addicter.sh $ref.lc $hyp.factors.lc > $x/outputs/$out.addicter.errs.lc; done; done
