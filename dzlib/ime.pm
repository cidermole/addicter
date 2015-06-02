#!/usr/bin/perl
# Input Method Editor
# Vybrané řetězce v textu nahradí znaky nebo jinými řetězci.
# Slouží ke snadnému zadávání znaků z cizích abeced pomocí české klávesnice.
# Copyright © 2008, 2012, 2013 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package ime;
use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");



#------------------------------------------------------------------------------
# Sestaví převodní tabulku pro písmena odvozená z latinky s diakritikou.
#------------------------------------------------------------------------------
sub sestavit_tabulku_latin
{
    my %tabulka =
    (
        # Písmena s vodorovnou čárkou nahoře (makronem).
        '-Amac-' => "\x{100}", # LATIN CAPITAL LETTER A WITH MACRON
        '-amac-' => "\x{101}", # LATIN SMALL LETTER A WITH MACRON
        '-amactil-' => "\x{101}\x{303}", # a s makronem a tildou
        '-Emac-' => "\x{112}", # LATIN CAPITAL LETTER E WITH MACRON
        '-emac-' => "\x{113}", # LATIN SMALL LETTER E WITH MACRON
        '-emactil' => "\x{113}\x{303}", # e s makronem a tildou
        '-Imac-' => "\x{12A}", # LATIN CAPITAL LETTER I WITH MACRON
        '-imac-' => "\x{12B}", # LATIN SMALL LETTER I WITH MACRON
        '-imactil-' => "\x{12B}\x{303}", # i s makronem a tildou
        '-Omac-' => "\x{14C}", # LATIN CAPITAL LETTER O WITH MACRON
        '-omac-' => "\x{14D}", # LATIN SMALL LETTER O WITH MACRON
        '-omactil-' => "\x{14D}\x{303}", # o s makronem a tildou
        '-Umac-' => "\x{16A}", # LATIN CAPITAL LETTER U WITH MACRON
        '-umac-' => "\x{16B}", # LATIN SMALL LETTER U WITH MACRON
        '-umactil-' => "\x{16B}\x{303}", # u s makronem a tildou
        # Písmena s čárkou doleva (gravem).
        '-Agra-' => "\x{C0}", # LATIN CAPITAL LETTER A WITH GRAVE
        '-agra-' => "\x{E0}", # LATIN SMALL LETTER A WITH GRAVE
        '-Egra-' => "\x{C8}", # LATIN CAPITAL LETTER E WITH GRAVE
        '-egra-' => "\x{E8}", # LATIN SMALL LETTER E WITH GRAVE
        '-Igra-' => "\x{CC}", # LATIN CAPITAL LETTER I WITH GRAVE
        '-igra-' => "\x{EC}", # LATIN SMALL LETTER I WITH GRAVE
        '-Ogra-' => "\x{D2}", # LATIN CAPITAL LETTER O WITH GRAVE
        '-ogra-' => "\x{F2}", # LATIN SMALL LETTER O WITH GRAVE
        '-Ugra-' => "\x{D9}", # LATIN CAPITAL LETTER U WITH GRAVE
        '-ugra-' => "\x{F9}", # LATIN SMALL LETTER U WITH GRAVE
        # Písmena se stříškou (circumflex).
        '-Acir-' => "\x{C2}", # LATIN CAPITAL LETTER A WITH CIRCUMFLEX
        '-acir-' => "\x{E2}", # LATIN SMALL LETTER A WITH CIRCUMFLEX
        '-Ecir-' => "\x{CA}", # LATIN CAPITAL LETTER E WITH CIRCUMFLEX
        '-ecir-' => "\x{EA}", # LATIN SMALL LETTER E WITH CIRCUMFLEX
        '-Icir-' => "\x{CE}", # LATIN CAPITAL LETTER I WITH CIRCUMFLEX
        '-icir-' => "\x{EE}", # LATIN SMALL LETTER I WITH CIRCUMFLEX
        '-Ocir-' => "\x{D4}", # LATIN CAPITAL LETTER O WITH CIRCUMFLEX
        '-ocir-' => "\x{F4}", # LATIN SMALL LETTER O WITH CIRCUMFLEX
        '-Ucir-' => "\x{DB}", # LATIN CAPITAL LETTER U WITH CIRCUMFLEX
        '-ucir-' => "\x{FB}", # LATIN SMALL LETTER U WITH CIRCUMFLEX
        '-Ycir-' => "\x{176}", # LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
        '-ycir-' => "\x{177}", # LATIN SMALL LETTER Y WITH CIRCUMFLEX
        # Písmena s přehláskou (umlaut, dieresis).
        '-I(di[ae]|uml)-' => "\x{CF}", # LATIN CAPITAL LETTER I WITH DIAERESIS
        '-i(di[ae]|uml)-' => "\x{EF}", # LATIN SMALL LETTER I WITH DIAERESIS
        # Písmena s vlnovkou (tildou).
        '-Atil-' => "\x{C3}", # LATIN CAPITAL LETTER A WITH TILDE
        '-atil-' => "\x{E3}", # LATIN SMALL LETTER A WITH TILDE
        '-Etil-' => "\x{1EBC}", # LATIN CAPITAL LETTER E WITH TILDE
        '-etil-' => "\x{1EBD}", # LATIN SMALL LETTER E WITH TILDE
        '-Itil-' => "\x{128}", # LATIN CAPITAL LETTER I WITH TILDE
        '-itil-' => "\x{129}", # LATIN SMALL LETTER I WITH TILDE
        '-Ntil-' => "\x{D1}", # LATIN CAPITAL LETTER N WITH TILDE
        '-ntil-' => "\x{F1}", # LATIN SMALL LETTER N WITH TILDE
        '-Otil-' => "\x{D5}", # LATIN CAPITAL LETTER O WITH TILDE
        '-otil-' => "\x{F5}", # LATIN SMALL LETTER O WITH TILDE
        '-Util-' => "\x{168}", # LATIN CAPITAL LETTER U WITH TILDE
        '-util-' => "\x{169}", # LATIN SMALL LETTER U WITH TILDE
        # Písmena s ocáskem doleva (cedillou, např. ve francouzštině).
        '-Cced-' => "\x{C7}", # LATIN CAPITAL LETTER C WITH CEDILLA
        '-cced-' => "\x{E7}", # LATIN SMALL LETTER C WITH CEDILLA
        '-Dced-' => "D\x{327}", # LATIN CAPITAL LETTER D + COMBINING CEDILLA
        '-dced-' => "d\x{327}", # LATIN SMALL LETTER D + COMBINING CEDILLA
        '-Gced-' => "\x{122}", # LATIN CAPITAL LETTER G WITH CEDILLA
        '-gced-' => "\x{123}", # LATIN SMALL LETTER G WITH CEDILLA
        '-Hced-' => "H\x{327}", # LATIN CAPITAL LETTER H + COMBINING CEDILLA
        '-hced-' => "h\x{327}", # LATIN SMALL LETTER H + COMBINING CEDILLA
        '-Kced-' => "\x{136}", # LATIN CAPITAL LETTER K WITH CEDILLA
        '-kced-' => "\x{137}", # LATIN SMALL LETTER K WITH CEDILLA
        '-Lced-' => "\x{13B}", # LATIN CAPITAL LETTER L WITH CEDILLA
        '-lced-' => "\x{13C}", # LATIN SMALL LETTER L WITH CEDILLA
        '-Nced-' => "\x{145}", # LATIN CAPITAL LETTER N WITH CEDILLA
        '-nced-' => "\x{146}", # LATIN SMALL LETTER N WITH CEDILLA
        '-Rced-' => "\x{156}", # LATIN CAPITAL LETTER R WITH CEDILLA
        '-rced-' => "\x{157}", # LATIN SMALL LETTER R WITH CEDILLA
        '-Sced-' => "\x{15E}", # LATIN CAPITAL LETTER S WITH CEDILLA
        '-sced-' => "\x{15F}", # LATIN SMALL LETTER S WITH CEDILLA
        '-Tced-' => "\x{162}", # LATIN CAPITAL LETTER T WITH CEDILLA
        '-tced-' => "\x{163}", # LATIN SMALL LETTER T WITH CEDILLA
        '-Zced-' => "Z\x{327}", # LATIN CAPITAL LETTER Z + COMBINING CEDILLA
        '-zced-' => "z\x{327}", # LATIN SMALL LETTER Z + COMBINING CEDILLA
        # Písmena s čárkou (alternativa k cedille, používaná v rumunštině).
        '-Scom-' => "\x{218}", # LATIN CAPITAL LETTER S WITH COMMA BELOW
        '-scom-' => "\x{219}", # LATIN SMALL LETTER S WITH COMMA BELOW
        '-Tcom-' => "\x{21A}", # LATIN CAPITAL LETTER T WITH COMMA BELOW
        '-tcom-' => "\x{21B}", # LATIN SMALL LETTER T WITH COMMA BELOW
        # Písmena s oblým háčkem (breve, např. rumunské a nebo turecké g).
        '-Abre-' => "\x{102}", # LATIN CAPITAL LETTER A WITH BREVE
        '-abre-' => "\x{103}", # LATIN SMALL LETTER A WITH BREVE
        '-Gbre-' => "\x{11E}", # LATIN CAPITAL LETTER G WITH BREVE
        '-gbre-' => "\x{11F}", # LATIN SMALL LETTER G WITH BREVE
        # Písmena s tečkou pod (např. pro transliteraci).
        '-ddob-' => "d\x{323}", # d s tečkou pod
        '-hdob-' => "h\x{323}", # h s tečkou pod
        '-ldob-' => "l\x{323}", # l s tečkou pod
        '-mdob-' => "m\x{323}", # m s tečkou pod
        '-ndob-' => "n\x{323}", # n s tečkou pod
        '-rdob-' => "r\x{323}", # r s tečkou pod
        '-sdob-' => "s\x{323}", # s s tečkou pod
        '-tdob-' => "t\x{323}", # t s tečkou pod
        # Písmena s tečkou nad (např. pro transliteraci).
        '-mdot-' => "m\x{307}", # m s tečkou nad
        '-ndot-' => "n\x{307}", # n s tečkou nad
        '-sdot-' => "\x{1E61}", # LATIN SMALL LETTER S WITH DOT ABOVE
        '-zdot-' => "\x{17C}",  # LATIN SMALL LETTER Z WITH DOT ABOVE
        # Písmena s kroužkem pod (např. r pro transliteraci z dévanágarí).
        '-rrib-' => "r\x{325}", # r s kroužkem pod
        # Další severo- a západoevropská písmena.
        '-Arin-' => "\x{C5}", # LATIN CAPITAL LETTER WITH RING ABOVE
        '-arin-' => "\x{E5}", # LATIN SMALL LETTER WITH RING ABOVE
        '-AE-' => "\x{C6}", # LATIN CAPITAL LIGATURE AE
        '-ae-' => "\x{E6}", # LATIN SMALL LIGATURE AE
        '-Disl-' => "\x{D0}", # LATIN CAPITAL LETTER ETH
        '-disl-' => "\x{F0}", # LATIN SMALL LETTER ETH
        '-Idot-' => "\x{130}", # LATIN CAPITAL LETTER I WITH DOT ABOVE
        '-idot-' => "\x{131}", # LATIN SMALL LETTER DOTLESS I
        '-Ng-' => "\x{14A}", # LATIN CAPITAL LETTER ENG
        '-ng-' => "\x{14B}", # LATIN SMALL LETTER ENG
        '-Osla-' => "\x{D8}", # LATIN CAPITAL LETTER O WITH STROKE
        '-osla-' => "\x{F8}", # LATIN SMALL LETTER O WITH STROKE
        '-OE-' => "\x{152}", # LATIN CAPITAL LIGATURE OE
        '-oe-' => "\x{153}", # LATIN SMALL LIGATURE OE
        '-TH-' => "\x{DE}", # LATIN CAPITAL LETTER THORN
        '-th-' => "\x{FE}", # LATIN SMALL LETTER THORN
        '-ss-' => "\x{DF}", # LATIN SMALL LETTER SHARP S
        # Další písmena.
        '-glot-' => "\x{2C0}", # MODIFIER LETTER GLOTTAL STOP # používám pro transliteraci arabského ajnu
        '-šva-' => "\x{259}", # LATIN SMALL LETTER SCHWA
    );
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku pro rumunštinu: písmena, která jsou dostupná na
# středoevropské klávesnici, nahradí správnějšími, která dostupná nejsou.
# Na české klávesnici jsou dostupné souhlásky "with cedilla", zatímco
# v rumunské Wikipedii jsem viděl, že používají "with comma below". V některých
# fontech (např. Arial Unicode MS) sice vypadají obě varianty prakticky stejně,
# ale v jiných ne.
#------------------------------------------------------------------------------
sub sestavit_tabulku_rom
{
    my %tabulka =
    (
        "\x{15E}" => "\x{218}", # LATIN CAPITAL LETTER S WITH CEDILLA => LATIN CAPITAL LETTER S WITH COMMA BELOW
        "\x{15F}" => "\x{219}", # LATIN SMALL LETTER S WITH CEDILLA   => LATIN SMALL LETTER S WITH COMMA BELOW
        "\x{162}" => "\x{21A}", # LATIN CAPITAL LETTER T WITH CEDILLA => LATIN CAPITAL LETTER T WITH COMMA BELOW
        "\x{163}" => "\x{21B}", # LATIN SMALL LETTER T WITH CEDILLA   => LATIN SMALL LETTER T WITH COMMA BELOW
    );
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do arabského písma.
#------------------------------------------------------------------------------
sub sestavit_tabulku_arab
{
    # Skupiny znaků, které v arabštině označují podobné hlásky a v češtině je obtížné je rozlišit:
    # t = teh,  T = tah
    # d = dal,  D = dad
    # s = seen, S = sad
    # z = zain, Z = zah
    # h = heh,  H = hah
    # Krátké a, i, u budeme přepisovat jako prázdný řetězec, protože krátké samohlásky se v arabštině obvykle vynechávají (i když na ně jsou prostředky).
    # Následující tabulka přiřazuje každému řetězci v latince kód nebo posloupnost kódů (decimální Unicode) odpovídajících arabských znaků.
    my @arab =
    (
        "a" => "",
        "e" => "",
        "i" => "",
        "u" => "",
        "'" => 1569, # hamza
        "á" => 1575, # alef
        "Á" => 1570, # alef madda
        "'á"=> 1571, # alef hamza above
        "Í" => 1573, # alef hamza below
        "A" => 1614, # fatha (krátké a)
        "AN"=> 1611, # fathatan (an na konci slova)
        "U" => 1615, # damma (krátké u)
        "UN"=> 1612, # dammatan (un na konci slova)
        "I" => 1616, # kasra (krátké i)
        "IN"=> 1613, # kasratan (in na konci slova)
        "__"=> 1617, # shadda (zdvojená souhláska)
        "_" => 1618, # sukun (žádná samohláska)
        "_á_" => 1648, # superscript alef (neznám užití)
        "b" => 1576, # beh
        "ah"=> 1577, # teh marbuta
        "t" => 1578, # teh
        "th"=> 1579, # theh
        "j" => 1580, # jeem
        "dž"=> 1580,
        "H" => 1581, # hah
        "kh"=> 1582, # khah
        "d" => 1583, # dal
        "dh"=> 1584, # thal
        "r" => 1585, # reh
        "z" => 1586, # zain
        "s" => 1587, # seen
        "sh"=> 1588, # sheen
        "š" => 1588,
        "S" => 1589, # sad
        "D" => 1590, # dad
        "T" => 1591, # tah
        "Z" => 1592, # zah
        "c" => 1593, # ain
        "gh"=> 1594, # ghain
        "f" => 1601, # feh
        "q" => 1602, # qaf
        "k" => 1603, # kaf
        "g" => 1709, # berberské g, jak jsem ho viděl v Maroku; podle Unikódu je tohle (3 tečky nahoře) ujgurské ng a to g má mít tečky dole (kód 1710)
        "l" => 1604, # lam
        "m" => 1605, # meem
        "n" => 1606, # noon
        "h" => 1607, # heh
        "w" => 1608, # waw
        "v" => 1608,
        "ú" => 1608,
        "o" => 1608,
        "ó" => 1608,
        "'ú"=> 1572, # waw hamza above
        "ý" => 1609, # alef maksura
        "y" => 1610, # yeh
        "í" => 1610,
        "é" => 1610,
        "'y"=> 1574, # yeh hamza above
        '0' => 1632,
        '1' => 1633,
        '2' => 1634,
        '3' => 1635,
        '4' => 1636,
        '5' => 1637,
        '6' => 1638,
        '7' => 1639,
        '8' => 1640,
        '9' => 1641,
        '%' => 1642,
    );
    my %tabulka_arab;
    pridat_smisene_pole_kodu(\%tabulka_arab, @arab);
    return \%tabulka_arab;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do urdsko-arabského písma.
#------------------------------------------------------------------------------
sub sestavit_tabulku_urdu
{
    # Skupiny znaků, které v urdštině označují podobné hlásky a v češtině je obtížné je rozlišit:
    # t = teh, Ť = tah, T = tteh, ť = theh
    # d = dal, Ď = dad, D = ddal, ď = thal
    # h (kh, gh, čh, džh, Th, Dh, th, dh, ph, bh) = heh dvačašmí, h = heh goal, H = hah, x/X = khah
    # é = yeh barrí, í/e = farsí yeh, y/j = yeh hamza
    # n = nún, m = mím, N/M = nún ghunna
    # á = alef, Á = alef madda
    # s = sín, S = sad; z = zajn, Z = zah; r = reh, R = rreh
    # Naopak znak waw lze do latinky přepsat různými způsoby, budeme reagovat na tyto protějšky: v, w, ú, o, ó.
    # Krátké a, i, u budeme přepisovat jako prázdný řetězec, protože krátké samohlásky se v urdštině obvykle vynechávají (i když na ně jsou prostředky).
    # Následující tabulka přiřazuje každému řetězci v latince kód nebo posloupnost kódů (decimální Unicode) odpovídajících urdských znaků.
    my @urdu =
    (
        "a" => "",
        "i" => "",
        "u" => "",
        "á" => 1575, # alef
        "Á" => 1570, # alef madda
        "e" => 1740, # farsi yeh
        "í" => 1740,
        "y" => 1574, # hamza yeh
        "j" => 1574,
        "é" => 1746, # yeh barree
        "v" => 1608, # waw
        "w" => 1608,
        "ú" => 1608,
        "o" => 1608,
        "ó" => 1608,
        "A" => 1614, # fatha (krátké a)
        "U" => 1615, # damma (krátké u)
        "I" => 1616, # kasra (krátké i)
        "_" => 1617, # shadda (žádná samohláska)
        "Í" => 1648, # superscript alef (neznám užití)
        "k" => 1705, # keheh
        "r" => 1585, # reh
        "R" => 1681, # rreh
        "kh" => "1705+1726", # keheh + heh doachashmee
        "gh" => "1711+1726",
        "čh" => "1670+1726",
        "džh" => "1580+1726",
        "Th" => "1657+1726",
        "Dh" => "1672+1726",
        "th" => "1578+1726",
        "dh" => "1583+1726",
        "ph" => "1662+1726",
        "bh" => "1576+1726",
        "h" => 1729, # heh goal
        "H" => 1581, # hah
        "x" => 1582, # khah
        "X" => 1582,
        "n" => 1606, # noon
        "m" => 1605, # meem
        "N" => 1722, # noon ghunna
        "M" => 1722,
        "t" => 1578, # teh
        "T" => 1657, # tteh
        "Ť" => 1591, # tah
        "ť" => 1579, # theh
        "d" => 1583, # dal
        "D" => 1672, # ddal
        "Ď" => 1590, # dad
        "ď" => 1584, # thal
        "s" => 1587, # seen
        "S" => 1589, # sad
        "l" => 1604, # lam
        "b" => 1576, # beh
        "dž" => 1580, # jeem
        "p" => 1662, # peh
        "." => 1748, # full stop
        "," => 1548, # comma
        "?" => 1567, # question
        "g" => 1711, # gaf
        "c" => 1593, # ain
        "C" => 1593,
        "q" => 1602, # qaf
        "š" => 1588, # sheen
        "f" => 1601, # feh
        "z" => 1586, # zain
        "Z" => 1592, # zah
        "č" => 1670, # tcheh
        "G" => 1594, # ghain
    );
    my %tabulka_urdu;
    pridat_smisene_pole_kodu(\%tabulka_urdu, @urdu);
    return \%tabulka_urdu;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do dévanágarí.
#------------------------------------------------------------------------------
sub sestavit_tabulku_devanagari
{
    my %tabulka_devanagari;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "ŕ", "ĺ", "E", "e", "é", "aj", "O", "o", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_devanagari, hex("905"), @samohlasky);
    my @souhlasky =
    (
        "k", "kh", "g",  "gh",  "ng",
        "č", "čh", "dž", "džh", "ň",
        "T", "Th", "D",  "Dh",  "N",
        "t", "th", "d",  "dh",  "n", "ń",
        "p", "ph", "b",  "bh",  "m",
        "j", "r",  "RR",  "l",   "L", "ł", "v",
        "ś", "š",  "s",  "h"
    );
    my @souhlasky2 = ("q", "Kh", "Gh", "z", "R", "Rh", "f", "Y");
    pridat_zdrojove_pole(\%tabulka_devanagari, hex("915"), map {$_."a"} @souhlasky);
    pridat_zdrojove_pole(\%tabulka_devanagari, hex("958"), map {$_."a"} @souhlasky2);
    pridat_dve_pole(\%tabulka_devanagari, (map {$_."a"} @souhlasky), (map {chr($_)} (hex("915") .. hex("939"))));
    pridat_dve_pole(\%tabulka_devanagari, (map {$_."a"} @souhlasky2), (map {chr($_)} (hex("958") .. hex("95F"))));
    my @diahlasky = ("á", "i", "í", "u", "ú", "ŕ", "Ŕ", "E", "e", "é", "aj", "O", "o", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr(hex("93E")+$i);
        pridat_dve_pole(\%tabulka_devanagari, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} (hex("915") .. hex("939"))));
        pridat_dve_pole(\%tabulka_devanagari, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} (hex("958") .. hex("95F"))));
    }
    # Přidat anusvár (bindu).
    $tabulka_devanagari{"M"} = chr(hex("902"));
    # Přidat anunásik (čandrabindu).
    $tabulka_devanagari{"MM"} = chr(hex("901"));
    # Přidat visarg (přídech).
    $tabulka_devanagari{"H"} = chr(hex("903"));
    # Přidat číslice.
    pridat_zdrojove_pole(\%tabulka_devanagari, hex("966"), (0..9));
    # Přidat do transliterační tabulky dandu (značka dévanágarí místo evropské tečky za větou).
    $tabulka_devanagari{"."} = chr(hex("964"));
    return \%tabulka_devanagari;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do bengálského písma.
