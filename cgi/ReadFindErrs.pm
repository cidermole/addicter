#!/usr/bin/perl
# Reads XML output of finderrs.pl (Addicter / Mark Fishel's Testchamber).
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package ReadFindErrs;
use utf8;
use open ":utf8";
use XML::Parser;



#------------------------------------------------------------------------------
# Reads the output for the n-th test sentence. Note: Addicter Web Interface
# calls the first sentence as "number 1" while the <sentence> index in XML from
# finderrs.pl starts at 0. Thus this function returns <sentence index="0"> if
# asked for $n==1.
#------------------------------------------------------------------------------
sub get_nth_sentence
{
    my $path = shift;
    my $n = shift;
    local %state;
    $state{state} = 'waiting';
    $state{wantid} = $n-1;
    my $parser = new XML::Parser(Handlers => {Start => \&handle_start, End => \&handle_end});
    $parser->parsefile($path);
    return \%state;
}



#------------------------------------------------------------------------------
# Handles the occurrence of a start tag of an XML element.
#------------------------------------------------------------------------------
sub handle_start
{
    my $expat = shift;
    my $element = shift;
    my %attr = @_;
    if($state{state} eq 'waiting' && $element eq 'sentence' && $attr{index} eq $state{wantid})
    {
        $state{state} = 'reading';
    }
    elsif($state{state} eq 'reading')
    {
        if($element =~ m/^(extraHypWord|missingRefWord|untranslatedHypWord|unequalAlignedTokens|ordErrorShiftWord|ordErrorSwitchWords)$/)
        {
            push(@{$state{errors}{$element}}, \%attr);
        }
    }
}



#------------------------------------------------------------------------------
# Handles the occurrence of an end tag of an XML element.
#------------------------------------------------------------------------------
sub handle_end
{
    my $expat = shift;
    my $element = shift;
    if($state{state} eq 'reading' && $element eq 'sentence')
    {
        $state{state} = 'finished';
    }
}



1;
