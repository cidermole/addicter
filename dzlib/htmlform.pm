#!/usr/bin/perl
# Knihovna pro vyplňování webových formulářů robotem.
# Některé formuláře fungují pouze v případě, že si nejdříve správně načteme všechny jejich položky včetně skrytých.
# Copyright © 2008, 2009, 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL
# 12.2.2010 Přepracována datová struktura pro uchovávání formuláře.

#==============================================================================
# Užití:
#------------------------------------------------------------------------------
# $ua = htmlform::vytvorit_klienta();
# $html = htmlform::get($ua, $url_formular, $prodleva);
# $formular = htmlform::precist_formular($html, $url_formular);
# htmlform::nastavit_hodnotu($formular, $nazev, $hodnota, $index);
# $response = htmlform::odeslat_formular($ua, $formular, $tlacitko, $charset);
#==============================================================================

package htmlform;
use utf8;
use Carp;
use LWP::UserAgent;
use LWP::RobotUA;
use HTTP::Cookies;
use HTTP::Request::Common;
use HTML::Parser;
use HTML::Entities;
use Encode; # obsah se převádí do UTF-8 až po stažení
use URI::Escape; # kódování nebezpečných bajtů uvnitř URI/URL
use MIME::QuotedPrint;
use htmlabspath;



#==============================================================================
# Datová struktura pro formulář z dokumentu HTML:
# 1. pole prvků formuláře (ve stejném pořadí jako ve vzorovém formuláři)
# 1.1 prvek formuláře je hash, který má následující položky:
# 1.1.1 název (nemusí být jedinečný, stejnojmenné prvky se ve formuláři mohou opakovat)
# 1.1.2 druh (text, checkbox, select, submit) (HTML typy hidden a textarea jsou taky text)
# 1.1.3 hodnota
# 2. hash, kde jsou tytéž prvky přístupné prostřednictvím svého jména
# 2.1 hodnotou hashe je odkaz na pole prvků daného jména
# 2.2 většinou má toto pole právě jeden prvek, ale někdy jich může mít více
# 2.3 pokud jich má více, jejich pořadí je stejné jako ve formuláři
# 3. hash, kde jsou tytéž prvky přístupné prostřednictvím hodnoty svého atributu id, pokud ho měly
#    (Vynuceno publikační databází OBD, kde mají tlačítka odlišné hodnoty atributů id a name,
#    přičemž podle toho druhého je nelze identifikovat a podle hodnoty také ne.)
#    (Předpokládá se jednoznačnost hodnot id s výjimkou prázdné hodnoty.
#    Při porušení jednoznačnosti nespadneme (nelze ovlivnit korektnost HTML, které jsme stáhli z webu),
#    ale zapamatujeme si poslední prvek s daným id.)
#    Hodnotou hashe  je tedy přímo odkaz na prvek, nikoli na pole prvků.
# 4. action (adresa, kam formulář odeslat)
# 5. method (metoda odeslání formuláře, 'get' nebo 'post')
# 6. enctype (formát, v jakém formulář odeslat, 'application/x-www-form-urlencoded' nebo 'multipart/form-data')
# Klíčová slova jsou action, method, enctype, array, hash, name, value, type, checkbox, select, options, file, filename, filetype, submit.
# Příklad:
# %formular =
# (
#     'action' => 'http://example.com/cgi-bin/login.pl',
#     'method' => 'post',
#     'enctype' => 'multipart/form-data',
#     'array' =>
#     [
#         {'name' => 'jmeno', 'value' => 'Dan'}, # default type => '' znamená text, textarea, hidden
#         {'name' => 'zeme', 'type' => 'select', 'options' => ['cz', 'sk'], 'value' => 'cz'}, # i pro HTML typ radio
#         {'name' => 'clen', 'type' => 'checkbox', 'value' => 1},
#         {'name' => 'telefon', 'value' => '221914225'},
#         {'name' => 'telefon', 'value' => '221914309'},
#         {'name' => 'clanek', 'type' => 'file', 'filename' => 'text.html', 'filetype' => 'text/html',
#                    'value' => 'Toto je obsah souboru <tt>text.txt</tt>.'},
#         {'type' => 'submit', 'value' => 'Odeslat formulář'}
#     ],
#     'hash' => # jiný způsob, jak se dostat na tytéž prvky (odkazy)
#     {
#         'jmeno'   => [&%p0],
#         'zeme'    => [&%p1],
#         'clen'    => [&%p2],
#         'telefon' => [&%p3, &%p4],
#         'clanek'  => [&%p5],
#         ''        => [&%p6]
#     },
#     'idhash' => # getElementById()
#     {
#         'fldName' => [&%p0],
#         'fldCntr' => [&%p1], ...
#     },
#     'submit' => &%p6 # odkaz na poslední odesílací tlačítko formuláře
# );
#==============================================================================



