#!/usr/bin/perl
# Addicter CGI viewer
# Copyright © 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL
# 2010-06-28: New parameter lang=s|t selects language for words that appear on both sides (e.g. 'USA').
# 2011-05-05: Source and target index files separated.

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use dzcgi;
use translit;
use translit::brahmi;
use AddicterHTML;

# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("</head>\n");
print("<body>\n");
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>");
# 0x900: Písmo devanágarí.
translit::brahmi::inicializovat(\%prevod, 2304, 1);
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
if(exists($config{experiment}))
{
    # Path to experiment we are analyzing (can be relative to the location of this script).
    $experiment = $config{experiment};
    print("<h1>$config{word}</h1>\n");
    # Figure out the name of the index file.
    $config{word} =~ m/^(.)/;
    $fl = $1;
    $indexname = sprintf("$experiment/$config{lang}index%04x.txt", ord($fl));
    # Read the index.
    open(INDEX, $indexname) or print("<p style='color:red'>Cannot open $indexname: $!</p>\n");
    while(<INDEX>)
    {
        # Chop off the line break.
        s/\r?\n$//;
        # Tab is the field separator.
        my @fields = split(/\t/, $_);
        my $word = shift(@fields);
        my @links = map {m/^(\w+):(\d+):(.*)$/; {'file' => $1, 'line' => $2, 'aliphrase' => $3}} (@fields);
        $index{$word} = \@links;
    }
    close(INDEX);
    # Print the first sentence pair where the word occurs.
    if(exists($index{$config{word}}))
    {
        my @examples;
        if($config{filter} eq 'tr')
        {
            @examples = grep {$_->{file} =~ m/^(TRS|TRT)$/} (@{$index{$config{word}}});
        }
        elsif($config{filter} eq 'r')
        {
            @examples = grep {$_->{file} =~ m/^(S|R)$/} (@{$index{$config{word}}});
        }
        elsif($config{filter} eq 'h')
        {
            @examples = grep {$_->{file} =~ m/^(S|H)$/} (@{$index{$config{word}}});
        }
        else
        {
            @examples = @{$index{$config{word}}};
        }
        my $numsnt = scalar(@examples);
        ###!!! Just testing how the styles work...
        print("<style>span.x:hover {color:green}</style>\n");
        my $plural = $numsnt>1 ? 's' : '';
        print("<p>Examples <span class='x'>of</span> the word in the <span class='x'>$config{filter}</span> data:\n");
        print("   The word '$config{word}' occurs in $numsnt sentence$plural.\n");
        if($numsnt>0)
        {
            my $example;
            my @links;
            if($config{exno}>=0 && $config{exno}<=$#examples)
            {
                $example = $examples[$config{exno}];
                if($config{exno}>0)
                {
                    my $prevexno = $config{exno}-1;
                    ###!!! all parameters should be preserved, not just filter
                    push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;exno=$prevexno&amp;filter=$config{filter}'>previous</a>");
                }
                if($config{exno}<$#examples)
                {
                    my $nextexno = $config{exno}+1;
                    ###!!! all parameters should be preserved, not just filter
                    push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;exno=$nextexno&amp;filter=$config{filter}'>next</a>");
                }
            }
            else
            {
                $example = $examples[0];
                if($#examples>0)
                {
                    ###!!! all parameters should be preserved, not just filter
                    push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;exno=1&amp;filter=$config{filter}'>next</a>");
                }
            }
            # So what do we need to read?
            my $sntno = $example->{line};
            # In the index files, the first sentence has index 0. However, we present it to the user as the sentence no. 1,
            # and so does also the get_nth_line() function work.
            $sntno++;
            my ($srcfile, $tgtfile, $alifile);
            if($example->{file} eq 'TRS' || $example->{file} eq 'TRT')
            {
                $srcfile = 'TRS';
                $tgtfile = 'TRT';
                $alifile = 'TRA';
            }
            elsif($example->{file} eq 'S' || $example->{file} eq 'R')
            {
                $srcfile = 'S';
                $tgtfile = 'R';
                $alifile = 'RA';
            }
            else
            {
                $srcfile = 'S';
                $tgtfile = 'H';
                $alifile = 'HA';
            }
            print("   This is the sentence number $example->{line} in file $example->{file}.</p>\n");
            ###!!! We should read this from the index file.
            my $path = "$experiment/";
            # my $path = 'C:\Documents and Settings\Dan\Dokumenty\Lingvistika\Projekty\addicter\';
            my %files =
            (
                'TRS' => "${path}train.src",
                'TRT' => "${path}train.tgt",
                'TRA' => "${path}train.ali",
                'S'   => "${path}test.src",
                'R'   => "${path}test.tgt",
                'H'   => "${path}test.system.tgt",
                'RA'  => "${path}test.ali",
                'HA'  => "${path}test.system.ali"
            );
            print(sentence_to_table(\%files, $sntno, $srcfile, $tgtfile, $alifile));
            # Print links to adjacent examples.
            ###!!! Add links to filters: training only, test/reference, test/hypothesis.
            push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;filter=tr'>training data only</a>");
            push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;filter=r'>test/reference</a>");
            push(@links, "<a href='example.pl?experiment=$experiment&amp;lang=$config{lang}&amp;word=$config{word}&amp;filter=h'>test/hypothesis</a>");
            if(scalar(@links))
            {
                my $links = join(' | ', @links);
                print("<p>$links</p>\n");
            }
            # Compute and print summary of alignments.
            my %alicps;
            foreach my $occ (grep {$_->{file} ne 'PT'} (@examples))
            {
                my $acp = $occ->{aliphrase};
                # Transliteration needed? If $occ is source, then aliphrase is target, i.e. Hindi.
                if($occ->{file} eq 'TRS' || $occ->{file} eq 'S')
                {
                    my $translit = translit::prevest(\%prevod, $acp);
                    # Punctuation etc. would not differ after transliteration, so check if it made a difference.
                    if($translit ne $acp)
                    {
                        $acp = "$acp / $translit";
                    }
                }
                $alicps{$acp}++;
            }
            my @alicps = sort {$alicps{$b} <=> $alicps{$a}} (keys(%alicps));
            print("<h2>Alignment summary</h2>\n");
            my $n = 0;
            my $list;
            for(my $i = 0; $i<=$#alicps; $i++)
            {
                my $acp = $alicps[$i];
                my $c = $alicps{$acp};
                $n += $c;
                if($i<20)
                {
                    $list .= '  <li>'.AddicterHTML::word_to_link($experiment, swaplang(), $acp)." ($c)</li>\n";
                }
            }
            print("<p>The word '$config{word}' occurred $n times and got aligned to ", scalar(@alicps), " distinct words/phrases. The most frequent ones follow (with frequencies):</p>\n");
            print("<ol>\n");
            print($list);
            print("</ol>\n");
            @examples = grep {$_->{file} =~ m/^PT$/} (@{$index{$config{word}}});
            if(scalar(@examples))
            {
                print("<h2>Phrase table</h2>\n");
                # A phrase table may be huge (millions of lines) and we cannot seek every example from scratch.
                # So we cannot use AddicterHTML::get_nth_line().
                print("<table border>\n");
                my $phrase_table = $path.'phrase_table.txt';
                open(IN, $phrase_table) or print("<p style='color:red'>Cannot read $phrase_table: $!</p>\n");
                my $i_example = 0;
                my $i_line = 0;
                while(my $line = <IN>)
                {
                    if($i_line==$examples[$i_example]->{line})
                    {
                        # Chop off the line break.
                        $line =~ s/\r?\n$//;
                        # Fields are separated by three vertical bars.
                        # List of fields: left hand side ||| source right hand side ||| target right hand side ||| weights
                        # Example:
                        # [X] ||| 100 [X,1] du [X,2] ||| 100 [X,1] of the [X,2] ||| 0.30103 1.0637686 1.1094114
                        my @fields = split(/\s*\|\|\|\s*/, $line);
                        my $ie = $i_example+1;
                        my $il = $i_line+1;
                        print("  <tr><td>$ie</td><td>$il</td><td>".join('</td><td>', @fields)."</td></tr>\n");
                        $i_example++;
                        last if($i_example>$#examples);
                    }
                    $i_line++;
                }
                close(IN);
                print("</table>\n");
            }
        }
    }
    else
    {
        print("<p style='color:red'>Unknown word $config{word}.</p>\n");
    }
}
else
{
    print("<p style='color:red'>No experiment specified.</p>\n");
}
# Close the HTML document.
print("</body>\n");
print("</html>\n");



###############################################################################
# SUBROUTINES
###############################################################################



#------------------------------------------------------------------------------
# Generates a HTML table with a sentence pair/triple (for test data, triples of
# source, reference and hypothesis may be available).
#------------------------------------------------------------------------------
sub sentence_to_table
{
    # This function accesses the global hashes %config and %prevod.
    my $files = shift;
    my $sntno = shift;
    my $srcfile = shift;
    my $tgtfile = shift;
    my $alifile = shift;
    my $html;
    my $srcline = AddicterHTML::get_nth_line($files->{$srcfile}, $sntno);
    my $tgtline = AddicterHTML::get_nth_line($files->{$tgtfile}, $sntno);
    my $aliline = AddicterHTML::get_nth_line($files->{$alifile}, $sntno);
    # Decompose alignments into array of arrays (pairs).
    my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
    my @srcwords = split(/\s+/, $srcline);
    my @tgtwords = split(/\s+/, $tgtline);
    # Display the source words along with their alignment links.
    $html .= "<table border style='font-family:Code2000'>\n";
    $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@srcwords, \@tgtwords, \@alignments, 0, $config{word});
    # An empty row separates source and target sections.
    $html .= "  <tr><td></td></tr>\n";
    # Display the target words along with their alignment links.
    $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1, $config{word}, \&translit_russian);
    ###!!! If the filter is test+reference, show a third row with system hypothesis.
    if($config{filter} eq 'r')
    {
        my $tgtline = AddicterHTML::get_nth_line($files->{H}, $sntno);
        my $aliline = AddicterHTML::get_nth_line($files->{HA}, $sntno);
        # Decompose alignments into array of arrays (pairs).
        my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
        my @tgtwords = split(/\s+/, $tgtline);
        $html .= "  <tr><td></td></tr>\n";
        $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1, $config{word}, \&translit_russian);
    }
    $html .= "</table>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Transliterates text from a Brahmi-based script to the Roman alphabet. Can be
# applied to the displayed words. Uses the global hash %prevod.
#------------------------------------------------------------------------------
sub translit_brahmi
{
    my $input = shift;
    my $output = translit::prevest(\%prevod, $input);
    return $output;
}



#------------------------------------------------------------------------------
# Transliterates text from Russian Cyrillic to the Roman alphabet. Can be
# applied to the displayed words.
#------------------------------------------------------------------------------
sub translit_russian
{
    my $input = shift;
    # Just a test... obviously it is very inefficient to declare the transliteration table here!
    # Unicode hex 400..45F (dec 1024..1119)
    # chr(200) ... LATIN CAPITAL LETTER E WITH GRAVE
    # chr(232) ... LATIN SMALL LETTER E WITH GRAVE
    my @roman = (chr(200), 'Ë', 'DJ', 'GJ', 'JE', 'S', 'I', 'JI', 'J', 'LJ', 'NJ', 'Ć', 'KJ', 'I', 'W', 'DŽ',
                 'A', 'B', 'V', 'G', 'D', 'E', 'Ž', 'Z', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'F', 'H', 'C', 'Č', 'Š', 'ŠČ', "''", 'Y', "'", chr(200), 'JU', 'JA',
                 'a', 'b', 'v', 'g', 'd', 'e', 'ž', 'z', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f', 'h', 'c', 'č', 'š', 'šč', "''", 'y', "'", chr(232), 'ju', 'ja',
                 chr(232), 'ë', 'dj', 'gj', 'je', 's', 'i', 'ji', 'j', 'lj', 'nj', 'ć', 'kj', 'i', 'w', 'dž');
    my %prevod;
    for(my $i = 0; $i<=$#roman; $i++)
    {
        $prevod{chr(1024+$i)} = $roman[$i];
    }
    my $output = translit::prevest(\%prevod, $input);
    return $output;
}



#------------------------------------------------------------------------------
# Changes the language parameter to the other value. Returns the other value.
# Useful for creating cross links.
#------------------------------------------------------------------------------
sub swaplang
{
    my $current = shift;
    $current = $config{lang} unless($current);
    # Return target if current is source.
    if($current =~ m/^s/i)
    {
        return 't';
    }
    # Return source if current is target.
    elsif($current =~ m/^t/i)
    {
        return 's';
    }
    # If current is neither source nor target, return unknown.
    else
    {
        return 'x';
    }
}
