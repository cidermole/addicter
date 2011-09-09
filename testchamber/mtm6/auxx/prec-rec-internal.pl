#!/usr/bin/perl
use strict;

my @fhs = openMany(@ARGV);

my $stats = {};
my $precRecs = {};

my $allFlags = {};

while (my $snts = readSentences(@fhs)) {
	my $sntMan = $snts->[0];
	my $sntAuto = $snts->[1];
	
	my @wordsMan = split(/ /, $sntMan);
	my @wordsAuto = split(/ /, $sntAuto);
	
	if ($#wordsMan != $#wordsAuto) {
		die("$#wordsMan != $#wordsAuto, wrong files probably");
	}
	
	for my $i (0..$#wordsMan) {
		my ($manFlags, $manSform) = getFlags($wordsMan[$i]);
		my ($autoFlags, $autoSform) = getFlags($wordsAuto[$i]);
		
		if (lc($manSform) ne lc($autoSform)) {
			die("Words in manual and automatic annotated files should match ($manSform != $autoSform)");
		}
		
		if (scalar keys %$manFlags > 1) {
			die("Many manual flags");
		}
		
		my @keys = keys %$manFlags;
		my $manFlag = shift @keys;
		
		$allFlags->{$manFlag} = 1;
		
		if ($autoFlags->{$manFlag}) {
			#$stats->{$manFlag}->{$manFlag}++;
			updateStats($stats, $precRecs, $manFlag, $manFlag);
		}
		else {
			for my $autoFlag (keys %$autoFlags) {
				$allFlags->{$autoFlag} = 1;
				
				#$stats->{$autoFlag}->{$manFlag}++;
				updateStats($stats, $precRecs, $autoFlag, $manFlag);
			}
		}
	}
}

my @flags = sort keys %$allFlags;

#header
print "||border=1\n";

printf "|| %15s ", "";

for my $headFlag (@flags) {
	printf "||! %8s", $headFlag;
}

print " ||\n";

#table
for my $autoFlag (@flags) {
	printf "||! %15s ", $autoFlag;
	
	for my $manFlag (@flags) {
		my $val = $stats->{$autoFlag}->{$manFlag};
		my $style = (($autoFlag eq $manFlag)? "!": "");
		printf "||$style %8d", $val;
	}
	
	print " ||\n";
}

#precisions and recalls
for my $types (['precision', 'prec'], ['recall', 'rec']) {
	printf("||! %14s ", $types->[0]);

	for my $manFlag (@flags) {
		printf("|| %7.2f",
			float($precRecs, $types->[1], $manFlag));
	}

	print " ||\n";
}

# f-score
printf("||! %14s ", 'f1-score');
for my $manFlag (@flags) {
	my $p = float($precRecs, 'prec', $manFlag);
	my $r = float($precRecs, 'rec', $manFlag);
	my $f = (2*$p*$r)/(($p+$r)||1);
	printf("|| %7.2f",$f);
}
print " ||\n";



printf STDERR "Total accuracy: %.3f\n", float($precRecs, 'all', 'all');

#####
#
#####
sub float {
	my ($db, $id, $flag) = @_;
	
	my $num = $db->{'correct-' . $id}->{$flag};
	my $denom = $db->{'total-' . $id}->{$flag};
	
	return (($denom == 0)? 0: $num/$denom);
}

#####
#
#####
sub updateStats {
	my ($stats, $precRecs, $autoFlag, $manFlag) = @_;
	
	$stats->{$autoFlag}->{$manFlag}++;
	
	my $updVal = (($autoFlag eq $manFlag)? 1: 0);
	
	$precRecs->{'correct-prec'}->{$autoFlag} += $updVal;
	$precRecs->{'total-prec'}->{$autoFlag}++;
	
	$precRecs->{'correct-rec'}->{$manFlag} += $updVal;
	$precRecs->{'total-rec'}->{$manFlag}++;
	
	$precRecs->{'correct-all'}->{'all'} += $updVal;
	$precRecs->{'total-all'}->{'all'}++;
}

#####
#
#####
sub getFlags {
	my ($word) = @_;
	
	my $result = {};
	
	my @parts = split(/~~/, $word);
	pop @parts;
	
	if (@parts > 0) {
		for my $k (@parts) {
			$result->{$k} = 1;
		}
	}
	else {
		$result->{'-'} = 1;
	}
	
	return $result;
}

#####
#
#####
sub noRead {
	die("Failed to open `" . $_[0] . "' for reading");
}

#####
#
#####
sub openRead {
	my $filename = shift;
	
	my $fh;
	
	open($fh, $filename) or noRead($filename);
	binmode($fh, ":utf8");
	
	return $fh;
}

#####
#
#####
sub openMany {
	my @fhs = ();
	for my $file (@_) {
		push @fhs, openRead($file);
	}
	return @fhs;
}

#####
#
#####
sub closeMany {
	for my $fh (@_) {
		close($fh);
	}
}

#####
#
#####
sub readSentence {
	my $fh = shift;
	
	my $string = <$fh>;
	
	if ($string) {
		$string =~ s/\n//g;
		$string =~ s/[ \t]{2,}/ /g;
		$string =~ s/^ //g;
		$string =~ s/ $//g;
		
		return $string;
	}
	else {
		return undef;
	}
}

#####
#
#####
sub readSentences {
	my @fhArr = @_;
	my @sntArr = ();
	
	my $allFinished = 1;
	my $allSucceeded = 1;
	
	for my $fh (@fhArr) {
		my $snt = readSentence($fh);
		
		if (defined($snt)) {
			$allFinished = undef;
		}
		else {
			$allSucceeded = undef;
		}
		
		push @sntArr, $snt;
	}
	
	if ($allSucceeded) {
		return \@sntArr;
	}
	elsif ($allFinished) {
		return undef;
	}
	else {
		die("Unequal number of lines in the input files");
	}
}
