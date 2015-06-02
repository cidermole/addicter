#!/usr/bin/perl
# Filtr na zdroják HTML. Nahrazuje relativní odkazy absolutními URL.
# Copyright © 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package htmlabspath;
use utf8;
use HTML::Parser;
use HTML::Entities;



#--------------------------------------------------------------------------
# Převede relativní webový odkaz na absolutní.
#--------------------------------------------------------------------------
sub zabsolutnit_odkaz
{
    my $odkaz = shift;
    my $zdroj = shift;
    my $debug = shift; # volitelný odkaz na pole, do kterého zaznamenáme všechny změny
    my $odkaz0 = $odkaz;
    # Odstranit ze zdroje případné parametry za otazníkem. Ty na cestu nemohou mít vliv.
    $zdroj =~ s/\?.*$//;
    # Rozebrat zdroj na jednotlivé prvky.
    my $zdroj_protokol;
    my $zdroj_pocitac;
    my $zdroj_cesta;
    my $domena = "[-a-zA-Z0-9_]+";
    if($zdroj =~ s-^(\w+:)//($domena(\.$domena)*)--)
    {
        $zdroj_protokol = $1;
        $zdroj_pocitac = $2;
    }
    # Odstranili jsme protokol a adresu počítače, takže nám zbývá cesta na disku tohoto počítače.
    $zdroj_cesta = $zdroj;
    # Jestliže odkaz začíná určením protokolu, je už absolutní.
    if($odkaz =~ m-^\w+://-i)
    {
        return $odkaz;
    }
    # Jestliže odkaz začíná otazníkem, vzít ze zdroje celou cestu kromě
    # případných parametrů za otazníkem. Ty nahradit novými.
    if($odkaz =~ m/^\?/)
    {
        $zdroj =~ s/\?.*$//;
        push(@{$debug}, "$odkaz0 => $zdroj$odkaz") if(defined($debug));
        return $zdroj.$odkaz;
    }
    # Jestliže odkaz začíná dvěma lomítky, vzít ze zdroje protokol a z odkazu ostatní (počítač a cestu).
    if($odkaz =~ m-^//-)
    {
        my $vysledek = "$zdroj_protokol$odkaz";
        push(@{$debug}, "$odkaz0 => $vysledek") if(defined($debug));
        return $vysledek;
    }
    # Jestliže odkaz začíná lomítkem, vzít ze zdroje protokol a počítač a
    # z odkazu ostatní (cestu).
    if($odkaz =~ m-^/-)
    {
        my $vysledek = "$zdroj_protokol//$zdroj_pocitac$odkaz";
        # Slepit zbytek zdroje s odkazem.
        push(@{$debug}, "$odkaz0 => $vysledek") if(defined($debug));
        return $vysledek;
    }
    # V ostatních případech jde o zcela relativní odkaz.
    my $vysledek;
    # Ze zdroje vzít všechno kromě poslední části cesty (souboru).
    # Je těžké poznat, zda cesta obsahuje určení souboru, nebo ne.
    # Pokud končí lomítkem, neobsahuje soubor.
    if($zdroj =~ m/\/$/)
    {
        $vysledek = $zdroj.$odkaz;
    }
    # Pokud nekončí lomítkem, ale jediná lomítka, která obsahuje, jsou ta
    # těsně za protokolem, také neobsahuje soubor.
    elsif($zdroj !~ m-[^/]/[^/]-) #/)
    {
        $vysledek = "$zdroj/$odkaz";
    }
    # Pokud obsahuje i další lomítka, ale úsek od posledního lomítka do konce
    # neobsahuje tečku (tj. název se neskládá ze základní části a přípony),
    # předpokládáme, že tato část také není soubor.
    elsif($zdroj =~ m-/[^/\.]*$-) #/)
    {
        $vysledek = "$zdroj/$odkaz";
    }
    # V ostatních případech považujeme za soubor část od posledního lomítka
    # do konce.
    else
    {
        $zdroj =~ s-/[^/]*$-/-;
        $vysledek = $zdroj.$odkaz;
    }
    # Vykrátit návraty do nadřazených složek.
    $vysledek =~ s-/[^/]+/\.\./-/-g;
    $vysledek =~ s-/[^/]+/\.\.$-/-g;
    # Odstranit případné zbytečné odkazy na tutéž složku.
    $vysledek =~ s-/\./-/-g;
    $vysledek =~ s-/\.$-/-g;
    push(@{$debug}, "$odkaz0 => $vysledek") if(defined($debug));
    return $vysledek;
}



#------------------------------------------------------------------------------
# Najde ve zdrojáku HTML relativní odkazy a nahradí je absolutními.
#------------------------------------------------------------------------------
sub zabsolutnit_odkazy
{
    my $html = shift; # původní zdroják HTML
    local $prefix = shift; # URL, ze kterého zdroják pochází (od něj se odvíjejí URL relativních odkazů)
    local $debug = shift; # volitelný odkaz na pole, do kterého zaznamenáme všechny změny
    local %stav;
    local $html1; # upravený zdroják HTML
    my $parser = HTML::Parser->new
    (
        start_h => [\&odk_handle_start, "tagname, \@attr"],
        end_h   => [\&odk_handle_end,   "tagname"],
        text_h  => [\&odk_handle_char,  "text"],
    );
    $parser->parse($html);
    return $html1;
}



#------------------------------------------------------------------------------
# Obslouží výskyt počáteční značky prvku XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub odk_handle_start
{
    my $element = shift;
    my %attr = @_;
    # Upravit odkazy.
    if($element =~ m/^(a|link)$/ and $attr{href} =~ m-^/-)
    {
        $attr{href} = zabsolutnit_odkaz($attr{href}, $prefix, $debug);
    }
    elsif($element eq "form" and $attr{action} =~ m-^/-)
    {
        $attr{action} = zabsolutnit_odkaz($attr{action}, $prefix, $debug);
    }
    elsif($element eq "script" and $attr{src} =~ m-^/-)
    {
        $attr{src} = zabsolutnit_odkaz($attr{src}, $prefix, $debug);
    }
    # Opsat HTML na výstup.
    $html1 .= "<$element";
    foreach my $a (keys(%attr))
    {
        $html1 .= " $a=\"$attr{$a}\"";
    }
    $html1 .= ">";
    push(@{$stav{prvky}}, $element);
}



#------------------------------------------------------------------------------
# Obslouží výskyt koncové značky prvku XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub odk_handle_end
{
    my $element = shift;
    pop(@{$stav{prvky}});
    # Na konci stylu zpracovat a vypsat také obsah stylu.
    if($element eq "style")
    {
        $stav{odlozeno} =~ s-\@import\s+"(/.*?)"-\@import "$prefix$1"-sig;
        $html1 .= $stav{odlozeno};
        $stav{odlozeno} = "";
    }
    # Opsat HTML na výstup.
    $html1 .= "</$element>";
}



#------------------------------------------------------------------------------
# Obslouží výskyt textu uvnitř XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub odk_handle_char
{
    my $string = decode_entities(shift);
    # Uvnitř <style> počkat, až bude načteno vše, můžou tam být taky odkazy.
    if($stav{prvky}[$#{$stav{prvky}}] eq "style")
    {
        $stav{odlozeno} .= $string;
    }
    # Opsat text na výstup.
    else
    {
        # Vypisujeme HTML, takže některé entity, které parser převedl na znaky,
        # musíme opět převést na entity, aby se nepovažovaly chybně za součást
        # kódu HTML.
        $string =~ s/&/&amp;/g;
        $string =~ s/</&lt;/g;
        $string =~ s/>/&gt;/g;
        $html1 .= $string;
    }
}



1;