#------------------------------------------------------------------------------
sub sestavit_tabulku_bengali
{
    my %tabulka_bengali;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "ŕ", "ĺ", "_", "_", "é", "aj", "_", "_", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_bengali, hex('985'), @samohlasky);
    my @souhlasky =
    (
        "k", "kh", "g",  "gh",  "ng",
        "č", "čh", "dž", "džh", "ň",
        "T", "Th", "D",  "Dh",  "N",
        "t", "th", "d",  "dh",  "n", "_",
        "p", "ph", "b",  "bh",  "m",
        "j", "r",  "_",  "l",   "_", "_", "_",
        "ś", "š",  "s",  "h"
    );
    my @souhlasky2 = ("_", "_", "_", "_", "R", "Rh", "_", "Y");
    pridat_zdrojove_pole(\%tabulka_bengali, hex('995'), map {$_.'a'} @souhlasky);
    pridat_zdrojove_pole(\%tabulka_bengali, hex('9D8'), map {$_.'a'} @souhlasky2);
    pridat_dve_pole(\%tabulka_bengali, (map {$_.'a'} @souhlasky), (map {chr($_)} (hex('995') .. hex('9B9'))));
    pridat_dve_pole(\%tabulka_bengali, (map {$_.'a'} @souhlasky2), (map {chr($_)} (hex('9D8') .. hex('9DF'))));
    my @diahlasky = ("á", "i", "í", "u", "ú", "ŕ", "Ŕ", "_", "_", "é", "aj", "_", "_", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr(hex('9BE')+$i);
        pridat_dve_pole(\%tabulka_bengali, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} (hex('995') .. hex('9B9'))));
        pridat_dve_pole(\%tabulka_bengali, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} (hex('9D8') .. hex('9DF'))));
    }
    # Přidat anusvár (bindu).
    $tabulka_bengali{'M'} = chr(hex('982'));
    # Přidat anunásik (čandrabindu).
    $tabulka_bengali{'MM'} = chr(hex('981'));
    # Přidat visarg (přídech).
    $tabulka_bengali{'H'} = chr(hex('983'));
    # Přidat číslice.
    pridat_zdrojove_pole(\%tabulka_bengali, hex('9E6'), (0..9));
    # Nakonec odstranit kombinace z jiných indických písem, které bengálština nepodporuje.
    foreach my $lat (keys(%tabulka_bengali))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka_bengali{$lat});
        }
    }
    return \%tabulka_bengali;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do gurmukhí.
