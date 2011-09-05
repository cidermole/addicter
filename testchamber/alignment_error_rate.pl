#!/usr/bin/perl
# Expects '0-1 1-1 ... \t 0-2 1-1 ...' on stdin
# Emits alignment precision, recall and error rate.
# For now, all points are considered Sure, later the input in column 1
# (reference) would support 'S 0-0 1-1 P 0-1 ...'
# Ondrej Bojar, bojar@ufal.mff.cuni.cz

use strict;
use warnings;

my $tot_refsure = 0;
# my $tot_refposs = 0;
my $tot_hyp_cap_refsure = 0;
my $tot_hyp_cap_refposs = 0;
my $tot_hypcnt = 0;
while (<>) {
	s/ +/ /;
	s/^ //g;
	s/ $//g;
  chomp;
  my ($ref, $hyp) = split /\t/;
  my %hypset = map { die "Bad point $_" if $_ !~ /^[0-9]+-[0-9]+$/; ($_, 1) }
               split / /, $hyp;
  my %refsureset = map { die "Bad point $_" if $_ !~ /^[0-9]+-[0-9]+$/; ($_, 1) }
               split / /, $ref;
  my %refpossset = %refsureset;

  $tot_refsure += scalar keys %refsureset;
  # $tot_refposs += scalar keys %refpossset;

  $tot_hypcnt += scalar keys %hypset;

  my %hyp_cap_refsure = map { ($_, 1) } grep { $hypset{$_} } keys %refsureset;
  my %hyp_cap_refposs = map { ($_, 1) } grep { $hypset{$_} } keys %refpossset;

  $tot_hyp_cap_refsure += scalar keys %hyp_cap_refsure;
  $tot_hyp_cap_refposs += scalar keys %hyp_cap_refposs;
}

my $recall = $tot_hyp_cap_refsure / $tot_refsure;
my $precision = $tot_hyp_cap_refposs / $tot_hypcnt;

my $alignment_error_rate = 1 - ($tot_hyp_cap_refsure + $tot_hyp_cap_refposs) 
                           / ($tot_refsure + $tot_hypcnt);

printf "total sure alignment points in the ref\t$tot_refsure\n";
printf "total alignment points in the hyp\t$tot_hypcnt\n";

printf "rec\t%.2f\nprec\t%.2f\nAER\t%.2f\n",
  $recall*100, $precision*100, $alignment_error_rate*100;

