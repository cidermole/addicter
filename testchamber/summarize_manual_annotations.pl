#!/usr/bin/perl
# Reads second.annotated.tokenized and summarizes errors.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

# Read and store the annotations.
# I am not performing summarization on-the-fly because the sentences are not ordered by their ID
# and I don't know how many annotators per sentence and system there are (and whether the number is fixed).
while(<>)
{
    # Remove line break.
    s/\r?\n$//;
    # Parse line.
    my @fields = split(/\t/, $_);
    my $sid = shift(@fields); # sentence id
    my $sysid = shift(@fields); # system id
    my $missing = shift(@fields); # list of tokens missing from the system output
    my $sentence = shift(@fields); # tokenized and annotated system output
    my @missing = split(/\s+/, $missing);
    my $n_miss_a = 0;
    my $n_miss_c = 0;
    my $n_miss_p = 0;
    foreach my $token (@missing)
    {
        if($token =~ m/^missA::.*$/)
        {
            $n_miss_a++;
        }
        elsif($token =~ m/^missC::.*$/)
        {
            $n_miss_c++;
        }
        elsif($token =~ m/^missP::.*$/)
        {
            $n_miss_p++;
        }
        else
        {
            print STDERR ("Unknown missing token '$token'\n");
        }
    }
    my @sentence = split(/\s+/, $sentence);
    my @splitok;
    foreach my $token (@sentence)
    {
        my $error;
        my $form;
        if($token =~ m/^(.*)::(.*?)$/)
        {
            $error = $1;
            $form = $2;
        }
        else
        {
            $error = 'correct';
            $form = $token;
        }
        push(@splitok, {'form' => $form, 'error' => $error});
    }
    # There may be more than one annotation (@missing + @splitok) per sentence and system.
    push(@{$annot{$sid}{$sysid}}, {'missing' => \@missing, 'sentence' => \@splitok, 'orig' => $_});
}
# Iterate over sentences and do the rest of summarization.
foreach my $sid (sort {$a<=>$b} (keys(%annot)))
{
    # Iterate over systems that translated the current sentence.
    foreach my $sysid (sort(keys(%{$annot{$sid}})))
    {
        # Shortcut to the list of annotations of this system output.
        my $a = $annot{$sid}{$sysid};
        # All annotations relate to the same system output, so they ought to have the same number of tokens.
        my $ntok = scalar(@{$a->[0]{sentence}});
        my $nanot = scalar(@{$a});
        for(my $i = 1; $i<$nanot; $i++)
        {
            my $ntok1 = scalar(@{$a->[$i]{sentence}});
            if($ntok1!=$ntok)
            {
                print STDERR ("sentence $sid, system $sysid\n");
                print STDERR ("annotator 0: $ntok tokens: $a->[0]{orig}\n");
                print STDERR ("annotator $i: $ntok1 tokens: $a->[$i]{orig}\n");
                die;
            }
        }
        # Count every error. Each annotator contributes 1/N occurrences where N is the number of annotators.
        for(my $i = 0; $i<$nanot; $i++)
        {
            foreach my $token (@{$a->[$i]{sentence}})
            {
                # The annotators were allowed to flag more than one error per token.
                # Sometimes the combinations may seem conflicting but we are not going to judge that now.
                # Let's just distribute the occurrence uniformly among the errors flagged.
                my @tokerrors = split(/::/, $token->{error});
                my $ntokerrors = scalar(@tokerrors);
                foreach my $error (@tokerrors)
                {
                    $errstat{$error} += 1/$nanot/$ntokerrors;
                }
            }
        }
    }
}
# Print summary.
print("SUMMARY OF ERRORS:\n");
# Order errors by descending frequency.
@sortederrors = sort {$errstat{$b} <=> $errstat{$a}} (keys(%errstat));
$total = 0;
foreach my $error (@sortederrors)
{
    $total += $errstat{$error};
    print("$error\t$errstat{$error}\n");
}
print("TOTAL\t$total\n");
