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

my ($srcSnt, $refSnt, $hypSnt);

my $filename = (scalar @ARGV == 0)? "-": $ARGV[0];

my $fh = io::openRead($filename);
binmode(STDOUT, ":utf8");

while (<$fh>) {
	my $tag = parse::xml($_);
	
	if (defined($tag)) {
		my $tagId = $tag->{'id'};
		my $fields = $tag->{'fields'};
		
		if ($tagId eq "source") {
			$srcSnt = parse::sentence($fields->{'text'});
		}
		elsif ($tagId eq "reference") {
			$refSnt = parse::sentence($fields->{'text'});
		}
		elsif ($tagId eq "hypothesis") {
			$hypSnt = flagg::convertFromFactored(parse::sentence($fields->{'text'}));
		}
		elsif ($tagId eq "missingRefWord") {
			$hypSnt->{'missed'}->{$fields->{'token'}}++;
		}
		elsif ($tagId eq "extraHypWord") {
			setMaybeFlag($hypSnt, $fields->{'idx'}, "extra", $fields->{'token'});
		}
		elsif ($tagId eq "untranslatedHypWord") {
			setMaybeFlag($hypSnt, $fields->{'idx'}, "unk", $fields->{'token'});
		}
		elsif ($tagId eq "unequalAlignedTokens") {
			#TODO currently defaults to form::, support lex:: and disam::
			setMaybeFlag($hypSnt, $fields->{'hypIdx'}, "form", $fields->{'hypToken'});
		}
		elsif ($tagId eq "ordErrorSwitchWords") {
			setMaybeFlag($hypSnt, $fields->{'hypIdx1'}, 'ows', $fields->{'hypToken1'}, 1);
			setMaybeFlag($hypSnt, $fields->{'hypIdx2'}, 'ows', $fields->{'hypToken2'}, 1);
		}
		elsif ($tagId eq "ordErrorShiftWord") {
			setMaybeFlag($hypSnt, $fields->{'hypPos'}, 'owl', $fields->{'hypToken'}, 1);
		}
		elsif ($tagId eq "/sentence") {
			flagg::display($hypSnt);
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
