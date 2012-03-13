#!/usr/bin/env perl
use Modern::Perl;
#use utf8::all;
use File::Spec;
use Getopt::Long;

BEGIN {
    # include packages from same folder where the
    # script is, even if launched from elsewhere
    # unshift(), not push(), to give own functions precedence over other libraries
    my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
    pop @dirs;
    unshift(@INC, File::Spec->catdir(@dirs));
}
use autodie;
use GreedyAligner;
use Carp;

my ( $ref_file, $hyp_file ) = @ARGV;
die "Aligns reference to hypothesis using greedy injective alignment algorithm\nUsage: $0 reference_filename hypothesis_filename" if @ARGV != 2;
open my $R, '<', $ref_file;
open my $H, '<', $hyp_file;

my $greedy = GreedyAligner->new();

while (1) {
    my $r_line = <$R> // last;
    my $h_line = <$H> // last;
    my @r_tokens = map {[split /\|/, $_]} split /\s/, $r_line;
    my @h_tokens = map {[split /\|/, $_]} split /\s/, $h_line;
    my $args = {
        hforms => [map {$_->[0]} @h_tokens],
        rforms => [map {$_->[0]} @r_tokens],
        htags => [map {$_->[1]} @h_tokens],
        rtags => [map {$_->[1]} @r_tokens],
        hlemmas => [map {$_->[2]} @h_tokens],
        rlemmas => [map {$_->[2]} @r_tokens],
    };
    
    # The main work is done here
    my $alignment = $greedy->align_sentence($args);
    
    say join ' ', map {$alignment->[$_] == -1 ? () : $_ . '-' . $alignment->[$_]} (0..$#h_tokens);
    
    # To debug, you can print forms instead of indices
    #say join ' ', map {$alignment->[$_] == -1 ? () : $h_tokens[$_][0] . '-' . $r_tokens[$alignment->[$_]][0]} (0..$#h_tokens);
}
close($R);
close($H);
