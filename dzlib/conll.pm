#!/usr/bin/perl
# Knihovna pro čtení a psaní souborů ve formátu CoNLL.
# Copyright © 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package conll;
use utf8;



#------------------------------------------------------------------------------
# Přečte větu. Vrátí ji jako pole polí. Pole má o jeden prvek více než věta
# slov. Prvek s indexem 0 je prázdný a odpovídá kořeni. Ostatní prvky obsahují
# pole hodnot z jednotlivých sloupců. Úmyslně se nesnažíme hodnoty ukládat do
# hashe a dávat jim jména podle významu sloupců pro CoNLL-X shared task. Formát
# je díky tomu obecnější.
#
# Čtení věty skončí prázdným řádkem nebo koncem souboru. Pokud je věta prázdná,
# protože ve vstupním souboru byly dva prázdné řádky za sebou, funkce vrátí
# pole o jediném prázdném prvku s indexem 0. Pokud je věta prázdná, protože
# jsme na konci souboru, funkce vrátí prázdnou hodnotu (tedy ani prázdný prvek
# pro kořen!) Tak může volající poznat, že soubor skončil. Funkce nerozlišuje
# případy, kdy poslední věta souboru je neprázdná a je, resp. není následována
# prázdným řádkem. Dva prázdné řádky na konci už by ale chování změnily.
#------------------------------------------------------------------------------
sub cist
{
    my $handle = shift;
    return if(eof($handle));
    # Založit nultý prvek pro kořen a vložit do něj odkaz na prázdné pole.
    my @veta = ([]);
    while(<$handle>)
    {
        # Odstranit znak konce řádku.
        s/\r?\n$//;
        # Jestliže je řádek prázdný, skončila věta.
        last if(m/^\s*$/);
        # Rozdělit řádek na jednotlivé atributy slova.
        my @slovo = split(/\t/, $_);
        # Přidat slovo do věty.
        push(@veta, \@slovo);
    }
    return \@veta;
}



#------------------------------------------------------------------------------
# Přepíše větu z pole polí do pole hashů, kde klíče jsou názvy sloupců podle
# CoNLL-X (2006) shared task (avšak malými písmeny).
#------------------------------------------------------------------------------
sub pojmenovat_sloupce_2006
{
    my $veta0 = shift; # pole polí
    my @veta1; # pole hashů
    my @nazvy = qw(id form lemma cpostag postag feats head deprel phead pdeprel);
    for(my $i = 0; $i<=$#{$veta0}; $i++)
    {
        my %slovo;
        # Jestliže mají vstupní data méně sloupců, budou některé hodnoty prázdné.
        # U kořene (nultého prvku) budou pravděpodobně všechny hodnoty prázdné.
        for(my $j = 0; $j<=$#nazvy; $j++)
        {
            $slovo{$nazvy[$j]} = $veta0->[$i][$j];
        }
        push(@veta1, \%slovo);
    }
    return \@veta1;
}



1;
