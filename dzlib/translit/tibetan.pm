#!/usr/bin/perl
# Funkce pro přípravu transliterace z tibetského písma do latinky.
# Copyright © 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package translit::tibetan;
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
    my %tibet =
    (
        3904 => 'k',
        3905 => 'kh',
        3906 => 'g',
        3907 => 'gh',
        3908 => 'ng',
        3909 => 'č',
        3910 => "čh",
        3911 => "dž",
        3913 => "ň",
        3914 => 'ţ',
        3915 => 'ţh',
        3916 => 'đ',
        3917 => 'đh',
        3918 => 'N',
        3919 => 't',
        3920 => 'th',
        3921 => 'd',
        3922 => 'dh',
        3923 => 'n',
        3924 => 'p',
        3925 => 'ph',
        3926 => 'b',
        3927 => 'bh',
        3928 => 'm',
        3929 => 'c',
        3930 => 'ch',
        3931 => 'dz',
        3932 => 'dzh',
        3933 => 'w',
        3934 => 'ž',
        3935 => 'z',
        3936 => "'",
        3937 => 'j',
        3938 => 'r',
        3939 => 'l',
        3940 => 'š',
        3941 => 'ś',
        3942 => 's',
        3943 => 'h',
        3944 => 'a',
        3945 => 'kś',
        3953 => 'á',
        3954 => 'i',
        3955 => 'í',
        3956 => 'u',
        3957 => 'ú',
        3958 => 'r',
        3959 => 'ŕ',
        3960 => 'l',
        3961 => 'ĺ',
        3962 => 'e',
        3963 => 'é',
        3964 => 'o',
        3965 => 'ó',
        3984 => ':k',
        3985 => ':kh',
        3986 => ':g',
        3987 => ':gh',
        3988 => ':ng',
        3989 => ':č',
        3990 => ':čh',
        3991 => ':dž',
        3993 => ':ň',
        3994 => ':ţ',
        3995 => ':ţh',
        3996 => ':đ',
        3997 => ':đh',
        3998 => ':N',
        3999 => ':t',
        4000 => ':th',
        4001 => ':d',
        4002 => ':dh',
        4003 => ':n',
        4004 => ':p',
        4005 => ':ph',
        4006 => ':b',
        4007 => ':bh',
        4008 => ':m',
        4009 => ':c',
        4010 => ':ch',
        4011 => ':dz',
        4012 => ':dzh',
        4013 => ':w',
        4014 => ':ž',
        4015 => ':z',
        4016 => ":'",
        4017 => ':j',
        4018 => ':r',
        4019 => ':l',
        4020 => ':š',
        4021 => ':ś',
        4022 => ':s',
        4023 => ':h',
        4024 => ':a',
        4025 => ':kś',
    );
    foreach my $kod (keys(%tibet))
    {
        $prevod->{chr($kod)} = $tibet{$kod};
    }
    return $prevod;
}



1;
