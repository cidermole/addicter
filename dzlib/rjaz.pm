# Sada funkcí pro rozpoznávání jazyků a kódování.
# (c) 2006 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL
package rjaz;

use utf8;



#------------------------------------------------------------------------------
# Převezme cestu k souboru, do kterého má uložit frekvenční charakteristiku.
# Charakteristiku k uložení dostane jako odkaz na hash.
#------------------------------------------------------------------------------
sub vypsat_statistiku
{
    my $statistika = shift;
    my $cesta = shift; # prázdná cesta znamená STDOUT
    if($cesta !~ m/^\s*$/)
    {
        open(FRQ, ">$cesta") or die("Nelze psát do souboru $cesta: $!\n");
    }
    else
    {
        *FRQ = *STDOUT;
    }
    binmode(FRQ, ":utf8");
    # Seřadit n-tice znaků sestupně podle n a podle četnosti.
    my @ntice = sort
    {
        my $vysledek = length($b) <=> length($a);
        unless($vysledek)
        {
            $vysledek = $statistika->{$b} <=> $statistika->{$a};
            unless($vysledek)
            {
                $vysledek = $a cmp $b;
            }
        }
        return $vysledek;
    }
    (keys(%{$statistika}));
    # Vypsat statistiku.
    foreach my $ntice (@ntice)
    {
        print FRQ ("$ntice\t$statistika->{$ntice}\n");
    }
    if($cesta !~ m/^\s*$/)
    {
        close(FRQ);
    }
}



#------------------------------------------------------------------------------
# Převezme cestu k souboru s frekvenční charakteristikou. Načte charakteristiku
# do hashe a odkaz na něj vrátí.
#------------------------------------------------------------------------------
sub nacist_statistiku
{
    my $cesta = shift;
    open(FRQ, $cesta) or die("Nelze otevřít soubor $cesta: $!\n");
    if(0)
    {
        binmode(FRQ, ":raw");
    }
    else
    {
        binmode(FRQ, ":utf8");
    }
    my %statistika;
    while(<FRQ>)
    {
        # Odstranit zalomení řádku.
        s/\r?\n$//;
        if(m/^(\S+)\s+(.*)$/)
        {
            $statistika{$1} = $2;
        }
    }
    close(FRQ);
    return \%statistika;
}



#------------------------------------------------------------------------------
# Převezme cestu ke složce a odkaz na hash hashů. Ve složce najde soubory,
# jejichž název končí na ".frq", načte z nich statistiku znaků, dvojic a trojic
# do hashe a odkaz na tento hash přidá do hashe hashů, na nějž dostala odkaz od
# volajícího.
#------------------------------------------------------------------------------
sub nacist_statistiky
{
    my $cesta = shift;
    my $statistiky = shift; # odkaz na hash hashů
    # Najít soubory se statistikami o různých jazycích a kódováních.
    opendir(DIR, $cesta) or die("Nelze otevřít složku $cesta: $!\n");
    my @soubory = readdir(DIR);
    closedir(DIR);
    # Načíst statistiky.
    foreach my $soubor (@soubory)
    {
        if($soubor =~ m/\.frq$/i)
        {
            my $jazyk = $soubor;
            $jazyk =~ s/\.frq$//i;
            $statistiky->{$jazyk} = nacist_statistiku($cesta."/".$soubor);
        }
    }
    return $statistiky;
}