#------------------------------------------------------------------------------
# Přidá prvek na konec formuláře. Zajistí, aby byl prvek současně přístupný
# i přes hash.
#
# Volání: pridat_prvek(\%formular, $name, $value[, $type[, \@options[, $index[, $id]]]]);
#------------------------------------------------------------------------------
sub pridat_prvek
{
    my $formular = shift; # odkaz na hash
    my $name = shift;
    my $value = shift;
    my $type = shift; # '' | 'checkbox' | 'submit' | 'select'
    my $options = shift; # odkaz na pole povolených hodnot (pro select) nebo jméno souboru (pro file)
    my $index = shift; # index prvku, před který se má nový prvek vložit; '' neznamená 0, nýbrž "na konec"; v rámci pole stejnojmenných prvků v hashi bude ale každopádně přidán na konec
    my $id = shift; # hodnota atributu id, pokud prvek nějaký má
    my %zaznam =
    (
        'name'  => $name,
        'value' => $value,
        'type'  => $type,
        'id'    => $id
    );
    if($type eq 'select')
    {
        $zaznam{options} = $options;
    }
    elsif($type eq 'file')
    {
        $zaznam{filename} = $options;
    }
    if($index eq '')
    {
        push(@{$formular->{array}}, \%zaznam);
    }
    else
    {
        splice(@{$formular->{array}}, $index, 0, \%zaznam);
    }
    push(@{$formular->{hash}{$name}}, \%zaznam);
    if($id ne '')
    {
        $formular->{idhash}{$id} = \%zaznam;
    }
    # Pokud formulář obsahuje alespoň jedno tlačítko, zapamatovat si to poslední.
    # Nevíme-li předem, jak se jmenuje tlačítko, které budeme chtít stisknout,
    # budeme moci zkusit formulář odeslat naslepo a doufat, že tlačítko bylo jen jedno nebo že jsou rovnocenná.
    if($type eq 'submit')
    {
        $formular->{submit} = \%zaznam;
    }
}



