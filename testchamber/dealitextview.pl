#!/usr/bin/perl
# Converts the output of alitextview.pl back to 0-1 ...
# Any other char than '-' in the alignment is treated as an alignment point.
# Ondrej Bojar, bojar@ufal.mff.cuni.cz

use strict;
use warnings;

binmode(STDIN, "utf8");
binmode(STDOUT, "utf8");
binmode(STDERR, "utf8");

my @lines = ();
my $rowlabelwidth = 0;
my $expected_points = undef;
my $nr = 0;
while (<>) {
  $nr++;
  chomp;
  if (/^$/) {
    resolve(\@lines) if 0 < scalar @lines;
    @lines = ();
    $rowlabelwidth = 0;
    $expected_points = undef;
    next;
  }
  if (0 == $rowlabelwidth && /^( *[^ ]+ )/) {
    # get the rowlabel width
    $rowlabelwidth = length($1);
  }
  # remove the rowlabel
  my $rowlabel = substr($_, 0, $rowlabelwidth, "");
  # print STDERR "RL '$rowlabel' LEFT '$_'\n";
  next if $rowlabel =~ /^\s*$/; # skip collabel lines
  my @points = split / /, $_;
  my $points = scalar @points;
  $expected_points = $points if !defined $expected_points;
  die "$nr:Bad line, expected $expected_points, got $points"
    if $points != $expected_points;
  push @lines, [ @points ];
  # print STDERR "POINTS @points\n";
}
resolve(\@lines) if 0 < scalar @lines;

sub resolve {
  my $lines = shift;
  my @outpoints;
  
  my $hasManualCorrections = '';
  
  for(my $r = 0; $r < scalar(@$lines); $r++) {
    my @points = @{$lines->[$r]};
    for(my $c = 0; $c < scalar(@{$lines->[$r]}); $c++) {
      if ($lines->[$r]->[$c] ne "-") {
        if ($lines->[$r]->[$c] ne "*") {
          #$hasManualCorrections = 'M ';
		  }
        push @outpoints, $r."-".$c;
      }
    }
  }
  print "$hasManualCorrections @outpoints\n";
}
