#!/usr/bin/perl
# runs Hjerson, gets from it the error categories and alignment and transforms it to Addicter html format
# Jan Berka 2012

sub usage {
	print STDERR ("Runs Hjerson, gets from it the error categories and alignment and transforms it to Addicter html format\n");
	print STDERR ("Usage:\nrunhjerson.pl --ref=reference_file --baseref=base_reference_file --hyp=hypothesis_file --basehyp=base_hypothesis_file [--src=source_file --work=workdir]\n");
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
use FindBin qw($Bin);

my $workdir = ' ';

GetOptions
(
    'src=s' => \$srcfile,
    'ref=s' => \$reffile,
    'baseref=s' => \$basereffile,
    'basehyp=s' => \$basehypfile,
    'hyp=s' => \$hypfile,
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
my $tcalignment = "$workdir/test.refhyp.ali";
my $tcerrorlist = "$workdir/tcerr.txt";

saferun("$tcpath/hjerson.py --ref $reffile --hyp $hypfile --baseref $basereffile --basehyp $basehypfile --ali $tcalignment --cats $workdir/test.cats");
saferun("cp $tcalignment $workdir/tcali.txt");
saferun("./hjersoner.pl hjersoner.pl --cat=$workdir/test.cats --ali=$workdir/test.refhyp.ali > $workdir/tcerr.txt");
