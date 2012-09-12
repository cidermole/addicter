#!/usr/bin/perl
# runs all alignment algorithms and error detection on them
# Copyright © 2012 Jan Berka, Dan Zeman
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
use FindBin qw($Bin);

sub usage {
        print STDERR ("Runs all alignment algorithms and applies error detection and classification of Addicter on them\n");
        print STDERR ("Usage:\nrundetection.pl --src=src_file --ref=reference_file  --hyp=hypothesis_file  [--work=workdir]\n");
        print STDERR ("\tOptional:\n");
        print STDERR ("\t--baseref=lemmatized_reference_file\n");
        print STDERR ("\t--basehyp=lemmatized_hypothesis_file\n");
}

sub saferun
{
        my ($cmd) = @_;
        my $result = system($cmd);
        if ($result != 0) {
                die("Command $cmd returned a non-zero status");
        }
}

GetOptions
(
    'src=s'     => \$srcfile,
    'ref=s'     => \$reffile,
    'hyp=s'     => \$hypfile,
    'baseref=s' => \$basereffile,
    'basehyp=s' => \$basehypfile,
    'work=s'    => \$workdir
);
unless($srcfile && $reffile && $hypfile)
{
    usage();
    die('Missing (src|ref|hyp)file');
}
# The baseref and basehyp files are needed by Hjerson to detect morphological errors.
# If we don't care for morphology or don't have a lemmatizer we will replace them by actual reference and hypothesis, respectively.
$basereffile = $reffile unless($basereffile);
$basehypfile = $hypfile unless($basehypfile);

my $scriptpath = $Bin; #dzsys::get_script_path();
my $tcpath = "$scriptpath/../testchamber";
$tcpath =~ s-/prepare/..--;
# Intermediate and output files:
my $tcalignment = "$workdir/test.refhyp.ali";
my $tcerrorlist = "$workdir/tcerr.txt";

# LCS
saferun("mkdir $workdir/LCS");
saferun("$tcpath/align-lcs.pl $reffile $hypfile > $workdir/LCS/test.refhyp.ali");
saferun("$scriptpath/detecter.pl -s $srcfile -r $reffile -h $hypfile -a $workdir/LCS/test.refhyp.ali -w $workdir/LCS");

# HMM
saferun("mkdir $workdir/HMM");
saferun("$tcpath/align-hmm.pl $reffile $hypfile > $workdir/HMM/test.refhyp.ali");
saferun("$scriptpath/detecter.pl -s $srcfile -r $reffile -h $hypfile -a $workdir/HMM/test.refhyp.ali -w $workdir/HMM");


# WER
saferun("mkdir $workdir/WER");
saferun("$tcpath/hjerson.py --ref $reffile --hyp $hypfile --baseref $basereffile --basehyp $basehypfile --ali $workdir/WER/test.refhyp.ali");
saferun("$scriptpath/detecter.pl -s $srcfile -r $reffile -h $hypfile -a $workdir/WER/test.refhyp.ali -w $workdir/WER");


# Greedy
saferun("mkdir $workdir/Greedy");
saferun("$tcpath/align-greedy.pl $reffile $hypfile > $workdir/Greedy/test.refhyp.ali");
saferun("$scriptpath/detecter.pl -s $srcfile -r $reffile -h $hypfile -a $workdir/Greedy/test.refhyp.ali -w $workdir/Greedy");
