#!/usr/bin/perl
use strict;

my @files = @ARGV;

my $fhs = openfiles(\@files);

while (my $lineSet = readlines($fhs)) {
	printset($lineSet);
}

closefiles($fhs);

#####
#
#####
sub openfiles {
	my ($filenames) = @_;
	my @fhs = ();
	
	for my $filename (@$filenames) {
		my $fh;
		open($fh, $filename) or die("Failed to open `$filename' for reading");
		push @fhs, $fh;
	}
	
	return \@fhs;
}

#####
#
#####
sub readlines {
	my ($fhs) = @_;
	
	my ($allFinished, $allRead) = (1, 1);
	my @result = ();
	
	for my $fh (@$fhs) {
		my $line = <$fh>;
		$line =~ s/\n//g;
		
		if ($line) {
			$allFinished = undef;
		}
		else {
			$allRead = undef;
		}
		
		push @result, $line;
	}
	
	if ($allFinished) {
		return undef;
	}
	
	if ($allRead) {
		return \@result;
	}
	
	die("Some files ended prematurely");
}

#####
#
#####
sub printset {
	my ($snts) = @_;
	
	my $joint;
	my $toOutput;
	
	for my $snt (@$snts) {
		my @words = split(/ /, $snt);
		for my $i (0..$#words) {
			push @{$joint->[$i]}, $words[$i];
		}
	}
	
	for my $word (@$joint) {
		push @$toOutput, join("|", @$word);
	}
	
	print join(" ", @$toOutput);
	print "\n";
}

#####
#
#####
sub closefiles {
	my ($fhs) = @_;
	
	for my $fh (@$fhs) {
		close($fh);
	}
}
