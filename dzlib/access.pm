##############################################################################
# Poskytuje funkce pro přenos dat mezi databázemi Microsoft Access a Perlem.
# S Accessem spolupracuje prostřednictvím textových souborů, které Access umí
# exportovat i importovat.
#
# (c) 2002 - 2005 Daniel Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL
#
# 9.12.2005 - Začínám pracovat na nové verzi. Základní čtecí funkce už nemá
#             v názvu _access (stejně se musí volat jako access::). UTF-8 už
#             je jediné podporované kódování. Čtecí funkce umí vrátit seznam
#             polí v pořadí, v jakém je uložil Access.
##############################################################################

package access;
use utf8;
use Encode;



#-----------------------------------------------------------------------------
# Přečte tabulku vyexportovanou z MS Access.
# Přečte ji ze souboru, jehož jméno dostane a který si sám otevře a zavře.
#-----------------------------------------------------------------------------
sub cist_tabulku
{
    my $soubor = shift; # jméno souboru
    # další parametry viz cist_otevreno()
    open(TABULKA, $soubor); # při neúspěchu neumírat, protože nevíme, jestli to volající chce
    my $handle = "TABULKA";
    my $tabulka = cist_otevreno($handle, @_);
    close(TABULKA);
    return $tabulka;
}



#-----------------------------------------------------------------------------
# Přečte tabulku vyexportovanou z MS Access.
# Přečte ji z již otevřeného souboru, na nějž dostane handle.
# Názvy polí si zjistí z prvního řádku souboru. Pokud dostane seznam názvů od
# volajícího, načtené názvy ignoruje. Pokud od volajícího dostane odkaz na
# prázdný seznam, vyplní do něj načtené názvy a umožní tak volajícímu později
# uložit tabulku se stejným pořadím sloupců.
#-----------------------------------------------------------------------------
sub cist_otevreno
{
    my $soubor = shift; # handle otevřeného souboru předaný jako typeglob (*STDIN)
    my $nazvy = shift; # odkaz na seznam sloupců, které volající chce, popř. kam se má uložit seznam všech sloupců nalezených v souboru
    my $filtr = shift; # odkaz na proceduru, která vrací -1, pokud se má záznam přeskočit, a +1, pokud se má skončit
    # Nedodal-li volající seznam názvů polí, očekávat je na prvním řádku.
    if($nazvy eq "")
    {
        my @nactene_nazvy = cist_zaznam_access($soubor);
        $nazvy = \@nactene_nazvy;
    }
    # Dodal-li volající prázdné pole na názvy polí, vyplnit mu do něj názvy, které jsme našli.
    elsif($#{$nazvy}<0)
    {
        @{$nazvy} = cist_zaznam_access($soubor);
    }
    # Jestliže volající nedodal filtr, vrátit všechny záznamy.
    if(!defined($filtr))
    {
        $filtr = sub {return 0;};
    }
    # Projít soubor a číst jednotlivé záznamy.
    my @tabulka;
    while(!eof($soubor))
    {
        my @zaznam = cist_zaznam_access($soubor);
        # Přiřadit hodnotám názvy.
        my %zaznam;
        for(my $i = 0; $i<=$#zaznam; $i++)
        {
            $zaznam{$nazvy->[$i]} = $zaznam[$i];
        }
        my $f = eval{$filtr->(\%zaznam)};
        next if($f==-1);
        last if($f==+1);
        push(@tabulka, \%zaznam);
    }
    return \@tabulka;
}



#-----------------------------------------------------------------------------
# Rozebere záznam vyexportovaný z MS Access. Pole jsou oddělena středníky,
# některá mohou být v uvozovkách, potom mohou obsahovat i středník. Mají-li
# obsahovat uvozovky, uvozovky se zdvojí. Nepřevádí se desetinná čárka na
# desetinnou tečku, protože se neví, která pole obsahují desetinná čísla.
# Od funkce dekodovat_zaznam_access() se liší tím, že si záznam i sám přečte
# ze souboru. Díky tomu může načíst i další řádky, když zjistí, že záznam na
# prvním řádku neskončil.
#-----------------------------------------------------------------------------
sub cist_zaznam_access
{
    my $soubor = $_[0]; # file handle
    my $stav = "zacatek";
    my @znaky_vsechny_radky;
    do
    {
        my $radek = decode("utf8", <$soubor>);
        # Zahodit případný konec řádku a zbytek rozsekat na znaky.
        # chomp($radek); nefunguje na linuxu pro windowsovy vstup
        $radek =~ s/[\r\n]+$//;
        my @znaky = split(//, $radek);
        my $i;
        # Oddělující uvozovky zahodit, neoddělující nechat.
        # Oddělující středníky převést na tabulátory, neoddělující nechat.
        # Dosavadní tabulátory převést na &tab;, dosavadní ampersandy na &amp;.
        for($i = 0; $i<=$#znaky; $i++)
        {
            # Zakódovat znaky, které dosud neměly zvláštní funkci, ale teď ji budou
            # mít.
            if($znaky[$i] eq "&")
            {
                $znaky[$i] = "&amp;";
            }
            elsif($znaky[$i] eq "\t")
            {
                $znaky[$i] = "&tab;";
            }
            # Podle toho, v jakém jsme stavu, naložit s uvozovkami a středníky.
            if($stav eq "zacatek")
            {
                if($znaky[$i] eq "\"")
                {
                    $znaky[$i] = "";
                    $stav = "text";
                }
                elsif($znaky[$i] eq ";")
                {
                    $znaky[$i] = "\t";
                    $stav = "zacatek";
                }
                else
                {
                    $stav = "hodnota";
                }
            }
            elsif($stav eq "text")
            {
                if($znaky[$i] eq "\"")
                {
                    if($znaky[$i+1] eq "\"")
                    {
                        # Dvě po sobě jdoucí uvozovky zastupují jednu skutečnou.
                        $znaky[$i+1] = "";
                    }
                    else
                    {
                        # Jedna uvozovka ukončuje stav text.
                        $znaky[$i] = "";
                        $stav = "hodnota";
                    }
                }
            }
            elsif($stav eq "hodnota")
            {
                if($znaky[$i] eq ";")
                {
                    $znaky[$i] = "\t";
                    $stav = "zacatek";
                }
            }
        }
        # Přidat znaky z tohoto řádku na konec pole všech znaků.
        splice(@znaky_vsechny_radky, $#znaky_vsechny_radky+1, 0, @znaky);
        # Pokud řádek skončil a jsme ve stavu text, máme problém. Data zřejmě obsahovala zalomení řádku.
        # Musíme přečíst nejméně jeden další řádek, obsahující pokračování dat.
        if($stav eq "text")
        {
            push(@znaky_vsechny_radky, "\n");
        }
    } while($stav eq "text");
    # Upravený řetězec slepit a pak rozsekat podle tabulátorů.
    # Pozor, split() má tendenci vynechat prázdné prvky na konci pole, ale my chceme vědět, kolik prvků pole má!
    # Poznáme to podle počtu tabulátorů a pole pak uměle natáhneme.
    my $znaky = join("", @znaky_vsechny_radky);
    $znaky =~ s/[^\t]//g;
    my $pocet_tabulatoru = length($znaky);
    my @pole = split(/\t/, join("", @znaky_vsechny_radky));
    $#pole = $pocet_tabulatoru if($#pole<$pocet_tabulatoru);
    # V jednotlivých prvcích pole vrátit do původního stavu skutečné tabulátory
    # a ampersandy. Současně také převést z Windows 1250 do ISO 8859-2.
    for($i = 0; $i<=$#pole; $i++)
    {
        $pole[$i] =~ s/&tab;/\t/g;
        $pole[$i] =~ s/&amp;/&/g;
        # Převést také konce řádků, které byly zakódovány už při exportu z Accessu.
        $pole[$i] =~ s/\\n/\n/g;
    }
    return @pole;
}



#-----------------------------------------------------------------------------
# Rozebere záznam vyexportovaný z MS Access. Pole jsou oddělena středníky,
# některá mohou být v uvozovkách, potom mohou obsahovat i středník. Mají-li
# obsahovat uvozovky, uvozovky se zdvojí. Nepřevádí se desetinná čárka na
# desetinnou tečku, protože se neví, která pole obsahují desetinná čísla.
#-----------------------------------------------------------------------------
sub dekodovat_zaznam_access
{
    # Zahodit případný konec řádku a zbytek rozsekat na znaky.
#    chomp($_[0]); # to nefunguje na linuxu pro windowsovy vstup
    $_[0] =~ s/[\r\n]+$//;
    my @znaky = split(//, $_[0]);
    my $i;
    # Oddělující uvozovky zahodit, neoddělující nechat.
    # Oddělující středníky převést na tabulátory, neoddělující nechat.
    # Dosavadní tabulátory převést na &tab;, dosavadní ampersandy na &amp;.
    my $stav = "zacatek";
    for($i = 0; $i<=$#znaky; $i++)
    {
        # Zakódovat znaky, které dosud neměly zvláštní funkci, ale teď ji budou
        # mít.
        if($znaky[$i] eq "&")
        {
            $znaky[$i] = "&amp;";
        }
        elsif($znaky[$i] eq "\t")
        {
            $znaky[$i] = "&tab;";
        }
        # Podle toho, v jakém jsme stavu, naložit s uvozovkami a středníky.
        if($stav eq "zacatek")
        {
            if($znaky[$i] eq "\"")
            {
                $znaky[$i] = "";
                $stav = "text";
            }
            elsif($znaky[$i] eq ";")
            {
                $znaky[$i] = "\t";
                $stav = "zacatek";
            }
            else
            {
                $stav = "hodnota";
            }
        }
        elsif($stav eq "text")
        {
            if($znaky[$i] eq "\"")
            {
                if($znaky[$i+1] eq "\"")
                {
                    # Dvě po sobě jdoucí uvozovky zastupují jednu skutečnou.
                    $znaky[$i+1] = "";
                }
                else
                {
                    # Jedna uvozovka ukončuje stav text.
                    $znaky[$i] = "";
                    $stav = "hodnota";
                }
            }
        }
        elsif($stav eq "hodnota")
        {
            if($znaky[$i] eq ";")
            {
                $znaky[$i] = "\t";
                $stav = "zacatek";
            }
        }
    }
    # Upravený řetězec slepit a pak rozsekat podle tabulátorů.
    # Pozor, split() má tendenci vynechat prázdné prvky na konci pole, ale my chceme vědět, kolik prvků pole má!
    # Poznáme to podle počtu tabulátorů a pole pak uměle natáhneme.
    my $znaky = join("", @znaky);
    $znaky =~ s/[^\t]//g;
    my $pocet_tabulatoru = length($znaky);
    my @pole = split(/\t/, join("", @znaky));
    $#pole = $pocet_tabulatoru if($#pole<$pocet_tabulatoru);
    # V jednotlivých prvcích pole vrátit do původního stavu skutečné tabulátory
    # a ampersandy.
    for($i = 0; $i<=$#pole; $i++)
    {
        $pole[$i] =~ s/&tab;/\t/g;
        $pole[$i] =~ s/&amp;/&/g;
    }
    return @pole;
}



#------------------------------------------------------------------------------
# Převezme pole skalárů a vypíše je jako řádek hodnot oddělených středníky.
# Pokud některý z nich obsahoval středník nebo uvozovky, obalí ho nejdřív
# uvozovkami. Pokud obsahoval uvozovky, tak je zdvojí.
#------------------------------------------------------------------------------
sub sestavit_zaznam_access
{
    my $zaznam;
    for(my $i = 0; $i<=$#_; $i++)
    {
        $zaznam .= ";" if($i>0);
        if($_[$i] =~ m/[;\"]/)
        {
            # Zneškodnit uvozovky.
            $_[$i] =~ s/\"/\"\"/g;
            # Zneškodnit středníky a všechno ostatní.
            $_[$i] = "\"$_[$i]\"";
        }
        $zaznam .= $_[$i];
    }
    $zaznam .= "\n";
    return $zaznam;
}



#------------------------------------------------------------------------------
# Vypíše tabulku do souboru. Tabulku přebírá jako pole hashů, volitelně se může
# omezit jen na některé řádky a na některé sloupce. Na výstupu je textový (CSV)
# soubor v UTF-8 s hodnotami oddělenými středníkem a v případě potřeby obalený-
# mi uvozovkami. První řádek souboru obsahuje názvy sloupců (polí). Takto ulo-
# ženou tabulku lze znovu načíst funkcí cist_tabulku_access().
#
# Poznámka: tato funkce by se mohla jmenovat psat_tabulku_access(). Výhledově
# chci ale spíše skončit u dvou funkcí, access::cist() a access::psat().
#------------------------------------------------------------------------------
sub psat_otevreno
{
    my $soubor = shift; # handle souboru otevřeného pro zápis (předává se jako *STDOUT)
    my $tabulka = shift; # odkaz na pole hashů
    my $od = shift; # index prvního hashe, který se má vypsat
    my $do = shift; # index posledního hashe, který se má vypsat
    my $nazvy = shift; # odkaz na pole názvů, ovlivní výběr a pořadí sloupců
    binmode($soubor, ":utf8");
    $od = 0 if($od<0 || $od eq "");
    $do = $#{$tabulka} if($do>$#{$tabulka} || $do eq "");
    my @klice = $nazvy ne "" ? @{$nazvy} : keys(%{$tabulka->[$od]});
    my $zaznam = sestavit_zaznam_access(@klice);
    print $soubor ($zaznam);
    for(my $i = $od; $i<=$do; $i++)
    {
        $zaznam = sestavit_zaznam_access(map{$tabulka->[$i]{$_}}(@klice));
        print $soubor ($zaznam);
    }
}



#------------------------------------------------------------------------------
# Vypíše tabulku do souboru. Obálka na funkci psat_otevreno(). Na rozdíl od ní
# nepřebírá handle otevřeného souboru, ale jméno souboru, který si sama otevře.
#------------------------------------------------------------------------------
sub psat
{
    my $soubor = shift; # jméno souboru
    # Při neúspěchu neházet výjimku, protože nevíme, zda to tak volající chce.
    # (V režimu CGI skončí výjimka neurčitým hlášením Internal server error;
    # kromě toho není jasné, jaké kódování by měla používat naše výjimka.)
    open(SOUBOR, ">$soubor");
    psat_otevreno(*SOUBOR, @_);
    close(SOUBOR);
}



#-----------------------------------------------------------------------------
# Převede desetinnou čárku na desetinnou tečku.
#-----------------------------------------------------------------------------
sub prevest_desetinnou_carku
{
    $_[0] =~ s/^(\d+),(\d+)$/$1.$2/;
    return $_[0];
}



1;
