#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use parse;
use io;
use flagg;

our @mainkeys = (qw(punct miss extr untr lex-dis diffpos infl ord-s ord-l));

#my $hypSnt;
my $stats = {};

#my $filename = (scalar @ARGV == 0)? "-": $ARGV[0];
my $filename = "-";

my $fh = io::openRead($filename);
binmode(STDOUT, ":utf8");

print STDERR join(",", @mainkeys) . "\n";

while (<$fh>) {
	if ($ARGV[0] eq "empty") {
		print join(",", map { 0 } @mainkeys) . ",0.0000\n";
	}
	else {
		my $tag = parse::xml($_);
		
		if (defined($tag)) {
			my $tagId = $tag->{'id'};
			my $fields = $tag->{'fields'};
			
			if ($tagId eq "sentence") {
				$stats = {};
			}
			elsif ($tagId eq "hypothesis") {
			#	$hypSnt = flagg::convertFromFactored(parse::sentence($fields->{'text'}));
				$stats->{'length'} = 0 + $fields->{'length'};
			}
			elsif ($tagId =~ /^(missingRefWord|extraHypWord|untranslatedHypWord)$/) {
				my $errType = undef;
				
				if (tokIsPunct($fields->{'token'})) {
					$errType = 'punct';
				}
				else {
					$errType = substr($tagId, 0, 4); # 'miss'/'extr'/'untr'
				}
				
				$stats->{$errType}++;
			}
			elsif ($tagId eq "unequalAlignedTokens") {
				my %uneqs = map { $_ + 0 => 1 } split(/,/, $fields->{'unequalFactorList'});
				
				my $errType = undef;
				
				if (tokIsPunct($fields->{'hypToken'}) or tokIsPunct()) {
					$errType = 'punct';
				}
				elsif ($uneqs{2}) {
					$errType = 'lex-dis';
				}
				elsif ($uneqs{1}) {
					$errType = 'diffpos';
				}
				else {
					$errType = 'infl';
				}
				
				$stats->{$errType}++;
			}
			elsif ($tagId eq "ordErrorSwitchWords") {
				my $errType = undef;
				
				if (tokIsPunct($fields->{'hypToken1'}) or tokIsPunct($fields->{'hypToken2'})) {
					$errType = 'punct';
				}
				else {
					$errType = 'ord-s';
				}
				
				$stats->{$errType}++;
			}
			elsif ($tagId eq "ordErrorShiftWord") {
				my $errType = undef;
				
				if (tokIsPunct($fields->{'hypToken'})) {
					$errType = 'punct';
				}
				else {
					$errType = 'ord-l';
				}
				
				$stats->{$errType}++;
			}
			elsif ($tagId eq "/sentence") {
				displayStats($stats);
			}
		}
	}
}

#####
#
#####
sub setMaybeFlag {
	my ($hypSnt, $idx, $flag, $rawToken, $override) = @_;
	
	if (!$override) {
		my $surForm = io::getWordFactor($hypSnt->{'hyp'}->[$idx]->{'factors'}, 0);
		my $pos = io::getWordFactor(parse::token($rawToken, 1));
		
		if ($surForm =~ /^[[:punct:]]+$/ or $pos eq "punct" or $pos eq "P") {
			$flag = "punct";
		}
	}
	
	$hypSnt->{'hyp'}->[$idx]->{'flags'}->{$flag} = 1;
}

#####
#
#####
sub displayStats {
	my ($stats) = @_;
	
	my @out = ();
	
	for my $k (@mainkeys) {
		push @out, sprintf("%.4f", ($stats->{'length'}? $stats->{$k} / $stats->{'length'}: 0));
	}
	
	push @out, "0.0000";
	
	print join(",", @out) . "\n";
}

#####
#
#####
sub tokIsPunct {
	my ($tok) = @_;
	
	my ($surf) = split(/\|/, $tok);
	
	return ($surf =~ /^[[:punct:]]+$/);
}