#------------------------------------------------------------------------------
sub sestavit_tabulku_gurmukhi
{
    my %tabulka_gurmukhi;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "_", "_", "_", "_", "é", "aj", "_", "_", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_gurmukhi, hex("A05"), @samohlasky);
    my @souhlasky =
    (
        "k", "kh", "g",  "gh",  "ng",
        "č", "čh", "dž", "džh", "ň",
        "T", "Th", "D",  "Dh",  "N",
        "t", "th", "d",  "dh",  "n", "_",
        "p", "ph", "b",  "bh",  "m",
        "j", "r",  "_",  "l",   "L", "_", "v",
        "ś", "_",  "s",  "h"
    );
    my @souhlasky2 = ("_", "Kh", "Gh", "z", "R", "_", "f", "_");
    pridat_zdrojove_pole(\%tabulka_gurmukhi, hex("A15"), map {$_."a"} @souhlasky);
    pridat_zdrojove_pole(\%tabulka_gurmukhi, hex("A58"), map {$_."a"} @souhlasky2);
    pridat_dve_pole(\%tabulka_gurmukhi, (map {$_."a"} @souhlasky), (map {chr($_)} (hex("A15") .. hex("A39"))));
    pridat_dve_pole(\%tabulka_gurmukhi, (map {$_."a"} @souhlasky2), (map {chr($_)} (hex("A58") .. hex("A5F"))));
    my @diahlasky = ("á", "i", "í", "u", "ú", "_", "_", "_", "_", "é", "aj", "_", "_", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr(hex("A3E")+$i);
        pridat_dve_pole(\%tabulka_gurmukhi, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} (hex("A15") .. hex("A39"))));
        pridat_dve_pole(\%tabulka_gurmukhi, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} (hex("A58") .. hex("A5F"))));
    }
    # Přidat anusvár (bindu).
    $tabulka_gurmukhi{"M"} = chr(hex("A02"));
    # Přidat anunásik (čandrabindu).
    $tabulka_gurmukhi{"MM"} = chr(hex("A01"));
    # Přidat visarg (přídech).
    $tabulka_gurmukhi{"H"} = chr(hex("A03"));
    # Přidat číslice.
    pridat_zdrojove_pole(\%tabulka_gurmukhi, hex("A66"), (0..9));
    # Nakonec odstranit kombinace z jiných indických písem, které gurmukhí nepodporuje.
    foreach my $lat (keys(%tabulka_gurmukhi))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka_gurmukhi{$lat});
        }
    }
    return \%tabulka_gurmukhi;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do telugu.
#------------------------------------------------------------------------------
sub sestavit_tabulku_telugu
{
    my $pocatek_samohlasek = 3077; # a
    my $pocatek_souhlasek = 3093; # ka
    my $konec_souhlasek = 3129; # ha
    my $pocatek_souhlasek_2 = 3160; # v telugštině se nepoužívají, v dévanágarí ano
    my $konec_souhlasek_2 = 3167;
    my $pocatek_diahlasek = 3134;
    my $anusvar = 3074;
    my $pocatek_cislic = 3174;
    my %tabulka_telugu;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "ŕ", "ĺ", "_", "e", "é", "aj", "_", "o", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_telugu, $pocatek_samohlasek, @samohlasky);
    # Přidat do transliterační tabulky souhlásky s implicitním "a".
    my @souhlasky =
    (
        "k", "kh", "g",  "gh",  "ng",
        "č", "čh", "dž", "džh", "ň",
        "T", "Th", "D",  "Dh",  "N",
        "t", "th", "d",  "dh",  "n", "_",
        "p", "ph", "b",  "bh",  "m",
        "j", "r",  "R",  "l",   "L", "_", "v",
        "ś", "š",  "s",  "h"
    );
    my @souhlasky2 = ("q", "Kh", "_", "_", "_", "_", "_", "_");
    pridat_zdrojove_pole(\%tabulka_telugu, $pocatek_souhlasek, map {$_."a"} @souhlasky);
    pridat_zdrojove_pole(\%tabulka_telugu, $pocatek_souhlasek_2, map {$_."a"} @souhlasky2);
    # Přidat do transliterační tabulky souhlásky s ostatními samohláskami a s virámem.
    my @diahlasky = ("á", "i", "í", "u", "ú", "ŕ", "Ŕ", "_", "e", "é", "aj", "_", "o", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr($pocatek_diahlasek+$i);
        pridat_dve_pole(\%tabulka_telugu, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} ($pocatek_souhlasek .. $konec_souhlasek)));
        pridat_dve_pole(\%tabulka_telugu, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} ($pocatek_souhlasek_2 .. $konec_souhlasek_2)));
    }
    # Přidat do transliterační tabulky anusvár.
    $tabulka_telugu{"M"} = chr($anusvar);
    # Přidat do transliterační tabulky dandu (značka dévanágarí místo evropské tečky za větou).
    # Problém: v telugštině se používá normální tečka, takže nechceme, aby se nám tečka přepsala na neexistující znak na pozici odpovídající dandě!
    # Přidat do transliterační tabulky číslice.
    pridat_zdrojove_pole(\%tabulka_telugu, $pocatek_cislic, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
    # Nakonec odstranit kombinace z jiných indických písem, které telugština nepodporuje.
    foreach my $lat (keys(%tabulka_telugu))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka_telugu{$lat});
        }
    }
    return \%tabulka_telugu;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do kannadštiny.
