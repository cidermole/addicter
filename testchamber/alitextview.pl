#!/usr/bin/perl
# Reads: src sent \t tgt sent \t alignment
# Prints beautiful tables in plain text.
# Source words are on lines, target words are on columns.
# Ondrej Bojar, bojar@ufal.mff.cuni.cz

use strict;
use Getopt::Long;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $hack_bad_ali = 0;
GetOptions(
  "hack-bad-alignments" => \$hack_bad_ali, # add extra words if needed
) or exit 1;

my %lettercombs = qw(
SURE            	*
POSSIBLE        	o
PHRASAL         	O
PHRASAL,SURE    	@
PHRASAL,POSSIBLE	?
);

my $nr = 0;
while (<>) {
  $nr++;
  chomp;
  my ($src, $tgt, $alistr) = split /\t/;
  my @src = split / /, trim($src);
  my @tgt = split / /, trim($tgt);

  my @ali = ();
  my $type = "SURE";
  foreach my $pair (split(/ /, trim($alistr))) {
    if ($pair =~ /-/) {
      my ($a, $b) = split /-/, $pair;
      if ($hack_bad_ali) {
        if ($a > $#src) {
          my $needws = $a-$#src;
          push @src, map { "HACK" } (1..$needws);
          print STDERR "$nr:Hacking src sent to show bad alignment point $pair\n";
        }
        if ($b > $#tgt) {
          my $needws = $b-$#tgt;
          push @tgt, map { "HACK" } (1..$needws);
          print STDERR "$nr:Hacking tgt sent to show bad alignment point $pair\n";
        }
      } else {
        die "$nr:Bad alignment point $pair: out of source sent" if $a > $#src;
        die "$nr:Bad alignment point $pair: out of target sent" if $b > $#tgt;
      }
      $ali[$a][$b]->{$type} = 1;
    } else {
      # setting ali type
      $type = $pair;
    }
  }
  
  my $srcmaxlen = 0;
  foreach my $w (@src) {
    my $len = length($w);
    $srcmaxlen = $len if $len > $srcmaxlen;
  }

  # print the table
  for(my $sw=0; $sw < @src; $sw++) {
    printf "%${srcmaxlen}s ", $src[$sw]; # source word
    for(my $tw=0; $tw < @tgt; $tw++) {
      if (defined $ali[$sw][$tw]) {
        my $typemix = join(",", sort {$a cmp $b} keys %{$ali[$sw][$tw]});
        my $mark = $lettercombs{$typemix};
        die "$nr:Bad type mix: $typemix" if ! defined $mark;
        print $mark;
      } else {
        print "-";
      }
      print " ";
    }
    print "\n";
  }
  # print target words
  my @occupied_to; # which line is occupied till
  my $outchars; # bidim array of chars
  for(my $tw=0; $tw < @tgt; $tw++) {
    my @tw = split //, $tgt[$tw];
    my $twlen = scalar @tw;
    my $xpos = $tw*2;
    # find first line where $tw can start
    my $emptyline = 0;
    for($emptyline = 0; $emptyline < @occupied_to; $emptyline++) {
      # print "considering $tgt[$tw] at $emptyline; occupied to $occupied_to[$emptyline]\n";
      last if $occupied_to[$emptyline] <= $xpos;
    }
    # print "PLACING $tgt[$tw] at xpos $xpos, line $emptyline\n";
    # place $tw on line $emptyline at $xpos
    for(my $i=0; $i<@tw; $i++) {
      $outchars->[$emptyline]->[$xpos+$i] = $tw[$i];
    }
    $occupied_to[$emptyline] = $xpos+$twlen+1;
  }
  my $prefix = " " x $srcmaxlen;
  $prefix .= " ";
  foreach my $line (@{$outchars}) {
    print $prefix;
    print join("", map { defined $_ ? $_ : " " } @{$line})."\n";
  }


  print "\n";
}

sub trim {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
}