#------------------------------------------------------------------------------
# Zjistí index prvku daného jména ve formuláři. Pokud má formulář více prvků
# téhož jména, zjistí index prvního prvku daného jména. Výsledek lze použít
# pro snadnější umístění nového prvku, který do formuláře přidáváme. Pokud
# formulář neobsahuje žádný prvek daného jména, funkce vrátí -1.
#------------------------------------------------------------------------------
sub zjistit_index_prvku
{
    my $formular = shift; # odkaz na hash
    my $name = shift;
    my $index = -1;
    for(my $i = 0; $i<=$#{$formular->{array}}; $i++)
    {
        if($formular->{array}[$i]{name} eq $name)
        {
            $index = $i;
            last;
        }
    }
    return $index;
}



#------------------------------------------------------------------------------
# Zjistí hodnotu prvku formuláře. Pokud má formulář více prvků téhož jména,
# zjistí hodnotu prvního prvku daného jména. Pokud víme, kolik stejnojmenných
# prvků ve formuláři je, můžeme volitelně zadat pořadí (od 0 do N-1).
#------------------------------------------------------------------------------
sub zjistit_hodnotu
{
    my $formular = shift; # odkaz na hash
    my $name = shift;
    my $index = shift; # default '' == 0
    my $prvek = $formular->{hash}{$name}[$index];
    return $prvek->{value};
}



#------------------------------------------------------------------------------
# Nastaví hodnotu prvku formuláře. Pokud má formulář více prvků téhož jména,
# nastaví hodnotu prvního prvku daného jména. Pokud víme, kolik stejnojmenných
# prvků ve formuláři je, můžeme volitelně zadat pořadí (od 0 do N-1). Pokud ale
# takový prvek ještě ve formuláři není, musíme nejdřív zavolat funkci
# pridat_prvek(). Jinak by formulář při odesílání dat na server tento prvek
# stejně přeskočil.
#------------------------------------------------------------------------------
sub nastavit_hodnotu
{
    my $formular = shift; # odkaz na hash
    my $name = shift;
    my $value = shift;
    my $index = shift; # default '' == 0
    # Pokud prvek toho jména ve formuláři není, měli jsme ho nejdříve přidat.
    # Buď může tato funkce rovnou prvek přidat na konec, nebo může zabít celý
    # proces. Vzhledem k tomu, že celý tento modul typicky slouží k předstírání,
    # že robot je živý uživatel s Firefoxem, bezpečnější bude vlastní iniciativu
    # minimalizovat.
    if(!exists($formular->{hash}{$name}))
    {
        confess("Neznámý prvek formuláře $name.\n");
    }
    my $prvek = $formular->{hash}{$name}[$index];
    my $dosavadni = $prvek->{value};
    $prvek->{value} = $value;
    return $dosavadni;
}



#------------------------------------------------------------------------------
# Nastaví hodnotu prvku formuláře, který má danou hodnotu atributu id. Takový
# prvek je z definice ve formuláři nejvýše jeden (zatímco prvků téhož jména
# může být několik). Pokud ale takový prvek ve formuláři není, funkce hodí
# výjimku.
#------------------------------------------------------------------------------
sub nastavit_hodnotu_podle_id
{
    my $formular = shift; # odkaz na hash
    my $id = shift;
    my $value = shift;
    # Pokud prvek toho jména ve formuláři není, měli jsme ho nejdříve přidat.
    # Buď může tato funkce rovnou prvek přidat na konec, nebo může zabít celý
    # proces. Vzhledem k tomu, že celý tento modul typicky slouží k předstírání,
    # že robot je živý uživatel s Firefoxem, bezpečnější bude vlastní iniciativu
    # minimalizovat.
    if($id eq '' || !exists($formular->{idhash}{$id}))
    {
        confess("Neznámý prvek formuláře s id='$id'.\n");
    }
    my $prvek = $formular->{idhash}{$id};
    my $dosavadni = $prvek->{value};
    $prvek->{value} = $value;
    return $dosavadni;
}



#------------------------------------------------------------------------------
# Odstraní prvek z formuláře. Pokud má formulář více prvků téhož jména,
# odstraní všechny. Může se hodit při napodobování akcí JavaScriptu.
#------------------------------------------------------------------------------
sub odstranit_prvek
{
    my $formular = shift; # odkaz na hash
    my $name = shift;
    # Projít pole prvků a odstranit všechny prvky daného jména.
    for(my $i = 0; $i<=$#{$formular->{array}}; $i++)
    {
        if($formular->{array}[$i]{name} eq $name)
        {
            splice(@{$formular->{array}}, $i, 1);
            $i--;
        }
    }
    # Odstranit záznam pro dané jméno prvku z hashe.
    delete($formular->{hash}{$name});
    ###!!! Měli bychom ho odstranit i z idhashe, ale zatím není dořešeno, jak najít id prvku podle jeho jména. Tak ho tam prostě necháme ležet.
    # Pokud šlo náhodou o poslední odesílací tlačítko, zničit i tento poslední odkaz na prvek.
    if($formular->{submit}{name} eq $name)
    {
        $formular->{submit} = undef;
    }
}



#------------------------------------------------------------------------------
# Vytáhne z formuláře pole dvojic názvů a hodnot, připravené k odeslání. Pokud
# dostane název tlačítka, jehož stisk chceme simulovat, vynechá v poli všechna
# ostatní tlačítka. Pro prvek typu soubor vrátí jako hodnotu odkaz na hash
# s klíči filename (jméno souboru) a file (obsah souboru), případně též type
# (popis typu souboru ve formátu, v jakém se dá vložit do hlavičky content-
# type, např. "text/html"). Funkce pro odeslání požadavku si s tím poradí.
#
# Volání: ziskat_pole_dvojic(\%formular[, $submit]);
#------------------------------------------------------------------------------
sub ziskat_pole_dvojic
{
    my $formular = shift; # odkaz na hash
    my $tlacitko = shift; # název tlačítka, jehož stisknutí simulujeme odesláním formuláře
    my @podvoj;
    foreach my $prvek (@{$formular->{array}})
    {
        # Vynechat prvky, které nemají název (v reálných formulářích se skutečně mohou objevit, ale jsou k ničemu).
        next if($prvek->{name} =~ m/^\s*$/);
        # Vynechat nezaškrtnutá zaškrtávátka.
        next if($prvek->{type} eq 'checkbox' && !$prvek->{value});
        # Vynechat jiná tlačítka než to, které mačkáme.
        next if($tlacitko && $prvek->{type} eq 'submit' && $prvek->{value} ne $tlacitko);
        # Připravit hodnotu. Netriviální to je pouze u typu soubor.
        my $hodnota;
        if($prvek->{type} eq 'file')
        {
            my %zaznam =
            (
                'filename' => $prvek->{filename},
                'type'     => $prvek->{filetype},
                'file'     => $prvek->{value}
            );
            $hodnota = \%zaznam;
        }
        else
        {
            $hodnota = $prvek->{value};
        }
        # Přidat dvojici atribut - hodnota.
        push(@podvoj, $prvek->{name}, $hodnota);
    }
    return \@podvoj;
}



#------------------------------------------------------------------------------
# Vygeneruje text se seznamem kolonek formuláře a hodnot, které by se teď
# odeslaly, kdyby se stisklo $tlacitko. Slouží pro ladění.
#------------------------------------------------------------------------------
sub vypsat_vyplneny_formular
{
    my $formular = shift; # odkaz na hash
    my $tlacitko = shift; # název tlačítka, jehož stisknutí simulujeme odesláním formuláře
    my $podvoj = ziskat_pole_dvojic($formular, $tlacitko);
    my $text;
    for(my $i = 0; $i<=$#{$podvoj}; $i += 2)
    {
        $text .= "$podvoj->[$i]\t= $podvoj->[$i+1]\n";
    }
    return $text;
}



#------------------------------------------------------------------------------
# Odešle formulář na adresu, která je u formuláře uložená. Na metodu, která je
# u formuláře uložená, se neohlíží a použije vždy POST. Bere však ohled na
# požadovaný formát POSTu. Volitelně může dostat název nebo popisek (hodnotu)
# tlačítka, kterým formulář odesíláme.
#------------------------------------------------------------------------------
sub odeslat_formular
{
    my $ua = shift; # odkaz na webového klienta
    my $formular = shift; # odkaz na hash
    my $tlacitko = shift; # název tlačítka, jehož stisknutí simulujeme odesláním formuláře
    my $charset = shift; # volitelně, jestliže server neunese UTF-8 (Caddis)
    my $podvoj = ziskat_pole_dvojic($formular, $tlacitko);
    return post($ua, $formular->{action}, $podvoj, $formular->{enctype}, $charset);
}



#==============================================================================
# Funkce pro odesílání požadavků HTTP GET a POST.
#==============================================================================



#------------------------------------------------------------------------------
# Vytvoří webového klienta. Umožní mu ukládat na disk cookies, což je často
# potřeba u serverů, na které se přihlašuje jménem a heslem.
#------------------------------------------------------------------------------
sub vytvorit_klienta
{
    # Vytvořit webového klienta.
    # Místo obyčejného klienta (UserAgent) bych mohl vytvořit robota (RobotUA),
    # který bude respektovat robots.txt a omezí se na 1 požadavek za minutu.
    # Interval stahování si ale raději ohlídám ručně a robots.txt vůbec nebudu
    # brát v úvahu, protože je klidně možné, že server, z něhož chci získat informace,
    # tam má napsáno, že o roboty nestojí.
    # $ua = LWP::RobotUA->new('Nazdárek', 'zeman@ufal.mff.cuni.cz');
    $ua = LWP::UserAgent->new;
    # Jak se bude klient identifikovat? Výchozí identifikace je libwww-perl/verze.
    # To by ale pak každý předpokládal, že jde o robota, a choval by se rasisticky.
    $ua->agent("Mozilla/5.0");
    # Výchozí timeout je 180 s, necháme to tak.
    # Výchozí nastavení nepoužívá proxy server, necháme to tak.
    # Následuje sbírka záhlaví, která souvisí s prohlížečem a jeho nastavením
    # a která mi přidal Firefox k jednomu autentickému požadavku. Dala by se přidávat
    # ke všem požadavkům. Nejsem si jist, zda se dají přidávat také přímo do agenta.
    # Momentálně to tu mám jen proto, aby se ta informace neztratila, ale nepoužívám ji.
    if(0)
    {
        $pozadavek->header('User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; cs; rv:1.9.2.10) Gecko/20100914 Firefox/3.6.10 ( .NET CLR 3.5.30729)');
        $pozadavek->header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
        $pozadavek->header('Accept-Language' => 'cs,en-us;q=0.7,en;q=0.3');
        $pozadavek->header('Accept-Encoding' => 'gzip,deflate');
        $pozadavek->header('Accept-Charset' => 'windows-1250,utf-8;q=0.7,*;q=0.7');
        $pozadavek->header('Keep-Alive' => '115');
        $pozadavek->header('Connection' => 'keep-alive');
        # A ještě tato dvě záhlaví, která sice souvisejí s konkrétním požadavkem, ale
        # na nastavení prohlížeče zřejmě záleží, zda se taková záhlaví vůbec budou odesílat.
        $pozadavek->header('Host' => 'oreus.is.cuni.cz'); # cílový server požadavku
        $pozadavek->header('Referer' => 'http://oreus.is.cuni.cz/fcgi/verso.fpl?fname=webf__index_text&__logout=jeLogout');
    }
    # Budeme muset zapnout cookies, protože se používají při identifikaci přihlášeného uživatele.
    # Domovská složka se liší podle toho, zda pracujeme ve Windows, nebo v Linuxu.
    my $home;
    if($ENV{HOME})
    {
        $home = $ENV{HOME};
    }
    elsif($ENV{HOMEDRIVE} && $ENV{HOMEPATH})
    {
        $home = $ENV{HOMEDRIVE}.$ENV{HOMEPATH};
    }
    else
    {
        $home = '.';
    }
    my $cookie_jar = HTTP::Cookies->new(file => "$home/lwp_cookies.dat", autosave => 1);
    $ua->cookie_jar($cookie_jar);
    return $ua;
}



#------------------------------------------------------------------------------
# Vrátí obsah odpovědi na požadavek HTTP. Pokud je obsah textový, pokusí se
# nejdříve rozpoznat jeho kódování a vrátit ho dekódovaný v interním UTF-8.
#------------------------------------------------------------------------------
sub dekodovat_obsah_response
{
    my $response = shift;
    # Překódovat obsah do UTF-8, pokud to umíme.
    my $obsah = $response->content();
    my $kodovani = 'utf8';
    my $content_type = $response->header('Content-Type');
    if($content_type =~ m-text/-)
    {
        if($content_type =~ m/charset=([-A-Za-z0-9_]+)/)
        {
            $kodovani = $1;
        }
        $obsah = decode($kodovani, $obsah);
    }
    return $obsah;
}



#------------------------------------------------------------------------------
# Pouhá obálka na HTTP požadavek GET.
# Používá globální hash %pocitadlo, což lze využít k omezení zátěže konkrétního
# serveru (a také k zamaskování skutečnosti, že se serverem mluví robot). Zatím
# ale počítadlo neeviduje zátěž pro každý server zvlášť, takže prodleva nastane
# i mezi dvěma požadavky, které jdou každý na jiný server.
# Vrací objekt HTTP::Response.
#------------------------------------------------------------------------------
sub get_response
{
    my $ua = shift; # odkaz na uživatelova agenta
    my $url = shift;
    my $prodleva = shift; # kolik vteřin čekat mezi dvěma požadavky?
    # Zkontrolovat, zda od posledního odeslaného požadavku kamkoliv uplynuly alespoň 2 vteřiny. Nechceme přetěžovat servery.
    my $aktualni_cas = time();
    if($aktualni_cas-$pocitadlo{cas_posledniho_pozadavku}<$prodleva)
    {
        sleep($prodleva);
    }
    $pocitadlo{cas_posledniho_pozadavku} = time();
    $pocitadlo{n_pozadavku}++;
    my $response = $ua->get($url);
    return $response;
}



#------------------------------------------------------------------------------
# Obálka na požadavek GET. Volá funkci get_response(), ale na rozdíl od ní už
# nevrací celou HTTP::Response, nýbrž pouze její obsah. Pokud je obsah textový,
# překóduje ho do UTF-8.
#------------------------------------------------------------------------------
sub get
{
    my $ua = shift; # odkaz na uživatelova agenta
    my $url = shift;
    my $prodleva = shift; # kolik vteřin čekat mezi dvěma požadavky?
    my $response = get_response($ua, $url, $prodleva);
    ###!!! V budoucnosti by možná bylo lepší, kdyby knihovní funkce sama bez dovolení na STDERR nepsala.
    ###!!! Na druhou stranu stejně mnohé funkce tohoto modulu raději rovnou umřou, než by ohlásily chybu nahoru.
    unless($response->is_success)
    {
        print STDERR ("Varování! Stažení $url se možná nepovedlo. Server odpověděl: ".$response->status_line."\n");
    }
    ###!!!
    # Překódovat obsah do UTF-8, pokud to umíme.
    return dekodovat_obsah_response($response);
}



#------------------------------------------------------------------------------
# Obálka na HTTP požadavek POST.
# Nízkoúrovňová funkce pro odeslání vyplněného formuláře.
#------------------------------------------------------------------------------
sub post
{
    my $ua = shift; # odkaz na uživatelova agenta
    my $url = shift; # url, které si data převezme
    my $formular = shift; # data formuláře (atributy a hodnoty)
    my $format = shift; # application/x-www-form-urlencoded nebo multipart/form-data
    my $charset = shift;
    my $prodleva = shift; # kolik vteřin čekat mezi dvěma požadavky?
    # Doplnit výchozí hodnoty nepovinných parametrů.
    $format = 'application/x-www-form-urlencoded' unless($format);
    $charset = 'utf8' unless($charset);
    # Zakódovat data formuláře a sestavit požadavek HTTP POST.
    my $request = pripravit_post($url, $formular, $format, $charset);
    ###!!! DEBUG !!!
    if(0)
    {
        print STDERR ("----- REQUEST -----\n");
        print STDERR ($request->as_string());
        print STDERR ("----- END OF REQUEST -----\n");
    }
    ###!!! END OF DEBUG !!!
    # Zkontrolovat, zda od posledního odeslaného požadavku kamkoliv uplynuly alespoň 2 vteřiny. Nechceme přetěžovat servery.
    my $aktualni_cas = time();
    if($aktualni_cas-$pocitadlo{cas_posledniho_pozadavku}<$prodleva)
    {
        sleep($prodleva);
    }
    $pocitadlo{cas_posledniho_pozadavku} = time();
    $pocitadlo{n_pozadavku}++;
    # Teď teprve dojde k vlastnímu odeslání požadavku.
    my $response = $ua->request($request);
    # Zkontrolovat, že odpověď není 500 (internal server error).
    # Pozor, odpověď 302 (found / moved temporarily) se nepovažuje za úspěch, ale z našeho pohledu to úspěch je.
    # Znamená vlastně přesměrování, cílová adresa se nachází v záhlaví "Location".
    # U požadavků GET a HEAD to user agent vyřeší sám a automaticky pošle nový požadavek na novou adresu.
    # Požadavek POST podle RFC standardně není přesměrovatelný, ale fakticky k tomu dochází.
    # U UserAgenta by šlo zapnout, aby přesměrování řešil automaticky i u POSTu.
    # Zatím ho neřešíme nijak. Na novou cílovou adresu už se asi nemá posílat POST, ale jen GET!
    # (Svého času jsem zkoušel přesměrování hlídat sám, na novou adresu jsem posílal taky POST a nefungovalo mi kvůli tomu přihlašování do Versa.)
    if(!($response->is_success() || $response->status_line() =~ m/^302/))
    {
        print STDERR ("Posting completed form to '$url'\n");
        my $statusline = $response->status_line();
        ###!!! Nechci, aby to umřelo na "555 Verso Chyba". Chci si prostudovat odpověď a dozvědět se o chybě co nejvíc.
        #confess($statusline);
        print STDERR ("$statusline\n");
    }
    return $response;
}



#------------------------------------------------------------------------------
# Vyrobí objekt HTTP::Request typu POST pro odeslání dat z formuláře. Ještě ale
# nic neodesílá.
#------------------------------------------------------------------------------
sub pripravit_post
{
    my $url = shift; # mohlo by se vzít z vyplněného formuláře, ale umožňujeme zadat jiné
    my $formular = shift; # odkaz na hash popsaný na začátku modulu
    my $format = shift; # application/x-www-form-urlencoded nebo multipart/form-data
    my $charset = shift; # default je utf8
    # Hranice může být asi ledacos a v praxi bývá náhodná.
    # Tuto jsem opsal z požadavku, který vygeneroval Firefox; příklad na webu zas byl 'AaB03x'.
    my $hranice = '---------------------------187161971819895';
    my $obsah = pripravit_data_mime($formular, $format, $hranice, $charset);
    my $request = sestavit_pozadavek_post($url, $obsah, $format, $hranice);
    return $request;
}



#------------------------------------------------------------------------------
# Připraví data formuláře k odeslání v jednom ze dvou k tomu určených formátů
# MIME. Vrací řetězec, který se do HTTP požadavku vkládá jako obsah. Obsah
# neobsahuje žádné záhlaví MIME.
#------------------------------------------------------------------------------
sub pripravit_data_mime
{
    my $formular = shift; # odkaz na pole (dvojice prvků odpovídá klíči a hodnotě)
    my $format = shift; # application/x-www-form-urlencoded nebo multipart/form-data
    my $hranice = shift; # pokud je formát multipart/form-data, oddělovač částí
    my $charset = shift; # kvůli webům jako Caddis, které nesnesou UTF-8
    $charset = 'utf8' unless($charset);
    my $mime;
    if($format eq 'application/x-www-form-urlencoded')
    {
        # Sestavit z položek a hodnot formuláře řetězec zakódovaný jako do URL.
        my @parametry;
        for(my $i = 0; $i<=$#{$formular}; $i += 2)
        {
            my $prirazeni = uri_escape(encode($charset, $formular->[$i])).'='.uri_escape(encode($charset, $formular->[$i+1]));
            push(@parametry, $prirazeni);
        }
        $mime = join('&', @parametry);
    }
    elsif($format eq 'multipart/form-data')
    {
        # Varování: Podle specifikace protokolu mají řádky končit CR LF, tedy \x0D\x0A.
        # Pokud tak nekončí (např. pokud končí pouze LF, tedy \x0A), některé servery to neunesou.
        # Např. knihovna com.oreilly.servlet.multipart.MultipartParser, kterou používá Biblio pod Tomcatem,
        # se sice pokouší tohle poznat, ale nekorektně, takže hodí výjimku.
        # Zdálo by se, že v Perlu tedy máme všechny řádky ukončovat "\r\n".
        # Jenže Perl se snaží být chytrý a význam \n si mění podle operačního systému a bůhvíčeho ještě,
        # tudíž nikdy nemáme jistotu, co vlastně nakonec odešle. Bezpečnější, byť ošklivější, je tedy
        # používat výhradně "\x0D\x0A".

        # Uf. Hledání téhle chyby mě stálo dva dny ladění Perlu i Javy, čtení logů a dokonce
        # dekompilování javovských knihoven pomocí úžasného webového nástroje Fernflower na
        # http://www.reversed-java.com/fernflower/
        for(my $i = 0; $i<=$#{$formular}; $i += 2)
        {
            # V současnosti umíme pouze takové položky, jejichž názvy se omezují na
            # alfanumerické ASCII znaky, podtržítko, pomlčku a kupodivu mezeru.
            # (Ne-ASCII znaky bychom museli zakódovat podle RFC2045.)
            #if($formular->[$i] !~ m/^[-A-Za-z0-9_ ]+$/)
            ###!!! Nevím, kde jsem se o výše uvedeném omezení dočetl, ale při sledování komunikace Firefoxu s OBD se mi zdá,
            ###!!! že dvojkříže a vykřičníky, které tam jsou taky potřeba, se posílají nezakódované.
            if($formular->[$i] !~ m/^[-A-Za-z0-9_ \#!\[\]]+$/)
            {
                confess("Pole formulare se nesmi jmenovat \"$formular->[$i]\".\n");
            }
            $mime .= "--$hranice\x0D\x0A";
            # Jinak se zachází s obyčejnými položkami, jinak se soubory.
            if(ref($formular->[$i+1]) eq 'HASH')
            {
                $mime .= "Content-Disposition: form-data; name=\"$formular->[$i]\"; filename=\"$formular->[$i+1]{filename}\"\x0D\x0A";
                if($formular->[$i+1]{type})
                {
                    $mime .= "Content-Type: $formular->[$i+1]{type}\x0D\x0A";
                }
                $mime .= "\x0D\x0A";
                # Vůbec si nejsem jistý, že se za obsah souboru má nebo smí přidat zalomení řádku.
                # Při pokusech se mi ale zdálo, že Firefox to tak dělá.
                $mime .= encode($charset, "$formular->[$i+1]{file}\x0D\x0A");
            }
            else
            {
                $mime .= "Content-Disposition: form-data; name=\"$formular->[$i]\"\x0D\x0A";
                $mime .= "\x0D\x0A";
                $mime .= encode($charset, "$formular->[$i+1]\x0D\x0A");
            }
        }
        $mime .= "--$hranice--\x0D\x0A\x0D\x0A";
    }
    else
    {
        confess("Neznamy format MIME \"$format\"\n");
    }
    return $mime;
}



#------------------------------------------------------------------------------
# Sestaví požadavek pro odeslání dat formuláře na server. Přebírá data
# formuláře už zformátovaná podle příslušného typu MIME (buď
# application/x-www-form-urlencoded, nebo multipart/form-data). Tato funkce je
# od formátování MIME oddělena, aby se formátování nemuselo opakovat v případě,
# že první požadavek nevrátil očekávanou odpověď (např. kvůli přesměrování) a
# je nutné sestavit požadavek nový.
#------------------------------------------------------------------------------
sub sestavit_pozadavek_post
{
    my $url = shift;
    my $content = shift; # zformátovaná data
    my $format = shift; # application/x-www-form-urlencoded nebo multipart/form-data
    my $hranice = shift; # pokud je formát multipart/form-data, oddělovač částí
    my $pozadavek = HTTP::Request->new(POST => $url);
    if($format eq 'application/x-www-form-urlencoded')
    {
        $pozadavek->header('Content-Length' => length($content));
        $pozadavek->content_type('application/x-www-form-urlencoded');
        $pozadavek->content($content);
    }
    elsif($format eq 'multipart/form-data')
    {
        $pozadavek->content_type("multipart/form-data; boundary=$hranice");
        $pozadavek->content($content);
        ###!!! Následující zásahy si vynucuje Caddis a obecně jsou v této podobě nežádoucí!
        $pozadavek->header('Accept-Language' => 'cs,en-us;q=0.7,en;q=0.3');
        $pozadavek->header('Accept-Charset'  => 'windows-1250,utf-8;q=0.7,*;q=0.7');
    }
    else
    {
        confess("Neznamy format MIME \"$format\"\n");
    }
    return $pozadavek;
}



#==============================================================================
# Parser HTML, který posbírá pole formuláře a jejich výchozí hodnoty.
# Předpokládá, že dokument obsahuje právě jeden formulář.
#==============================================================================



#------------------------------------------------------------------------------
# Najde ve zdrojáku HTML formulář. Posbírá prvky formuláře spolu s jejich
# výchozími hodnotami a vrátí je jako pole, ve kterém se střídají názvy prvků
# a jejich hodnoty.
#------------------------------------------------------------------------------
sub precist_formular
{
    my $html = shift; # zdroják HTML s formulářem
    my $url = shift; # URL, odkud byl formulář stažen, kvůli vyhodnocení relativní cesty
    local %stav;
    local %formular;
    my $parser = HTML::Parser->new
    (
        start_h => [\&handle_start, "tagname, \@attr"],
        end_h   => [\&handle_end,   "tagname"],
        text_h  => [\&handle_char,  "dtext"],
    );
    $parser->parse($html);
    # Zabsolutnit adresu, na kterou se má formulář odeslat.
    $formular{action} = htmlabspath::zabsolutnit_odkaz($formular{action}, $url);
    return \%formular;
}



#------------------------------------------------------------------------------
# Obslouží výskyt počáteční značky prvku XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub handle_start
{
    my $element = shift;
    my %attr = @_;
    # Na začátku formuláře zapnout sběr údajů.
    if($element eq 'form' && !$stav{precteno})
    {
        $stav{formular} = 1;
        # U řady formulářů předem víme, kam budeme chtít hodnoty odeslat, vždy tomu ale tak být nemusí.
        # Proto si zapamatujeme i URL "podatelny".
        $formular{action} = $attr{action};
        $formular{method} = $attr{method};
        $formular{enctype} = $attr{enctype};
    }
    # Uvnitř formuláře sbírat prvky <input>, <textarea> a <select>.
    elsif($stav{formular})
    {
        # U zaškrtávátek si zapamatovat, zda jsou zaškrtnuta.
        # U ostatních si zapamatovat jejich hodnotu.
        if($element eq 'input')
        {
            if($attr{type} eq 'checkbox')
            {
                my $value = exists($attr{checked}) ? ($attr{value} ? $attr{value} : 1) : '';
                pridat_prvek(\%formular, $attr{name}, $value, 'checkbox', undef, undef, $attr{id});
            }
            elsif($attr{type} eq 'radio')
            {
                # Prvek <input> typu 'radio' zpracujeme stejně jako vnořené prvky <select> a <option>:
                # Vyjmenovaný seznam povolených hodnot, z nichž nejvýše jedna může být vybraná.
                # Oproti pravděpodobnému chování normálního prohlížeče je v tom drobný rozdíl, který ignorujeme:
                # Volitelné hodnoty <select> tvoří jeden ovládací prvek na jednom místě v uspořádaném seznamu prvků.
                # Prohlížeč i my odešle zvolenou hodnotu na tomto místě. Naproti tomu výběr typu 'radio' tvoří dohromady
                # několik prvků <input>, které teoreticky mohou být roztroušené na různých místech formuláře
                # (skutečně k tomu dojde např. pokud do seznamu možností bude vložený podseznam). Prohlížeč v takovém
                # případě zařadí zvolenou hodnotu na to místo v seznamu, na kterém se nacházela ve formuláři, zatímco
                # my budeme mít celý soubor rádiových hodnot ukotvený k jedinému bodu formuláře a tam taky vypíšeme
                # vybranou hodnotu.
                # Jestliže už jsme zaznamenali jiný input radio se stejným jménem, poznamenat si k němu novou hodnotu.
                # Jinak přidat prvek do formuláře a poznamenat si k němu první hodnotu.
                # Každopádně zjistit, zda je nastaven atribut checked, a pokud ano, upravit aktuální hodnotu prvku.
                if(exists($formular{hash}{$attr{name}}))
                {
                    my $field = $formular{hash}{$attr{name}}[-1];
                    ref($field) eq 'HASH' or confess("Internal error, field=$attr{name}");
                    push(@{$field->{options}}, $attr{value});
                    if(exists($attr{checked}))
                    {
                        $field->{value} = $attr{value};
                    }
                }
                else
                {
                    pridat_prvek(\%formular, $attr{name}, exists($attr{checked}) ? $attr{value} : '', 'select', [$attr{value}], undef, $attr{id});
                }
            }
            ###!!! Také ještě neumíme načíst kolonku pro soubor.
            elsif($attr{type} =~ m/^(submit|button)$/)
            {
                pridat_prvek(\%formular, $attr{name}, $attr{value}, 'submit', undef, undef, $attr{id});
            }
            else
            {
                pridat_prvek(\%formular, $attr{name}, $attr{value}, $attr{type}, undef, undef, $attr{id});
            }
        }
        # U velkých textových oken budeme muset posbírat obsah prvku.
        elsif($element eq 'textarea')
        {
            $stav{textarea} = 1;
            $stav{name} = $attr{name};
        }
        # U rozbalítek si potřebujeme zapamatovat přinejmenším jméno a aktuální hodnotu, ideálně však i seznam povolených hodnot.
        elsif($element eq 'select')
        {
            $stav{select} = 1;
            $stav{name} = $attr{name};
            $stav{options} = [];
            $stav{selected} = '';
        }
        elsif($element eq 'option')
        {
            push(@{$stav{options}}, $attr{value});
            if(exists($attr{selected}))
            {
                $stav{selected} = $attr{value};
            }
        }
    }
}



#------------------------------------------------------------------------------
# Obslouží výskyt koncové značky prvku XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub handle_end
{
    my $element = shift;
    # Na konci formuláře vypnout sběr údajů.
    if($element eq 'form' and $stav{formular})
    {
        # Zabránit načítání případných dalších formulářů do téže datové struktury.
        # Současná implementace umí načíst jen první formulář na stránce.
        $stav{precteno} = 1;
        $stav{formular} = 0;
    }
    # Na konci textové oblasti vypnout sběr textu.
    elsif($element eq 'textarea' and $stav{textarea})
    {
        pridat_prvek(\%formular, $stav{name}, $stav{posbirany_text}, 'text', undef, undef, $attr{id});
        $stav{posbirany_text} = '';
        $stav{textarea} = 0;
    }
    # Na konci rozbalítka vypnout sběr možností.
    elsif($element eq 'select' and $stav{select})
    {
        pridat_prvek(\%formular, $stav{name}, $stav{selected}, 'select', $stav{options}, undef, undef, $attr{id});
        $stav{select} = 0;
    }
}



#------------------------------------------------------------------------------
# Obslouží výskyt textu uvnitř XML. Volá ji parser XML.
#------------------------------------------------------------------------------
sub handle_char
{
    my $string = decode_entities(shift);
    if($stav{textarea})
    {
        $stav{posbirany_text} .= $string;
    }
}



1;
