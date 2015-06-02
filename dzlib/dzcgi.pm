#!/usr/bin/perl
# Knihovna funkcí pro cgi skripty.
# (c) 2002 - 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package dzcgi;
use utf8; # říct Perlu, že tento zdroják je v UTF-8
use Encode; # aby se mohly číst parametry ze souboru v UTF-8
use URI::Escape;



#-----------------------------------------------------------------------------
# Dekóduje bajty schované za procentem. S výsledkem naloží jako s řetězcem
# bajtů, které kódují znakový řetězec metodou UTF-8 (u většiny řetězců, které
# získáme z formulářů, to skutečně tak bude).
#-----------------------------------------------------------------------------
sub dekodovat_old # Z nějakého důvodu to nefungovalo správně, když se v zakódovaném textu vyskytlo "%25", tj. "%".
{
    my $parametr = shift;
    # Dekódovat mezeru (je zapsána jako "+").
    $parametr =~ s/\+/ /g;
    # Dekódovat bajty zapsané jako procenta.
    # Samotné procento (zakódované jako %25) dekódovat až nakonec.
    while($parametr =~ m/(%[0-9A-F][0-9A-F])/ && $1 ne "%25")
    {
        my $sekv = $1;
        my $znak = chr(hex(substr($sekv, 1, 2)));
        $parametr =~ s/$sekv/$znak/g;
    }
    # Dekódovat procenta.
    $parametr =~ s/%25/%/g;
    # Dekódovat zalomení řádku.
    $parametr =~ s/(%0D)?%0A/\n/ig;
    # Získali jsme řetězec bajtů v UTF-8. Převést na unikódový řetězec znaků.
    $parametr = decode("utf8", $parametr);
    return $parametr;
}
sub dekodovat
{
    my $parametr = shift;
    $parametr =~ s/\+/%20/g;
    $parametr = uri_unescape($parametr);
    $parametr = decode('utf8', $parametr);
    return $parametr;
}



