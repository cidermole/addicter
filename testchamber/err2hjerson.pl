#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	# include packages from same folder where the
	# script is, even if launched from elsewhere
	# unshift(), not push(), to give own functions precedence over other libraries
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	unshift(@INC, File::Spec->catdir(@dirs));
}

use parse;
use io;
use flagg;

my ($hypSnt, $refSnt, $sntIdx);

my $filename = (scalar @ARGV == 0)? "-": $ARGV[0];

my $fh = io::openRead($filename);
binmode(STDOUT, ":utf8");

while (<$fh>) {
	my $tag = parse::xml($_);
	
	if (defined($tag)) {
		my $tagId = $tag->{'id'};
		my $fields = $tag->{'fields'};
		
		if ($tagId eq "hypothesis") {
			$hypSnt = flagg::convertFromFactored(parse::sentence($fields->{'text'}));
		}
		elsif ($tagId eq "reference") {
			$refSnt = flagg::convertFromFactored(parse::sentence($fields->{'text'}));
		}
		elsif ($tagId eq "missingRefWord") {
			setFlag($refSnt, $fields->{'idx'}, "miss");
		}
		elsif ($tagId eq "extraHypWord" or $tagId eq "untranslatedHypWord") {
			setFlag($hypSnt, $fields->{'idx'}, "ext");
		}
		elsif ($tagId eq "unequalAlignedTokens") {
			if ($fields->{'unequalFactorList'} =~ /0/) {
				my $flagtag = ($fields->{'unequalFactorList'} =~ /2/)? 'lex': 'infl';
				
				setFlag($hypSnt, $fields->{'hypIdx'}, $flagtag);
				setFlag($refSnt, $fields->{'refIdx'}, $flagtag);
			}
		}
		elsif ($tagId eq "ordErrorSwitchWords") {
			setFlag($hypSnt, $fields->{'hypIdx1'}, 'reord');
			setFlag($refSnt, $fields->{'refIdx1'}, 'reord');
			setFlag($hypSnt, $fields->{'hypIdx2'}, 'reord');
			setFlag($refSnt, $fields->{'refIdx2'}, 'reord');
		}
		elsif ($tagId eq "ordErrorShiftWord") {
			setFlag($hypSnt, $fields->{'hypPos'}, 'reord');
			setFlag($refSnt, $fields->{'refPos'}, 'reord');
		}
		elsif ($tagId eq "sentence") {
			$sntIdx = $fields->{'index'};
		}
		elsif ($tagId eq "/sentence") {
			print "" . ($sntIdx + 1) . "::ref-err-cats: ";
			flagg::display($refSnt, 1);
			print "" . ($sntIdx + 1) . "::hyp-err-cats: ";
			flagg::display($hypSnt, 1);
			print "\n";
		}
	}
}

#####
#
#####
sub setFlag {
	my ($hypSnt, $idx, $flag) = @_;
	
	$hypSnt->{'hyp'}->[$idx]->{'flags'}->{$flag} = 1;
}
