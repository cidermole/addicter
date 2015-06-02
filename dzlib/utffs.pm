# Práce se soubory, jejichž názvy máme v UTF-8.
# (c) 2006 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package utffs;
use utf8;
use Encode;
require 5.000;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(printstderr encodeterm uglob uopen uopendir ureaddir umkdir ucopy ufex);

# Kódování, ve kterém musí být jména souborů předávaná systémovým funkcím.
$kodovani_system = "cp1250";
# Kódování, které používá terminál.
$kodovani_terminal = $ENV{ComSpec} =~ m/\\cmd\.exe$/ ? 'cp852' : 'utf8';



#------------------------------------------------------------------------------
# Vypíše svůj vstup na STDERR v kódování terminálu.
#------------------------------------------------------------------------------
sub printstderr
{
    if($kodovani_terminal eq 'utf8')
    {
        print STDERR (@_);
    }
    else
    {
        print STDERR (map{encode($kodovani_terminal, $_)}(@_));
    }
}



#------------------------------------------------------------------------------
# Překóduje svůj vstup do kódování terminálu.
#------------------------------------------------------------------------------
sub encodeterm
{
    return map{encode($kodovani_terminal, $_)}(@_);
}



#------------------------------------------------------------------------------
# Jako glob(), ale vstup a výstup v UTF-8.
#------------------------------------------------------------------------------
sub uglob
{
    my $maska = shift;
    # Zdvojit zpětná lomítka v masce.
    $maska =~ s/\\/\\\\/g;
    # Zneškodnit mezery v masce.
    $maska =~ s/ /\\ /g;
    # Překódovat masku do kódování, ve kterém chtějí cesty dostávat systémové funkce.
    $maska = encode($kodovani_system, $maska);
    # Zavolat vestavěný glob().
    my @soubory = glob($maska);
    # Překódovat výsledky zpět do UTF-8.
    @soubory = map{decode($kodovani_system, $_)}(@soubory);
    return @soubory;
}



#------------------------------------------------------------------------------
# Jako open(), ale vstup v UTF-8.
# Po volání uopen(SOUBOR, $cesta) přistupujeme k otevřenému souboru takto:
# while(<utffs::SOUBOR>) {...}
#------------------------------------------------------------------------------
sub uopen
{
    my $handle = shift;
    my $soubor = shift;
    # Zjistit, zda se chystáme číst, nebo psát.
    my $zpracovat = "číst";
    if($soubor =~ m/^>/)
    {
        $zpracovat = "psát do";
    }
    elsif($soubor =~ m/^\|/)
    {
        $zpracovat = "psát do roury";
    }
    elsif($soubor =~ m/\|$/)
    {
        $zpracovat = "číst z roury";
    }
    # Překódovat název souboru do kódování, ve kterém chtějí cesty dostávat systémové funkce.
    my $soubor_system = encode($kodovani_system, $soubor);
    return (open($handle, $soubor_system) or die(encodeterm("Nelze $zpracovat $soubor: $!\n")));
}



#------------------------------------------------------------------------------
# Jako opendir(), ale vstup v UTF-8.
# Po volání uopendir(DIR, $cesta) přistupujeme k otevřené složce takto:
# readdir(utffs::DIR)
#------------------------------------------------------------------------------
sub uopendir
{
    my $handle = shift;
    my $slozka = shift;
    # Překódovat název složky do kódování, ve kterém chtějí cesty dostávat systémové funkce.
    my $slozka_system = encode($kodovani_system, $slozka);
    return (opendir($handle, $slozka_system) or die(encodeterm("Nelze otevřít složku $slozka: $!\n")));
}



#------------------------------------------------------------------------------
# Jako readdir(), ale výstup v UTF-8.
#------------------------------------------------------------------------------
sub ureaddir
{
    my $handle = shift;
    my @soubory = readdir($handle);
    @soubory = map {decode($kodovani_system, $_)} @soubory;
    return @soubory;
}



#------------------------------------------------------------------------------
# Jako mkdir(), ale očekává vstup v UTF-8 a zkontroluje, zda složka už
# neexistuje.
#------------------------------------------------------------------------------
sub umkdir
{
    my $slozka = shift;
    # Překódovat název souboru do kódování, ve kterém chtějí cesty dostávat systémové funkce.
    my $slozka_system = encode($kodovani_system, $slozka);
    unless(-d $slozka_system)
    {
        return (mkdir($slozka_system) or die(encodeterm("Nelze vytvořit $slozka: $!\n")));
    }
    return 1;
}



#------------------------------------------------------------------------------
# Zkopíruje soubor na nové místo s využitím systémových příkazů. Zdrojová a
# cílová cesta se očekává v UTF-8.
#------------------------------------------------------------------------------
sub ucopy
{
    my $zdroj = shift;
    my $cil = shift;
    uopen(ZDR, "<$zdroj");
    uopen(CIL, ">$cil");
    binmode(ZDR, ':raw');
    binmode(CIL, ':raw');
    while(<ZDR>)
    {
        print CIL;
    }
    close(ZDR);
    close(CIL);
}



#------------------------------------------------------------------------------
# Zjistí, zda existuje soubor, složka apod. Používá operátory typu "-f".
# Argumenty očekává v UTF-8.
#------------------------------------------------------------------------------
sub ufex
{
    my $operator = shift;
    my $cesta = shift;
    # Kvůli evalu zdvojit zpětná lomítka v cestě.
    $cesta =~ s/\\/\\\\/g;
    # Překódovat cestu do kódování, ve kterém chtějí cesty dostávat systémové funkce.
    # Překódování se musí provést až uvnitř evalu, jinak by neplatilo, že zdroják
    # evalu je v UTF-8 (což Perl očekává, protože tuto vlastnost zdroják evalu
    # zdědil od nadřazeného zdrojáku).
    return eval("$operator encode(\"$kodovani_system\", \"$cesta\")");
}



1;
