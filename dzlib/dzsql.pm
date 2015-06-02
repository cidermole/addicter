# Knihovna funkcí pro interakci mezi daty v textových souborech a databázovými servery MySQL a PostgreSQL.
# Copyright © 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package dzsql;
use utf8;
use open ':utf8';
use DBI;
use Encode;
use mail;



#------------------------------------------------------------------------------
# Funkce connect() byla přesunuta do modulu sitesql, který se liší obsahem pro
# web server ufal (sql server PostgreSQL na eulerovi) a pro web/sql server kub
# (MySQL).
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Přečte údaje z databáze. Vzorové volání:
# $odkaz_na_pole_hashu = dzsql::dotaz($db, "kod", "hry.nazev AS nazev",
# "zbozi.nazev", "hry INNER JOIN zbozi ON hry.kod = zbozi.kod ".$filtr.$razeni);
#------------------------------------------------------------------------------
sub dotaz
{
    my $databaze = shift;
    my $from = pop(@_);
    my @nazvy = @_;
    my $nazvy = join(", ", @nazvy);
    # $dotaz je globální proměnná, aby si ji volající mohl prohlédnout za účelem ladění.
    $dotaz = "SELECT $nazvy FROM $from";
    if($debug) # globální v tomto modulu
    {
        print("<p style='color:red'>$dotaz</p>\n");
    }
    my $dtzobj = $databaze->prepare($dotaz);
    $dtzobj->execute();
    # Upravit názvy přejmenovaných polí.
    for(my $i = 0; $i<=$#nazvy; $i++)
    {
        $nazvy[$i] =~ s/^.*\s+AS\s+//i;
    }
    return nacist_vysledek_dotazu($dtzobj, \@nazvy);
}



#------------------------------------------------------------------------------
# Vyzvedne výsledek dotazu opakovaným voláním fetchrow_array().
#------------------------------------------------------------------------------
sub nacist_vysledek_dotazu
{
    my $dtzobj = shift; # dotaz, na který už bylo zavoláno execute()
    my $nazvy = shift; # odkaz na pole názvů sloupců (polí)
    my @pole;
    # Automaticky předpokládáme, že všechny naše databáze používají kódování UTF8.
    # Musíme si ale ručně nastavit příznak UTF8, protože fetchrow_array() vrací řetězec bajtů.
    while(my @radek = map {decode('utf8', $_)} ($dtzobj->fetchrow_array()))
    {
        my %zaznam;
        for(my $i = 0; $i<=$#{$nazvy}; $i++)
        {
            # Odstranit mezery na konci hodnot. MySQL to nedělal, ale PostgreSQL je tam vkládá.
            $radek[$i] =~ s/\s+$//s;
            # Uložit hodnotu do hashe pod názvem příslušného sloupce.
            $zaznam{$nazvy->[$i]} = $radek[$i];
        }
        push(@pole, \%zaznam);
    }
    return \@pole;
}



#------------------------------------------------------------------------------
# Získá vybrané řádky z tabulky. Tato funkce je zaměnitelná s výše uvedenou
# starší funkcí dotaz(), ale má jiné volání, které se více podobá voláním
# funkcí insert() a update() níže.
#
# Příklad:
#   $radky = select($db, 'hry', { values => \%zaznam, wfields => ['kod'], sfields => ['nazev', 'cena'], nfields => ['cena'] });
# Výsledný dotaz:
#   SELECT nazev, cena FROM hry WHERE kod = 'car';
#------------------------------------------------------------------------------
sub select
{
    my $databaze = shift;
    my $tabulka = shift; # název tabulky, popř. spojení tabulek (INNER|LEFT|RIGHT JOIN ... ON)
    my $p = rozebrat_parametry('select', @_);
    my $obalene = obalit_textove_hodnoty($p->{values}, $p->{nfields}, $p->{wfields});
    my $pole = join(', ', @{$p->{sfields}});
    my $filtr = join(' AND ', map {"$_ = $obalene->{$_}"} (@{$p->{wfields}}));
    # $dotaz je globální proměnná, aby si ji volající mohl prohlédnout za účelem ladění.
    $dotaz = "SELECT $pole FROM $tabulka WHERE $filtr;";
    my $dtz = $databaze->prepare($dotaz);
    $dtz->execute();
    return nacist_vysledek_dotazu($dtz, $p->{sfields});
}



#------------------------------------------------------------------------------
# Přidá řádek do tabulky. Předpokládá, že jsme připojeni k databázi. Nestará se
# o to, zda tabulka existuje (kdyžtak dojde k chybě) a zda jsme ji před
# přidáváním případně vyprázdnili. Řádek chce dostat jako odkaz na hash, kde
# klíče jsou názvy polí a hodnoty jsou skaláry. Dotaz v SQL ukládá do globální
# proměnné, aby si ho volající v případě neúspěchu mohl prohlédnout.
#
# Příklad:
#   insert($db, 'hry', \%zaznam, ['nazev', 'cena']);
# Alternativně:
#   insert($db, 'hry', { values => \%zaznam, ifields => ['nazev', 'cena'], nfields => ['cena'] });
# Výsledný dotaz:
#   INSERT INTO hry (nazev, cena) VALUES ('Carcassonne', 438);
#------------------------------------------------------------------------------
sub insert
{
    my $databaze = shift;
    my $tabulka = shift; # název tabulky
    my $p = rozebrat_parametry('insert', @_);
    # Seznam polí, která se mají vložit, musí být neprázdný, jinak nemáme práci.
    return 0 unless(scalar(@{$p->{ifields}}));
    my $obalene = obalit_textove_hodnoty($p->{values}, $p->{nfields}, $p->{ifields});
    my $pole = join(', ', @{$p->{ifields}});
    my $hodnoty = join(', ', map {$obalene->{$_}} (@{$p->{ifields}}));
    # $dotaz je globální proměnná, aby si ji volající mohl prohlédnout za účelem ladění.
    $dotaz = "INSERT INTO $tabulka ($pole) VALUES ($hodnoty);";
    return $databaze->do($dotaz);
}



#------------------------------------------------------------------------------
# Aktualizuje hodnoty existujícího řádku tabulky. Předpokládá, že jsme
# připojeni k databázi. Nestará se o to, zda tabulka existuje (kdyžtak dojde
# k chybě). Řádek chce dostat jako odkaz na hash, kde klíče jsou názvy polí a
# hodnoty jsou skaláry. Vrátí úspěch/neúspěch. Dotaz v SQL ukládá do globální
# proměnné, aby si ho volající v případě neúspěchu mohl prohlédnout.
#
# Příklad:
#   update($db, 'hry', \%zaznam, ['nazev', 'cena'], ['kod'], ['cena']);
# Alternativně:
#   update($db, 'hry', { values => \%zaznam, wfields => ['kod'], ufields => ['nazev', 'cena'], nfields => ['cena'] });
# Výsledný dotaz:
#   UPDATE hry SET nazev = 'Carcassonne', cena = '438' WHERE kod = 'car';
#------------------------------------------------------------------------------
sub update
{
    my $databaze = shift;
    my $tabulka = shift; # název tabulky
    my $p = rozebrat_parametry('update', @_);
    # Seznam polí identifikujících záznam a seznam polí, která se mají aktualizovat, musí být neprázdný, jinak nemáme práci.
    return 0 unless(scalar(@{$p->{wfields}}) && scalar(@{$p->{ufields}}));
    my $obalene = obalit_textove_hodnoty($p->{values}, $p->{nfields}, $p->{ufields}, $p->{wfields});
    # Sestavit seznam přiřazení nových hodnot.
    my $prirazeni = join(', ', map {"$_ = $obalene->{$_}"} (@{$p->{ufields}}));
    my $filtr = join(' AND ', map {"$_ = $obalene->{$_}"} (@{$p->{wfields}}));
    # $dotaz je globální proměnná, aby si ji volající mohl prohlédnout za účelem ladění.
    $dotaz = "UPDATE $tabulka SET $prirazeni WHERE $filtr;";
    return $databaze->do($dotaz);
}



#------------------------------------------------------------------------------
# Odstraní existující řádek tabulky. Předpokládá, že jsme připojeni k databázi.
# Nestará se o to, zda tabulka existuje (kdyžtak dojde k chybě). V souladu
# s voláním ostatních funkcí SQL očekává odkaz na hash, ve kterém budou
# vyplněna alespoň pole nezbytná pro identifikaci záznamu, a názvy polí, která
# se pro identifikaci mají použít. Vrátí úspěch/neúspěch. Dotaz v SQL ukládá do
# globální proměnné, aby si ho volající v případě neúspěchu mohl prohlédnout.
#
# Příklad:
#   delete($db, 'hry', { values => \%zaznam, wfields => ['kod'], nfields => ['cena'] });
# Výsledný dotaz:
#   DELETE FROM hry WHERE kod = 'car';
#------------------------------------------------------------------------------
sub delete
{
    my $databaze = shift;
    my $tabulka = shift; # název tabulky
    my $p = rozebrat_parametry('delete', @_);
    # Seznam polí identifikujících záznam musí být neprázdný, jinak nemáme práci.
    return 0 unless(scalar(@{$p->{wfields}}));
    my $obalene = obalit_textove_hodnoty($p->{values}, $p->{nfields}, $p->{wfields});
    # Sestavit seznam přiřazení nových hodnot.
    my $filtr = join(' AND ', map {"$_ = $obalene->{$_}"} (@{$p->{wfields}}));
    # $dotaz je globální proměnná, aby si ji volající mohl prohlédnout za účelem ladění.
    $dotaz = "DELETE FROM $tabulka WHERE $filtr;";
    return $databaze->do($dotaz);
}



#------------------------------------------------------------------------------
# Rozebere vstupní parametry funkce update() (různé druhy polí a hodnot). Vrátí
# hash, kde jsou parametry pojmenovány.
#------------------------------------------------------------------------------
sub rozebrat_parametry
{
    my $funkce = shift; # insert|update
    if(ref($_[0]) eq 'HASH' && exists($_[0]{values}) && !defined($_[1]))
    {
        return $_[0];
    }
    # insert nepotřebuje wfields pro identifikaci existujícího záznamu
    elsif($funkce eq 'insert')
    {
        return { 'values' => $_[0], 'ifields' => $_[1], 'nfields' => $_[2] };
    }
    else
    {
        return { 'values' => $_[0], 'ufields' => $_[1], 'wfields' => $_[2], 'nfields' => $_[3] };
    }
}



#------------------------------------------------------------------------------
# Převezme hash hodnot a seznam číselných polí. Vrátí jiný hash se stejnými
# klíči (názvy polí). Hodnoty číselných polí budou do nového hashe okopírovány
# tak, jak jsou, zatímco hodnoty ostatních (textových) polí budou obalené
# apostrofy, aby se daly vložit do výrazu SQL. Nepředpokládá se, že by hodnotou
# mohl být odkaz, a neprovádí se hloubková kopie.
#------------------------------------------------------------------------------
sub obalit_textove_hodnoty
{
    my $zdroj = shift; # odkaz na hash
    my $nfields = shift; # odkaz na pole názvů číselných hodnot
    # Volitelně též odkazy na jedno nebo několik dalších polí názvů.
    # Pokud tyto názvy ve zdroji chybí, obalením se pro ně vytvoří prázdná hodnota '' nebo 0,
    # aby jejich použití ve výrazu SQL nezpůsobilo syntaktickou chybu.
    my @klice = keys(%{$zdroj});
    push(@klice, @{$nfields});
    foreach my $pole (@_)
    {
        # Pokud se název nějakého sloupce opakuje v několika polích (např. wfields i ufields),
        # budeme hodnoty těchto polí obalovat a přepisovat opakovaně, ale pravděpodobně nás
        # to nezdrží víc, než kdybychom se nejdřív pokoušeli duplikáty identifikovat a přeskočit.
        push(@klice, @{$pole});
    }
    $fields = \@klice;
    my %cil;
    # Nahashovat si názvy číselných polí.
    my %cislo;
    map {$cislo{$_} = 1} (@{$nfields});
    # Okopírovat hodnoty do nového hashe.
    foreach my $klic (@{$fields})
    {
        if($cislo{$klic})
        {
            if(defined($zdroj->{$klic}))
            {
                $cil{$klic} = $zdroj->{$klic};
            }
            else
            {
                $cil{$klic} = 0;
            }
        }
        else
        {
            # ASCII apostrof používáme na ohraničení řetězců v SQL. Pokud má být součástí hodnoty, musíme ho zdvojit.
            # V MySQL se před počáteční apostrof ještě kladlo "_utf8", ale PostgreSQL tohle nepoužívá.
            my $x = $zdroj->{$klic};
            $x =~ s/'/''/sg;
            $cil{$klic} = "'$x'";
        }
    }
    return \%cil;
}



#------------------------------------------------------------------------------
# Přidá tabulku do databáze. Předpokládá, že jsme připojeni k databázi. Pokud
# tabulka existuje, smaže starou a založí ji znova. Tabulka je pole hashů,
# seznam klíčů se předává zvlášť jako pole @nazvy. Díky tomu nemusí mít všechny
# hashe všechny klíče, je možné určit výběr a pořadí klíčů. Funkce předpokládá,
# že klíče obsahují pouze znaky [a-z0-9_], takže nedojde k problémům v SQL.
#------------------------------------------------------------------------------
sub insert_table
{
    my $databaze = shift;
    my $nazev_tabulky = shift;
    my $tabulka = shift; # odkaz na pole hashů
    my $nazvy = shift; # odkaz na pole klíčů do hashů
    # Neznáme původní typy sloupců a předpokládáme, že to jsou samé řetězce.
    # Proběhnout tabulku a pro každý sloupec zjistit maximální délku hodnoty.
    my %maxdelky;
    # Žádnému sloupci nedovolit nulovou délku, to by SQL server nemusel strávit.
    foreach my $sloupec (@{$nazvy})
    {
        $maxdelky{$sloupec} = 1;
    }
    foreach my $radek (@{$tabulka})
    {
        foreach my $sloupec (@{$nazvy})
        {
            my $delka = length($radek->{$sloupec});
            if($delka>$maxdelky{$sloupec})
            {
                $maxdelky{$sloupec} = $delka;
            }
        }
    }
    # Každému sloupci určit typ. Pro sloupce s maximální délkou 255 nebo menší
    # to bude "CHAR". Pro delší řetězce to bude "TEXT" (může mít až 65535 znaků
    # (nebo bajtů?)).
    my %typy;
    foreach my $sloupec (@{$nazvy})
    {
        if($maxdelky{$sloupec}>255)
        {
            $typy{$sloupec} = "TEXT";
        }
        else
        {
            $typy{$sloupec} = "CHAR($maxdelky{$sloupec})";
        }
    }
    # Odstranit dosavadní tabulku z databáze.
    $databaze->do("DROP TABLE $nazev_tabulky;");
    # Vytvořit v databázi novou tabulku.
    my @sloupce = map {"$_ $typy{$_}"} @{$nazvy};
    my $dotaz = "CREATE TABLE $nazev_tabulky (".join(", ", @sloupce).");";
    $databaze->do($dotaz) or die("Nelze spustit dotaz $dotaz.\n");
    # Nalít do tabulky data.
    foreach my $radek (@{$tabulka})
    {
        insert($databaze, $nazev_tabulky, $radek, $nazvy);
    }
}



#------------------------------------------------------------------------------
# Pokusí se provést dotaz. Pokud se to nepovede, pošle e-mail s chybovým
# hlášením na udanou adresu. Tohle je důležité u objednávkových, přihláškových
# a podobných formulářů. Párkrát už se nám stalo, že se kvůli výpadku MySQL
# nepodařilo data z formuláře uložit do databáze a dozvěděli jsme se o tom
# pouze v případě, že se dotyčný uživatel sám ozval. Jeho přihláška nám sice
# přišla také e-mailem, ale nevšimli jsme si, že do databáze se nedostala.
#------------------------------------------------------------------------------
sub do_or_mail
{
    my $databaze = shift;
    my $dotaz = shift;
    my $adresa = shift;
    if(!$databaze->do($dotaz) || $DBI::errstr)
    {
        mail::odeslat
        ({
            'From' => 'robot@hrejsi.cz',
            'To' => $adresa,
            'text' =>
                "Nepodařilo se vykonat tento dotaz SQL:\n".
                "$dotaz\n\n".
                "Databázová knihovna hlásí:\n".
                "$DBI::errstr\n"
        });
    }
}



#------------------------------------------------------------------------------
# Získá seznam tabulek v databázi. Pozor, tohle je specifický postup platný
# pro PostgreSQL! V MySQL je to jinak! Nebude na to nějaký společný nástroj
# v DBI, který by nás pomocí ovladačů odstínil od implementačních detailů?
#------------------------------------------------------------------------------
sub list_tables
{
    my $databaze = shift;
    # Omezením na vlastnictví uživatele "zeman" se zbavíme systémových tabulek.
    my $dotaz = "SELECT tablename FROM pg_tables WHERE tableowner='zeman';";
    ###!!! ještě zbývá provést dotaz a vrátit jeho výstup
    # @names = $dbh->tables( $catalog, $schema, $table, $type ); $type = "TABLE";
}
#txt2sql.pl db tbl < tbl.txt
#Předpokládá se, že skript zná cestu k databázovému serveru (ip, port, uživatel, heslo...) a umí rozlišit mysql a postgresql.
#První řádek textového souboru obsahuje názvy polí. Skript si je upraví, aby obsahovaly jen a-z0-9_
#Zatím stále platí, že textový soubor nenese informaci o typu sloupce ani o indexech. Skript si typy vymyslí, indexy netvoří.
#Na rozdíl od dosavadní praxe by skript měl umět poznat, že v databázi dotyčná tabulka existuje, a měl by vědět, jak se zachovat.
#Později bude skript vedle prostého importu umožňovat také synchronizaci textového souboru s databází.



1;
