#!/usr/bin/perl
#
#  topical
#
#  Created by Andy Armstrong on 2007-08-05.
#  Copyright (c) 2007 Hexten. All rights reserved.

use strict;
use warnings;
use Data::Dumper;

$| = 1;

sub _call_hooks {
    print join( ', ', map { defined $_ ? $_ : 'undef' } @_ ), "\n";
}

my $depth = 0;

my $old_require = *CORE::GLOBAL::require;

BEGIN {
    *CORE::GLOBAL::require = sub {
        my ( $p, $f, $l ) = caller;
        my $arg = @_ ? $_[0] : $_;
        my $rc;

        $depth++;

        # If a 'before' hook throws an error we'll still call the
        # 'after' hooks - to keep everything in balance.
        eval { _call_hooks( 'before', $depth, $arg, $p, $f, $l ) };

        # Only call require if the 'before' hooks succeeded.
        $rc = eval { CORE::require $arg } unless $@;

        # Save the error for later
        my $err = $@;

        # Call the 'after' hooks whatever happened. If they throw an error
        # we'll lose any preceding error - but then 'after' hooks aren't
        # supposed to fail...
        {
            local $@;    # Things break if we trample on $@
            eval { _call_hooks( 'after', $depth, $arg, $p, $f, $l, $rc, $err ) };
        }

        $depth--;

        if ( $err ) {
            # Patch up error message
            $err =~ s/at \s+ .*? \s+ line \s+ \d+/at $f line $l/x;
            die $err;
        }
        return $rc;
    };
}

for ( qw(Spork.pm) ) {
    require;
}