#------------------------------------------------------------------------------
# Projde pole slov a získá z nich statistiku znaků, dvojic a trojic.
#------------------------------------------------------------------------------
sub zjistit_statistiku_z_pole
{
    my @slova = @_;
    # Přičtením neznámé trojice, dvojice a jednice zajistit, že nedostaneme nulu do jmenovatele.
    my @n;
    $n[3] = 1;
    $n[2] = 1;
    $n[1] = 1;
    # Projít slova a u každého prozkoumat znaky, ze kterých se skládá.
    my %statistika;
    foreach my $slovo (@slova)
    {
        my $oslovo = "[$slovo]";
        while(length($oslovo)>0)
        {
            # Zapamatovat si trojici znaků.
            if($oslovo =~ m/^(...)/)
            {
                $statistika{$1}++;
                $n[3]++;
            }
            # Zapamatovat si dvojici znaků.
            if($oslovo =~ m/^(..)/)
            {
                $statistika{$1}++;
                $n[2]++;
            }
            # Zapamatovat si jeden znak a hned ho umazat.
            $oslovo =~ s/^(.)//;
            $statistika{$1}++;
            $n[1]++;
        }
    }
    # Převést absolutní četnosti na relativní.
    foreach my $ntice (keys(%statistika))
    {
        my $jmenovatel = $n[length($ntice)];
        $statistika{$ntice} /= $jmenovatel if($jmenovatel);
    }
    return \%statistika;
}



