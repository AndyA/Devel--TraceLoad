use strict;
use warnings;

BEGIN {
    my $x   = 'bleep';
    my $pog = sub {
        require for $x;
    };
}
