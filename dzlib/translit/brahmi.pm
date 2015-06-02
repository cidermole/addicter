#!/usr/bin/perl
# Funkce pro přípravu transliterace z indického písma do latinky.
# Copyright © 2007, 2008, 2009, 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL
# 2.8.2009: přidána vědecká transliterace (potřebná pro články, ale nepraktická v terminálu)
# 21.11.2010: přidán přepis do systému WX (jednoznačný přepis používaný v Hajdarábádu, zuboretné t=w, d=x)

package translit::brahmi;
use utf8;



# První sloupec = Danova transliterace (podle české výslovnosti, snaha neztrácet informaci, vyhýbá se odděleným znakům pro diakritiku).
# Druhý sloupec = Vědecká transliterace (mezinárodnější a vhodnější do článků, využívá oddělené znaky pro diakritiku).
# Třetí sloupec = Transliterace WX (používaná indickými počítačovými lingvisty, prosté zobrazení do oblasti ASCII).
@altlat =
(
    ['m'.chr(771), 'm'.chr(771), 'z'], # čandrabindu = m s vlnovkou
    [chr(241),     'm'.chr(775), 'M'], # anusvár = n s vlnovkou, resp. m s tečkou nahoře
    ["'",          'h'.chr(803), 'H'], # visarg
    ['a', 'a',      'a'],
    ['á', chr(257), 'A'],
    ['i', 'i',      'i'],
    ['í', chr(299), 'I'],
    ['u', 'u',      'u'],
    ['ú', chr(363), 'U'],
    ['ŕ', 'r'.chr(805), 'q'],
    ['ĺ', 'l'.chr(805), 'Q'],
    [chr(234), chr(234), 'eV'], # čandra e
    ['e', chr(232), 'eV'], # krátké e
    ['é',  'e',     'e'], # normální e je polodlouhé nebo dlouhé
    ['ai', 'ai',    'E'], # vyslovuje se jako ae, otevřené dlouhé e
    ['ô',  'ô',     'OY'], # čandra o
    ['o', chr(242), 'oV'], # krátké o
    ['ó',  'o',     'o'], # normální o je polodlouhé nebo dlouhé
    ['au', 'au',    'O'], # vyslovuje se jako ao, otevřené dlouhé o, jako v anglickém "automatic"
    ['k',  'k',  'k'],
    ['kh', 'kh', 'K'],
    ['g',  'g',  'g'],
    ['gh', 'gh', 'G'],
    [chr(331), 'n'.chr(775), 'f'], # ng
    ['č',   'c',  'c'],
    ['čh',  'ch', 'C'],
    ['dž',  'j',  'j'],
    ['džh', 'jh', 'J'],
    ['ň', chr(241), 'F'],
    ['ţ', 't'.chr(803), 't'], # retroflexní t
    ['ţh', 't'.chr(803).'h', 'T'],
    [chr(273), 'd'.chr(803), 'd'],
    [chr(273).'h', 'd'.chr(803).'h', 'D'],
    [chr(326), 'n'.chr(803), 'N'],
    ['t',  't',  'w'], # zubové t
    ['th', 'th', 'W'],
    ['d',  'd',  'x'],
    ['dh', 'dh', 'X'],
    ['n',  'n',  'n'],
    [chr(329), 'n'], # "NNNA", specifické pro tamilštinu
    ['p',  'p',  'p'],
    ['ph', 'ph', 'P'],
    ['b',  'b',  'b'],
    ['bh', 'bh', 'B'],
    ['m',  'm',  'm'],
    ['j',  'y',  'y'],
    ['r',  'r',  'r'],
    [chr(343), 'r'], # tvrdé R z jižních jazyků
    ['l',  'l',  'l'],
    [chr(316), 'l'.chr(803), 'lY'], # tvrdé (retroflexní?) L (maráthština)
    ['ř', 'l'], # něco mezi L, americkým R a Ž nebo Ř (tamilština, malajálamština)
    ['v', 'v', 'v'],
    ['ś', 'ś', 'S'], # normální š
    ['š', 's'.chr(803), 'R'], # retroflexní š ze sanskrtu, v hindštině se vyslovuje stejně jako normální š
    ['s', 's', 's'],
    ['h', 'h', 'h'],
    ['q', 'q', 'kZ'],
    ['ch', 'x', 'KZ'],
    [chr(287), chr(287), 'gZ'], # hrdelní gh z arabštiny
    ['z', 'z', 'jZ'],
    [chr(343), 'r'.chr(803), 'dZ'], # DDDHA = DDA + NUKTA
    [chr(343).'h', 'r'.chr(803).'h', 'DZ'], # RHA = DDHA + NUKTA
    ['f', 'f', 'PZ'],
    [chr(309), chr(375), 'yZ'], # YYA = YA + NUKTA (zřejmě odpovídá JYA z ISCII (bengálština, ásámština a urijština), výslovnost snad něco mezi j a ď, můj přepis je "j", resp. vědecky "y" se stříškou)
    ['ŕ', 'r'.chr(772).chr(805), 'q'], # VOCALIC RR
    ['ĺ', 'l'.chr(772).chr(805), 'Q'], # VOCALIC LL
    ['óm', 'om'], # posvátná slabika z modliteb
);



