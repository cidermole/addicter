# Funkce pro počítání s časem a daty.
# Copyright © 2006-2008, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL
# 2014-10-22: Celá knihovna přepracována, nyní je hlavní jednotkou esek a (snad!) jsem odstranil chyby způsobené používáním systémové funkce localtime().
#             Staré důležité funkce datum2eden() a eden2datum() byly namapovány na nové, ale pokud by byl s localtime() problém, budu se k nim muset vrátit.

package cas;
require 5.000;
require Exporter;
use utf8;

@ISA = qw(Exporter);
@EXPORT = qw(esek2hash datumcas2esek esek2datumcas datum2eden eden2datum eden2esek esek2mcas sek2cas den_v_tydnu ted);



# Hlavní datové typy, které tento modul používá:
# datum: řetězec ve tvaru "8.5.2006"
# cas:   řetězec ve tvaru "15:37:56"
# datumcas: řetězec ve tvaru "8.5.2006 15:37:56"
# rmdhms: řetězec ve tvaru "20060508153756"
# mcas:  místní čas - stejný formát jako datumcas, ale hodnota je upravená podle časového pásma a letního času
# eden:  počet dní od začátku epochy (1. ledna v roce epochy je den č. 0), např. pro datum "8.5.2006" a epochu 1970 je to 13277
# esek:  počet nepřestupných sekund od začátku epochy, např. pro 8.5.2006 0:00:00 UTC a epochu 1970 je to 1147132800
# time:  počet nepřestupných sekund od začátku systémové epochy (pro MacOS 1904, pro ostatní 1970)
# hash:  kompletní soubor údajů odvoditelných pro jeden bod v čase (např. samostatně den, měsíc, rok atd.)



#------------------------------------------------------------------------------
# Základní časovou jednotkou budou esek (sekundy od začátku epochy).
# Následující funkce převádějí esek na různé jiné hodnoty (kvůli zpětné
# kompatibilitě tu máme pro některé funkce i ekvivalent s dlouhým jménem,
# esek2...()).
# Funkce all vrací pole hodnot stejné jako vestavěná funkce localtime().
# Některé hodnoty jsou nepředžvýkané, třeba rok.
#------------------------------------------------------------------------------
sub sek { my $esek = shift; my @a = parsesek($esek); return $a[0]; }
sub min { my $esek = shift; my @a = parsesek($esek); return $a[1]; }
sub hod { my $esek = shift; my @a = parsesek($esek); return $a[2]; }
# číslo dne v měsíci
sub den { my $esek = shift; my @a = parsesek($esek); return $a[3]; }
# číslo měsíce v roce
sub mes { my $esek = shift; my @a = parsesek($esek); return $a[4]+1; }
sub rok { my $esek = shift; my @a = parsesek($esek); return 1900+$a[5]; }
# index měsíce pro vyhledávání v poli názvů měsíců (leden je 0)
sub imes { my $esek = shift; my @a = parsesek($esek); return $a[4]; }
# index dne v týdnu pro vyhledávání v poli názvů dnů (0 je neděle, 1 je pondělí, 6 je sobota)
sub idvt { my $esek = shift; my @a = parsesek($esek); return $a[6]; }
# Vrací true, jestliže v daném okamžiku platí letní čas.
# Tohle stanoví systém na základě místních nastavení. Hodnota esek sama o sobě neví, zda jsme třeba v Arizoně, kde letní čas neplatí.
sub je_letni_cas { my $esek = shift; my @a = parsesek($esek); return $a[8]; }
# český název měsíce
sub mesic { my $esek = shift; return ('leden', 'únor', 'březen', 'duben', 'květen', 'červen', 'červenec', 'srpen', 'září', 'říjen', 'listopad', 'prosinec')[imes($esek)]; }
# český název měsíce v genitivu
sub mesic { my $esek = shift; return ('ledna', 'února', 'března', 'dubna', 'května', 'června', 'července', 'srpna', 'září', 'října', 'listopadu', 'prosince')[imes($esek)]; }
# český název dne v týdnu
sub dvt { my $esek = shift; return ('neděle', 'pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota')[idvt($esek)]; }
# datum (s tečkami, bez mezer, bez doplňujících nul)
sub datum { my $esek = shift; my @a = parsesek($esek); return sprintf("%d.%d.%d", $a[3], $a[4]+1, $a[5]+1900); }
# čas (s dvojtečkami, s doplňujícími nulami)
sub cas { my $esek = shift; my @a = parsesek($esek); return sprintf("%d:%02d:%02d", $a[2], $a[1], $a[0]); }
# kombinace data a času
sub datumcas { my $esek = shift; my @a = parsesek($esek); return sprintf("%d.%d.%d %d:%02d:%02d", $a[3], $a[4]+1, $a[5]+1900, $a[2], $a[1], $a[0]); }
# datum a čas, který je možné přečíst (na rozdíl od esek), ale lze podle něj třídit, např. "19711221153705"
sub rmdhms { my $esek = shift; my @a = parsesek($esek); return sprintf("%04d%02d%02d%02d%02d%02d", $a[5]+1900, $a[4]+1, $a[3], $a[2], $a[1], $a[0]); }
sub rmd { my $esek = shift; my @a = parsesek($esek); return sprintf("%04d%02d%02d", $a[5]+1900, $a[4]+1, $a[3]); }
sub rm { my $esek = shift; my @a = parsesek($esek); return sprintf("%04d%02d", $a[5]+1900, $a[4]+1); }
sub md { my $esek = shift; my @a = parsesek($esek); return sprintf("%02d%02d", $a[4]+1, $a[3]); }
# číslo dne od začátku epochy
sub eden { my $esek = shift; return int($esek/86400); }



