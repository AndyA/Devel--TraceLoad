package Devel::TraceLoad::Hook;

use strict;
use warnings;

use base qw(Exporter);
use vars qw/$VERSION @EXPORT_OK/;

@EXPORT_OK = qw( register_require_hook );
$VERSION   = '0.9.0';

my @hooks;

BEGIN {
    my $depth = 0;
    *CORE::GLOBAL::require = sub {

        my ( $p, $f, $l ) = caller;
        my $arg = @_ ? shift : $_;
        my $rc;

        $depth++;

        # If a 'before' hook throws an error we'll still call the
        # 'after' hooks - to keep everything in balance.
        eval { _call_hooks( 'before', $depth, $arg, $p, $f, $l ) };

        # Only call require if the 'before' hooks succeeded.
        $rc = eval { CORE::require $arg } unless $@;

        # Call the 'after' hooks whatever happened. If they throw an error
        # we'll lose any preceding error - but then 'after' hooks aren't
        # supposed to fail.
        eval { _call_hooks( 'after', $depth, $arg, $p, $f, $l, $rc, $@ ) };

        $depth--;

        if ( my $err = $@ ) {
            # Patch up error message
            $err =~ s/at \s+ .*? \s+ line \s+ \d+/at $f line $l/x;
            die $err;
        }
        return $rc;
    };
}

sub _call_hooks {
    my @errs = ();

    for my $hook ( @hooks ) {
        eval { $hook->( @_ ) };
        push @errs, $@ if $@;
    }

    # Rethrow after calling all the hooks. We assume that usually only
    # one hook will fail and that we'll be rethrowing that error here -
    # but we concatenate all the errors so that when multiple hooks fail
    # someone gets to see the diagnostic.

    die join( ', ', @errs ) if @errs;
}

sub register_require_hook { push @hooks, @_ }

1;

__END__

=head1 NAME

Devel::TraceLoad::Hook - Install a hook function to be called for each require.

=head1 VERSION

This document describes Devel::TraceLoad::Hook version 0.9.0

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE 

=over

=item C<< register_require_hook >>

Register a function to be called immediately before and after each
C<require> (and C<use>).

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Devel::TraceLoad::Hook requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<< YAML >> is required for yaml output.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to 
C<bug-devel-traceload>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