#-----------------------------------------------------------------------------
# Převede text v UTF-8 na řetězec bajtů a každý bajt zakóduje pro použití
# v URL (procento a hexadecimální číslo 00-FF).
#-----------------------------------------------------------------------------
sub zakodovat
{
    my $parametr = shift;
    # Převést text na řetězec bajtů (některé znaky UTF-8 odpovídají více než 1 bajtu).
    my $rawbytes = encode("utf8", $parametr);
    # Zakódovat zvláštní znaky v hodnotách i v klíčích.
    my @bajty = split(//, $rawbytes);
    for(my $i = 0; $i<=$#bajty; $i++)
    {
        my $kod = ord($bajty[$i]);
        if($kod<=64 && !($kod>=48 && $kod<=58) && $bajty[$i] !~ m/[\.,]/ || $kod>=128)
        {
            $bajty[$i] = sprintf("%%%02X", $kod);
        }
    }
    $parametry = join("", @bajty);
    return $parametr;
}



#------------------------------------------------------------------------------
# Rozebere řetězec s parametry tvaru "x=7&y=-15.6&..." Společná část pro
# parametry získané různým způsobem (URL, formulář GET, POST...)
#------------------------------------------------------------------------------
sub rozebrat_parametry
{
    my $parametry = $_[0];
#    print("Rozebírám parametry $parametry\n");
    my $uloziste = $_[1]; # odkaz na cílový hash
    my %_lokalni_uloziste; # pro případ, že volající žádné úložiště neposkytl
    if($uloziste eq "")
    {
        $uloziste = \%_lokalni_uloziste;
    }
    # Rozsekat parametry po jednom do pole.
    my @parametry = split(/&/, $parametry);
    # Teď jsou všechny parametry soustředěné v poli @parametry.
    # Projít je a rozebrat.
    for(my $i = 0; $i<=$#parametry; $i++)
    {
        # Jestliže parametrický záznam obsahuje rovnítko, považovat ho za přiřazení atribut=hodnota.
        if($parametry[$i] =~ m/(.*?)=(.*)/)
        {
            my $atribut = dekodovat($1);
            my $hodnota = dekodovat($2);
            # Jestliže je před jménem atributu zavináč, může mít více hodnot a ty se musí uložit do pole.
            if($atribut =~ s/^\@//)
            {
                push(@{$uloziste->{$atribut}}, $hodnota);
            }
            # Jinak nepředpokládáme, že se do tohoto atributu bude přiřazovat vícekrát.
            # Dojde-li k tomu, pozdější přiřazení přepíše hodnotu dřívějšího.
            else
            {
                $uloziste->{$atribut} = $hodnota;
            }
        }
        # Jestliže parametrický záznam neobsahuje rovnítko, považovat ho celý za název boolovského atributu.
        else
        {
            $uloziste->{$parametry[$i]} = 1;
        }
    }
    return $uloziste;
}



#------------------------------------------------------------------------------
# Přečte parametry CGI (jsou v prostředí v proměnné QUERY_STRING, ve tvaru
# atribut=hodnota, jednotlivá přiřazení jsou oddělena ampersandem. Dostaly se
# tam buď jako součást URL za otazníkem, nebo jako data z formuláře používají-
# cího metodu GET. Funkce vrací seznam parametrů v hashi.
#------------------------------------------------------------------------------
sub cist_parametry
{
    # Odkaz na cílový hash (úložiště) je nepovinný, můžeme ho vyrobit tady.
    # Pokud ale skript čte parametry z různých zdrojů, chce je všechny do jednoho
    # hashe a ten si musí vyrobit sám a nám na něj předat odkaz.
    my $uloziste = shift;
    # Parametry dodané jako součást URL nebo formulářovou metodou GET jsou v proměnné prostředí QUERY_STRING.
    my $parametry = $ENV{"QUERY_STRING"};
    my $vysledek = rozebrat_parametry($parametry, $uloziste);
    return $vysledek;
}



#------------------------------------------------------------------------------
# Přečte data z formuláře používajícího metodu POST. Od funkce cist_parametry
# se liší tím, že data čte ze standardního vstupu.
#------------------------------------------------------------------------------
sub cist_formular_post
{
    # Parametry z formuláře dodané metodou POST čekají na standardním vstupu.
    my $parametry;
    my $uloziste = $_[0]; # odkaz na cílový hash
    while(<STDIN>)
    {
        chomp;
        if($parametry ne "")
        {
            $parametry .= "&";
        }
        $parametry .= $_;
    }
    return rozebrat_parametry($parametry, $uloziste);
}



#------------------------------------------------------------------------------
# Přečte parametry z příkazového řádku.
#------------------------------------------------------------------------------
sub cist_parametry_argv
{
    my $uloziste = shift; # odkaz na cílový hash
    # Parametry dodané jako součást URL nebo formulářovou metodou GET jsou v proměnné prostředí QUERY_STRING.
    my $parametry = join("&", @main::ARGV);
    return rozebrat_parametry($parametry, $uloziste);
}



#-----------------------------------------------------------------------------
# Načte parametry ze souboru, jehož jméno dostane.
#-----------------------------------------------------------------------------
sub cist_parametry_ze_souboru
{
    my $jmeno_souboru = $_[0];
    my $parametry = $_[1]; # odkaz na hash
    open(PARAMETRY, $jmeno_souboru); # don't die
    while(<PARAMETRY>)
    {
        chomp;
        $_ = decode("utf8", $_);
        if(m/(.*?)=(.*)/)
        {
            $parametry->{$1} = $2;
        }
    }
    close(PARAMETRY);
}



#-----------------------------------------------------------------------------
# Sestaví parametry tohoto skriptu opět do jednoho řetězce ve stejném formátu
# jako QUERY_STRING. Na požádání některé z nich upraví. Používá se při
# formulování odkazů na spřátelené skripty nebo sebe sama, když chceme
# zachovat všechny parametry až na několik.
#-----------------------------------------------------------------------------
sub sestavit_parametry
{
    my $parametry = shift; # odkaz na hash s původními parametry
    # Zkopírovat hash s parametry a v kopii provést požadované změny.
    my $upravene = upravit_parametry($parametry, @_);
    # Sestavit QUERY_STRING.
    my @parametry;
    while(my ($klic, $hodnota) = each(%{$upravene}))
    {
        # Zakódovat zvláštní znaky v hodnotách i v klíčích.
        $klic = zakodovat($klic);
        $hodnota = zakodovat($hodnota);
        # Po zakódování přidat do seznamu.
        push(@parametry, "$klic=$hodnota");
    }
    my $retezec = join("&amp;", @parametry);
    return $retezec;
}



#-----------------------------------------------------------------------------
# Zkopíruje hash s parametry a v kopii provede úpravy.
#-----------------------------------------------------------------------------
sub upravit_parametry
{
    my $parametry = shift; # odkaz na hash s původními parametry
    # Další parametry této funkce jsou případné požadavky na změny ve tvaru
    # parametr=hodnota.
    my @zmeny = @_;
    my %nove;
    while(my ($klic, $hodnota) = each(%{$parametry}))
    {
        # Z původních parametrů vyházet všechny, jejichž název začínal podtržítkem.
        # Ty jsou dopočítané skriptem a uživatele nezajímají.
        # Rovněž vynechat parametry s prázdnou hodnotou.
        if($klic !~ m/^_/ && $hodnota ne "")
        {
            $nove{$klic} = $hodnota;
        }
    }
    # Aplikovat změny.
    foreach my $zmena (@zmeny)
    {
        if($zmena =~ m/(.*?)=(.*)/)
        {
            # Parametr s prázdnou hodnotou vymazat.
            if($2 eq "")
            {
                delete($nove{$1});
            }
            else
            {
                $nove{$1} = $2;
            }
        }
        # Parametr uvedený bez nové hodnoty se má vymazat.
        else
        {
            delete($nove{$zmena});
        }
    }
    return \%nove;
}



1;
