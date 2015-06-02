#!/usr/bin/perl
# Rozloží závorkování Penn na pole slov a pole složek.
# (c) 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package penn;
use utf8;



#------------------------------------------------------------------------------
# Rozloží závorkování (složkový strom ve formátu Penn) na pole symbolů (závorek
# s neterminály, terminálů a pravých závorek).
#------------------------------------------------------------------------------
sub zsplit
{
    # Příklad: (TOP (S (NP (NN John)) (VP (VB loves) (NP (NN Mary))) (. .)))
    my $strom = shift;
    # Odstranit konec řádku.
    $strom =~ s/\r?\n$//;
    # Před každou levou i pravou závorku vložit mezeru pro případ, že tam ještě není.
    $strom =~ s/([\(\)])/ $1/g;
    # Přebytečné mezery zase umazat. Zejména je nechceme na začátku a na konci, aby nevzniklo prázdné slovo.
    $strom =~ s/^\s+//s;
    $strom =~ s/\s+$//s;
    $strom =~ s/\s+/ /sg;
    # Rozdělit závorkování na pole symbolů. Některé jsou terminály, některé levé závorky s neterminály, některé pravé závorky.
    my @symboly = split(/\s+/, $strom);
    return @symboly;
}



#------------------------------------------------------------------------------
# Převezme závorkování v poli (tak, jak by ho vrátila funkce zsplit) a vrátí
# řetězec, který se dá přímo vypsat. Od obyčejného join() se liší tím, že maže
# přebytečné mezery a na konec přidává zalomení řádku.
#------------------------------------------------------------------------------
sub zjoin
{
    my @symboly = @_;
    my $strom = join(" ", @symboly);
    $strom =~ s/^\s+//s;
    $strom =~ s/\s+$//s;
    $strom =~ s/\s+/ /gs;
    $strom =~ s/\s+\)/\)/g;
    $strom .= "\n";
    return $strom;
}



#------------------------------------------------------------------------------
# Rozloží závorkování (složkový strom ve formátu Penn) na pole slov a pole
# složek.
#------------------------------------------------------------------------------
sub decompose
{
    # Příklad: (TOP (S (NP (NN John)) (VP (VB loves) (NP (NN Mary))) (. .)))
    my $strom = shift;
    my @slova;
    my @slozky;
    my @symboly = zsplit($strom);
    # Projít pole zleva doprava. Rozpracované složky ukládat na zásobník, hotové do pole složek.
    # Pamatovat si průběžnou pozici v původní větě (0 je před prvním slovem, N je za N-tým slovem).
    my @zasobnik;
    my $pozice = 0;
    for(my $i = 0; $i<=$#symboly; $i++)
    {
        # Levou závorkou začíná nová složka. Uložit do zásobníku jako rozpracovanou.
        if($symboly[$i] =~ m/^\((.*)/)
        {
            my $neterminal = $1;
            # Odtrhnout z neterminálu funkci, pokud ji obsahuje.
            my $funkce;
            if($neterminal =~ m/^(.*?)=(.*)$/)
            {
                $neterminal = $1;
                $funkce = $2;
            }
            my %slozka = ("label" => $neterminal, "fun" => $funkce, "i" => $pozice);
            push(@zasobnik, \%slozka);
        }
        # Pravou závorkou končí složka. Vyjmout rozpracovanou ze zásobníku a dokončit ji.
        elsif($symboly[$i] =~ m/^\)/)
        {
            my $slozka = pop(@zasobnik);
            $slozka->{j} = $pozice;
            # Všechny složky, které předcházejí právě dokončené složce, vejdou
            # se do jejího rozsahu a nemají dosud rodiče, jsou jejími dětmi.
            my @prava_strana;
            for(my $k = $#slozky; $k>=0 && $slozky[$k]{i}>=$slozka->{i}; $k--)
            {
                unless($slozky[$k]{parent})
                {
                    $slozky[$k]{parent} = $slozka;
                    unshift(@prava_strana, $slozky[$k]{label});
                }
            }
            $slozka->{rhs} = join(" ", @prava_strana);
            push(@slozky, $slozka);
        }
        # Slovo, které nezačíná závorkou, je obyčejný terminál.
        else
        {
            push(@slova, $symboly[$i]);
            $pozice++;
        }
    }
    # Zabalit výsledek do hashe.
    my %vysledek =
    (
        "slova" => \@slova,
        "slozky" => \@slozky
    );
    return \%vysledek;
}



1;
