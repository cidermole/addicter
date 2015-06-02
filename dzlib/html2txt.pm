#!/usr/bin/perl
# Funkce pro odstranění HTML kódu.
# (c) 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package html2txt;
use utf8;
use HTML::Parser ();
use HTML::Entities;



#------------------------------------------------------------------------------
# Odstraní ze zdrojáku webové stránky HTML kód a ponechá prostý text.
# Zachová hranice odstavců jako zalomení řádků.
#------------------------------------------------------------------------------
sub prevest
{
    my $html = shift;
    # Předhodit HTML parseru. Parser bude ukládat text do proměnné $dokument.
    local $dokument;
    local $off = 0;
    $p->parse($html);
    $p->eof();
    # Odstranit z dokumentu přebytečné mezery.
    $dokument =~ s/^\s+//s;
    $dokument =~ s/\s+$//s;
    $dokument =~ s/\s*<p>\s*/<p>/sg;
    $dokument =~ s/\s+/ /sg;
    $dokument =~ s/^(<p>)+//s;
    $dokument =~ s/(<p>)+$//s;
    $dokument =~ s/(<p>)+/<p>/sg;
    # Nyní dokument neobsahuje žádné zalomení řádku (CR ani LF).
    # Značky konce odstavce nahradit zalomením řádku.
    $dokument =~ s/<p>/\n/sg;
    $dokument .= "\n";
    # Dekódovat entity v dokumentu, který teď už neobsahuje žádné značky HTML.
    decode_entities($dokument);
    return $dokument;
}



BEGIN
{
    $p = HTML::Parser->new
    (
        api_version => 3,
        start_h => [\&start_hook, "tagname, attr"],
        end_h   => [\&end_hook,   "tagname"],
        text_h  => [\&text_hook,  "text"]
    );
}



#------------------------------------------------------------------------------
# Ošetří výskyt počáteční značky HTML.
#------------------------------------------------------------------------------
sub start_hook
{
    my $tagname = shift;
    my $attr = shift;
    # Značky HTML, které tak či onak signalizují začátek odstavce, nezahazovat,
    # ale nahradit značkou <p>, abychom o informaci o hranici odstavce nepřišli.
    if($tagname =~ m/^(div|h[1-6]|table|tr|th|td|p|ul|ol|li|dl|dt|dd|select|option)$/i)
    {
        $dokument .= '<p>';
    }
    # Zalomení řádku uvnitř odstavce nahradit alespoň mezerou, aby se neslepila slova.
    # Často se používá pro formátování adres apod., kde je ještě lepší nahradit je čárkou a mezerou.
    if($tagname eq 'br')
    {
        $dokument .= ', ';
    }
    # Vypnout sběr textu uvnitř vybraných prvků HTML.
    if($tagname =~ m/^(head|style|script)$/i)
    {
        $off++;
    }
}



#------------------------------------------------------------------------------
# Ošetří výskyt koncové značky HTML.
#------------------------------------------------------------------------------
sub end_hook
{
    my $tagname = shift;
    # Zapnout sběr textu vně vybraných prvků HTML.
    if($tagname =~ m/^(head|style|script)$/i && $off>0)
    {
        $off--;
    }
}



#------------------------------------------------------------------------------
# Ošetří výskyt prostého textu.
#------------------------------------------------------------------------------
sub text_hook
{
    my $text = shift;
    unless($off)
    {
        $dokument .= $text;
    }
}



1;