#------------------------------------------------------------------------------
# Vrátí aktuální čas v esek, tj. zavolá systémový time() a přepočítá výsledek
# ze systémové epochy na naši epochu. Systémový time() by měl vracet čas UTC,
# tj. nezávislý na momentálním nastavení časového pásma.
#------------------------------------------------------------------------------
sub nastavit_ted_greenwich { my $time = time(); return time2esek($time); }
sub nastavit_ted_local { my $time = time(); return time2esek($time)+posun_localtime(); } ###!!! asi blbě, mixuju rozdíly epoch a rozdíly časových pásem
sub nastavit_ted { return nastavit_ted_local(); }



#------------------------------------------------------------------------------
# Klíčová funkce pro převod čitelného data a času na eseky. Na rozdíl od
# opačného směru, kde můžeme využít vestavěnou funkci localtime(), tenhle směr
# si musíme odpracovat. Tato varianta funkce se nezabývá případným letním časem
# a není tedy přímým protějškem zjišťovací funkce rmdhms($esek). Důvodem je
# obrana proti zacyklení. Abychom zjistili, zda platí letní čas, potřebujeme
# zavolat localtime(), který ale zase vždy voláme i s touto funkcí.
#------------------------------------------------------------------------------
sub nastavit_rmdhms_zimni_cas
{
    my $rmdhms = shift;
    $rmdhms =~ m/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/;
    my $rok = $1;
    my $mes = $2;
    my $den = $3;
    my $hod = $4;
    my $min = $5;
    my $sek = $6;
    # Epocha je číslo roku, na jehož začátku (1. ledna v 0:00:00) máme
    # umístěnou nulu časové osy. Eseky (epochální sekundy) počítáme od tohoto
    # bodu. Operační systém má také svou epochu, obvykle je to rok 1970. My
    # v této knihovně můžeme mít nastavenou svou vlastní epochu, která je na
    # té systémové nezávislá (a umí vždy zjistit, o kolik se od té systémové
    # liší). Takže se nemusíme bát, že v jiném operačním systému bude čas
    # fungovat jinak.
    my $epocha = epocha();
    # Výsledek pro nás zatím bude číslo dne (0 je 1. ledna epochálního roku).
    # Čas přidáme až na konci.
    my $vysledek = 0;
    my($irok, $imes);
    my @delka_mesice = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    # Postup se liší podle toho, zda se zadané datum nachází v epoše, nebo před ní.
    if($rok>=$epocha)
    {
        for($irok = $epocha; $irok<$rok; $irok++)
        {
            $vysledek += pocet_dni_v_roce($irok);
        }
        for($imes = 1; $imes<$mes; $imes++)
        {
            $vysledek += $delka_mesice[$imes-1];
        }
        if(($mes>2) && je_prestupny_rok($rok))
        {
            $vysledek++;
        }
        $vysledek += $den;
        # První den epochy má mít číslo 0, ale zatím jsme se chovali, jako by to měla být jednička. Odečíst ji.
        $vysledek--;
    }
    # Pro roky před epochou musíme postupovat v opačném směru.
    else # $rok<$epocha
    {
        for($irok = $epocha-1; $irok>$rok; $irok--)
        {
            $vysledek -= pocet_dni_v_roce($irok);
        }
        for($imes = 12; $imes>$mes; $imes--)
        {
            $vysledek -= $delka_mesice[$imes-1];
        }
        if(($mes<2) && je_prestupny_rok($rok))
        {
            $vysledek--;
        }
        $vysledek -= $delka_mesice[$mes-1]-$den+1;
    }
    # Dosavadní výsledek vyjadřuje počet dní od začátku epochy.
    # Převést výsledek na počet sekund a přičíst čas v rámci dne.
    $vysledek = $vysledek*86400+$hod*3600+$min*60+$sek;
    return $vysledek;
}



#------------------------------------------------------------------------------
# Obálka kolem funkce nastavit_rmdhms_zimni_cas(), která navíc zjišťuje, zda
# v daném okamžiku platí letní čas, a pokud ano, tak koriguje výsledek, aby
# odpovídal interpretaci vstupu podle letního času. Díky tomu bude platit, že
# $x == nastavit_rmdhms(rmdhms($x)).
#------------------------------------------------------------------------------
sub nastavit_rmdhms
{
    my $rmdhms = shift;
    my $esek_pred_korekci = nastavit_rmdhms_zimni_cas($rmdhms);
    my $esek = $esek_pred_korekci;
    # Zeptám se na letní čas systému. Nevím, jak ho má implementovaný (ví například, ve kterých letech se u nás nepoužíval?)
    if(je_letni_cas($esek_pred_korekci))
    {
        # V době letního času ukazují hodiny o hodinu víc než kolik odpovídá danému geografickému časovému pásmu.
        # Např. v Praze máme v létě čas, který v zimě platí na Ukrajině. Eseky ale chceme i v létě dostat tak, jak platí v daném místě v zimě.
        $esek -= 3600;
        # V roce 2014 bude letní čas končit v noci ze soboty 25. na neděli 26. října.
        # V neděli ve 3:00 se hodiny posunou zpět na 2:00. Čas 2014-10-26 02:30:00 tedy bude dvakrát, jednou ještě v letním čase a podruhé v zimním.
        # A jak se zachová tato funkce?
        # O půlnoci bude hodnota esek činit 1 414 278 000 a zpětný převod bude 26.10.2014 0:00:00, letní čas.
        # V jednu hodinu v noci ........... 1 414 281 600 .................... 26.10.2014 1:00:00, letní čas.
        # Ve dvě hodiny v noci ............ 1 414 288 800 .................... 26.10.2014 2:00:00, zimní čas.
        # Esekový rozdíl mezi jednou a dvěma hodinami v noci tedy činí 2 hodiny, resp. 7200 sekund.
        # Eseky sem od epochy doputovaly v zimním čase, pak se zjistilo, že tahle eseková hodnota už do zimního času patří, a ke korekci nedošlo.
        # Na esekovou hodnotu spadající mezi 2. a 3. hodinu ranní letního času se tedy nedá touto funkcí dostat:
        # ???????????????????? ............ 1 414 285 200 .................... 26.10.2014 2:00:00, letní čas.
        # ???????????????????? ............ 1 414 288 799 .................... 26.10.2014 2:59:59, letní čas.
        # V neděli 30. března naopak začínal letní čas a ve 2:00 se hodiny posunuly dopředu na 3:00.
        # 2014-03-30 01:00:00 ............. 1 396 141 200 .................... 30.3.2014 1:00:00, zimní čas.
        # 2014-03-30 02:00:00 ............. 1 396 141 200 .................... 30.3.2014 1:00:00, zimní čas (čas 2:00 vlastně vůbec neexistoval, byl rovnou 3:00).
        # 2014-03-30 02:30:00 ............. 1 396 143 000 .................... 30.3.2014 1:30:00, zimní čas (dtto).
        # 2014-03-30 03:00:00 ............. 1 396 144 800 .................... 30.3.2014 3:00:00, letní čas.
    }
    return $esek;
}



