package Devel::TraceLoad::Hook;

use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw( register_require_hook );

my @hooks;

BEGIN {
    my $depth = 0;
    *CORE::GLOBAL::require = sub {

        my ( $p, $f, $l ) = caller;
        my $arg = @_ ? shift : $_;

        $depth++;

        _call_hooks( 'before', $depth, $arg, $p, $f, $l );
        my $rc = eval { CORE::require $arg };
        _call_hooks( 'after', $depth, $arg, $p, $f, $l, $rc, $@ );

        $depth--;

        if ( my $err = $@ ) {
            # Patch up error message
            $err =~ s/at \s+ .*? \s+ line \s+ \d+/at $f line $l/x;
            die $err;
        }
        return $rc;
    };
}

sub _call_hooks { $_->( @_ ) for @hooks }
sub register_require_hook { push @hooks, @_ }

1;
