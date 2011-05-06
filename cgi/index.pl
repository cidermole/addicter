#!/usr/bin/perl
# Addicter CGI viewer
# Copyright © 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL
# 2011-05-05: Source and target index files separated.

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use lib 'C:\Documents and Settings\Dan\Dokumenty\Lingvistika\lib';
use lib '/home/zeman/lib';
use dzcgi;

# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("</head>\n");
print("<body>\n");
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>");
print("  <h1>Addicter: explore words in training corpus</h1>\n");
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
# Get list of subfolders that should contain index files of experiments.
$subfolders = get_subfolders();
if(scalar(@{$subfolders}))
{
    print("  <p>Select experiment to analyze: ", join(' | ', map {"<a href='index.pl?experiment=$_'>$_</a>"} (@{$subfolders})), "</p>\n");
}
else
{
    print("  <p style='color:red'>No experiments to analyze.</p>\n");
}
if(exists($config{experiment}))
{
    # Path to experiment we are analyzing (can be relative to the location of this script).
    $experiment = $config{experiment};
    if(!exists($config{letter}))
    {
        print_start_letters('s');
        print_start_letters('t');
    }
    else
    {
        print_words_by_letter();
    }
}
# Close the HTML document.
print("</body>\n");
print("</html>\n");



###############################################################################
# SUBROUTINES
###############################################################################



#------------------------------------------------------------------------------
# Scans the current folder for subfolders with index files of various
# experiments.
#------------------------------------------------------------------------------
sub get_subfolders
{
    opendir(DIR, '.') or print("<p style='color:red'>Cannot read current folder: $!</p>\n");
    my @subfolders = grep {-d $_ && !m/^\./} (readdir(DIR));
    closedir(DIR);
    return \@subfolders;
}



#------------------------------------------------------------------------------
# Reads an index (source or target) and prints the list of start letters of
# words in that index.
#------------------------------------------------------------------------------
sub print_start_letters
{
    # Which index to read? 's' or 't'?
    my $oprf = shift;
    my $indexname = $oprf.'index.txt';
    # Read the master index (first letters of words).
    open(INDEX, "$experiment/$indexname") or print("<p style='color:red'>Cannot open $indexname!</p>\n");
    my $firstletters = <INDEX>;
    close(INDEX);
    $firstletters =~ s/\r?\n$//;
    my @firstletters = split(/\s+/, $firstletters);
    # Print list of words we can inspect.
    my $corpus_part = $oprf eq 's' ? 'source' : $oprf eq 't' ? 'target' : "<span style='color:red'>unknown</span>";
    print("  <p>The $corpus_part corpus contains words beginning in the following letters. Click on a letter to view the list of words beginning in that letter.</p>\n");
    foreach my $letter (@firstletters)
    {
        print("  <a href='index.pl?experiment=$experiment&amp;lang=$oprf&amp;letter=$letter'>$letter</a>\n");
    }
}



#------------------------------------------------------------------------------
# Reads an index (source or target) and prints the list of words that start
# with a given letter in that index.
#------------------------------------------------------------------------------
sub print_words_by_letter
{
    # Which index file do we need?
    my $indexname = sprintf("$experiment/$config{lang}index%04x.txt", ord($config{letter}));
    my %index;
    open(INDEX, $indexname) or print("<p style='color:red'>Cannot open $indexname: $!</p>\n");
    while(<INDEX>)
    {
        s/\r?\n$//;
        my ($word, $sentences) = split(/\t/, $_);
        my @sentences = split(/\s+/, $sentences);
        $index{$word} = \@sentences;
    }
    close(INDEX);
    foreach my $word (sort(keys(%index)))
    {
        print("  <a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$word'>$word</a>\n");
    }
}