#------------------------------------------------------------------------------
# Funkce pro nastavení určité složky času na konkrétní hodnotu. Všechny ostatní
# složky, které na ní nezávisí, zůstanou nezměněné. Vrací esek.
#------------------------------------------------------------------------------
sub nastavit_rmd { my $rmd = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$rmd$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_rm { my $rm = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$rm$3$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_md { my $md = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$md$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_rok { my $rok = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$rok$2$3$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_mes { my $mes = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$mes$3$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_den { my $den = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$den$4$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_datum { my $datum = shift; my $esek = shift; $datum =~ m/(\d+)\.(\d+)\.(\d+)/; my $rmd = sprintf("%04d%02d%02d", $3, $2, $1); return nastavit_rmd($rmd, $esek); }
sub nastavit_hms { my $hms = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$hms/; return nastavit_rmdhms($rmdhms); }
sub nastavit_hm { my $hm = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$hm$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_hod { my $hod = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$hod$5$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_min { my $min = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$4$min$6/; return nastavit_rmdhms($rmdhms); }
sub nastavit_sek { my $sek = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$4$5$sek/; return nastavit_rmdhms($rmdhms); }



#------------------------------------------------------------------------------
# Funkce pro nastavení určité složky času na konkrétní hodnotu. Všechny menší
# složky se vynulují. Hodí se pro převod časových konstant, se kterými chceme
# nějaký čas porovnat, např. "je daný čas menší než 9:30 v daný den?" Hodnotu
# "9:30" pak potřebujeme nastavit jako "9:30:00".
#------------------------------------------------------------------------------
sub xset_rmd { my $rmd = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/${rmd}000000/; return nastavit_rmdhms($rmdhms); }
sub xset_rm { my $rm = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/${rm}01000000/; return nastavit_rmdhms($rmdhms); }
sub xset_md { my $md = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1${md}000000/; return nastavit_rmdhms($rmdhms); }
sub xset_rok { my $rok = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/${rok}0101000000/; return nastavit_rmdhms($rmdhms); }
sub xset_mes { my $mes = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1${mes}01000000/; return nastavit_rmdhms($rmdhms); }
sub xset_den { my $den = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2${den}000000/; return nastavit_rmdhms($rmdhms); }
sub xset_hms { my $hms = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$hms/; return nastavit_rmdhms($rmdhms); }
sub xset_hm { my $hm = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3${hm}00/; return nastavit_rmdhms($rmdhms); }
sub xset_hod { my $hod = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3${hod}0000/; return nastavit_rmdhms($rmdhms); }
sub xset_min { my $min = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$4${min}00/; return nastavit_rmdhms($rmdhms); }
sub xset_sek { my $sek = shift; my $esek = shift; my $rmdhms = rmdhms($esek); $rmdhms =~ s/^(\d+)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1$2$3$4$5$sek/; return nastavit_rmdhms($rmdhms); }



#------------------------------------------------------------------------------
# Funkce pro porovnávání času v esek s různými časovými konstantami vyjádřenými
# v rmdhms.
#------------------------------------------------------------------------------
sub ltrmd { my $esek1 = shift; my $rmd = shift; my $esek2 = xset_rmd ($md, $esek1); return $esek1 < $esek2; }
sub gtrmd { my $esek1 = shift; my $rmd = shift; my $esek2 = plus_den(xset_rmd($md, $esek1)); return $esek1 >= $esek2; }
sub ltmd { my $esek1 = shift; my $md = shift; my $esek2 = xset_md ($md, $esek1); return $esek1 < $esek2; }
sub gtmd { my $esek1 = shift; my $md = shift; my $esek2 = plus_den(xset_md($md, $esek1)); return $esek1 >= $esek2; }
sub lthm { my $esek1 = shift; my $hm = shift; my $esek2 = xset_hm ($hm, $esek1); return $esek1 < $esek2; }
sub gthm { my $esek1 = shift; my $hm = shift; my $esek2 = xset_hm ($hm, $esek1); return $esek1 > $esek2; }



#------------------------------------------------------------------------------
# Funkce pro přičtení určitého (i záporného) počtu určitých časových jednotek
# k časovému údaji v esek.
#------------------------------------------------------------------------------
sub plus_min { my $esek = shift; my $n = shift; $n = 1 if(!defined($n)); return $esek + $n * 60; }
sub plus_hod { my $esek = shift; my $n = shift; $n = 1 if(!defined($n)); return $esek + $n * 3600; }
sub plus_den { my $esek = shift; my $n = shift; $n = 1 if(!defined($n)); return $esek + $n * 86400; }
sub plus_tyden { my $esek = shift; my $n = shift; $n = 1 if(!defined($n)); return $esek + $n * 604800; }
sub plus_mesic
{
    my $esek = shift;
    my $n = shift;
    $n = 1 if(!defined($n));
    my $mes0 = mes($esek);
    my $mes1 = $mes0 + $n;
    if($mes1>=1 && $mes1<=12)
    {
        return nastavit_mes($mes1, $esek);
    }
    elsif($mes1>12)
    {
        my $rok0 = rok($esek);
        my $rok1 = $rok0 + 1;
        $n -= 12 - $mes0 + 1;
        $rok1 += int($n / 12);
        $mes1 = 1 + $n % 12;
        my $rm1 = sprintf("%d%02d", $rok1, $mes1);
        return nastavit_rm($rm1, $esek);
    }
    else # $mes1 < 1
    {
        my $rok0 = rok($esek);
        my $rok1 = $rok0 - 1;
        $n -= $mes0;
        $rok1 -= int($n / 12);
        $mes1 = 12 - $n % 12;
        my $rm1 = sprintf("%d%02d", $rok1, $mes1);
        return nastavit_rm($rm1, $esek);
    }
}
sub plus_rok { my $esek = shift; my $n = shift; $n = 1 if(!defined($n)); my $rok = rok($esek); return nastavit_rok ($rok + $n, $esek); }



#------------------------------------------------------------------------------
# Funkce pro zjištění rozdílu mezi dvěma okamžiky v různě velkých jednotkách.
#------------------------------------------------------------------------------
sub rozdil_sek { my ($esek1, $esek2) = @_; return ($esek1-$esek2); }
sub rozdil_min { my ($esek1, $esek2) = @_; return ($esek1-$esek2) / 60; }
sub rozdil_hod { my ($esek1, $esek2) = @_; return ($esek1-$esek2) / 3600; }
sub rozdil_den { my ($esek1, $esek2) = @_; return ($esek1-$esek2) / 86400; }
sub rozdil_tyden { my ($esek1, $esek2) = @_; return ($esek1-$esek2) / 604800; }
sub rozdil_mesic
{
    my $esek1 = shift;
    my $esek2 = shift;
    my $zapor = 0;
    if($esek1<$esek2)
    {
        $zapor = 1;
        my $x = $esek1;
        $esek1 = $esek2;
        $esek2 = $x;
    }
    my $rm1 = rm($esek1);
    my $rm2 = rm($esek2);
    my $rozdil = 0;
    # Započítat celé měsíce.
    while($rm1>$rm2)
    {
        $rozdil++;
        $rm1--;
        if($rm1 =~ m/^(\d+)00$/)
        {
            my $rok = $1;
            $rok--;
            $rm1 = $rok.'12';
        }
    }
    # Přičíst části okrajových měsíců.
    my $esek1rm2 = nastavit_rm($rm2, $esek1);
    # Rozdíl v rámci měsíce může být kladný i záporný (s ohledem na čísla dnů v měsíci u $esek1 a $esek2).
    my $rden = rozdil_den($esek1rm2, $esek2);
    my $ndni = pocet_dni_v_mesici($esek2);
    $rozdil += $rden/$ndni;
    return $zapor ? -$rozdil : $rozdil;
}
sub rozdil_rok
{
    my $esek1 = shift;
    my $esek2 = shift;
    my $zapor = 0;
    if($esek1<$esek2)
    {
        $zapor = 1;
        my $x = $esek1;
        $esek1 = $esek2;
        $esek2 = $x;
    }
    my $rok1 = rok($esek1);
    my $rok2 = rok($esek2);
    my $rozdil = 0;
    if($rok1==$rok2)
    {
        my $rden = rozdil_den($esek1, $esek2);
        my $ndni = pocet_dni_v_roce($esek1);
        $rozdil = $rden/$ndni;
    }
    else
    {
        # Nejdříve zahrnout do rozdílu celé mezilehlé roky.
        if($rok1-$rok2 >= 2)
        {
            $rozdil += $rok1-$rok2-1;
        }
        # Přičíst začátek roku 1.
        my $zacatek = xset_rok($rok1);
        my $rden = rozdil_den($esek1, $zacatek);
        my $ndni = pocet_dni_v_roce($esek1);
        $rozdil += $rden/$ndni;
        # Přičíst konec roku 2.
        my $konec = xset_rok($rok2+1);
        $rden = rozdil_den($konec, $esek2);
        $ndni = pocet_dni_v_roce($esek2);
        $rozdil += $rden/$ndni;
    }
    return $zapor ? -$rozdil : $rozdil;
}



#------------------------------------------------------------------------------
# Zjistí, zda určité datum připadá na český státní nebo ostatní svátek. Jako
# parametr bere esek, tj. kompletní časový údaj, ale na rok se obvykle nedívá,
# tj. nebere v úvahu, že např. 17. listopad je státním svátkem až od roku 2000
# (zákon 245/2000 Sb.) Výjimkou je akorát Velikonoční pondělí, které každý rok
# připadá na jiný den.
#------------------------------------------------------------------------------
sub je_svatek
{
    my $esek = shift;
    my $rmdhms = rmdhms($esek);
    # Není-li to pevný svátek, mohlo by to být Velikonoční pondělí.
    my $vpon = md(plus_den(nastavit_velikonocni_nedeli($esek)));
    return $rmdhms =~ m/^(\d+)(0101|$vpon|0501|0508|0705|0706|0928|1028|1117|1224|1225|1226)\d\d\d\d\d\d$/;
}



#------------------------------------------------------------------------------
# Gaussův algoritmus pro výpočet data velikonoční neděle v daném roce. Údajně
# platí pro všechny roky od roku 1900 do roku 2099 s výjimkou let 1954 a 1981,
# kdy byly velikonoce o týden dřív. Vstup i výstup je v esek.
#------------------------------------------------------------------------------
sub nastavit_velikonocni_nedeli
{
    my $esek = shift;
    my $rok = rok($esek);
    my $zbytek1 = $rok % 19;
    my $zbytek2 = $rok % 4;
    my $zbytek3 = $rok % 7;
    my $zbytek4 = ($zbytek1*19+24) % 30;
    my $zbytek5 = (5+2*$zbytek2+4*$zbytek3+6*$zbytek4) % 7;
    # Referenční datum je 22. března.
    my $rmd = $rok.'0322';
    return plus_den(nastavit_rmd($rmd), $zbytek4+$zbytek5);
}



#------------------------------------------------------------------------------
# Zjistí, zda určité datum připadá na český pracovní den, tj. není to ani
# sobota, ani neděle, ani zákonem stanovený svátek. Rok se používá pouze pro
# určení data Velikonočního pondělí, ale nebere se např. v úvahu, že soboty
# byly do určitého roku pracovní.
#------------------------------------------------------------------------------
sub je_pracovni_den
{
    my $esek = shift;
    return idvt($esek) =~ m/^[12345]$/ && !je_svatek($esek);
}



#------------------------------------------------------------------------------
# Najde nejbližší další pracovní den od daného dne (okamžiku). Bere esek a
# vrací jiný esek. Umí i n pracovních dnů odteď, a to i směrem zpět (záporné
# n).
#------------------------------------------------------------------------------
sub plus_pracovni_den
{
    my $esek = shift;
    my $n = shift;
    $n = 1 if(!defined($n));
    my $krok = $n<0 ? -1 : 1;
    my $absn = abs($n);
    for(my $i = 0; $i<$absn; $i++)
    {
        do
        {
            $esek = plus_den($esek, $krok);
        }
        while(!je_pracovni_den($esek));
    }
    return $esek;
}



#------------------------------------------------------------------------------
# Nastaví epochu pro přepočítávání data na celé číslo a zpět. Epocha je číslo
# roku, tj. epocha začíná 1. ledna v tomto roce. (1. leden roku epochy je
# epochální den č. 0. Den č. 1 je 2. leden.)
#------------------------------------------------------------------------------
$epocha = 1970; # default
sub nastavit_epochu
{
    my $dosavadni_epocha = $epocha;
    $epocha = shift;
    return $dosavadni_epocha;
}



#------------------------------------------------------------------------------
# Zjistí epochu pro přepočítávání data na celé číslo a zpět. Epocha je číslo
# roku, tj. epocha začíná 1. ledna v tomto roce. (1. leden roku epochy je
# epochální den č. 0. Den č. 1 je 2. leden.)
#------------------------------------------------------------------------------
sub epocha
{
    return $epocha;
}



###!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
###!!! Kurva, co tady blbnu kvůli posunu localtime(), když exituje funkce
###!!! gmtime()? Dokonce už jsem ji v minulosti použil, viz dole!
#------------------------------------------------------------------------------
# Pro převod eseků na různé jiné hodnoty používám funkci localtime(). Výhodou
# je, že jde o vestavěnou funkci a dotyčné výpočty by proto měly být rychlejší,
# než kdybych si je psal sám (jako to dělám při převodu opačným směrem). Na
# druhou stranu má tato funkce nevýhodu, že se ptá systému na aktuální časové
# pásmo, možná i na letní čas a další věci. V neposlední řadě se systémová
# epocha může lišit od té mé a ne všechny systémy mají stejnou epochu (MacOS
# má 1904, ostatní mají 1970). Proto potřebujeme funkci, která zjistí odchylku
# localtime() od mé epochy a časového pásma UTC.
#------------------------------------------------------------------------------
sub posun_localtime
{
    # Necháme localtime() interpretovat nulu na základě jeho systémové epochy
    # (pro MacOS 1904, pro ostatní 1970) a právě nastaveného časového pásma.
    my @a = localtime(0);
    my $rmdhms = sprintf("%04d%02d%02d%02d%02d%02d", $a[5]+1900, $a[4]+1, $a[3], $a[2], $a[1], $a[0]);
    # Převedeme výsledek zpět na eseky funkcí, která na localtime() nezávisí.
    # (Pokud je systémová epocha stejná jako ta naše, tak to nebude moc náročný
    # výpočet, půjde jen o časové pásmo.)
    # Jestliže nám vyjde něco jiného než 0, je to posun způsobený časovým pásmem a/nebo jinou epochou.
    # Pokud budeme chtít použít localtime() pro interpretaci našich eseků, zavoláme localtime($esek-$posun).
    my $posun = nastavit_rmdhms_zimni_cas($rmdhms);
    return $posun;
}



#------------------------------------------------------------------------------
# Interpretuje eseky pomocí localtime(), ale bez vlivu systémové epochy a
# časového pásma, které se do localtime() jinak promítají. Výsledkem je pole
# hodnot, které mají stejnou interpretaci jako u localtime().
#------------------------------------------------------------------------------
sub parsesek
{
    my $esek = shift;
    return localtime($esek-posun_localtime());
}



#------------------------------------------------------------------------------
# Zjistí počet dní v aktuálním měsíci; u února bere v potaz přestupný rok.
# Vstupem je časový údaj v esekách.
#------------------------------------------------------------------------------
sub pocet_dni_v_mesici
{
    my $esek = shift;
    my $imes = imes($esek);
    return (31, (je_prestupny_rok($esek) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$imes];
}



#------------------------------------------------------------------------------
# Zjistí počet dní v roce v závislosti na tom, zda je to přestupný rok. Jako
# parametr funguje jak číslo roku, tak eseky, až na drobné výjimky popsané u
# funkce je_prestupny_rok().
#------------------------------------------------------------------------------
sub pocet_dni_v_roce
{
    my $rok = shift;
    return je_prestupny_rok($rok) ? 366 : 365;
}



#------------------------------------------------------------------------------
# Zjistí, zda jde o přestupný, nebo normální rok. Nebere v úvahu, že přestupné
# roky byly zavedeny až s gregoriánským kalendářem v 16. století. Klidně ohlásí
# přestupný rok před Kristem.
#------------------------------------------------------------------------------
sub je_prestupny_rok
{
    # Kvůli zpětné kompatibilitě musí tato funkce umět na vstupu číslo roku.
    # Současně ale chceme, aby stejně jako všechny ostatní klíčové funkce nyní
    # uměla pracovat s eseky. Heuristika: dostatečně velké číslo jsou eseky.
    # Den má 86400 sekund, rok o 365 dnech má 31 536 000 sekund.
    # Když budeme za eseky považovat vše, co je v absolutní hodnotě vyšší než 10000, tak jsme tím přišli jen o necelé 2 dny kolem epochální nuly.
    # Současně jsme vyloučili roky v pravěku nebo v daleké budoucnosti, které nás pravděpodobně stejně nezajímají.
    my $rok = shift;
    if(abs($rok)>10000)
    {
        my $esek = $rok;
        $rok = rok($esek);
    }
    if(($rok % 400 == 0) || ($rok % 4 == 0) && ($rok % 100 != 0))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}



#==============================================================================
# Starší funkce, které nemají esek jako centrální časovou jednotku, jsou tu
# kvůli zpětné kompatibilitě. Některé z nich s eseky pracují, ale mají jinak
# vytvořené názvy a nyní jsou to jen aliasy na funkce uvedené výše.
#==============================================================================



#------------------------------------------------------------------------------
# Převezme počet nepřestupných sekund od začátku naší epochy a vrátí hash
# s různými údaji odvoditelnými pro daný časový bod.
#   sek ...... sekunda (0..59)
#   min ...... minuta (0..59)
#   hod ...... hodina (0..23)
#   den ...... den v měsíci (1..31)
#   mes ...... číslo měsíce (1..12)
#   rok ...... rok gregoriánského kalendáře (nenulové celé číslo)
#   imes ..... index měsíce pro vyhledávání v poli názvů měsíců (0..11)
#   idvt ..... index dne v týdnu pro vyhledávání v poli názvů dnů (0..6; 0 je neděle, 1 je pondělí!)
#   letni .... true, jestliže je právě letní čas (0..1)
#   eden ..... počet dní od začátku naší epochy (celé číslo)
#   esek ..... počet sekund od začátku naší epochy (celé číslo)
#   system ... počet sekund od začátku systémové epochy (celé číslo)
#   mesic .... název měsíce (leden..prosinec)
#   mesice ... název měsíce v genitivu (ledna..prosince)
#   dvt ...... název dne v týdnu (pondělí..neděle)
#   datum .... celé datum, např. "21.12.1971"
#   cas ...... celý čas, např. "15:37:05"
#   rmdhms ... datum a čas, který je možné přečíst (na rozdíl od esek), ale lze podle něj třídit, např. "19711221153705"
#------------------------------------------------------------------------------
sub esek2hash
{
    my $esek = shift;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = parsesek($esek);
    my %hash =
    (
        "sek" => $sec,   # sekunda
        "min" => $min,   # minuta
        "hod" => $hour,  # hodina
        "den" => $mday,  # den (číslo dne v měsíci)
        "mes" => $mon+1, # měsíc (číslo měsíce v roce)
        "rok" => 1900+$year, # rok
        "imes" => $mon,  # index měsíce pro vyhledávání v poli názvů měsíců
        "idvt" => $wday, # index dne v týdnu pro vyhledávání v poli názvů dnů (0 je neděle, 1 je pondělí)
        "letni" => $isdst, # true, jestliže je právě letní čas
        "esek" => $esek,   # počet sekund od začátku naší epochy
        "system" => esek2time($esek), # počet sekund od začátku systémové epochy
    );
    $hash{mesic} = ("leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec")[$hash{imes}];
    $hash{mesice} = ("ledna", "února", "března", "dubna", "května", "června", "července", "srpna", "září", "října", "listopadu", "prosince")[$hash{imes}];
    $hash{dvt} = ("neděle", "pondělí", "úterý", "středa", "čtvrtek", "pátek", "sobota")[$hash{idvt}];
    $hash{datum} = sprintf("%d.%d.%d", $hash{den}, $hash{mes}, $hash{rok});
    $hash{cas} = sprintf("%d:%02d:%02d", $hash{hod}, $hash{min}, $hash{sek});
    $hash{datumcas} = "$hash{datum} $hash{cas}";
    $hash{rmdhms} = sprintf("%04d%02d%02d%02d%02d%02d", $hash{rok}, $hash{mes}, $hash{den}, $hash{hod}, $hash{min}, $hash{sek});
    # Předpočítat počet dnů od začátku mé epochy.
    $hash{eden} = datum2eden($hash{datum});
    return \%hash;
}



#------------------------------------------------------------------------------
# Zjistí pro libovolné datum, kolikátý je to den od začátku epochy (nastavena
# na začátku funkce, např. na 1.1.1970). Umožňuje provádět aritmetické operace
# s daty. 1. leden roku epochy je den č. 0.
#------------------------------------------------------------------------------
sub datum2eden
{
    my $epocha = epocha();
    my $datum = shift; # dd.mm.rrrr
    my $esek = nastavit_datum($datum);
    return eden($esek);
}



#------------------------------------------------------------------------------
# Přepočítá počet dnů od začátku epochy na datum ve formátu d.m.rrrr.
#------------------------------------------------------------------------------
sub eden2datum
{
    my $eden = shift;
    my $esek = $eden * 86400;
    return datum($esek);
}



#------------------------------------------------------------------------------
# Pro zadané číslo dne od začátku epochy zjistí, kolikátý je to den v týdnu.
# (0 = neděle, 6 = sobota)
# Týden nám začíná po anglicku nedělí, abychom se zbytečně neodchylovali od
# toho, jak má dny číslované operační systém. Na druhou stranu díky tomu
# ostatní dny mají intuitivnější čísla (pondělí 1, pátek 5 atd.)
#------------------------------------------------------------------------------
sub den_v_tydnu
{
    my $den = shift;
    # Počítání dne v týdnu by mělo být nezávislé na epoše.
    # Co když někoho napadne použít jinou než defaultní epochu?
    # 1.1.2007 bylo pondělí, tj. 31.12.2006 byla neděle.
    my $den0 = datum2eden('31.12.2006');
    # Modulo bude správně fungovat i pro dny před "dnem 0":
    # -1 % 7 == 6
    # -6 % 7 == 1
    # -7 % 7 == 0
    # -8 % 7 == 6
    return ($den-$den0)%7;
}



#------------------------------------------------------------------------------
# Přepočítá počet sekund od začátku systémové epochy na počet sekund od začátku
# naší epochy.
#------------------------------------------------------------------------------
sub time2esek
{
    my $time = shift;
    # Pokud jsme tuto funkci již někdy volali, pak známe posun naší epochy vůči systémové.
    # V opačném případě ho musíme vypočítat.
    if($posun_epochy eq "")
    {
        ###!!! Tohle mi nějak nefunguje správně, výsledkem je o den nižší číslo, než je správně.
        ###!!! Zatím prostě nastavím posun na nulu, beztak to funguje na obou systémech, na kterých tuhle knihovnu reálně používám.
        $posun_epochy = 0;
        if(0)
        {
            # Nechat systém převést $time podle jeho epochy na univerzálně platné časové údaje.
            my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime($time);
            # Z těchto údajů vypočítat počet sekund od začátku naší epochy.
            my $esek = datum2eden("$mday.".($mon+1).".".($year+1900))*86400+$hour*3600+$min*60+$sec;
            # Abychom nemuseli tento výpočet opakovat, zapamatovat si v globální proměnné rozdíl mezi naší a systémovou epochou.
            $posun_epochy = $esek-$time;
        }
    }
    return $time+$posun_epochy;
}



#------------------------------------------------------------------------------
# Přepočítá počet sekund od začátku naší epochy na počet sekund od začátku
# systémové epochy.
#------------------------------------------------------------------------------
sub esek2time
{
    my $esek = shift;
    # Pokud jsme tuto funkci již někdy volali, pak známe posun naší epochy vůči systémové.
    # V opačném případě ho musíme vypočítat.
    if($posun_epochy eq "")
    {
        # Perl umožňuje získat datum a čas na základě počtu sekund od začátku systémové epochy,
        # ale neumožňuje získat počet sekund od začátku systémové epochy na základě data a času.
        # Vzhledem k tomu, že neznáme systémovou epochu (nevíme, zda neběžíme pod MacOS nebo
        # něčím ještě kurióznějším), musíme si nechat systémem přepočítat nějaký čas (třeba 0)
        # na jednotky, ze kterých už posun dokážeme zjistit.
        time2esek(0);
    }
    return $esek-$posun_epochy;
}



#------------------------------------------------------------------------------
# Zjistí pro libovolné datum a čas, kolik sekund uplynulo od začátku epochy.
#------------------------------------------------------------------------------
sub datumcas2esek
{
    my $datumcas = shift; # dd.mm.rrrr hh:mm:ss
    $datumcas =~ m/(\d+\.\d+\.\d+)\s+(\d+):(\d+):(\d+)/;
    my $datum = $1;
    my $hod = $2;
    my $min = $3;
    my $sek = $4;
    return datum2eden($datum)*86400+$hod*3600+$min*60+$sek;
}



#------------------------------------------------------------------------------
# Převede počet sekund od začátku epochy na datum a čas (UTC).
#------------------------------------------------------------------------------
sub esek2datumcas
{
    my $esek = shift;
    my $zarovnat = shift;
    my $eden = int($esek/86400);
    my $hod = int(($esek%86400)/3600);
    my $min = int(($esek%3600)/60);
    my $sek = $esek%60;
    my $datum = eden2datum($eden);
    my $nmd = $zarovnat ? "10" : "";
    my $nmh = $zarovnat ? "2" : "";
    return sprintf("%${nmd}s %${nmh}d:%02d:%02d", $datum, $hod, $min, $sek);
}



#------------------------------------------------------------------------------
# Převede datum a čas ve formátu rmdhms na počet sekund od začátku epochy.
#------------------------------------------------------------------------------
sub rmdhms2esek
{
    my $rmdhms = shift; # rrrrmmddhhmmss
    return nastavit_rmdhms($rmdhms);
}



#------------------------------------------------------------------------------
# Převede počet sekund od začátku epochy na datum a čas (UTC) ve formátu rmdhms.
#------------------------------------------------------------------------------
sub esek2rmdhms
{
    my $esek = shift;
    return rmdhms($esek);
}



#------------------------------------------------------------------------------
# Převede dny na sekundy.
#------------------------------------------------------------------------------
sub eden2esek
{
    my $eden = shift;
    return $eden*86400;
}



#------------------------------------------------------------------------------
# Převede počet sekund od začátku epochy na datum a čas v určitém časovém
# pásmu.
#------------------------------------------------------------------------------
sub esek2mcas
{
    my $esek = shift;
    my $pasmo = shift; # číslo od -12 do +12, udávající časový posun pásma oproti UTC
    my $uvest_pasmo = shift;
    my $zarovnat = shift;
    my $datumcas = esek2datumcas($esek+$pasmo*3600, $zarovnat);
    if($uvest_pasmo)
    {
        # Některé země nejsou od Greenwiche posunuté o celé hodiny.
        my $uprpasmo;
        my $desetiny = abs($pasmo)-int(abs($pasmo));
        if($desetiny)
        {
            $uprpasmo = sprintf("%+d:%d", $pasmo, 60*$desetiny);
        }
        else
        {
            $uprpasmo = sprintf("%+d", $pasmo);
        }
        $datumcas .= " GMT$uprpasmo";
    }
    return $datumcas;
}



#------------------------------------------------------------------------------
# Převede počet vteřin na větší časové jednotky. Sám si vybere největší
# takovou jednotku, jejíž počet ještě vyjde nenulový.
#------------------------------------------------------------------------------
sub sek2cas
{
    my $cas = shift;
    my $format = shift; # 0: bez jednotek, vždy v hodinách; 1: "7:50 m"; 2: "3 vteřiny"
    my $oddelovac = shift; # co vložit mezi číslo a jednotky; default je mezera; prázdný řetězec nejde zadat
    $oddelovac = " " if($oddelovac eq "");
    my $hod = int($cas/3600);
    my $min = int(($cas%3600)/60);
    my $sek = $cas%60;
    my $hlaseni;
    if($hod==0)
    {
        if($min==0)
        {
            if($format==2)
            {
                $hlaseni = sprintf("$sek${oddelovac}vteřin%s", $sek==1 ? "u" : $sek>=2 && $sek<=4 ? "y" : "");
            }
            else
            {
                $hlaseni = "$sek s";
            }
        }
        else
        {
            if($format==2)
            {
                $hlaseni = sprintf("%d:%02d${oddelovac}minut", $min, $sek);
            }
            else
            {
                $hlaseni = sprintf("%d:%02d${oddelovac}m", $min, $sek);
            }
        }
    }
    else
    {
        if($format==2)
        {
            $hlaseni = sprintf("%d:%02d:%02d${oddelovac}hodin", $hod, $min, $sek);
        }
        else
        {
            $hlaseni = sprintf("%d:%02d:%02d${oddelovac}h", $hod, $min, $sek);
        }
    }
    return $hlaseni;
}



#------------------------------------------------------------------------------
# Zjistí aktuální čas a vrátí odkaz na hash, ve kterém je aktuální čas různě
# formátovaný.
#------------------------------------------------------------------------------
sub ted
{
    # Zjistit počet nepřestupných sekund od začátku epochy (pozor, v tomto
    # případě nejde o moji epochu nastavenou v tomto modulu, nýbrž o systémovou
    # epochu - pro většinu systémů je to 1.1.1970 0:00:00 UTC, pro MacOS je to
    # 1.1.1904 0:00:00 UTC).
    my $time = time();
    return esek2hash(time2esek($time));
}



#------------------------------------------------------------------------------
# Vypíše dobu, po kterou program běžel. K tomu potřebuje dostat časové otisky
# začátku a konce.
#------------------------------------------------------------------------------
sub sestavit_hlaseni_o_trvani_programu
{
    my $starttime = shift;
    my $stoptime = time();
    my $jazyk = shift; $jazyk = 'cs' if(!defined($jazyk));
    my $cas = $stoptime-$starttime;
    my $hod = int($cas/3600);
    my $min = int(($cas%3600)/60);
    my $sek = $cas%60;
    my $hlaseni;
    if($hod==0)
    {
        if($min==0)
        {
            if($jazyk eq 'en')
            {
                $hlaseni = sprintf("Program took $sek seconds%s.\n", $sek==1 ? "u" : $sek>=2 && $sek<=4 ? "y" : "");
            }
            else
            {
                $hlaseni = sprintf("Program běžel $sek vteřin%s.\n", $sek==1 ? "u" : $sek>=2 && $sek<=4 ? "y" : "");
            }
        }
        else
        {
            if($jazyk eq 'en')
            {
                $hlaseni = sprintf("Program took %d:%02d minutes.\n", $min, $sek);
            }
            else
            {
                $hlaseni = sprintf("Program běžel %d:%02d minut.\n", $min, $sek);
            }
        }
    }
    else
    {
        if($jazyk eq 'en')
        {
            $hlaseni = sprintf("Program took %2d:%02d:%02d hours.\n", $hod, $min, $sek);
        }
        else
        {
            $hlaseni = sprintf("Program běžel %2d:%02d:%02d hodin.\n", $hod, $min, $sek);
        }
    }
    return $hlaseni;
}
#------------------------------------------------------------------------------
# Kvůli zpětné kompatibilitě ještě tatáž funkce pod jiným jménem. Navzdory
# jménu nic nikam nevypisuje, pouze sestaví hlášení, které si volající vypíše
# sám, kam uzná.
#------------------------------------------------------------------------------
sub vypsat_delku_trvani_programu
{
    return sestavit_hlaseni_o_trvani_programu(@_);
}



#------------------------------------------------------------------------------
# Zjistí, kdy byl naposledy měněn soubor, ve vteřinách od začátku epochy (tady
# ovšem nejde o mou epochu z funkce zert::epocha(), ale o systémovou epochu).
#------------------------------------------------------------------------------
sub cassoubor
{
    my $soubor = $_[0];
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($soubor);
    # Není mi jasné, zda mám použít ctime (inode change time), nebo mtime (last modify time).
    return $mtime;
}



1;
