#!/usr/bin/perl
#prevede vystup Hjersona do formatu pro Addicter

use utf8;

#binmode(STDOUT, ":utf8");
#binmode(STDERR, ":utf8");
#binmode(STDIN, ":utf8");
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
$xmltext .= "<document>\n\n";

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
		$xmltext .= "\t".'<source length="'.$srclength.'" text="'.sentenceToXml($srctext).'"/>'."\n";
	}
	$xmltext .= "\t".'<hypothesis length="'.$hyplength.'" text="'.sentenceToXml($hyptext).'"/>'."\n";
	$xmltext .= "\t".'<reference length="'.$reflength.'" text="'.sentenceToXml($reftext).'"/>'."\n";
	
	for (my $k=0;$k<=$#refwords;$k++)
	{
		my $rword = toXml($refwords[$k]);
		if ($referrs[$k] eq 'miss')
		{
			$xmltext .= "\t".'<missingRefWord idx="'.$k.'" surfaceForm="'.$rword.'" token="'.$rword.'"'."/>\n";
		}
		elsif ($referrs[$k] eq 'lex')
		{
			$xmltext .= "\t".'<otherMismatch refIdx="'.$k.'" surfaceForm="'.$rword.'" refToken="'.$rword.'"'."/>\n";
		}
	}
	
	for (my $k=0;$k<=$#hypwords;$k++)
	{
		my $hword = toXml($hypwords[$k]);
		if ($hyperrs[$k] eq 'ext')
		{
			$xmltext .= "\t".'<extraHypWord idx="'.$k.'" surfaceForm="'.$hword.'" token="'.$hword.'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'reord')
		{
			$xmltext .= "\t".'<reorderingError hypIdx="'.$k.'" surfaceForm="'.$hword.'" hypToken="'.$hword.'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'lex')
		{
			$xmltext .= "\t".'<otherMismatch hypIdx="'.$k.'" surfaceForm="'.$hword.'" hypToken="'.$hword.'"'."/>\n";
		}
		elsif ($hyperrs[$k] eq 'infl')
		{
			$xmltext .= "\t".'<inflectionalError hypIdx="'.$k.'" surfaceForm="'.$hword.'" hypToken="'.$hword.'"'."/>\n";
		}
	}
	
	
	
	$xmltext .= "</sentence>\n\n"
}

$xmltext .= '</document>';

print $xmltext;









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

# changes 'dangerous' characters (e.g <,>,',") to safe form (&lt; and so on)
sub toXml {
	my $word = shift;
	my @characters = split(//, $word);
	my $toReturn = '';
	for (my $n = 0; $n <= $#characters; $n++) {
		if ($characters[$n] eq '<') {
			 $toReturn .= '&lt;';
		}
		elsif ($characters[$n] eq '>') {
	                $toReturn .= '&gt;';
        	}
        	elsif ($characters[$n] eq '"') {
                	$toReturn .= '&quot;';
        	}
		else {
			$toReturn .= $characters[$n];
		}
	}
	return $toReturn;
}

sub sentenceToXml {
	my $sentence = shift;
	my @words = split(/ /, $sentence);
	my $toReturn = '';
	for (my $i = 0; $i <= $#words; $i++) {
		$toReturn .= toXml($words[$i]).' ';
	}
	return $toReturn;
}
