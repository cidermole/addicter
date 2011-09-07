package GreedyAligner;
use Modern::Perl;
use Moose;
use MooseX::SemiAffordanceAccessor;
use List::MoreUtils qw(all any);
use Carp;

has score_limit => (
    is            => 'ro',
    isa           => 'Num',
    default       => 4,
    documentation => 'minimum score for a node pair to be aligned',
);

has weights => (
    is            => 'ro',
    isa           => 'HashRef',
    lazy_build    => 1,
    documentation => 'weight vector of the features'
);

sub _build_weights {
    return {
        lemma_similarity       => 7,
        tag_similarity         => 6,
        aligned_left_neighbor  => 3,
        aligned_right_neighbor => 3,
        ord_similarity         => 5,
    };
}

# other factors apart from forms
my @FACTORS = qw(lemmas tags);

sub align_sentence {
    my ( $self, $args ) = @_;
    $self->_check_args($args);
    my ( $hlast, $rlast ) = ( $args->{hlast}, $args->{rlast} );
    $args->{align} = [ map {-1} ( 0 .. $hlast ) ];

    # We need to know which nodes are still unaligned, i.e. free
    # TODO banchmark using hash instead of array (values %free_h)
    $args->{free_h} = [ 0 .. $hlast ];
    $args->{free_r} = [ 0 .. $rlast ];

    # First, try super-greedy alignment (to make it faster):
    # If there is only one node with the same form, align it.
    # Then similarly for lemmas.
    $self->prealign_same( $args, 'forms' );
    $self->prealign_same( $args, 'lemmas' );

    my $max_score = 0;
    my ( $max_h, $max_r, @score );
    foreach my $h ( @{ $args->{free_h} } ) {
        foreach my $r ( @{ $args->{free_r} } ) {
            my $s = $self->score( $args, $h, $r );
            $score[$h][$r] = $s;
            if ( $s > $max_score ) {
                ( $max_score, $max_h, $max_r ) = ( $s, $h, $r );
            }
        }
    }

    # The main loop
    while ( $max_score > $self->score_limit ) {

        # Mark the winning alignment pair from the lat iteration.
        $self->_align( $args, $max_h, $max_r );

        # The only weights that must be updated are aligned_*_neighbor.
        $score[ $max_h - 1 ][ $max_r - 1 ] += $self->weights->{aligned_right_neighbor} if $max_h && $max_r;
        $score[ $max_h + 1 ][ $max_r + 1 ] += $self->weights->{aligned_left_neighbor} if $max_h != $hlast && $max_r != $rlast;

        # Now find the maximum again
        # TODO use heap instead to make it faster
        $max_score = 0;
        foreach my $h ( @{ $args->{free_h} } ) {
            foreach my $r ( @{ $args->{free_r} } ) {
                my $s = $score[$h][$r];
                if ( $s > $max_score ) {
                    ( $max_score, $max_h, $max_r ) = ( $s, $h, $r );
                }
            }
        }
    }

    return $args->{align};
}

sub _check_args {
    my ( $self, $args ) = @_;
    confess "no args provided" if !$args;
    for my $rh (qw(r h)) {
        my $forms = $args->{ $rh . 'forms' } or confess "${rh}forms is a required arg";
        my $len = @$forms;

        # remember the index of the last token in a reference/hypothesis sentence
        $args->{"${rh}last"} = $len - 1;

        # check the other factors have the same number of items for the sentence
        for my $factor (@FACTORS) {
            my $f = $args->{ $rh . $factor };
            next if !$f;
            my $f_len = @$f;
            confess "Factor $rh$factor contains $f_len while there are $len forms" if $f_len != $len;
        }

        # Use lowercased forms instead of missing lemmas.
        # By overriding guess_lemma you can also do e.g. stemming.
        if ( !$args->{ $rh . 'lemmas' } ) {
            my @lcforms = map { $self->guess_lemma($_) } @{ $args->{ $rh . 'forms' } };
            $args->{ $rh . 'lemmas' } = \@lcforms;
        }
    }
    return;
}

sub guess_lemma {
    my ( $self, $form ) = @_;
    return lc $form;
}

sub prealign_same {
    my ( $self, $args, $attr ) = @_;
    my %r_forms;
    foreach my $r ( @{ $args->{free_r} } ) {
        my $r_form = $args->{"r$attr"}[$r];
        if ( defined $r_forms{$r_form} ) {
            $r_forms{$r_form} = -2;
        }
        else {
            $r_forms{$r_form} = $r;
        }
    }
    foreach my $h ( @{ $args->{free_h} } ) {
        my $r = $r_forms{ $args->{"h$attr"}[$h] };
        if ( defined $r && $r != -2 ) {
            $self->_align( $args, $h, $r );
        }
    }
    return;
}

sub _align {
    my ( $self, $args, $h, $r ) = @_;
    $args->{align}[$h] = $r;

    # Delete the aligned nodes from the pool of free nodes.
    $args->{free_h} = [ grep { $_ != $h } @{ $args->{free_h} } ];
    $args->{free_r} = [ grep { $_ != $r } @{ $args->{free_r} } ];
    return;
}

sub score {
    my ( $self, $args, $h, $r ) = @_;
    my ( $hlast, $rlast ) = ( $args->{hlast}, $args->{rlast} );
    my %features;

    $features{lemma_similarity} = $self->lemma_similarity( $args, $h, $r );
    $features{tag_similarity} = $self->tag_similarity( $args, $h, $r );
    $features{aligned_left_neighbor}  = 1 if $h           && $args->{align}[ $h - 1 ] == $r - 1;
    $features{aligned_right_neighbor} = 1 if $h != $hlast && $args->{align}[ $h + 1 ] == $r + 1;
    $features{ord_similarity} = 1 - abs( ( $h / $hlast ) - ( $r / $rlast ) );

    my $score = 0;
    foreach my $feature_name ( keys %features ) {
        $score += $features{$feature_name} * $self->weights->{$feature_name};
    }
    return $score;
}

use Text::JaroWinkler;

sub lemma_similarity {
    my ( $self, $args, $h, $r ) = @_;
    return Text::JaroWinkler::strcmp95( $args->{hlemmas}[$h], $args->{rlemmas}[$r], 20 );
}

sub tag_similarity {
    my ( $self, $args, $h, $r ) = @_;
    my ( $htag, $rtag ) = ( $args->{htags}[$h], $args->{rtags}[$r] );
    return 0 if !$htag || !$rtag;
    return substr( $htag, 0, 1 ) eq substr( $rtag, 0, 1 );
}

1;

# Copyright 2011 Martin Popel
# This file is distributed under the GNU GPL v2 or later.

__END__
    # Collect the unaligned=free nodes
    my ( @free_h, @aligned_r );
    foreach my $h ( 0 .. $hlast ) {
        if ( $args->{align}[$h] != -1) {
            $aligned_r[ $args->{align}[$h] ] = 1;
        }
        else {
            push @free_h, $h;
        }
    }
    my @free_r = grep { !$aligned_r[$_] } ( 0 .. $rlast );
