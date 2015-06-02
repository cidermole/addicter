#!/usr/bin/perl
# Functions for preparation of transliteration from Urdu to Latin script.
# Unlike my previous attempt translit::urdu, this one is non-deterministic and outputs sets of characters in places of vowel ambiguity.
# Copyright © 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package translit::urdund;
use utf8;
use translit;



# The transliteration table will be owned by the caller of inicializovat().
# Nevertheless, we will store the reference to the last created table here.
$table;
# We will also store the maximum lookahead for keys in $table.
$maxl;



#------------------------------------------------------------------------------
# Stores character transliterations in a hash. Unlike my other transliteration
# tables, this one assumes that each word is processed separately and that it
# is enclosed in <angle brackets> before processing (of course, the caller must
# escape any real angle brackets as a consequence). Word-boundary marks
# facilitate resolving some vowel ambiguities.
#------------------------------------------------------------------------------
sub inicializovat
{
    # Reference to the hash in which the transliteration table shall be stored.
    my $prevod = shift;
    # Mapping of hexadecimal unicodes of Urdu consonants to their Latin equivalents.
    my %cons =
    (
        "\x{628}" => 'b',
        "\x{67E}" => 'p',
        "\x{62A}" => 't',
        "\x{679}" => "\x{1E6D}", # t dot below
        "\x{62B}" => "\x{1E61}", # s dot above
        "\x{62C}" => 'j',
        "\x{686}" => 'č',
        "\x{62D}" => "h\x{327}", # h cedilla
        "\x{62E}" => 'x',
        "\x{62F}" => 'd',
        "\x{688}" => "\x{1E0D}", # d dot below
        "\x{630}" => "\x{17C}",  # z dot above
        "\x{631}" => 'r',
        "\x{691}" => "\x{1E5B}", # r dot below
        "\x{632}" => 'z',
        "\x{698}" => 'ž',
        "\x{633}" => 's',
        "\x{634}" => 'š',
        "\x{635}" => "\x{15F}",  # s cedilla
        "\x{636}" => "z\x{327}", # z cedilla
        "\x{637}" => "\x{163}",  # t cedilla
        "\x{638}" => "d\x{327}", # d cedilla
        "\x{639}" => "\x{2C0}",  # glottal stop
        "\x{63A}" => "\x{11F}",  # g breve
        "\x{641}" => 'f',
        "\x{642}" => 'q',
        "\x{6A9}" => 'k',
        "\x{6AF}" => 'g',
        "\x{644}" => 'l',
        "\x{645}" => 'm',
        "\x{646}" => 'n',
        "\x{6BA}" => "\x{F1}",   # n tilde
        "\x{6C1}" => 'h',
        # Heh doachashmee is used exclusively to form aspirated variants of consonants.
        # It cannot be confused with normal heh goal, thus no need to transliterate it differently from 'h'.
        # However, we have to enumerate the aspirated consonants to ensure that no vowel is placed e.g. between 'b' and 'h' in 'bh'.
        #'06BE' => 'h', # heh doachashmee; don't define it separately so we see if it occurs elsewhere than expected
        "\x{628}\x{6BE}" => 'bh',
        "\x{67E}\x{6BE}" => 'ph',
        "\x{62A}\x{6BE}" => 'th',
        "\x{679}\x{6BE}" => "\x{1E6D}h", # t dot below + h
        "\x{62C}\x{6BE}" => 'jh',
        "\x{686}\x{6BE}" => 'čh',
        "\x{62F}\x{6BE}" => 'dh',
        "\x{688}\x{6BE}" => "\x{1E0D}h", # d dot below + h
        "\x{691}\x{6BE}" => "\x{1E5B}h", # r dot below + h
        "\x{6A9}\x{6BE}" => 'kh',
        "\x{6AF}\x{6BE}" => 'gh'
    );
    # We will be adding special cases to %cons but we need to remember the original set.
    my @normal_consonants = keys(%cons);
    # The semi-vowel waw
    my $waw = chr(hex('0648'));
    my $alef = chr(hex('0627'));
    my $noonghunna = chr(hex('06BA'));
    # Word-initial => consonant
    $cons{'<'.$waw} = 'w';
    # Before alef => consonant
    $prevod->{$waw.$alef} = "w\x{101}"; # w + a macron
    # Word-final => vowel
    $prevod->{$waw.'>'} = "[\x{16B}o]"; # u macron | o
    # Before noon ghunna => o
    $prevod->{$waw.$noonghunna} = "o\x{F1}"; # o + n tilde
    # EXCEPTION: the word "hUM" (I-am)
    $prevod->{"<\x{6C1}".$waw.$noonghunna.'>'} = "h\x{16B}\x{F1}"; # h + u macron + n tilde
    # Otherwise fully ambiguous
    $prevod->{$waw} = "[w\x{16B}o]"; # w | u macron | o
    # The semi-vowel yeh
    my $yeh = chr(hex('06CC'));
    # Word-initial => consonant
    $cons{'<'.$yeh} = 'y';
    # Word-internal after alef => consonant
    # (This rule could be applied recursively and thus escape the regular space.
    # We only cover normal consonant + alef + yeh but not yeh + alef + yeh.)
    # The same for waw.
    foreach my $nc (@normal_consonants)
    {
        $cons{$nc.$alef.$waw} = $cons{$nc}."\x{101}w";
        $cons{$nc.$alef.$yeh} = $cons{$nc}."\x{101}y";
    }
    # Before alef => consonant
    $prevod->{$yeh.$alef} = "y\x{101}"; # y + a macron
    # Word-final => long i
    $prevod->{$yeh.'>'} = "\x{12B}"; # i macron
    # Before noon ghunna => vowel
    $prevod->{$yeh.$noonghunna} = "[\x{12B}e]\x{F1}"; # (i macron | e) + n tilde
    # Otherwise fully ambiguous
    $prevod->{$yeh} = "[y\x{12B}e]"; # y | i macron | e
    # Yeh barree => e
    my $yehbarree = chr(hex('06D2'));
    $prevod->{$yehbarree} = 'e';
    # Alef
    # Word-initial followed by waw or yeh => short vowel + y|w or nothing + long vowel (represented by the next character)
    $prevod->{'<'.$alef.$waw} = "[\x{259}w\x{259}|\x{16B}|o]"; # (schwa + w + schwa) | u macron | o
    $prevod->{'<'.$alef.$yeh} = "[\x{259}y\x{259}|\x{12B}|e]"; # (schwa + y + schwa) | i macron | e
    # Word-initial followed by short vowel diacritic => short vowel
    my $zabar = chr(hex('064E')); # arabic fatha
    my $pesh = chr(hex('064F')); # arabic damma
    my $zer = chr(hex('0650')); # arabic kasra
    $prevod->{'<'.$alef.$zabar} = 'a';
    $prevod->{'<'.$alef.$pesh} = 'u';
    $prevod->{'<'.$alef.$zer} = 'i';
    # Word-initial followed by anything else => short vowel
    $prevod->{'<'.$alef} = "\x{259}"; # schwa
    # Elsewhere => long a
    $prevod->{$alef} = "\x{101}"; # a macron
    # Alef madda => long a
    $prevod->{chr(hex('0622'))} = "\x{101}"; # a macron
    # Some vowel combinations with hamza
    my $hamza = chr(hex('0654')); # or 674?
    my $wawhamza = chr(hex('0624'));
    my $yehhamza = chr(hex('0626'));
    my $yehbarreehamza = chr(hex('06D3'));
    $prevod->{$alef.$wawhamza} = "\x{101}[\x{16B}o]"; # a macron + u macron
    $prevod->{$alef.$waw.$hamza} = "\x{101}[\x{16B}o]"; # a macron + u macron
    $prevod->{$alef.$yehhamza.$yehbarree} = "\x{101}e"; # a macron + e
    $prevod->{$alef.$yehbarreehamza} = "\x{101}e"; # a macron + e
    $prevod->{$alef.$yehhamza.$yeh} = "\x{101}\x{12B}"; # a macron + i macron
    $prevod->{$alef.$yehhamza} = "\x{101}\x{12B}"; # a macron + i macron
    $prevod->{$waw.$yehhamza.$yeh.'>'} = "[\x{16B}o]\x{12B}"; # (u macron | o) + i macron
    $prevod->{$waw.$yehhamza.$yehbarree} = "[\x{16B}o]e"; # (u macron | o) + e
    $prevod->{$yeh.$yehhamza} = "e\x{12B}"; # e + i macron
    # Short vowels
    $prevod->{$zabar} = 'a';
    $prevod->{$pesh} = 'u';
    $prevod->{$zer} = 'i';
    ###!!!
    ### zer + yeh => long i (zer is superfluous in word-final position)
    ### pesh + waw => long u
    ### waw + inverted pesh ("ulTaa pesh") => long u (alternate representation)
    ### alef + "big yai" (yeh barree) => word-initial e (yeh barree changes shape - but people often use normal yeh instead!)
    ### medial yeh without diacritics => e (but we have to be sure that the text would be diacriticized wherever appropriate)
    ### waw without diacritics => o (but we have to be sure that the text would be diacriticized wherever appropriate)
    ### zabar + yeh (or yeh barree, see above) => ae
    ### zabar + waw => ao
    # Add the consonants to the transliteration table.
    foreach my $c (keys(%cons))
    {
        my $t = $cons{$c};
        # Add word-final consonant without short vowel.
        $prevod->{$c.'>'} = $t;
        # Consonant + alef => consonant + long a
        $prevod->{$c.$alef} = $t."\x{101}"; # a macron
        # Consonant + alef + yeh hamza + yeh barree
        $prevod->{$c.$alef.$yehhamza.$yehbarree} = $t."\x{101}e"; # a macron + e
        $prevod->{$c.$alef.$yehbarreehamza} = $t."\x{101}e"; # a macron + e
        # Consonant + alef + yeh hamza + yeh
        $prevod->{$c.$alef.$yehhamza.$yeh} = $t."\x{101}\x{12B}"; # a macron + i macron
        # Consonant + alef + yeh hamza
        $prevod->{$c.$alef.$yehhamza} = $t."\x{101}\x{12B}"; # a macron + i macron
        # Consonant + alef + waw hamza
        $prevod->{$c.$alef.$wawhamza} = $t."\x{101}[\x{16B}o]"; # a macron + (u macron | o)
        $prevod->{$c.$alef.$waw.$hamza} = $t."\x{101}[\x{16B}o]"; # a macron + (u macron | o)
        # Consonant + waw + alef => consonant + schwa + w + long a
        $prevod->{$c.$waw.$alef} = $t."\x{259}w\x{101}"; # schwa + w + a macron
        # Consonant + waw + alef + yeh hamza => consonant + schwa + w + long a + long i
        $prevod->{$c.$waw.$alef.$yehhamza} = $t."\x{259}w\x{101}\x{12B}";
        # Consonant + word-final waw => consonant + long u | o
        $prevod->{$c.$waw.'>'} = $t."[\x{16B}o]"; # u macron | o
        # Consonant + waw + noon ghunna => consonant + o + n tilde
        $prevod->{$c.$waw.$noonghunna} = $t."o\x{F1}"; # o + n tilde
        # Consonant + waw => consonant + ambiguous w (but without schwa, although there could be also wa|wi|wu)
        $prevod->{$c.$waw} = $t."[w\x{16B}o]"; # w | u macron | o
        # Consonant + waw + yeh hamza + yeh
        $prevod->{$c.$waw.$yehhamza.$yeh.'>'} = $t."[\x{16B}o]\x{12B}"; # (u macron | o) + i macron
        # Consonant + waw + yeh hamza + yeh barree
        $prevod->{$c.$waw.$yehhamza.$yehbarree} = $t."[\x{16B}o]e"; # (u macron | o) + e
        # Consonant + yeh + alef => consonant + schwa + y + long a
        $prevod->{$c.$yeh.$alef} = $t."\x{259}y\x{101}"; # schwa + y + a macron
        # Consonant + word-final yeh => consonant + long i
        $prevod->{$c.$yeh.'>'} = $t."\x{12B}"; # i macron
        # Consonant + yeh + noon ghunna => consonant + vowel
        $prevod->{$c.$yeh.$noonghunna} = $t."[\x{12B}e]\x{F1}"; # (i macron | e) + n tilde
        # Consonant + yeh => consonant + ambiguous y (but without schwa, although there could be also ya|yi|yu)
        $prevod->{$c.$yeh} = $t."[y\x{12B}e]"; # y | i macron | e
        # Consonant + yeh barree => consonant + e
        $prevod->{$c.$yehbarree} = $t.'e';
        # Consonant + yeh + yeh hamza => consonant + e + i macron (is this the only correct reading?)
        $prevod->{$c.$yeh.$yehhamza} = $t."e\x{12B}"; # e + i macron
        # Consonant + yeh hamza => consonant + short vowel + long i or e
        $prevod->{$c.$yehhamza} = $t."\x{259}[\x{12B}e]";
        # Consonant + yeh hamza + yeh barree => consonant + short vowel + e
        $prevod->{$c.$yehhamza.$yehbarree} = $t."\x{259}e";
        $prevod->{$c.$yehbarreehamza} = $t."\x{259}e";
        # Consonant + short vowel diacritic => consonant + short vowel
        $prevod->{$c.$zabar} = $t.'a';
        $prevod->{$c.$pesh} = $t.'u';
        $prevod->{$c.$zer} = $t.'i';
        # Consonant + short vowel diacritic + long vowel => consonant + disambiguated long vowel
        $prevod->{$c.$pesh.$waw} = $t."\x{16B}"; # u macron
        $prevod->{$c.$zer.$yeh} = $t."\x{12B}"; # i macron
        # Add word-initial and -internal consonant with ambiguous short vowel (represented by schwa).
        $prevod->{$c} = $t."\x{259}";
    }
    # Mapping of hexadecimal unicodes of Urdu punctuation, numbers and other symbols to their Latin equivalents.
    my %other =
    (
        '060C' => ',',        # arabic comma
        '061B' => ';',        # arabic semicolon
        '061F' => '?',        # arabic question mark
        '06D4' => '.',        # arabic full stop
        '0660' => '0',
        '0661' => '1',
        '0662' => '2',
        '0663' => '3',
        '0664' => '4',
        '0665' => '5',
        '0666' => '6',
        '0667' => '7',
        '0668' => '8',
        '0669' => '9',
        '066A' => '%',
        '066B' => '.',       # arabic decimal separator
        '066C' => ',',       # arabic thousands separator
        '06F0' => '0',       # extended arabic-indic digit
        '06F1' => '1',
        '06F2' => '2',
        '06F3' => '3',
        '06F4' => '4',
        '06F5' => '5',
        '06F6' => '6',
        '06F7' => '7',
        '06F8' => '8',
        '06F9' => '9',
    );
    # Add the characters to the transliteration table.
    foreach my $kod (keys(%other))
    {
        $prevod->{chr(hex($kod))} = $other{$kod};
    }
    # Hard-coded disambiguation of selected frequent words (unless they are inherently ambiguous such as "tU|to").
    my $b = "\x{628}";
    my $p = "\x{67E}";
    my $t = "\x{62A}";
    my $T = "\x{679}";
    my $j = "\x{62C}";
    my $c = "\x{686}";
    my $H = "\x{62D}";
    my $x = "\x{62E}";
    my $d = "\x{62F}";
    my $D = "\x{688}";
    my $r = "\x{631}";
    my $s = "\x{633}";
    my $sh = "\x{634}";
    my $f = "\x{641}";
    my $q = "\x{642}";
    my $k = "\x{6A9}";
    my $g = "\x{6AF}";
    my $l = "\x{644}";
    my $m = "\x{645}";
    my $n = "\x{646}";
    my $N = "\x{6BA}";
    my $h = "\x{6C1}";
    $prevod->{"<$alef$yeh$k>"} = 'ek';
    $prevod->{"<$alef$waw$r>"} = 'or';
    $prevod->{"<$k$waw>"} = 'ko';
    $prevod->{"<$m$yeh$N>"} = "me\x{F1}";
    $prevod->{"<$h$yeh$N>"} = "he\x{F1}";
    $prevod->{"<$h$waw>"} = 'ho';
    $prevod->{"<$j$waw>"} = 'jo';
    $prevod->{"<$k$waw$yehhamza$yeh>"} = "ko\x{12B}";
    $prevod->{"<$n$h$yeh$N>"} = "nah\x{12B}\x{F1}";
    $prevod->{"<$l$yehbarreehamza>"} = 'lie';
    $prevod->{"<$h$waw$yehhamza$yeh>"} = "h\x{16B}\x{12B}";
    $prevod->{"<$h$waw$yehhamza$yehbarree>"} = "h\x{16B}e";
    $prevod->{"<$h$waw$t$alef>"} = "hot\x{101}";
    $prevod->{"<$h$waw$t$yehbarree>"} = 'hote';
    $prevod->{"<$l$waw$g>"} = 'log';
    $prevod->{"<$l$waw$g$waw$N>"} = "logo\x{F1}";
    # Unused word boundaries shall be removed.
    $prevod->{'<'} = '';
    $prevod->{'>'} = '';
    # Figure out the maximum lookahead for the current transliteration table.
    foreach $key (keys(%{$prevod}))
    {
        my $l = length($key);
        $maxl = $l if($l>$maxl);
    }
    # Remember the pointer in this package.
    $table = $prevod;
    return $prevod;
}



