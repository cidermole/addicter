#!/usr/bin/perl
# Common subroutines for Addicter CGI / HTML-generating scripts.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package AddicterHTML;
use utf8;
use open ":utf8";



#------------------------------------------------------------------------------
# Generates a part of an HTML table with a sentence and corresponding aligned
# words from the other language. The function generates two table rows. One row
# contains words (tokens) of the sentence. The other row contains the
# alignments: numeric indices and the actual tokens from the corresponding
# sentence in the other language. The tokens in the main row are linked to
# word example pages. Tokens in the alignment row are not hyperlinks. By
# default, the main row is displayed first and the alignment row second. They
# can be swapped by specifying that the sentence is in the target language.
#------------------------------------------------------------------------------
sub sentence_to_table_row
{
    # Need experiment name as parameter, don't want to access the global %config from a library package.
    my $experiment = shift;
    # Source and target of the alignment, not necessarily source and target languages in the experiment analyzed.
    my $srcwords = shift; # array reference
    my $tgtwords = shift; # array reference
    my $alignments = shift; # reference to array of arrays (pairs).
    my $target = shift; # 0|1: influences not only the order of the table rows
    # Optionally, specify focus word. It will be highlighted and will not be a hyperlink.
    my $focusword = shift; # string
    # Optionally, words can be transliterated from a foreign script to the Roman alphabet.
    my $translitroutine = shift; # ref to subroutine
    my ($linklang, $aithis, $aithat);
    unless($target)
    {
        $linklang = 's';
        $aithis = 0;
        $aithat = 1;
    }
    else
    {
        $linklang = 't';
        $aithis = 1;
        $aithat = 0;
    }
    my $mainrow;
    $mainrow .= "  <tr>";
    for(my $i = 0; $i<=$#{$srcwords}; $i++)
    {
        my $translit;
        if($translitroutine)
        {
            $translit = '<br/>'.&{$translitroutine}($srcwords->[$i]);
        }
        # Every word except for the current one is a link to its own examples.
        my $word = $focusword && $srcwords->[$i] eq $focusword ? "<span style='color:red'>$focusword</span>" : word_to_link($experiment, $linklang, $srcwords->[$i]);
        $mainrow .= "<td>$word$translit</td>";
    }
    $mainrow .= "</tr>\n";
    # Get the alignments in the order of the source sentence.
    # Preprocess them into an array first, this will enable us to collapse subsequent identical cells into one.
    my @alirow;
    for(my $i = 0; $i<=$#{$srcwords}; $i++)
    {
        my $ali_word = join('&nbsp;', map {$tgtwords->[$_->[$aithat]]} (grep {$_->[$aithis]==$i} (@{$alignments})));
        my $ali_link = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[$aithis]==$i} (@{$alignments})));
        # The third element is the column span of the cell, initially set to 1 everywhere.
        push(@alirow, [$ali_word, $ali_link, 1]);
    }
    # Collapse neighboring cells into one if they contain the same words.
    my $last_word;
    for(my $i = $#alirow; $i>=0; $i--)
    {
        if($i<$#alirow && $alirow[$i][0] eq $last_word)
        {
            # Copy over the alignment links from right.
            $alirow[$i][1] .= '&nbsp;'.$alirow[$i+1][1];
            # Extend the current column span.
            $alirow[$i][2] += $alirow[$i+1][2];
            # Remove the record neighboring to the right.
            splice(@alirow, $i+1, 1);
        }
        $last_word = $alirow[$i][0];
    }
    # Second row contains target words aligned to source words.
    my $alirow;
    $alirow .= "  <tr>";
    for(my $i = 0; $i<=$#alirow; $i++)
    {
        my $aliphrase = $alirow[$i][0];
        # Highlight the focus word in the aligned phrase, too.
        if($focusword)
        {
            $aliphrase =~ s/\Q$focusword\E/<span style='color:red'>$focusword<\/span>/g;
        }
        $alirow .= "<td colspan='$alirow[$i][2]'>$aliphrase<br/>$alirow[$i][1]</td>";
    }
    $alirow .= "</tr>\n";
    # Put the two rows together.
    # Originally, for target sentences, we displayed the alignment row before the main row.
    # Perhaps it would be better to always show the main row first.
    my $html;
    if(0)
    {
        $html = $target ? $alirow.$mainrow : $mainrow.$alirow;
    }
    else
    {
        $html = $mainrow.$alirow;
    }
    return $html;
}



#------------------------------------------------------------------------------
# Converts a word into a hyperlink to the page with an example of the word as
# occurs in the corpus.
#------------------------------------------------------------------------------
sub word_to_link
{
    my $experiment = shift;
    my $lang = shift;
    my $word = shift;
    my $html = "<a href='example.pl?experiment=$experiment&amp;lang=$lang&amp;word=$word'>$word</a>";
    return $html;
}



1;