#------------------------------------------------------------------------------
# Projde text a získá z něj statistiku znaků, dvojic a trojic.
#------------------------------------------------------------------------------
sub zjistit_statistiku
{
    my $dokument = shift;
    # Odstranit číslice a zvláštní znaky (pouze ty z ASCII oblasti, ostatní už mohou nést zajímavou informaci).
    $dokument =~ s/[!-@\[-\`\{-~]/ /sg;
    # Rozdělit dokument na slova.
    my @slova = split(/\s+/, $dokument);
    # Neutralizovat vliv četnosti slov na četnost znaků: každé slovo započítat jen jednou!
    if(1)
    {
        my %slovnik;
        foreach my $slovo (@slova)
        {
            $slovnik{$slovo}++;
        }
        @slova = keys(%slovnik);
    }
    return zjistit_statistiku_z_pole(@slova);
}



#------------------------------------------------------------------------------
# Porovná statistiky dvou různých textů a vrátí míru jejich podobnosti
# z intervalu <0;1> (0: dokumenty jsou znakově zcela disjunktní; 1: dokumenty
# mají totožnou statistiku). Operace je komutativní!
#------------------------------------------------------------------------------
sub porovnat_statistiky1
{
    my $s1 = shift; # odkaz na hash
    my $s2 = shift; # odkaz na hash
    # Zatím se porovnávají jen samotné znaky. Porovnávání dvojic a trojic
    # implementuji později. Předpokládáme, že kód znaku nemůže být větší než 256,
    # protože jsme dokumenty načítali, aniž bychom předem předpokládali nějaké
    # kódování, natož nějaké vícebajtové.
    my $rozdil;
    for(my $kod = 0; $kod<256; $kod++)
    {
        $rozdil += abs($s1->{chr($kod)}-$s2->{chr($kod)});
    }
    # Rozdíl mezi statistikami leží v intervalu <0;2>. Převést do intervalu <0;1>.
    $rozdil /= 2;
    # Převést rozdíl na podíl shody (vynásobíme-li to stem, dostaneme procenta shody).
    $rozdil = 1-$rozdil;
    return $rozdil;
}



#------------------------------------------------------------------------------
# Porovná statistiky dvou různých textů a vrátí míru jejich podobnosti
# z intervalu <0;1> (0: dokumenty jsou znakově zcela disjunktní; 1: dokumenty
# mají totožnou statistiku). Operace je komutativní!
#------------------------------------------------------------------------------
sub porovnat_statistiky
{
    my $s1 = shift; # odkaz na hash
    my $s2 = shift; # odkaz na hash
    # Porovnávají se trojice znaků. Statistiky samostatných znaků a dvojic se ignorují.
    # Kvůli ladění si pamatovat i rozdíl pro každou ntici zvlášť.
    my %rozdily;
    my $rozdil;
    foreach my $trojice (keys(%{$s1}))
    {
        next unless(length($trojice)==3);
        if(exists($s2->{$trojice}))
        {
            $rozdily{$trojice} = abs($s1->{$trojice}-$s2->{$trojice});
        }
        else
        {
            $rozdily{$trojice} = $s1->{$trojice};
        }
        $rozdil += $rozdily{$trojice};
    }
    # Ještě trojice, které se vyskytly pouze v $s2.
    foreach my $trojice (keys(%{$s2}))
    {
        next unless(length($trojice)==3);
        unless(exists($s1->{$trojice}))
        {
            $rozdily{$trojice} = $s2->{$trojice};
            $rozdil += $rozdily{$trojice};
        }
    }
    # Ladění: vypsat nejkřiklavější rozdíly.
    if($debug)
    {
        my @klice = sort {$rozdily{$b}<=>$rozdily{$a}} keys(%rozdily);
        for(my $i = 0; $i<20; $i++)
        {
            my $trojice = $klice[$i];
            printf STDERR ("$trojice\troz:%10.8f\ts1:%10.8f\ts2:%10.8f\n", $rozdily{$trojice}, $s1->{$trojice}, $s2->{$trojice});
        }
        print("\n");
    }
    # Rozdíl mezi statistikami leží v intervalu <0;2>. Převést do intervalu <0;1>.
    $rozdil /= 2;
    # Převést rozdíl na podíl shody (vynásobíme-li to stem, dostaneme procenta shody).
    my $shoda = 1-$rozdil;
    return $shoda;
}



#------------------------------------------------------------------------------
# Převezme statistiku textu X a sadu statistik Y. V sadě Y najde statistiku,
# která je nejpodobnější statistice textu X, a vrátí její název nebo podrobný
# rozbor.
#------------------------------------------------------------------------------
sub najit_nejpodobnejsi_statistiku
{
    my $statistika = shift;
    my $jazyky = shift;
    my $typ = shift; # typ výsledku:
        # default = jen kód jazyka
        # 2 = dvojice (kód, shoda)
        # 3 = pole (ne odkaz na pole): kód1, shoda1, kód2, shoda2...; sestupně uspořádané podle shod
    # Porovnat statistiku rozpoznávaného dokumentu se statistikami známých jazyků.
    my %shoda;
    foreach my $jazyk (keys(%{$jazyky}))
    {
        if($debug)
        {
            print STDERR ("   \t              \tdokument     \t$jazyk\n");
        }
        $shoda{$jazyk} = porovnat_statistiky($statistika, $jazyky->{$jazyk});
    }
    # Seřadit jazyky sestupně podle míry shody s rozpoznávaným dokumentem.
    my @jazyky = sort{$shoda{$b}<=>$shoda{$a}}(keys(%shoda));
    if($typ == 3)
    {
        my @pole;
        foreach my $jazyk (@jazyky)
        {
            push(@pole, $jazyk);
            push(@pole, $shoda{$jazyk});
        }
        return @pole;
    }
    elsif($typ == 2)
    {
        return ($jazyky[0], $shoda{$jazyky[0]});
    }
    else
    {
        return $jazyky[0];
    }
}



#------------------------------------------------------------------------------
# Převezme text X a sadu statistik Y. V sadě Y najde statistiku, která je
# nejpodobnější statistice textu X, a vrátí její název.
#------------------------------------------------------------------------------
sub zjistit_jazyk
{
    local $debug = 0;
    my $text = shift;
    my $jazyky = shift; # odkaz na hash hashů
    my $typ = shift; # typ výsledku:
        # default = jen kód jazyka
        # 2 = dvojice (kód, shoda)
        # 3 = pole (ne odkaz na pole): kód1, shoda1, kód2, shoda2...; sestupně uspořádané podle shod
    my $statistika = zjistit_statistiku($text);
    if($debug)
    {
        print STDERR ("Charakteristika dokumentu:\n");
        my $n = 0;
        foreach my $klic (sort {$statistika->{$b}<=>$statistika->{$a}} keys(%{$statistika}))
        {
            if(length($klic)==3)
            {
                print STDERR ("$klic\t$statistika->{$klic}\n");
                $n++ unless($klic =~ m/[\[\]]/);
                last if($n>10);
            }
        }
    }
    # Porovnat statistiku rozpoznávaného dokumentu se statistikami známých jazyků.
    return najit_nejpodobnejsi_statistiku($statistika, $jazyky, $typ);
}



1;