#------------------------------------------------------------------------------
# Uloží do hashe přepisy souhlásek a slabik. Odkaz na cílový hash převezme jako
# parametr. Vrátí délku nejdelšího řetězce, jehož přepis je v hashi definován.
#------------------------------------------------------------------------------
sub inicializovat
{
    # Odkaz na hash, do kterého se má ukládat převodní tabulka.
    my $prevod = shift;
    # Kód začátku segmentu s daným písmem (o 1 nižší než kód znaku čandrabindu).
    my $pocatek = shift;
    # Volba alternativní sady výstupních znaků.
    my $alt = shift;
    local $maxl = 1;
    my $candrabindu = $pocatek+1;
    my $anusvara = $pocatek+2;
    my $visarga = $pocatek+3;
    my $samohlasky = $pocatek+5;
    my $souhlasky = $pocatek+21;
    my $nukta = $pocatek+60;
    my $diasamohlasky = $pocatek+62;
    my $virama = $pocatek+77;
    my $om = $pocatek+80;
    my $souhlasky2 = $pocatek+88;
    my $cislice = $pocatek+102;
    my $tippi = $pocatek+112;
    my $addak = $pocatek+113;
    # Má se do latinky přidávat nečeská diakritika, aby se neztrácela informace?
    my $bezztrat = 1;
    # Zvolit výstupní sadu latinských písmen.
    my @lat = map {$_->[$alt]} @altlat;
    my $latcandrabindu = $lat[0];
    my $latanusvara = $lat[1];
    my $latvisarga = $lat[2];
    my @samohlasky = @lat[3..18];
    my @diasamohlasky = @lat[4..18];
    my @souhlasky = @lat[19..55];
    my @souhlasky2 = @lat[56..63];
    # Samostatné samohlásky.
    for(my $i = 0; $i<=$#samohlasky; $i++)
    {
        my $src = chr($samohlasky+$i);
        $prevod->{$src} = $samohlasky[$i];
        $maxl = length($src) if(length($src)>$maxl);
    }
    # Sestavit převodní tabulku všech souhlásek.
    # Vyrobíme dvě pole. Prvek prvního pole je indická souhláska, prvek druhého je její latinský protějšek.
    # Na obou stranách mohou být řetězce znaků, nemusí to být jen jeden znak.
    # Základní sada souhlásek, které se v indických písmech vyskytují.
    my @indicke_souhlasky = map {chr($_)} ($souhlasky..$souhlasky+$#souhlasky);
    my @latinske_souhlasky = @souhlasky;
    # Znaky s nuktou (tečkou) pro souhlásky, které se objevily dodatečně.
    push(@indicke_souhlasky, map {chr($_)} ($souhlasky2..$souhlasky2+$#souhlasky2));
    push(@latinske_souhlasky, @souhlasky2);
    # Tytéž znaky s nuktou se mohou objevit také jako řetězec dvou znaků: bázový znak ze základní sady + znak nukty.
    push(@indicke_souhlasky, chr($pocatek+2325-2304).chr($nukta)); # QA = KA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2326-2304).chr($nukta)); # KHHA = KHA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2327-2304).chr($nukta)); # GHHA = GA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2332-2304).chr($nukta)); # ZA = JA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2337-2304).chr($nukta)); # DDDHA = DDA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2338-2304).chr($nukta)); # RHA = DDHA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2347-2304).chr($nukta)); # FA = PHA + NUKTA
    push(@indicke_souhlasky, chr($pocatek+2351-2304).chr($nukta)); # YYA = YA + NUKTA
    push(@latinske_souhlasky, @souhlasky2);
    # Gurmukhí: s + nukta = š
    push(@indicke_souhlasky, chr($pocatek+2616-2560).chr($nukta)); # SA + NUKTA
    push(@latinske_souhlasky, 'š');
    ###!!! KONTROLA
#    die unless($#indicke_souhlasky==$#latinske_souhlasky);
    # Gurmukhí: znaménko addak zdvojuje následující souhlásku (přestože jako diakritika se připojuje k té předcházející).
    my $n = scalar(@indicke_souhlasky);
    for(my $i = 0; $i<$n; $i++)
    {
        push(@indicke_souhlasky, chr($addak).$indicke_souhlasky[$i]);
        push(@latinske_souhlasky, $latinske_souhlasky[$i].$latinske_souhlasky[$i]);
    }
    # Souhlásky implicitně obsahují samohlásku "a".
    # Pokud má slabika obsahovat jinou samohlásku, musí za znakem pro souhlásku následovat diakritické znaménko samohlásky.
    for(my $i = 0; $i<=$#indicke_souhlasky; $i++)
    {
        my $src = $indicke_souhlasky[$i];
        my $tgt = $latinske_souhlasky[$i];
        pridat_slabiky($prevod, $src, $tgt, $diasamohlasky, \@diasamohlasky, $virama);
    }
    # Anusvara způsobuje, že předcházející samohláska je nosová.
    # Anusvára se na konci vyslovuje m, jinde n, ň nebo m podle následující souhlásky.
    # Znaménko candrabindu rovněž nazalizuje předcházející samohlásku.
    $prevod->{chr($candrabindu)} = $latcandrabindu;
    $prevod->{chr($anusvara)} = $latanusvara;
    # Visarga přidává neznělý dech za samohláskou.
    $prevod->{chr($visarga)} = $latvisarga;
    # Číslice.
    for(my $i = 0; $i<=9; $i++)
    {
        my $src = chr($cislice+$i);
        $prevod->{$src} = $i;
        $maxl = length($src) if(length($src)>$maxl);
    }
    # Další znaky.
    $prevod->{chr($om)} = $lat[65];
    # Znaménko tippi v písmu gurmukhí označuje nazalizaci stejně jako bindí (anusvár).
    $prevod->{chr($tippi)} = $latanusvara;
    return $maxl;
}



#------------------------------------------------------------------------------
# Přidá do převodní tabulky kombinace dané souhlásky se všemi samohláskami.
#------------------------------------------------------------------------------
sub pridat_slabiky
{
    my $prevod = shift; # odkaz na převodní tabulku (hash)
    my $src = shift; # řetězec obsahující počáteční souhlásku slabiky v daném indickém písmu
    my $tgt = shift; # řetězec obsahující přepis této souhlásky do latinky
    my $srcsam = shift; # kód první nesamostatné samohlásky v daném indickém písmu
    my $tgtsam = shift; # odkaz na pole přepisů nesamostatných samohlásek do latinky
    my $virama = shift; # kód znaku virám v daném indickém písmu
    $prevod->{$src} = $tgt.'a';
    $maxl = length($src) if(length($src)>$maxl);
    # Znaménko virám likviduje implicitní samohlásku "a".
    my $src2 = chr($virama);
    $prevod->{$src.$src2} = $tgt;
    $maxl = length($src.$src2) if(length($src.$src2)>$maxl);
    for(my $j = 0; $j<=$#{$tgtsam}; $j++)
    {
        my $src2 = chr($srcsam+$j);
        $prevod->{$src.$src2} = $tgt.$tgtsam->[$j];
        $maxl = length($src.$src2) if(length($src.$src2)>$maxl);
    }
}



1;
