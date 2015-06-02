# Prochází podstrom složek a souborů, simuluje tedy linuxový příkaz find.
# Narazí-li na složku, do které nemá právo vstoupit nebo ji číst, nebude se o to ani pokoušet.
# Copyright © 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package find;
use utf8;



#------------------------------------------------------------------------------
# Projde podstrom složek a souborů. Na každou složku a soubor s výjimkou '.' a
# '..' zavolá callback funkci, která může se jménem souboru udělat, co chce, a
# u složky navíc musí vrátit 1, pokud se do složky má vlézt dovnitř.
#
# Ukázkové volání: find::go('.', \&find::print);
#------------------------------------------------------------------------------
sub go
{
    my $cesta = shift;
    my $callback = shift;
    my $callback2 = shift; # volitelné: zavolá se ve složce po projití všech podsložek a souborů
    # Vede cesta ke složce, do které máme právo vstoupit a číst její obsah?
    unless(-d $cesta && -r $cesta && -x $cesta)
    {
        return 0;
    }
    # Otevřít složku a načíst její obsah.
    # Pokud to navzdory výše provedenému testu nejde, je něco špatně a nezbývá než hodit výjimku.
    opendir(DIR, $cesta) or die("Nelze číst obsah složky $cesta: $!\n");
    my @obsah = readdir(DIR);
    closedir(DIR);
    # Projít obsah složky a roztřídit si ho podle druhu.
    my %druh;
    foreach my $objekt (@obsah)
    {
        # Odkaz na aktuální složku a jejího rodiče zcela ignorovat.
        if($objekt =~ m/^\.\.?$/)
        {
            $druh{$objekt} = '.';
        }
        # U složek nás zajímá, zda je smíme procházet a číst.
        elsif(-d "$cesta/$objekt")
        {
            if(-r "$cesta/$objekt" && -x "$cesta/$objekt")
            {
                $druh{$objekt} = 'drx';
            }
            else
            {
                $druh{$objekt} = 'd';
            }
        }
        # Soubor nebo cokoli jiného (periferní zařízení?)
        else
        {
            $druh{$objekt} = 'o';
        }
        # Pokud je to symbolický odkaz (na složku nebo na soubor), poznamenat si to taky.
        if(-l "$cesta/$objekt")
        {
            $druh{$objekt} .= 'l';
        }
    }
    # Projít obsah složky ještě jednou. Tentokrát volat callback funkci a případně rovnou procházet děti.
    foreach my $objekt (@obsah)
    {
        next if($druh{$objekt} eq '.');
        my $vysledek = &{$callback}($cesta, $objekt, $druh{$objekt});
        if($druh{$objekt} eq 'drx' && $vysledek)
        {
            go("$cesta/$objekt", $callback, $callback2);
        }
    }
    # Pokud si to volající přál, zavolat ještě callback2 na konci zpracování každé složky.
    if($callback2)
    {
        &{$callback2}($cesta);
    }
}



#------------------------------------------------------------------------------
# Ukázková callback funkce, která vytiskne úplnou cestu k objektu na standardní
# výstup. Její návratová hodnota říká, zda se máme vnořit do aktuálního objektu
# (tj. za předpokladu, že druh objektu je drx, tedy složka, do které smíme
# vstoupit).
#------------------------------------------------------------------------------
sub print
{
    my $cesta = shift;
    my $objekt = shift;
    my $druh = shift;
    print("$cesta/$objekt\n");
    return $druh eq 'drx';
}



1;
