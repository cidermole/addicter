#!/usr/bin/perl
# Applies the error detecting and labeling stuff to an experiment.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

sub usage
{
    print STDERR ("detecterr.pl -s srcfile -r reffile -h hypfile [-w workdir]\n");
}

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
use dzsys;

my $workdir = '.';
GetOptions
(
    'src=s' => \$srcfile,
    'ref=s' => \$reffile,
    'hyp=s' => \$hypfile,
    'work=s' => \$workdir
);
unless($srcfile && $reffile && $hypfile)
{
    usage();
    die('Missing (src|ref|hyp)file');
}
my $scriptpath = dzsys::get_script_path();
my $tcpath = "$scriptpath/../testchamber";
$tcpath =~ s-/prepare/..--;
# Intermediate and output files:
my $tcalignment = "$workdir/tcali.txt";
my $tcerrorlist = "$workdir/tcerr.txt";
# Align the hypothesis with the reference translation.
dzsys::saferun("$tcpath/align-hmm.pl $reffile $hypfile > $tcalignment") or die;
# Find and classify translation errors based on the texts and the alignment.
dzsys::saferun("$tcpath/finderrs.pl $srcfile $hypfile $reffile $tcalignment > $tcerrorlist") or die;
# Summarize errors. Result: file 'summary'.
dzsys::saferun("$tcpath/errsummary.pl $tcerrorlist") or die;
