#!/usr/bin/perl
#prevede vystup Hjersona do formatu pro Addicter

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;

my ($catsfile, $alifile, $srcfile) = processInputArgsAndOpts();
open(DATA, $catsfile);
my @data = <DATA>;
close(DATA);

open(ALIDATA, $alifile);
my @alidata = <ALIDATA>;
close(ALIDATA);

my @srcdata;
if ($srcfile)
{
	open(SRCDATA, $srcfile);
	@srcdata = <SRCDATA>;
	close(SRCDATA);
}

my $xmltext = '';
$xmltext .= "<document>\n";

for (my $i=0;$i<$#data;$i+=3)
{
	my $ref = $data[$i];
	chomp $ref;
	my $hyp = $data[$i+1];
	chomp $hyp;
	my $ali = $alidata[$i/3];
	chomp $ali;
	
	my @reftokens = split(/ /, $ref);
	my @hyptokens = split(/ /, $hyp);
	
	my @firsttoken = split(/::/, $reftokens[0]);
	my $index = $firsttoken[0]-1;
	
	my @refwords;
	my @referrs;
	my @hypwords;
	my @hyperrs;
	
	for (my $j=1; $j<=$#reftokens; $j++)
	{
		my @token = split(/~~/, $reftokens[$j]);
		push(@refwords, $token[0]);
		push(@referrs, $token[1]);
	}
	for (my $j=1; $j<=$#hyptokens; $j++)
	{
		my @token = split(/~~/, $hyptokens[$j]);
		push(@hypwords, $token[0]);
		push(@hyperrs, $token[1]);
	}
	
	#dodelat src - musi se pridat na vstup zvlast
	if ($srcfile)
	{
		#my $srclength = ;
		#my $srctext = ;
	}
	my $reflength = $#refwords+1;
	my $reftext = join(' ', @refwords);
	my $hyplength = $#hypwords+1;
	my $hyptext = join(' ', @hypwords);
	
	$xmltext .= '<sentence index="'.$index.'">'."\n";
	if ($srcfile)
	{
		$xmltext .= "\t".'<source length="'.$srclength.'" text="'.$srctext.'"/>'."\n";
	}
	$xmltext .= "\t".'<hypothesis length="'.$hyplength.'" text="'.$hyptext.'"/>'."\n";
	$xmltext .= "\t".'<reference length="'.$reflength.'" text="'.$reftext.'"/>'."\n";
	
	for (my $k=0;$k<=$#refwords;$k++)
	{
		if ($referrs[$k] eq 'miss')
		{
			$xmltext .= "\t".'<missingRefWord idx="'.$k.'" surfaceForm="'.$refwords[$k].'" token="'.$refwords[$k].'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'lex')
		{
			$xmltext .= "\t".'<otherMismatch refIdx="'.$k.'" refToken="'.$hypwords[$k].'"'."/>\n";
		}
	}
	
	for (my $k=0;$k<=$#hypwords;$k++)
	{
		if ($hyperrs[$k] eq 'ext')
		{
			$xmltext .= "\t".'<extraHypWord idx="'.$k.'" surfaceForm="'.$hypwords[$k].'" token="'.$hypwords[$k].'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'reord')
		{
			$xmltext .= "\t".'<reorderingError hypIdx="'.$k.'" hypToken="'.$hypwords[$k].'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'lex')
		{
			$xmltext .= "\t".'<otherMismatch hypIdx="'.$k.'" hypToken="'.$hypwords[$k].'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'infl')
		{
			$xmltext .= "\t".'<inflectionalError hypIdx="'.$k.'" hypToken="'.$hypwords[$k].'"'."/>\n";
		}
	}
	
	
	
	$xmltext .= "</sentence>\n"
}

$xmltext .= '</document>';

print $xmltext;
print "\n";










#####################################
# SUBROUTINES
#####################################

sub processInputArgsAndOpts {
	my ($catsfile,$alifile,$srcfile);
	GetOptions
	(
		'cat=s' => \$catsfile,
		'ali=s' => \$alifile,
		'src=s' => \$srcfile
	);
	
	if (!$catsfile or !$alifile) {
		die("Required arguments: error categories file and alignment file");
	}
	return ($catsfile,$alifile,$srcfile);
}
