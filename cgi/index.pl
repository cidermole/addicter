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
use dzcgi;
use AddicterHTML;

# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("  <style>\n");
print("    a:link, a:visited { text-decoration: none }\n");
print("    a:hover { text-decoration: underline }\n");
print("    a.info {position:relative; z-index:24; background-color:#ccc; color:#000; text-decoration:none}\n");
print("    a.info:hover {z-index:25; background-color:#ff0}\n");
print("    a.info span {display: none}\n");
print("    a.info:hover span {display:block; position:absolute; top:2em; left:2em; width:15em; border:1px solid #0cf; background-color:#cff; color:#000; text-align:center; text-decoration:none}\n");
print("  </style>\n");
print("</head>\n");
print("<body>\n");
print("  <h1>Addicter</h1>\n");
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
    print("  <h1>Current Experiment: <span style='color:red'>$experiment</span></h1>\n");
    print("  <h2><a href='tcerrread.pl?experiment=$experiment'>Error Summary</a></h2>\n");
    print("  <table border='1'>\n");
    print("    <tr>\n");
    print("      <td valign=top style='background:yellow'>\n");
    print("        <h2><a href='browsetest.pl?experiment=$experiment'>Test Data Browser</a></h2>\n");
    my $ellipsis = chr(8230); # ...
    for(my $i = 1; $i<=4; $i++)
    {
        my $srcline = AddicterHTML::get_nth_line("$experiment/test.src", $i);
        my $tgtline = AddicterHTML::get_nth_line("$experiment/test.tgt", $i);
        $srcline = substr($srcline, 0, 80).$ellipsis if(length($srcline)>80);
        $tgtline = substr($tgtline, 0, 80).$ellipsis if(length($tgtline)>80);
        $srcline =~ s/\s/&nbsp;/g;
        $tgtline =~ s/\s/&nbsp;/g;
        print("        $srcline<br/>\n");
        print("        $tgtline<br/>\n");
    }
    print("      </td>\n");
    print("      <td valign=top style='background:lightblue'>\n");
    print("        <h2>Word Explorer</h2>\n");
    print("<form method=get action='index.pl'>\n");
    print("  SRC:\n");
    print("  <input type=hidden name=experiment value='$config{experiment}' />\n");
    print("  <input type=hidden name=lang value='s' />\n");
    my $default = $config{lang} eq 's' ? $config{re} : '';
    print("  <a class=info>\n");
    print("  <input type=text name=re value='$default' />");
    print("<span>Perl-style regular expression to search for source words</span></a>\n");
    print_start_letters($experiment, 's');
    print("</form>\n");
    print("<form method=get action='index.pl'>\n");
    print("  TGT:\n");
    print("  <input type=hidden name=experiment value='$config{experiment}' />\n");
    print("  <input type=hidden name=lang value='t' />\n");
    $default = $config{lang} eq 't' ? $config{re} : '';
    print("  <a class=info>\n");
    print("  <input type=text name=re value='$default' />");
    print("<span>Perl-style regular expression to search for target words</span></a>\n");
    print_start_letters($experiment, 't');
    print("</form>\n");
    print("      </td>\n");
    print("    </tr>\n");
    print("  </table>\n");
    if(exists($config{letter}))
    {
        print_words_by_letter($experiment, $config{lang}, $config{letter});
    }
    elsif(exists($config{re}))
    {
        # For safety reasons, the regular expression must not contain embedded code execution.
        my $re = $config{re};
        $re = '' if($re =~ m/\(\?\??\{/);
        if($re)
        {
            # Escape &<> in the regular expression. It is needed for displaying the RE.
            $re =~ s/&/&amp;/g;
            $re =~ s/</&lt;/g;
            $re =~ s/>/&gt;/g;
            print_words_matching_re($config{lang}, $re);
        }
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
    my $experiment = shift;
    # Which index to read? 's' or 't'?
    my $oprf = shift;
    # Do we want to print the introductory sentence, too?
    my $intro = shift;
    my $indexname = $oprf.'index.txt';
    # Read the master index (first letters of words).
    open(INDEX, "$experiment/$indexname") or print("<p style='color:red'>Cannot open $indexname!</p>\n");
    my $firstletters = <INDEX>;
    close(INDEX);
    $firstletters =~ s/\r?\n$//;
    my @firstletters = split(/\s+/, $firstletters);
    # Print list of words we can inspect.
    if($intro)
    {
        my $corpus_part = $oprf eq 's' ? 'source' : $oprf eq 't' ? 'target' : "<span style='color:red'>unknown</span>";
        print("  <p>The $corpus_part corpus contains words beginning in the following letters. Click on a letter to view the list of words beginning in that letter.</p>\n");
    }
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
    my $experiment = shift;
    my $lang = shift;
    my $letter = shift;
    # Which index file do we need?
    my $indexname = sprintf("$experiment/${lang}index%04x.txt", ord($letter));
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



#------------------------------------------------------------------------------
# Prints the list of words that match a regular expression.
#------------------------------------------------------------------------------
sub print_words_matching_re
{
    # Which index to read? 's' or 't'?
    my $oprf = shift;
    my $indexname = $oprf.'index.txt';
    my $re = shift;
    # Read the master index (first letters of words).
    open(INDEX, "$experiment/$indexname") or print("<p style='color:red'>Cannot open $indexname!</p>\n");
    my $firstletters = <INDEX>;
    close(INDEX);
    $firstletters =~ s/\r?\n$//;
    my @firstletters = split(/\s+/, $firstletters);
    # Loop over first letters, go through all index files.
    my %index;
    foreach my $fl (@firstletters)
    {
        my $indexname = sprintf("$experiment/$config{lang}index%04x.txt", ord($fl));
        open(INDEX, $indexname) or print("<p style='color:red'>Cannot open $indexname: $!</p>\n");
        while(<INDEX>)
        {
            s/\r?\n$//;
            my ($word, $sentences) = split(/\t/, $_);
            next unless($word =~ m/$re/);
            my @sentences = split(/\s+/, $sentences);
            $index{$word} = \@sentences;
        }
        close(INDEX);
    }
    # Show the words beginning in the regular expression first.
    # Chances are that the expression actually is the exact word the user is searching for.
    print("<p>Filter regular expression: <span style='color:green'>$re</span><br/>\n");
    my @words = sort(keys(%index));
    unless($re =~ m/^\^/)
    {
        my @words_beg = grep {$_ =~ m/^$re/} (@words);
        my @words_rest = grep {$_ !~ m/^$re/} (@words);
        my $nwb = scalar(@words_beg);
        my $nwr = scalar(@words_rest);
        my $swb = 's' unless($nwb==1);
        my $swr = 's' unless($nwr==1);
        my $veswr = 'es' if($nwr==1);
        print("Found $nwb word$swb whose prefix matches the RE and $nwr other word$swr that match$veswr the RE.</p>\n");
        @words = (@words_beg, @words_rest);
    }
    else
    {
        my $nw = scalar(@words);
        print("Found $nw words matching the RE.</p>\n");
    }
    foreach my $word (@words)
    {
        print("  <a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$word'>$word</a>\n");
    }
}
