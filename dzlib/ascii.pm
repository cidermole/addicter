#!/usr/bin/perl
# Funkce pro převedení všech znaků Unikódu na malá písmena ASCII kvůli porovnávání a hledání.
# (c) 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package ascii;
use utf8;



#------------------------------------------------------------------------------
# Inicializuje převodní tabulku.
#------------------------------------------------------------------------------
BEGIN
{
    use charnames ();
    # Latinským písmenům s diakritikou přiřadit odpovídající písmena bez diakritiky.
    for(my $i = 128; $i<1024; $i++)
    {
        my $char = chr($i);
        my $name = charnames::viacode($i);
        if($name =~ m/^(LATIN (CAPITAL|SMALL) LETTER \w+) WITH /i)
        {
            my $basename = $1;
            my $basecode = charnames::vianame($basename);
            if($basecode)
            {
                my $basechar = chr($basecode);
                $tr{$char} = $basechar;
                #print STDERR ("$char => $basechar\t$i => $basecode\t$name\t=> $basename\n");
            }
        }
    }
}



#------------------------------------------------------------------------------
# Převede text na pokud možno ASCII, ale nepřevádí velká písmena na malá.
#------------------------------------------------------------------------------
sub ascii
{
    my $text = shift;
    my @znaky = split(//, $text);
    @znaky = map {exists($tr{$_}) ? $tr{$_} : $_} (@znaky);
    $text = join("", @znaky);
    return $text;
}



#------------------------------------------------------------------------------
# Převede text na malá písmena pokud možno ASCII.
#------------------------------------------------------------------------------
sub zjednodusit
{
    my $text = shift;
    return lc(ascii($text));
}



1;
