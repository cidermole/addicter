package opts;
use strict;
use Getopt::Long;

our $dumpEachSnt = undef;

#####
#
#####
sub processOpts {
	GetOptions(
		'dump' => \$dumpEachSnt
	);
}

1;