#------------------------------------------------------------------------------
sub sestavit_tabulku_kannada
{
    # pocatek tabulky je 3200 (\x{C80}), konec je 3327 (\x{CFF}). Pocatek telugstiny by tedy mel byt 3200-128=3072.
    my $pocatek_samohlasek = 3205; # a
    my $pocatek_souhlasek = 3221; # ka
    my $konec_souhlasek = 3257; # ha
    my $pocatek_souhlasek_2 = 3288; # v kannadštině se nepoužívají, v dévanágarí ano
    my $konec_souhlasek_2 = 3295;
    my $pocatek_diahlasek = 3262;
    my $anusvar = 3202;
    my $pocatek_cislic = 3302;
    my %tabulka_kannada;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "ŕ", "ĺ", "_", "e", "é", "aj", "_", "o", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_kannada, $pocatek_samohlasek, @samohlasky);
    # Přidat do transliterační tabulky souhlásky s implicitním "a".
    my @souhlasky =
    (
        "k", "kh", "g",  "gh",  "ng",
        "č", "čh", "dž", "džh", "ň",
        "T", "Th", "D",  "Dh",  "N",
        "t", "th", "d",  "dh",  "n", "_",
        "p", "ph", "b",  "bh",  "m",
        "j", "r",  "R",  "l",   "L", "_", "v",
        "ś", "š",  "s",  "h"
    );
    my @souhlasky2 = ("q", "Kh", "_", "_", "_", "_", "_", "_");
    pridat_zdrojove_pole(\%tabulka_kannada, $pocatek_souhlasek, map {$_."a"} @souhlasky);
    pridat_zdrojove_pole(\%tabulka_kannada, $pocatek_souhlasek_2, map {$_."a"} @souhlasky2);
    # Přidat do transliterační tabulky souhlásky s ostatními samohláskami a s virámem.
    my @diahlasky = ("á", "i", "í", "u", "ú", "ŕ", "Ŕ", "_", "e", "é", "aj", "_", "o", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr($pocatek_diahlasek+$i);
        pridat_dve_pole(\%tabulka_kannada, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} ($pocatek_souhlasek .. $konec_souhlasek)));
        pridat_dve_pole(\%tabulka_kannada, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} ($pocatek_souhlasek_2 .. $konec_souhlasek_2)));
    }
    # Přidat do transliterační tabulky anusvár.
    $tabulka_kannada{"M"} = chr($anusvar);
    # Přidat do transliterační tabulky dandu (značka dévanágarí místo evropské tečky za větou).
    # Problém: v kannadštině se používá normální tečka, takže nechceme, aby se nám tečka přepsala na neexistující znak na pozici odpovídající dandě!
    # Přidat do transliterační tabulky číslice.
    pridat_zdrojove_pole(\%tabulka_kannada, $pocatek_cislic, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
    # Nakonec odstranit kombinace z jiných indických písem, které telugština nepodporuje.
    foreach my $lat (keys(%tabulka_kannada))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka_kannada{$lat});
        }
    }
    return \%tabulka_kannada;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do tamilštiny.
#------------------------------------------------------------------------------
sub sestavit_tabulku_tamil
{
    my $pocatek_samohlasek = 2949; # a
    my $pocatek_souhlasek = 2965; # ka
    my $konec_souhlasek = 3001; # ha
#    my $pocatek_souhlasek_2 = 3160; # v tamilštině se nepoužívají, v dévanágarí ano
#    my $konec_souhlasek_2 = 3167;
    my $pocatek_diahlasek = 3006;
    my $anusvar = 2946;
    my $pocatek_cislic = 3047;
    my %tabulka_tamil;
    # Přidat do transliterační tabulky samostatné samohlásky.
    my @samohlasky = ("a", "á", "i", "í", "u", "ú", "_", "_", "_", "e", "é", "aj", "_", "o", "ó", "au");
    pridat_zdrojove_pole(\%tabulka_tamil, $pocatek_samohlasek, @samohlasky);
    # Přidat do transliterační tabulky souhlásky s implicitním "a".
    my @souhlasky =
    (
        "k", "_", "_",  "_",  "ng",
        "č", "_",  "dž", "_", "ň",
        "T", "_",   "_",  "_",    "N",
        "t", "_",   "_",  "_",    "n", "ń",
        "p", "_",   "_",  "_",    "m",
        "j", "r",  "R",  "l",   "L", "ł", "v",
        "ś", "š",  "s",  "h"
    );
#    my @souhlasky2 = ("q", "Kh", "Gh", "z", "DDDH", "RH", "f", "Y");
    pridat_zdrojove_pole(\%tabulka_tamil, $pocatek_souhlasek, map {$_."a"} @souhlasky);
#    pridat_zdrojove_pole(\%tabulka_tamil, $pocatek_souhlasek_2, map {$_."a"} @souhlasky2);
    # Přidat do transliterační tabulky souhlásky s ostatními samohláskami a s virámem.
    my @diahlasky = ("á", "i", "í", "u", "ú", "_", "_", "_", "e", "é", "aj", "_", "o", "ó", "au", ""); # poslední je virám
    for(my $i = 0; $i<=$#diahlasky; $i++)
    {
        my $dia0 = $diahlasky[$i];
        my $dia1 = chr($pocatek_diahlasek+$i);
        pridat_dve_pole(\%tabulka_tamil, (map {$_.$dia0} @souhlasky), (map {chr($_).$dia1} ($pocatek_souhlasek .. $konec_souhlasek)));
#        pridat_dve_pole(\%tabulka_tamil, (map {$_.$dia0} @souhlasky2), (map {chr($_).$dia1} ($pocatek_souhlasek_2 .. $konec_souhlasek_2)));
    }
    # Přidat do transliterační tabulky anusvár.
    $tabulka_tamil{'M'} = chr($anusvar);
    # Přidat do transliterační tabulky dandu (značka dévanágarí místo evropské tečky za větou).
    # Problém: v tamilštině se používá normální tečka, takže nechceme, aby se nám tečka přepsala na neexistující znak na pozici odpovídající dandě!
    # Přidat do transliterační tabulky číslice.
    pridat_zdrojove_pole(\%tabulka_tamil, $pocatek_cislic, '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '100', '1000');
    # Nakonec odstranit kombinace z jiných indických písem, které tamilština nepodporuje.
    foreach my $lat (keys(%tabulka_tamil))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka_tamil{$lat});
        }
    }
    return \%tabulka_tamil;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do hiragany nebo katakany.
