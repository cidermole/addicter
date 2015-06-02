#!/usr/bin/perl
# Knihovna pro hledání neprojektivit ve stromě. Strom je velmi abstraktní, vlastně jen pole odkazů na rodiče.
# Copyright © 2001-2004, 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package neproj;
use utf8;

#------------------------------------------------------------------------------
# Převezme pole, kde j-tý prvek odpovídá j-tému uzlu (slovu věty) a obsahuje
# index i rodiče j-tého uzlu. Vrátí pole o stejném počtu prvků. Hodnotou prvku
# je jednička, jestliže je prvek zavěšen neprojektivně, jinak nula.
#------------------------------------------------------------------------------
sub zjistit
{
    my @strom = @_;
    my @neproj = map {0} (0..$#strom);
    for(my $i = 1; $i<=$#strom; $i++)
    {
        my $z = $i;
        my $r = $strom[$i];
        next if($r==0);
        my ($i0, $i1);
        if($z<$r)
        {
            $i0 = $z;
            $i1 = $r;
        }
        else
        {
            $i0 = $r;
            $i1 = $z;
        }
        for(my $j = $i0+1; $j<$i1; $j++)
        {
            # Zjistit, zda j-tý uzel má mezi svými předky r.
            my $k = $j;
            while($strom[$k]!=0)
            {
                if($strom[$k]==$r)
                {
                    goto proj;
                }
                $k = $strom[$k];
            }
            # Mezi předky j nebylo r nalezeno, uzel z je neprojektivní.
            $neproj[$z] = 1;
            # Skočit sem, pokud právě kontrolované j-té slovo netvoří díru.
            # To neznamená, že mezi řídícím a závislým uzlem se nenajde ještě
            # jiné slovo, které díru tvoří. Název "proj" je tedy zavádějící.
          proj:
        }
    }
    return @neproj;
}



1;
