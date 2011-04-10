package const;
use strict;

our $SEEN_UNAL_PROB = 0.001;
our $BEAM_WIDTH = 25;

our $MRM_SNT = "sentence";
our $MRM_ERRCAT = "error_cat";
our $MRM_ALL = "dump_all";

our $mrmTest = {
	$MRM_SNT => 1,
	$MRM_ERRCAT => 2,
	$MRM_ALL => 4
};

1;