#------------------------------------------------------------------------------
# This module needs its own implementation of the transliteration function in
# order to find and use word boundaries.
#------------------------------------------------------------------------------
sub prevest
{
    my $text = shift;
    # Protect any preexisting angle brackets from our changes.
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    # Insert word boundaries between letters at the beginning and end of text.
    $text =~ s/^(\pL)/<$1/;
    $text =~ s/(\pL)$/$1>/;
    # Insert word boundaries between spaces (including newlines) and letters.
    $text =~ s/(\s)(\pL)/$1<$2/gs;
    $text =~ s/(\pL)(\s)/$1>$2/gs;
    # Insert word boundaries between punctuation and letters.
    $text =~ s/(\pP)(\pL)/$1<$2/g;
    $text =~ s/(\pL)(\pP)/$1>$2/g;
    # Insert word boundaries between letter and zero-width non-joiner.
    $text =~ s/(\pL)\x{200C}(\pL)/$1><$2/g;
    $text =~ s/(\pL)\x{200C}/$1>/g;
    $text =~ s/\x{200C}(\pL)/<$2/g;
    # Use the core transliteration function and our transliteration table to convert the preprocessed text.
    my $result = translit::prevest($table, $text, $maxl);
    # Remove the protection of angle brackets (angle brackets introduced by us have been removed by the transliteration function).
    $result =~ s/&lt;/</g;
    $result =~ s/&gt;/>/g;
    $result =~ s/&amp;/&/g;
    return $result;
}



1;
