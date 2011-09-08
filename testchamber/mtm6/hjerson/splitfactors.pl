#!/usr/bin/perl -w

use strict;

my ($filename, @factors) = @ARGV;
my %indices = map {$_ => 1} @factors;

open(INFILE, "<$filename") or die "couldn't open '$filename' for read: $!\n";
while(my $line = <INFILE>)
{
	chop $line;
	print join(' ', map {my $i = 0; join('|', grep($indices{$i++}, split(/\|/, $_)))} split(/\s+/, $line)) . "\n";
}
close(INFILE);
