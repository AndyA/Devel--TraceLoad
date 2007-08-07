package Spork;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

use vars qw(@EXPORT_OK $VERSION);

@EXPORT_OK = qw( );
$VERSION   = '0.0.3';

#require 5.8.5;

print "Spork!\n";

sub import {
    my $arg = join(', ', @_);
    print __PACKAGE__, "::import($arg)\n";
    my ( $p, $f, $l ) = caller;
    print "$p, $f, $l\n";
}

1;
