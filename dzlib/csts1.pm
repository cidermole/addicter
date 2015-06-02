#!/usr/bin/perl
# Nová verze knihovny pro čtení a psaní CSTS. Není poplatná češtině a DZ Parseru. Pracuje jen v UTF-8.
# (c) 2006 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package csts;
use utf8;
use open ":utf8";
# HTML parser je tolerantnější k chybám na vstupu než XML parser.
use HTML::Parser;



# Globální proměnné:
$rozectena_veta; # 1 pokud jsme od posledního <s> ještě nezpracovali celou větu
@veta; # pole slov (tj. odkazů na hashe s anotacemi)
$cilcdat; # odkaz na položku hashe, kam se uloží cdata, která právě čteme
$zdroj; # název zdroje anotace, pod kterým se mají uložit cdata, která právě čteme
$podcil; # odkaz na položku hashe v rámci shluku, kam se mají uložit cdata, která právě čteme
$cdata; # rozečtená cdata, tj. text mezi značkami SGML
$zveta; # odkaz na externí funkci, která zpracuje větu



#------------------------------------------------------------------------------
# Čte CSTS ze souboru nebo ze standardního vstupu.
#------------------------------------------------------------------------------
sub cist
{
    $zveta = shift;
    # Výchozí a zatím jediné kódování je UTF-8.
    binmode(STDIN, ":utf8");
    binmode(STDERR, ":utf8");
    # Vytvořit parser.
    my $parser = HTML::Parser->new
    (
        case_sensitive => 1,
        start_h => [\&stag, "tagname, attr"],
        end_h   => [\&etag, "tagname"],
        text_h  => [sub { $cdata .= $_[0] }, "dtext"],
    );
    while(<>)
    {
        # Odstranit konec řádku.
        s/\r?\n$//;
        # Předat řádek parseru.
        $parser->parse($_);
    }
    $parser->eof();
    # Není-li dokument korektně ukončen koncovými značkami SGML, máme poslední větu ještě nezpracovanou.
    if($rozectena_veta)
    {
        zpracovat_vetu();
    }
}



#------------------------------------------------------------------------------
# Obslouží počáteční značku SGML.
#------------------------------------------------------------------------------
sub stag
{
    my $tagname = shift;
    my $attr = shift;
    # Pokud jsme před touto značkou přečetli nějaká CDATA, uložit je.
    ulozit_cdata();
    # Jestliže začíná věta a není dokončeno zpracování předcházející věty, dokončit ho.
    if($tagname eq "s")
    {
        if($rozectena_veta)
        {
            zpracovat_vetu();
            # Vymazat proměnné pro čtení další věty.
            splice(@veta);
        }
        $rozectena_veta = 1;
    }
    # Začíná slovo.
    elsif($tagname =~ m/^[fd]$/)
    {
        $#veta++;
        $cilcdat = "form";
    }
    # Začíná heslo.
    elsif($tagname eq "l")
    {
        $cilcdat = "lemma";
    }
    # Začíná heslo navržené taggerem.
    elsif($tagname eq "MDl")
    {
        $cilcdat = "m";
        $zdroj = "md".$attr->{src};
        $podcil = "lemma";
    }
    # Začíná značka.
    elsif($tagname eq "t")
    {
        $cilcdat = "tag";
    }
    # Začíná morfologická značka navržená taggerem.
    elsif($tagname eq "MDt")
    {
        $cilcdat = "m";
        $zdroj = "md".$attr->{src};
        $podcil = "mtag";
    }
    # Začíná číslo slova ve větě.
    elsif($tagname eq "r")
    {
        $cilcdat = "ord";
    }
    # Začíná číslo rodiče ve větě.
    elsif($tagname eq "g")
    {
        $cilcdat = "parentord";
    }
    # Začíná číslo rodiče navržené parserem.
    elsif($tagname eq "MDg")
    {
        $cilcdat = "s";
        $zdroj = "md".$attr->{src};
        $podcil = "pord";
    }
    # Začíná analytická funkce.
    elsif($tagname eq "A")
    {
        $cilcdat = "afun";
    }
    # Začíná syntaktická značka navržená parserem.
    elsif($tagname eq "MDA")
    {
        $cilcdat = "s";
        $zdroj = "md".$attr->{src};
        $podcil = "stag";
    }
}



#------------------------------------------------------------------------------
# Obslouží koncovou značku SGML.
#------------------------------------------------------------------------------
sub etag
{
    my $tagname = shift;
    # Pokud jsme před touto značkou přečetli nějaká CDATA, uložit je.
    ulozit_cdata();
    # Pokud končí věta nebo prvek nadřazený větě, zpracovat větu.
    if($tagname =~ m/^(s|p|c|doc|csts)$/)
    {
        if($rozectena_veta)
        {
            zpracovat_vetu();
            # Vymazat proměnné pro čtení další věty.
            splice(@veta);
            $rozectena_veta = 0;
        }
    }
}



