#!/usr/bin/perl
# Applies the error detecting and labeling stuff to an experiment.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Parts based on this code by Mark Fishel:
# https://svn.ms.mff.cuni.cz/svn/statmt/trunk/addicter/testchamber/mtm-addicter.sh
# License: GNU GPL

sub usage
{
    print STDERR ("Applies the error detection and classification on an experiment\n");
    print STDERR ("detecterr.pl -s srcfile -r reffile -h hypfile [-a alignment] [-w workdir]\n");
}

sub saferun 
{
	my ($cmd) = @_;
	my $result = system($cmd);
	if ($result != 0) {
		die("Command $cmd returned a non-zero status");
	}
}

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
#use dzsys;
use FindBin qw($Bin);

my $workdir = '.';
GetOptions
(
    'src=s' => \$srcfile,
    'ref=s' => \$reffile,
    'hyp=s' => \$hypfile,
    'ali=s' => \$alifile,
    'work=s' => \$workdir
);
unless($reffile && $hypfile)
{
    usage();
    die('Missing (ref|hyp)file');
}
my $scriptpath = $Bin; #dzsys::get_script_path();
my $tcpath = "$scriptpath/../testchamber";
$tcpath =~ s-/prepare/..--;
# Intermediate and output files:
my $tcalignment = "$workdir/tcali.txt";
my $tcerrorlist = "$workdir/tcerr.txt";
# if source is not given, generate a dummy source file
unless($srcfile)
{
    $srcfile = "$workdir/src.txt";
    open(H, $hypfile) or die("Cannot read $hypfile: $!");
    open(S, ">$srcfile") or die("Cannot write $srcfile: $!");
    while(<H>)
    {
        print S ("(dummy text)\n");
    }
    close(H);
    close(S);
}
# Align the hypothesis with the reference translation, unless custom alignment has been provided.
if($alifile)
{
    open(A, $alifile) or die("Cannot read $alifile: $!");
    open(TCA, ">$tcalignment") or die("Cannot write $tcalignment: $!");
    while(<A>)
    {
        print TCA;
    }
    close(A);
    close(TCA);
}
else
{
    saferun("$tcpath/align-greedy.pl $reffile $hypfile > $tcalignment");
}

# Find and classify translation errors based on the texts and the alignment.
saferun("$tcpath/finderrs.pl $srcfile $hypfile $reffile $tcalignment > $tcerrorlist");

# Summarize errors. Result: file 'summary'.
saferun("cat $tcerrorlist | $tcpath/err2hjerson.pl | $tcpath/summarize-errors.pl");