#------------------------------------------------------------------------------
sub sestavit_tabulku_kana
{
    # hiragana = 12353
    # katakana = 12449
    my $pocatek = shift;
    my %tabulka;
    my @latinka =
    (
        '', 'a', '', 'i', '', 'u', '', 'e', '', 'o',
        'ka', 'ga', 'ki', 'gi', 'ku', 'gu', 'ke', 'ge', 'ko', 'go',
        'sa', 'za', 'si', 'zi', 'su', 'zu', 'se', 'ze', 'so', 'zo',
        'ta', 'da', 'ti', 'di', '', 'tu', 'du', 'te', 'de', 'to', 'do',
        'na', 'ni', 'nu', 'ne', 'no',
        'ha', 'ba', 'pa', 'hi', 'bi', 'pi', 'hu', 'bu', 'pu', 'he', 'be', 'pe', 'ho', 'bo', 'po',
        'ma', 'mi', 'mu', 'me', 'mo',
        '', 'ya', '', 'yu', '', 'yo',
        'ra', 'ri', 'ru', 're', 'ro',
        '', 'wa', 'wi', 'we', 'wo',
        'n',
        'vu'
    );
    my %alternativy =
    (
        'shi' => 'si',
        'ši'  => 'si',
        'chi' => 'ti',
        'či'  => 'ti',
        'ji'  => 'zi', # could be both 'zi' and 'di' but 'zi' is more common
        'dži' => 'zi', # could be both 'zi' and 'di' but 'zi' is more common
        'ži'  => 'zi',
        'tsu' => 'tu',
        'cu'  => 'tu',
        'ju'  => 'du',
        'dzu' => 'du',
        'fu'  => 'hu'
    );
    for(my $i = 0; $i<=$#latinka; $i++)
    {
        $tabulka{$latinka[$i]} = chr($pocatek+$i);
        pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, $latinka[$i]);
    }
    delete($tabulka{''});
    foreach my $klic (keys(%alternativy))
    {
        $tabulka{$klic} = $tabulka{$alternativy{$klic}};
        pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, $klic);
    }
    # Složené slabiky (např. "kjó").
    my %slozene =
    (
        'ky' => 'ki',
        'gy' => 'gi',
        'sh' => 'si',
        'š'  => 'si',
        'j'  => 'zi',
        'dž' => 'zi',
        'ch' => 'ti',
        'č'  => 'ti',
        'dz' => 'di',
        'ny' => 'ni',
        'hy' => 'hi',
        'by' => 'bi',
        'py' => 'pi',
        'my' => 'mi',
        'ry' => 'ri'
    );
    my %male_y =
    (
        'a' => chr($pocatek+66),
        'u' => chr($pocatek+68),
        'o' => chr($pocatek+70)
    );
    foreach my $samohlaska (keys(%male_y))
    {
        foreach my $souhlaska (keys(%slozene))
        {
            $tabulka{$souhlaska.$samohlaska} = $tabulka{$slozene{$souhlaska}}.$male_y{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, $souhlaska.$samohlaska);
        }
    }
    # Substituce samohlásek. Souhlásky, vzniklé fonologickými změnami, nemají úplnou sadu samohlásek.
    # Zejména v katakaně je to ale někdy potřeba.
    # Příklady: fu + malé e = fe. Zdrojové slabiky: či, cu, ši, dži, fu.
    my %male_samo =
    (
        'a' => chr($pocatek+0),
        'i' => chr($pocatek+2),
        'u' => chr($pocatek+4),
        'e' => chr($pocatek+6),
        'o' => chr($pocatek+8)
    );
    foreach my $samohlaska (keys(%male_samo))
    {
        # fa, fe, fi, fo
        # va, ve, vi, vo (ty mají i své zvláštní znaky, ale pouze v katakaně (\x{30F7}..\x{30FA}); navíc Ivan Krouský je na straně 63 nepoužil)
        unless($samohlaska eq 'u')
        {
            $tabulka{'f'.$samohlaska} = $tabulka{'fu'}.$male_samo{$samohlaska};
            $tabulka{'v'.$samohlaska} = $tabulka{'vu'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'f'.$samohlaska);
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'v'.$samohlaska);
        }
        # še (ša, šu, šo se dělá jako šja, šju, šjo)
        # če (ča, ču, čo se dělá jako čja, čju, čjo)
        if($samohlaska eq 'e')
        {
            $tabulka{'š'.$samohlaska} = $tabulka{'si'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'š'.$samohlaska);
            $tabulka{'sh'.$samohlaska} = $tabulka{'si'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'sh'.$samohlaska);
            $tabulka{'č'.$samohlaska} = $tabulka{'ti'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'š'.$samohlaska);
            $tabulka{'ch'.$samohlaska} = $tabulka{'ti'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'sh'.$samohlaska);
        }
        # ti, di (čteno ty, dy)
        if($samohlaska eq 'i')
        {
            # Pozor, přepisy slabik "ti", "di" už ve skutečnosti v tabulce máme a jsou shodné s přepisy "či", "dži".
            # Teď tedy přepisujeme dřívější přepisy novými.
            $tabulka{'t'.$samohlaska} = $tabulka{'te'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 't'.$samohlaska);
            $tabulka{'d'.$samohlaska} = $tabulka{'de'}.$male_samo{$samohlaska};
            pridat_zdvojenou_souhlasku_kana($pocatek, \%tabulka, 'd'.$samohlaska);
        }
    }
    # Interpunkce je společná pro hiraganu i katakanu.
    $tabulka{','} = chr(12289);
    $tabulka{'.'} = chr(12290);
    # Potřebujeme mít možnost oddělit slabiky např. kvůli odlišení slov "kan'i" (jednoduchý) a "kani" (krab).
    # Pomlčka je nevhodná, protože ji používáme pro mnoho entit. Apostrof zase není dostupný na české klávesnici,
    # tak pro jistotu přidáme i paragraf, který je na české klávesnici tam, kde je na anglické apostrof.
    $tabulka{"'"} = '';
    $tabulka{'§'} = '';
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Pro danou slabiku hiragany nebo katakany přidá do tabulky odpovídající
# slabiku se zdvojenou počáteční souhláskou. Do tabulky musí být nejdřív přidán
# přepis nezdvojené slabiky.
#------------------------------------------------------------------------------
sub pridat_zdvojenou_souhlasku_kana
{
    my $pocatek = shift; # rozlišuje hiraganu a katakanu
    my $tabulka = shift;
    my $latinka = shift;
    # Zdvojování lze aplikovat pouze na slabiky, které nezačínají samohláskou.
    unless($latinka =~ m/^[aiueo]/)
    {
        # Zkontrolovat, že už v tabulce máme přepis nezdvojené slabiky.
        die("Neznámá slabika $latinka") unless(exists($tabulka->{$latinka}));
        # Zdvojená souhláska se tvoří pomocí malého "cu".
        my $malecu = chr($pocatek+34);
        my $zdvoj = $latinka;
        $zdvoj =~ s/^(.)/$1$1/;
        $tabulka->{$zdvoj} = $malecu.$tabulka->{$latinka};
    }
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do hiragany.
#------------------------------------------------------------------------------
sub sestavit_tabulku_hiragana
{
    return sestavit_tabulku_kana(12353);
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do katakany.
#------------------------------------------------------------------------------
sub sestavit_tabulku_katakana
{
    my $tabulka = sestavit_tabulku_kana(12449);
    # Navíc oproti hiraganě:
    # Mezera mezi slovy přepsanými ze západních jazyků se nahrazuje tečkou.
    $tabulka->{' '} = chr(12539); # KATAKANA MIDDLE DOT
    # Dlouhé samohlásky se v hiraganě řeší druhým znakem pro samohlásku, v katakaně zvláštním prodlužovacím znakem.
    my $prodluz = chr(12540); # KATAKANA-HIRAGANA PROLONGED SOUND MARK
    my @slabiky = keys(%{$tabulka});
    foreach my $kratka (@slabiky)
    {
        my $dlouha = $kratka;
        if($dlouha =~ s/a$/á/ ||
           $dlouha =~ s/e$/é/ ||
           $dlouha =~ s/i$/í/ ||
           $dlouha =~ s/o$/ó/ ||
           $dlouha =~ s/u$/ú/)
        {
            $tabulka->{$dlouha} = $tabulka->{$kratka}.$prodluz;
        }
    }
    return $tabulka;
}



#------------------------------------------------------------------------------
# Vybrané znaky kandži (čínské znaky používané v japonštině). Většina z nich má
# více než jedno čtení. Některá čtení se objevují ve slovech, jejichž další
# části se píší hiraganou; v tom případě může tato tabulka obsahovat na vstupu
# celé slovo latinkou a na výstupu směs kandži a kany.
#------------------------------------------------------------------------------
sub sestavit_tabulku_kanji
{
    # Budeme potřebovat převodní tabulku z latinky do hiragany a volající ji pravděpodobně už má, každopádně si ji může nechat vyrobit.
    my $lat2hiragana = shift;
    # Nejdříve obrácená tabulka, ta se bude zapisovat snadněji.
    # Kandži (+ latinka místo hiragany v případě potřeby) => latinka (mezinárodní romanizace bez diakritiky; dlouhé samohlásky zdvojením).
    # Jeden znak může mít více než jedno čtení (typicky alespoň jedno sinojaponské a jedno japonské).
    my %kan2lat =
    (
        "\x{4E00}" => ['ichi'], # jeden
        "\x{4E8C}" => ['ni'], # dva
        "\x{4E8C}cu" => ['futatsu'], # dva
        "\x{4EBA}" => ['jin', 'nin', 'hito'], # člověk
        "\x{5165}" => ['juu', 'nyuu'], # vstoupit
        "\x{5165}ru" => ['hairu'], # vstoupit
        "\x{5165}reru" => ['ireru'], # vložit
        "\x{529B}" => ['riki', 'ryoku', 'chikara'], # síla
        "\x{5341}" => ['juu', 'too'], # deset
        "\x{5C0F}" => ['shou'], # xiao, malý: šógakkó = základní škola
        "\x{5C0F}sai" => ['chiisai'], # malý
        "\x{5C0F}sana" => ['chiisana'], # malý
        "\x{5C0F}neko" => ['koneko'], # kotě
        "\x{5C0F}\x{5DDD}" => ['ogawa'], # potok
        "\x{5927}" => ['dai', 'tai', 'oo'], # da, velký: daigaku = univerzita; tairiku = kontinent
        "\x{5927}sai" => ['oosai'], # velký
        "\x{5927}sana" => ['oosana'], # velký
        "\x{571F}" => ['do', 'tsuchi'], # di, země, půda
        "\x{4E0A}" => ['jou', 'ue', 'uwa', 'kami'], # shang, nahoře, nad
        "\x{4E0A}geru" => ['ageru'], # zvedat
        "\x{4E0A}garu" => ['agaru'], # stoupat
        "\x{4E0A}ru" => ['noboru'], # vystupovat (po schodech)
        "\x{4E0B}" => ['ka', 'ge', 'shita', 'shimo'], # xia, dole, pod
        "\x{4E0B}geru" => ['sageru'], # snižovat
        "\x{4E0B}garu" => ['sagaru'], # klesat
        "\x{4E0B}ru" => ['kudaru'], # sestupovat (po schodech, s kopce)
        "\x{53E3}" => ['kou', 'kuchi', 'guchi'], # kou, ústa
        "\x{5C71}" => ['san', 'yama'], # shan, hora
        "\x{5DDD}" => ['sen', 'kawa', 'gawa'], # chuan, kawa, řeka
        "\x{5B50}" => ['shi', 'su'], # zi, dítě
        "\x{5B50}domo" => ['kodomo'], # dítě
        "\x{5973}" => ['jo', 'nyou', 'onna'], # nü, žena
        "\x{4E2D}" => ['chuu', 'juu', 'naka'], # zhong, střed
        "\x{4ECA}" => ['kon', 'ima'], # nyní
        "\x{5FC3}" => ['shin', 'kokoro'], # xin, srdce, duše
        "\x{624B}" => ['shu', 'te'], # ruka
        "\x{65B9}" => ['hou', 'kata'], # strana, směr, způsob
        "\x{65E5}" => ['nichi', 'jitsu', 'hi', 'bi'], # ri, slunce, den
        "\x{6708}" => ['getsu', 'gatsu', 'tsuki'], # yue, měsíc
        "\x{6728}" => ['moku', 'boku', 'ki', 'ho'], # mu, strom
        "nami\x{6728}" => ['namiki'], # stromořadí
        "\x{6C34}" => ['sui', 'mizu'], # shui, voda
        "\x{706B}" => ['ka', 'hi', 'bi'], # huo, oheň
        "\x{706B}\x{5C71}" => ['kazan'], # sopka
        "\x{706B}bana" => ['hibana'], # jiskra
        "hana\x{706B}" => ['hanabi'], # ohňostroj
        "\x{76EE}techi" => ['mokutechi'], # cíl
        "\x{76EE}" => ['me', 'moku'], # oko
        "\x{76EE}gane" => ['megane'], # brýle
        "\x{4EBA}\x{751F}" => ['jinsei'], # lidský život
        "\x{4E00}\x{751F}" => ['ishshou'], # iššó, celý život
        "\x{751F}kiru" => ['ikiru'], # žít
        "\x{751F}keru" => ['ikeru'], # oživit
        "\x{751F}kebana" => ['ikebana'], # ikebana
        "\x{751F}mareru" => ['umareru'], # narodit se
        "\x{751F}mu" => ['umu'], # porodit
        "\x{672C}" => ['hon', 'moto'], # kniha, původ, kořen
        "\x{65E5}\x{672C}" => ['nihon', 'nippon'], # Japonsko
        "\x{672C}\x{65E5}" => ['honjitsu'], # dnes
        "\x{4E2D}\x{7ACB}" => ['chuuritsu'], # neutrální
        "\x{7ACB}tsu" => ['tatsu'], # stát
        "\x{76EE}\x{7ACB}tsu" => ['medatsu'], # být nápadný
        "\x{7ACB}ba" => ['tachiba'], # stanovisko
        "\x{6B63}fuku" => ['seifuku'], # uniforma
        "\x{6B63}\x{6708}" => ['shougatsu'], # Nový rok
        "\x{6B63}shii" => ['tadashii'], # správný
        "\x{6B63}su" => ['tadasu'], # opravit
        "\x{7530}" => ['ten', 'ta'], # pole, rýžové pole
        "\x{6C34}\x{7530}" => ['suiden'], # zavodněné pole
        "\x{7530}nbo" => ['tanbo'], # rýžové pole
        "yu\x{51FA}" => ['yushutsu'], # export, vývoz
        "\x{51FA}ru" => ['deru'], # vycházet, vyjít
        "\x{51FA}\x{53E3}" => ['deguchi'], # východ
        "\x{51FA}su" => ['dasu'], # vydávat, vydat (knihu)
        "\x{53F3}yoku" => ['uyoku'], # pravice (politická)
        "\x{5DE6}yoku" => ['sayoku'], # levice (politická)
        "\x{5DE6}\x{53F3}" => ['sayuu'], # vlevo a vpravo
        "\x{53F3}" => ['migi'], # pravý
        "\x{53F3}\x{624B}" => ['migite'], # pravá ruka
        "\x{5DE6}" => ['hidari'], # levý
        "\x{5DE6}\x{624B}" => ['hidarite'], # levá ruka
        "\x{53E4}" => ['ko', 'furu'], # starý, starobylý
        "\x{53E4}dai" => ['kodai'], # starověk
        "\x{53E4}i" => ['furui'], # starý
        "\x{5148}\x{6708}" => ['sengetsu'], # minulý měsíc
        "\x{5148}\x{751F}" => ['sensei'], # učitel, profesor, mistr
        "\x{5148}ni" => ['sakini'], # předem, dříve
        "\x{5148}hodo" => ['sakihodo'], # prve, nedávno
        "ryo\x{884C}" => ['ryokou'], # cestování (ryokou suru = cestovat)
        "ryuu\x{884C}" => ['ryuukou'], # móda
        "\x{884C}gi" => ['gyougi'], # chování
        "\x{884C}" => ['gyou'], # odstavec (popř. moji no gyougi, ale zatím nevím, co je moji)
        "\x{884C}ku" => ['iku', 'yuku'], # jít, jet
        "\x{884C}kima" => ['ikima'], # ikimasu, ikimasen, ikimašita (jde, nejde, šel)
        "\x{884C}ki" => ['yuki'], # směrem do (Toukyou yuki no kyuukou = expres do Tokia)
        "\x{884C}u" => ['okonau'], # konat
        "\x{884C}wareru" => ['okonawareru'], # konat se
        "\x{5E74}" => ['nen', 'toshi'], # rok
        "\x{5E74}\x{6708}\x{65E5}" => ['nengappi'], # datum
        "shin\x{5E74}" => ['shinnen'], # nový rok
        "\x{4ECA}\x{5E74}" => ['kotoshi'], # letos
        "\x{4F11}\x{65E5}" => ['kyuujitsu'], # volný den
        "\x{4F11}mu" => ['yasumu'], # odpočívat, mít volno
        "\x{4F11}mima" => ['yasumima'], # yasumimasu, yasumimasen, yasumimašita (odpočívá, neodpočívá, odpočíval)
        "o\x{4F11}minasai" => ['oyasuminasai'], # dobrou noc
        "\x{4F11}mi" => ['yasumi'], # volno, prázdniny (např. natsu yasumi jsou letní prázdniny)
        "\x{8A9E}" => ['go'], # jazyk, řeč
        "\x{8A9E}ru" => ['kataru'], # vyprávět
        "\x{8A71}" => ['wa'], # řeč
        "den\x{8A71}" => ['denwa'], # telefon
        "\x{8A71}su" => ['hanasu'], # mluvit
        "\x{8A71}shi" => ['hanashi'], # hanašimasu, hanašimasen, hanašimašita (mluví, nemluví, mluvil); hanaši = příběh
        "\x{8A71}shi\x{624B}" => ['hanashite'], # vypravěč
        "\x{58F2}" => ['bai'], # prodat (sinojaponsky)
        "\x{58F2}ten" => ['baiten'], # stánek, obchod
        "\x{58F2}ru" => ['uru'], # prodat
        "\x{58F2}rima" => ['urima'], # urimasu, urimasen, urimašita (prodá, neprodá, prodal)
        "\x{58F2}\x{8CB7}" => ['baibai'], # nákup a prodej, obchod
        "\x{8CB7}u" => ['kau'], # koupit
        "\x{8CB7}ima" => ['kaima'], # kaimasu, kaimasen, kaimašita (koupí, nekoupí, koupil)
        "\x{8CB7}i\x{624B}" => ['kaite'], # kupující
        "\x{8CB7}mono" => ['kaimono'], # nákupy
        "ji\x{66F8}" => ['jisho'], # slovník
        "\x{66F8}dou" => ['shodou'], # kaligrafie
        "\x{66F8}ku" => ['kaku'], # psát
        "\x{66F8}kima" => ['kakima'], # kakimasu, kakimasen, kakimašita (napíše, nenapíše, napsal)
        "\x{8AAD}\x{66F8}" => ['dokusho'], # četba
        "\x{8AAD}\x{672C}" => ['tokuhon'], # čítanka
        "\x{8AAD}mu" => ['yomu'], # číst
        "\x{8AAD}mima" => ['yomima'], # yomimasu, yomimasen, yomimašita (čte, nečte, četl)
        "\x{6625}\x{5206}" => ['shunbun'], # jarní rovnodennost
        "\x{6625}" => ['haru'], # jaro
        "\x{590F}ki" => ['kaki'], # letní období
        "\x{590F}" => ['nacu'], # léto
        "\x{79CB}\x{5206}" => ['shuubun'], # podzimní rovnodennost
        "\x{79CB}" => ['aki'], # podzim
        "\x{51AC}min" => ['toumin'], # zimní spánek
        "\x{51AC}" => ['fuyu'], # zima
        "hen\x{4E8B}" => ['henja'], # odpověď
        "\x{4E8B}" => ['koto', 'goto'], # abstraktní věc, např. šigoto = práce
        "ken\x{7269}" => ['kenbun'], # prohlídka města
        "ni\x{7269}" => ['nimon'], # zavazadlo
        "\x{7269}" => ['mono'], # věc
        "\x{8AAD}\x{8005}" => ['dokusha'], # čtenář
        "shinbunki\x{8005}" => ['shinbunkisha'], # novinář
        "\x{8005}" => ['sha', 'mono'], # člověk, osoba
        "\x{521D}\x{65E5}" => ['shonichi'], # první den
        "\x{521D}me" => ['hajime'], # začátek
        "\x{521D}" => ['hatsu'], # první
        "\x{59CB}\x{7D42}" => ['shijuu'], # od začátku do konce
        "\x{59CB}me" => ['hajime'], # začátek
        "\x{59CB}meru" => ['hajimeru'], # začínat
        "\x{7D42}" => ['shuu', 'owa'], # konec, poslední, owaru = končit
        "\x{7D42}eru" => ['oeru'], # končit
        # Další znaky (ještě nebyly v učebnici)
        "\x{898B}ru" => ['miru'], # dívat se, vidět
        "\x{898B}ma" => ['mima'], # mimasu, mimasen, mimašita (vidí, nevidí, viděl)
    );
    # Invertovat tabulku.
    my %lat2kanji;
    foreach my $klic (keys(%kan2lat))
    {
        # Klíč má být směs kandži a kany. Jestliže obsahuje latinku, převést latinku na hiraganu.
        my $hklic = prepsat_tabulka($lat2hiragana, $klic);
        foreach my $lat (@{$kan2lat{$klic}})
        {
            ###!!! Zatím ignorujeme fakt, že některé latinské sekvence jsou homonymní. Prostě jim zůstane poslední znak, který potkáme.
            $lat2kanji{$lat} = $hklic;
        }
    }
    # Spojit tabulku pro kandži s tabulkou pro hiraganu. Vše, na co nenajdeme znak, přepíšeme hiraganou.
    my %tabulka = %{$lat2hiragana};
    foreach my $klic (keys(%lat2kanji))
    {
        $tabulka{$klic} = $lat2kanji{$klic};
    }
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do cyrilice.
#------------------------------------------------------------------------------
sub sestavit_tabulku_cyrilice
{
    my $jazyk = shift; # default 'rus', jinak 'ukr'
    my %tabulka;
    # Následující tabulka přiřazuje každému řetězci v latince kód nebo posloupnost kódů (decimální Unicode) odpovídajících znaků cyrilice.
    # Písmena, která jdou po sobě, přidáme později najednou.
    my @cyr =
    (
        'ŠČ' => 1065, # 429,
        'Šč' => 1065, # 429,
        'šč' => 1097, # 449,
        'JU' => 1070, # 42E,
        'Ju' => 1070, # 42E,
        'ju' => 1102, # 44E,
        'JA' => 1071, # 42F,
        'Ja' => 1071, # 42F,
        'ja' => 1103, # 44F,
        'JE' => 1028, # 404,
        'Je' => 1028, # 404,
        'je' => 1108, # 454,
        'JI' => 1031, # 407,
        'Ji' => 1031, # 407,
        'ji' => 1111, # 457,
        'JO' => 1025, # 401,
        'Jo' => 1025, # 401,
        'jo' => 1105, # 451,
        'Ë'  => 1025, # 401,
        'ë'  => 1105, # 451,
        #"kh" => "1705+1726", # keheh + heh doachashmee
    );
    pridat_smisene_pole_kodu(\%tabulka, @cyr);
    # Tvrdý znak: Ěě
    # Měkký znak: Íí
    # Tvrdé e: Éé
    # Dvojité Ww zde pouze drží místo pro ŠČ/šč, které musím definovat jinde zvlášť, protože se skládá ze dvou písmen.
    # Hex 410..42D velká, 430..44D malá (dec 1040..1069 a 1072..1101)
    my @velka = split(//, 'ABVGDEŽZIJKLMNOPRSTUFHCČŠWĚYÍÉ');
    my @mala  = split(//, 'abvgdežzijklmnoprstufhcčšwěyíé');
    for(my $i = 0; $i<=29; $i++)
    {
        $tabulka{$velka[$i]} = chr(1040+$i);
        $tabulka{$mala [$i]} = chr(1072+$i);
    }
    # Alternativně lze "ch" zapsat jako "x".
    $tabulka{'X'} = chr(1061);
    $tabulka{'x'} = chr(1093);
    # Běloruské polo-u-polo-v lze zapsat jako "w".
    $tabulka{'W'} = chr(1038);
    $tabulka{'w'} = chr(1118);
    # Dříve jsem ještě používal pro měkký znak čárku a háček. Na Linuxu je ale s mrtvými klávesami problém.
    $tabulka{'´'} = chr(1100);
    $tabulka{'ˇ'} = chr(1068);
    # Některá písmena přepisovat jinak v ukrajinštině.
    if($jazyk eq 'ukr')
    {
        # Posunutý přepis "i" a "y", místo tvrdého znaku apostrof - ten lze také zapsat paragrafem.
        $tabulka{'Y'} = $tabulka{'I'};
        $tabulka{'y'} = $tabulka{'i'};
        $tabulka{'I'} = chr(1030);
        $tabulka{'i'} = chr(1110);
        # "g" změnit na "h"
        $tabulka{'G'} = chr(1168);
        $tabulka{'g'} = chr(1169);
        $tabulka{'H'} = chr(1043);
        $tabulka{'h'} = chr(1075);
    }
    $tabulka{'§'} = "'";
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Sestaví převodní tabulku z latinky do řečtiny.
#------------------------------------------------------------------------------
sub sestavit_tabulku_rectina
{
    my %tabulka;
    # Následující tabulka přiřazuje každému řetězci v latince kód nebo posloupnost kódů (decimální Unicode) odpovídajících urdských znaků.
    # Písmena, která jdou po sobě, přidáme později najednou.
    my @gre =
    (
        'TH' => 920, # 398,
        'Th' => 920, # 398,
        'th' => 952, # 3B8,
        'CH' => 935, # 3A7,
        'Ch' => 935, # 3A7,
        'ch' => 967, # 3C7,
        'PS' => 936, # 3A8,
        'Ps' => 936, # 3A8,
        'ps' => 968, # 3C8,
    );
    pridat_smisene_pole_kodu(\%tabulka, @gre);
    my @velka = split(//, 'ABGDEZÎQIKLMNXOPR_STUFHVÔJÜáéýí');
    my @mala  = split(//, 'abgdezîqiklmnxopršstufhvôjüóúů_');
    for(my $i = 0; $i<=30; $i++)
    {
        $tabulka{$velka[$i]} = chr(913+$i);
        $tabulka{$mala [$i]} = chr(945+$i);
    }
    # Omegu lze alternativně zapsat jako "w".
    $tabulka{'W'} = chr(937);
    $tabulka{'w'} = chr(969);
    # Nakonec odstranit neexistující znaky přidané navíc.
    foreach my $lat (keys(%tabulka))
    {
        if($lat =~ m/_/)
        {
            delete($tabulka{$lat});
        }
    }
    return \%tabulka;
}



#------------------------------------------------------------------------------
# Ve vstupním textu přepíše pomocné sekvence cílovými znaky a řetězec vrátí.
#------------------------------------------------------------------------------
sub prepsat
{
    my $text = shift;
    my $tabulka_latin = sestavit_tabulku_latin();
    $text = prepsat_tabulka($tabulka_latin, $text);
    # Přepis cedill na čárku v rumunštině.
    my $tabulka_rom = sestavit_tabulku_rom();
    $text = prepsat_vsechny_useky_v_danem_pismu('r[ou]m', $tabulka_rom, $text);
    # Přepis do ruské cyrilice.
    my $tabulka_rus = sestavit_tabulku_cyrilice('rus');
    $text = prepsat_vsechny_useky_v_danem_pismu('rus', $tabulka_rus, $text);
    # Přepis do ukrajinské cyrilice.
    my $tabulka_ukr = sestavit_tabulku_cyrilice('ukr');
    $text = prepsat_vsechny_useky_v_danem_pismu('ukr', $tabulka_ukr, $text);
    # Přepis do řečtiny.
    my $tabulka_gre = sestavit_tabulku_rectina('gre');
    $text = prepsat_vsechny_useky_v_danem_pismu('gre', $tabulka_gre, $text);
    # Přepis do arabštiny.
    my $tabulka_arab = sestavit_tabulku_arab();
    $text = prepsat_vsechny_useky_v_danem_pismu('ara?b?', $tabulka_arab, $text);
    # Přepis do urdštiny.
    my $tabulka_urdu = sestavit_tabulku_urdu();
    $text = prepsat_vsechny_useky_v_danem_pismu('urd', $tabulka_urdu, $text);
    # Přepis do dévanágarí.
    my $tabulka_devanagari = sestavit_tabulku_devanagari();
    $text = prepsat_vsechny_useky_v_danem_pismu('dev', $tabulka_devanagari, $text);
    # Přepis do bengálštiny.
    my $tabulka_bengali = sestavit_tabulku_bengali();
    $text = prepsat_vsechny_useky_v_danem_pismu('ben', $tabulka_bengali, $text);
    # Přepis do gurmukhí.
    my $tabulka_gurmukhi = sestavit_tabulku_gurmukhi();
    $text = prepsat_vsechny_useky_v_danem_pismu('gur', $tabulka_gurmukhi, $text);
    # Přepis do telugštiny.
    my $tabulka_telugu = sestavit_tabulku_telugu();
    $text = prepsat_vsechny_useky_v_danem_pismu('tel', $tabulka_telugu, $text);
    # Přepis do kannadštiny.
    my $tabulka_kannada = sestavit_tabulku_kannada();
    $text = prepsat_vsechny_useky_v_danem_pismu('knd', $tabulka_kannada, $text);
    # Přepis do tamilštiny.
    my $tabulka_tamil = sestavit_tabulku_tamil();
    $text = prepsat_vsechny_useky_v_danem_pismu('tam', $tabulka_tamil, $text);
    # Přepis do hiragany.
    my $tabulka_hiragana = sestavit_tabulku_hiragana();
    $text = prepsat_vsechny_useky_v_danem_pismu('hir', $tabulka_hiragana, $text);
    # Přepis do katakany.
    $text = prepsat_vsechny_useky_v_danem_pismu('kat', sestavit_tabulku_katakana(), $text);
    # Přepis do směsi kandži a hiragany.
    my $tabulka_kanji = sestavit_tabulku_kanji($tabulka_hiragana);
    while($text =~ m/-(kan)1-(.*?)-(?:\1)0-/s)
    {
        my $jazyk = $1;
        my $latinka = $2;
        my $kanji = prepsat_tabulka($tabulka_kanji, $latinka);
        $text =~ s/-${jazyk}1-.*?-${jazyk}0-/$kanji/s;
    }
    # Přepis nelatin1 znaků do entit HTML.
    while($text =~ m/-ent1-(.*?)-ent0-/s)
    {
        my $retezec = $1;
        $retezec = join('', map {$_ = ord($_)>=256 ? '&amp;#'.ord($_).';' : $_} split(//, $retezec));
        $text =~ s/-ent1-.*?-ent0-/$retezec/s;
    }
    # Několik dalších znakových substitucí provést taky tady.
    # Specielně ty ztrojené a zdvojené pomlčky musí být úplně na konci, aby nezablokovaly sousedící jiné entity.
    $text =~ s/-xx-/\x{D7}/g; # MULTIPLICATION SIGN
    $text =~ s/&sup2;/\xB2/g; # SUPERSCRIPT TWO
    $text =~ s/&sup3;/\xB3/g; # SUPERSCRIPT THREE
    $text =~ s/-nb-/&nbsp;/g; # mezera nerozdělující slovo, jako jediná má zůstat jako entita
    $text =~ s/-br-/<br\/>/g;   # pevné zalomení řádku
    # Náhrada spojovníku pomlčkou nebo dlouhou pomlčkou. Dříve jsem používal zkratky "--" a "---".
    # Musely se nahrazovat až jako poslední (em, pak en), aby jejich nahrazení nepoškodilo jiné entity.
    # I tak to kolidovalo se syntaxí HTML a MediaWiki. Teď, když náhrady přesunuji do samostatné
    # knihovny, která má být obecná a o HTML ani MediaWiki raději nic nevědět, raději volím bezpečnější
    # zkratky, než abych zde komplikoval regulární výrazy ve snaze zachránit syntax všeho možného.
    $text =~ s/-nd-/\x{2013}/g; # EN DASH
    $text =~ s/-md-/\x{2014}/g; # EM DASH
#    $text =~ s/---/\x{2014}/g; # EM DASH
    # Nerušit <!-- ... --> (HTML komentáře).
#    $text =~ s/(?<!<!)--(?!>)/\x{2013}/g; # EN DASH
    # Typografické uvozovky.
    $text =~ s/-en"1-/\x{201C}/g; # LEFT DOUBLE QUOTATION MARK
    $text =~ s/-en"0-/\x{201D}/g; # RIGHT DOUBLE QUOTATION MARK
    $text =~ s/-en'1-/\x{2018}/g; # LEFT SINGLE QUOTATION MARK
    $text =~ s/-en'0-/\x{2019}/g; # RIGHT SINGLE QUOTATION MARK
    $text =~ s/-cs"1-/\x{201E}/g; # DOUBLE LOW-9 QUOTATION MARK
    $text =~ s/-cs"0-/\x{201C}/g; # LEFT DOUBLE QUOTATION MARK (who was so dumb to call this left?)
    $text =~ s/-cs'1-/\x{201A}/g; # SINGLE LOW-9 QUOTATION MARK
    $text =~ s/-cs'0-/\x{2018}/g; # LEFT SINGLE QUOTATION MARK (who was so dumb to call this left?)
    $text =~ s/-"-/\x{201C}English\x{201D} \x{201E}česky\x{201C} \x{2018}English\x{2019} \x{201A}česky\x{2018}/g; # the entire repertoire
    $text =~ s/-\.\.\.-/\x{2026}/g; # HORIZONTAL ELLIPSIS
    return $text;
}



#------------------------------------------------------------------------------
# Nahradí v textu úseky označené značkou písma přepisem těchto úseků v daném
# písmu. Úseky jsou označené kódem písma, na začátku s jedničkou a na konci
# s nulou, např. '-rus1-spasibo-rus0-'.
#------------------------------------------------------------------------------
sub prepsat_vsechny_useky_v_danem_pismu
{
    my $prepinac = shift; # řetězec nebo regulární výraz
    my $tabulka = shift; # odkaz na převodní hash
    my $text = shift;
    while($text =~ m/-($prepinac)1-(.*?)-(?:\1)0-/s)
    {
        my $latinka = $2;
        my $prepsano = prepsat_tabulka($tabulka, $latinka);
        $text =~ s/-${prepinac}1-.*?-${prepinac}0-/$prepsano/s;
    }
    return $text;
}



#------------------------------------------------------------------------------
# Převezme pole řetězců, z nichž každý se má přepsat na právě jeden znak
# Unikódu a kódy cílových znaků představují souvislý úsek Unikódu. Dále
# převezme kód prvního cílového znaku a odkaz na hash s převodní tabulkou.
# Tento odkaz také vrátí.
#------------------------------------------------------------------------------
sub pridat_zdrojove_pole
{
    my $tabulka = shift; # odkaz na hash
    my $cil0 = shift; # kód prvního cílového znaku
    my @zdroj = @_; # pole zdrojových řetězců
    for(my $i = 0; $i<=$#zdroj; $i++)
    {
        $tabulka->{$zdroj[$i]} = chr($cil0+$i);
    }
    return $tabulka;
}



#------------------------------------------------------------------------------
# Převezme pole zdrojových řetězců a pole cílových řetězců. Obě pole musí být
# stejně dlouhá, jednotlivé řetězce mohou být libovolně dlouhé. Dále převezme
# odkaz na hash s převodní tabulkou, do které má uložit převody.
#------------------------------------------------------------------------------
sub pridat_dve_pole
{
    my $tabulka = shift; # odkaz na hash
    my $n = ($#_+1)/2;
    my @zdroj = @_[0..($n-1)];
    my @cil = @_[$n..(2*$n-1)];
    for(my $i = 0; $i<$n; $i++)
    {
        $tabulka->{$zdroj[$i]} = $cil[$i];
    }
    return $tabulka;
}



#------------------------------------------------------------------------------
# Převezme pole zdrojových a cílových řetězců. První prvek je zdrojový, druhý
# cílový, třetí zdrojový, čtvrtý cílový atd. Dále převezme odkaz na hash
# s převodní tabulkou, do které má uložit převody.
#------------------------------------------------------------------------------
sub pridat_smisene_pole
{
    my $tabulka = shift; # odkaz na hash
    for(my $i = 0; $i<$#_; $i += 2)
    {
        $tabulka->{$_[$i]} = $_[$i+1];
    }
    return $tabulka;
}



#------------------------------------------------------------------------------
# Převezme pole zdrojových a cílových řetězců. První prvek je zdrojový, druhý
# cílový, třetí zdrojový, čtvrtý cílový atd. Dále převezme odkaz na hash
# s převodní tabulkou, do které má uložit převody.
#------------------------------------------------------------------------------
sub pridat_smisene_pole_kodu
{
    my $tabulka = shift; # odkaz na hash
    for(my $i = 0; $i<$#_; $i += 2)
    {
        # Převést cílové kódy na řetězec.
        my $cil = $_[$i+1] eq "" ? "" : join("", map {chr($_)} split(/\+/, $_[$i+1]));
        $tabulka->{$_[$i]} = $cil;
    }
    return $tabulka;
}



#------------------------------------------------------------------------------
# Přepíše text na základě převodní tabulky řetězců (např. z jednoho písma do
# druhého).
#------------------------------------------------------------------------------
sub prepsat_tabulka
{
    my $tabulka = shift; # odkaz na hash
    my $zdroj = shift; # řetězec, který má být přepsán
    my $cil; # přepsaný řetězec
    # Zjistit délku nejdelšího zdrojového řetězce. Na každé pozici pak budeme testovat prefixy až do této délky!
    my $maxdelka = 0;
    foreach my $klic (keys(%{$tabulka}))
    {
        my $delka = length($klic);
        if($delka>$maxdelka)
        {
            $maxdelka = $delka;
        }
    }
    # Projít řetězec a přepsat ho.
    while($zdroj ne '')
    {
        # Zkusit všechny délky prefixů, začít od nejdelšího.
        my $nalezeno = 0;
        for(my $i = $maxdelka; $i>0; $i--)
        {
            # Podívat se na prefix délky $i a zjistit, jestli ho známe jako zdrojový řetězec.
            if($zdroj =~ m/^(.{$i})/s && exists($tabulka->{$1}))
            {
                # Nalezený prefix odstranit ze zdroje.
                $zdroj =~ s/^(.{$i})//s;
                # Jeho přepis přidat do cíle.
                $cil .= $tabulka->{$1};
                # Ukončit hledání, resp. začít ho v dalším kole znova od začátku.
                $nalezeno = 1;
                last;
            }
        }
        # I pokud nebyl rozpoznán žádný prefix, musíme užrat alespoň první znak, abychom se hnuli z místa.
        unless($nalezeno)
        {
            $zdroj =~ s/^(.)//s;
            $cil .= $1;
        }
    }
    return $cil;
}



#------------------------------------------------------------------------------
# Vrátí převodní tabulku jako text HTML, který lze využít jako nápovědu.
#------------------------------------------------------------------------------
sub prevest_tabulku_do_html
{
    my $tabulka = shift;
    my $html;
    $html .= "<table border='1'>\n";
    $html .= "  <tr>\n";
    $html .= "    ";
    my @klice = sort(keys(%{$tabulka}));
    foreach my $klic (@klice)
    {
        # Tabulka může obsahovat nesamostatné znaky.
        # Mezerami kolem nich se snažíme zajistit, aby se nekombinovaly se značkami HTML.
        $html .= "<td> $klic </td>";
    }
    $html .= "\n";
    $html .= "  </tr>\n";
    $html .= "  <tr>\n";
    $html .= "    ";
    foreach my $klic (@klice)
    {
        # Tabulka může obsahovat nesamostatné znaky.
        # Mezerami kolem nich se snažíme zajistit, aby se nekombinovaly se značkami HTML.
        $html .= "<td> $tabulka->{$klic} </td>";
    }
    $html .= "\n";
    $html .= "  </tr>\n";
    $html .= "</table>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Vygeneruje nápovědu v HTML.
#------------------------------------------------------------------------------
sub napoveda
{
    my $html;
    $html .= "<h1>Nápověda</h1>\n";
    $html .= "<h2>Latinka s&nbsp;diakritikou</h2>\n";
    $html .= prevest_tabulku_do_html($tabulka_latin);
    $html .= "<h2>Rumunština</h2>\n";
    $html .= '<tt>-(r[ou]m)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_rom);
    $html .= "<h2>Ruština</h2>\n";
    $html .= '<tt>-(rus)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_rus);
    $html .= "<h2>Ukrajinština</h2>\n";
    $html .= '<tt>-(ukr)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_ukr);
    $html .= "<h2>Řečtina</h2>\n";
    $html .= '<tt>-(gre)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_gre);
    $html .= "<h2>Arabština</h2>\n";
    $html .= '<tt>-(ara?b?)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_arab);
    $html .= "<h2>Urdština</h2>\n";
    $html .= '<tt>-(urd)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_urdu);
    $html .= "<h2>Dévanágarí</h2>\n";
    $html .= '<tt>-(dev)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_devanagari);
    $html .= "<h2>Bengálština</h2>\n";
    $html .= '<tt>-(ben)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_bengali);
    $html .= "<h2>Gurmukhí</h2>\n";
    $html .= '<tt>-(gur)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_gurmukhi);
    $html .= "<h2>Telugština</h2>\n";
    $html .= '<tt>-(tel)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_telugu);
    $html .= "<h2>Kannadština</h2>\n";
    $html .= '<tt>-(knd)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_kannada);
    $html .= "<h2>Tamilština</h2>\n";
    $html .= '<tt>-(tam)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_tamil);
    $html .= "<h2>Hiragana</h2>\n";
    $html .= '<tt>-(hir)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_hiragana);
    $html .= "<h2>Katakana</h2>\n";
    $html .= '<tt>-(kat)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_katakana);
    $html .= "<h2>Kandži</h2>\n";
    $html .= '<tt>-(kan)1-(.*?)-(?:\1)0-</tt>'."\n";
    $html .= prevest_tabulku_do_html($tabulka_kanji);
    return $html;
}



#------------------------------------------------------------------------------
# Inicializuje převodní tabulky. Odkazy na tabulky jsou globální proměnné.
# Nemůže se ve zdrojáku nacházet před funkcemi, které volá.
#------------------------------------------------------------------------------
BEGIN
{
    $tabulka_latin = sestavit_tabulku_latin();
    $tabulka_rom = sestavit_tabulku_rom();
    $tabulka_rus = sestavit_tabulku_cyrilice('rus');
    $tabulka_ukr = sestavit_tabulku_cyrilice('ukr');
    $tabulka_gre = sestavit_tabulku_rectina();
    $tabulka_arab = sestavit_tabulku_arab();
    $tabulka_urdu = sestavit_tabulku_urdu();
    $tabulka_devanagari = sestavit_tabulku_devanagari();
    $tabulka_bengali = sestavit_tabulku_bengali();
    $tabulka_gurmukhi = sestavit_tabulku_gurmukhi();
    $tabulka_telugu = sestavit_tabulku_telugu();
    $tabulka_kannada = sestavit_tabulku_kannada();
    $tabulka_tamil = sestavit_tabulku_tamil();
    $tabulka_hiragana = sestavit_tabulku_hiragana();
    $tabulka_katakana = sestavit_tabulku_katakana();
    $tabulka_kanji = sestavit_tabulku_kanji();
}



1;