#------------------------------------------------------------------------------
# Přesune CDATA z globální proměnné do místa určení.
#------------------------------------------------------------------------------
sub ulozit_cdata
{
    # Odstranit přebytečné mezery (zejména zalomení řádku na konci).
    $cdata =~ s/^\s+//s;
    $cdata =~ s/\s+$//s;
    # Uložit do místa určení.
    if($cilcdat eq 'm')
    {
        $veta[$#veta]{m}{$zdroj}[0]{$podcil} = $cdata;
    }
    elsif($cilcdat eq 's')
    {
        $veta[$#veta]{s}{$zdroj}[0]{$podcil} = $cdata;
    }
    elsif($cilcdat ne '')
    {
        $veta[$#veta]{$cilcdat} = $cdata;
    }
    # Vyprázdnit schránku. Příště budeme číst nanovo.
    $cilcdat = '';
    $cdata = '';
}



#------------------------------------------------------------------------------
# Dobuduje datovou strukturu popisující větu a pak zavolá externí funkci, která
# ví, co se má s větou udělat.
#------------------------------------------------------------------------------
sub zpracovat_vetu
{
    # Přidat kořen.
    unshift(@veta, {ord => 0});
    for(my $i = 1; $i<=$#veta; $i++)
    {
        # Zkontrolovat, že každé slovo má ord buď prázdný, nebo odpovídající jeho skutečné pozici ve větě.
        if($veta[$i]{ord} !~ m/^\s*$/ && $veta[$i]{ord} != $i)
        {
            print STDERR (join(" ", map{"$_->{ord}:$_->{form}"}(@veta)), "\n");
            print STDERR ("i = $i, ord = $veta[$i]{ord}\n");
            # Neumírat. Oznámit chybu, opravit ji a pokračovat.
            print STDERR ("The ord attribute does not correspond to the real position of the word in the sentence.\n");
            $veta[$i]{ord} = $i;
            print STDERR ("The value has been corrected to $i.\n");
        }
        # Převést číselné odkazy na rodiče na přímé odkazy do paměti.
        $veta[$i]{parent} = $veta[$veta[$i]{parentord}];
        # Provázat strom i shora dolů: každému uzlu vybudovat seznam odkazů na děti.
        push(@{$veta[$i]{parent}{children}}, $veta[$i]);
    }
    # Zavolat externí zpracovatelskou funkci.
    &{$zveta}(\@veta);
    # Opět zrušit provázání shora dolů, jinak by odkazy byly cyklické a Perl by nemohl uklidit.
    foreach my $slovo (@veta)
    {
        delete($slovo->{children});
    }
}



#------------------------------------------------------------------------------
# Vyrobí z věty CSTS řetězec a vrátí ho.
#------------------------------------------------------------------------------
sub zakodovat
{
    my $veta = shift;
    my $csts = "<s>\n";
    for(my $i = 1; $i<=$#{$veta}; $i++)
    {
        # Zakódovat ve vypisovaných položkách menšítka, většítka a endítka.
        my %zakodovano;
        foreach my $polozka qw(form lemma tag ord parentord afun)
        {
            $zakodovano{$polozka} = $veta->[$i]{$polozka};
            $zakodovano{$polozka} =~ s/&/&amp;/g;
            $zakodovano{$polozka} =~ s/</&lt;/g;
            $zakodovano{$polozka} =~ s/>/&gt;/g;
        }
        $csts .= "<f>$zakodovano{form}";
        $csts .= "<l>$zakodovano{lemma}";
        $csts .= "<t>$zakodovano{tag}";
        $csts .= "<r>$zakodovano{ord}";
        $csts .= "<g>$zakodovano{parentord}";
        $csts .= "<A>$zakodovano{afun}";
        # Projít případné alternativní syntaktické anotace a zakódovat je.
        my @zdroje = sort(keys(%{$veta->[$i]{s}}));
        foreach my $zdroj (@zdroje)
        {
            my $pord = $veta->[$i]{s}{$zdroj}[0]{pord};
            # Odstranit z názvu zdroje případné "md".
            $zdroj =~ s/^md//;
            $csts .= "<MDg src=\"$zdroj\">$pord";
        }
        $csts .= "\n";
    }
    return $csts;
}



#------------------------------------------------------------------------------
# Vypíše větu ve formátu CSTS na standardní výstup.
#------------------------------------------------------------------------------
sub psat_vetu
{
    my $veta = shift;
    print(zakodovat($veta));
}



#------------------------------------------------------------------------------
# Strom je v souboru reprezentován číselnými odkazy od závislého uzlu k řídící-
# mu. Takto lze ovšem zapsat i struktury, které nejsou stromy. Pokud se bojíme,
# že načítaná data mohou být nekorektní, tato funkce je zkontroluje.
#------------------------------------------------------------------------------
sub je_strom
{
    my $anot = shift;
    my $zdroj = shift; # pokud je více struktur, která se má kontrolovat?
    $zdroj = "rodic_vzor" if($zdroj eq "");
    # Zjistit, zda všechny odkazy vedou na existující uzel, zda všechny končí
    # v nule, a netvoří tudíž cykly ani nejde o nesouvislý les.
    for(my $i = 1; $i<=$#{$anot}; $i++)
    {
        # Kvůli cyklům si evidovat všechny uzly, kterými jsme prošli na cestě
        # ke kořeni. Do cyklu totiž můžeme vstoupit až u některého předka!
        my @evidence;
        for(my $j = $i; $j>0; $j = $anot->[$j]{$zdroj})
        {
            if($anot->[$j]{$zdroj} !~ m/^\d+$/ ||
               $anot->[$j]{$zdroj}<0 ||
               $anot->[$j]{$zdroj}>$#{$anot} ||
               $evidence[$j])
            {
                return 0;
            }
            $evidence[$j] = 1;
        }
    }
    return 1;
}



1;
