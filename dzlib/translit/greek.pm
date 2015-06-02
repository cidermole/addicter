#!/usr/bin/perl
# Funkce pro přípravu transliterace z řecké abecedy do latinky.
# Copyright © 2013 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package translit::greek;
use utf8;



#------------------------------------------------------------------------------
# Uloží do hashe přepisy znaků.
#------------------------------------------------------------------------------
sub inicializovat
{
    # Odkaz na hash, do kterého se má ukládat převodní tabulka.
    my $prevod = shift;
    # Má se do latinky přidávat nečeská diakritika, aby se neztrácela informace?
    my $bezztrat = 1;
    my $alt = 1; # český přepis pro putty
    my %greek =
    (
        913 => 'A', # alfa
        914 => 'B', # beta
        915 => 'G', # gamma
        916 => 'D', # delta
        917 => 'E', # epsilon
        918 => 'Z', # zeta
        919 => 'Î', # eta
        920 => 'TH', # theta
        921 => 'I', # jota
        922 => 'K', # kappa
        923 => 'L', # lambda
        924 => 'M', # mý
        925 => 'N', # ný
        926 => 'X', # xí
        927 => 'O', # omikron
        928 => 'P', # pí
        929 => 'R', # ró
        931 => 'S', # sigma
        932 => 'T', # tau
        933 => 'Y', # ypsilon
        934 => 'F', # fí
        935 => 'H', # chí
        936 => 'PS', # psí
        937 => 'Ô', # omega
        945 => 'a', # alfa
        946 => 'b', # beta
        947 => 'g', # gamma
        948 => 'd', # delta
        949 => 'e', # epsilon
        950 => 'z', # zeta
        951 => 'î', # eta
        952 => 'th', # theta
        953 => 'i', # jota
        954 => 'k', # kappa
        955 => 'l', # lambda
        956 => 'm', # mý
        957 => 'n', # ný
        958 => 'x', # xí
        959 => 'o', # omikron
        960 => 'p', # pí
        961 => 'r', # ró
        962 => 's', # sigma (koncová)
        963 => 's', # sigma
        964 => 't', # tau
        965 => 'y', # ypsilon
        966 => 'f', # fí
        967 => 'h', # chí
        968 => 'ps', # psí
        969 => 'ô', # omega
        # With dialytika
        938 => 'Ï',
        939 => 'Ÿ',
        970 => 'ï',
        971 => 'ÿ',
        # With tonos
        902 => 'Á',
        904 => 'É',
        905 => 'Î',
        906 => 'Í',
        908 => 'Ó',
        910 => 'Ý',
        911 => 'Ô',
        940 => 'á',
        941 => 'é',
        942 => 'î',
        943 => 'í',
        972 => 'ó',
        973 => 'ý',
        974 => 'ô',
        # With dialytika and tonos
        912 => 'í',
        944 => 'ý',
        # Archaic letters
        988 => 'V', # digamma / vau / 6
        989 => 'v',
        1010 => 's', # lunate sigma
    );
    foreach my $kod (keys(%greek))
    {
        $prevod->{chr($kod)} = $greek{$kod};
    }
    # Samohláskové spřežky v moderní řečtině
    $prevod->{'ΑΥ'} = 'AU'; # místo "AY"
    $prevod->{'Αυ'} = 'Au'; # místo "Ay"
    $prevod->{'αυ'} = 'au'; # místo "ay"
    $prevod->{'ΑΎ'} = 'AÚ'; # místo "AÝ"
    $prevod->{'Αύ'} = 'Aú'; # místo "Aý"
    $prevod->{'αύ'} = 'aú'; # místo "aý"
    $prevod->{'ΕΥ'} = 'EU'; # místo "EY"
    $prevod->{'Ευ'} = 'Eu'; # místo "Ey"
    $prevod->{'ευ'} = 'eu'; # místo "ey"
    $prevod->{'ΕΎ'} = 'EÚ'; # místo "EÝ"
    $prevod->{'Εύ'} = 'Eú'; # místo "Eý"
    $prevod->{'εύ'} = 'eú'; # místo "eý"
    $prevod->{'ΟΥ'} = 'OU'; # místo "OY"
    $prevod->{'Ου'} = 'Ou'; # místo "Oy"
    $prevod->{'ου'} = 'ou'; # místo "oy"
    $prevod->{'ΟΎ'} = 'OÚ'; # místo "OÝ"
    $prevod->{'Ού'} = 'Oú'; # místo "Oý"
    $prevod->{'ού'} = 'oú'; # místo "oý"
    return $prevod;
}



1;
