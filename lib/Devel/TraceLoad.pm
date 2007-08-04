package Devel::TraceLoad;

require 5.6.1;

use warnings;
use strict;
use Carp;
use Scalar::Util qw/isvstring/;
use Devel::TraceLoad::Hook qw/register_require_hook/;

use vars qw/$VERSION/;
$VERSION = '0.9.0';

use constant OUTFILE => 'traceload';

my %opts = (
    after   => 0,    # Display summary after execution
    during  => 0,    # Display loads as they happen
    yaml    => 0,    # Summary is YAML, implies after
    dump    => 0,    # Dump to 'traceload' in the current dir
    summary => 0,    # Display summary of dependencies
    stdout  => 0,    # Output to stdout

    # after     => 0,  # Display information about loaded modules on exit
    # all       => 0,  # Display modules already loaded before D::T was loaded
    # flat      => 0,  # Don't indent, display first load only
    # pretty    => 0,  # Display rule above, below output at script exit
    # noversion => 0,
    # path      => 0,
    # stdout    => 0,
    # sort      => 0,
    # test      => 0,  # for easy comparaison with the core require
    # trace     => 0,  # non stop trace
    # s_by_s    => 0,  # trace associated to an execution stop
);

sub _is_version {
    my $ver = shift;
    return unless defined $ver;
    return join '.', map ord, split //, $ver if isvstring( $ver );
    return $ver if $ver =~ /^ \d+ (?: [.] \d+ )* $/x;
    return;
}

sub _get_version {
    my $pkg = shift;
    no strict 'refs';
    return _is_version( ${"${pkg}::VERSION"} );
}

sub _get_module {
    my $file = shift;
    return $file if $file =~ m{^/};
    $file =~ s{/}{::}g;
    $file =~ s/[.]pm$//;
    return $file;
}

sub _text_out {
    my ( $fh, $log, $depth ) = @_;
    my $pad = '  ' x $depth;

    for my $info ( @$log ) {
        my @comment = ();

        push @comment, defined $info->{version}
          ? "version: $info->{version}"
          : 'no version';

        if ( my $err = $info->{error} ) {
            $err =~ s/\(.*//g;
            $err =~ s/\s+/ /g;
            $err =~ s/\s+$//;
            push @comment, "error: $err";
        }

        print $fh sprintf( "%s%s (%s), line %d: %s%s\n",
            $pad, $info->{file}, $info->{pkg}, $info->{line}, $info->{module},
            ( @comment ? ' (' . join( ', ', @comment ) . ')' : '' ) );
        _text_out( $fh, $info->{nested}, $depth + 1 );
    }
}

sub _gather_deps {
    my ( $by_dep, $log ) = @_;
    for my $info ( @$log ) {
        push @{ $by_dep->{ $info->{module} } }, $info;
        _gather_deps( $by_dep, $info->{nested} );
    }
}

sub _underline {
    my $str = shift;
    return "$str\n" . ( '=' x length( $str ) ) . "\n";
}

{
    my @load_log    = ();
    my @version_log = ();

    sub import {
        my $class = shift;

        # Parse args
        for my $arg ( @_ ) {
            my $set = ( $arg =~ s/^([+-])(.+)/$2/ ) ? ( $1 eq '+' || 0 ) : 1;
            croak "Unknown option: $arg" unless exists $opts{$arg};
            $opts{$arg} = $set;
        }

        # dump, yaml imply after
        $opts{after} ||= $opts{yaml} || $opts{dump} || !$opts{during};

        $opts{fh}        = $opts{stdout} ? \*STDOUT : \*STDERR;
        $opts{dump_name} = OUTFILE;
        $opts{enabled}   = 1;

        if ( $opts{yaml} ) {
            eval 'use YAML';
            if ( $@ ) {
                $opts{yaml}  = 0;
                $opts{after} = 0;
                croak "YAML not available";
            }
            $opts{dump_name} .= '.yaml';
        }

        my @stack   = ( \@load_log );
        my $exclude = qr{ [.] (?: al | ix ) $}x;

        # Register callback function
        register_require_hook(
            sub {
                my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;

                return unless $opts{enabled};
                return if $arg =~ $exclude;

                # require <version>
                if ( my $ver = _is_version( $arg ) ) {
                    if ( $when eq 'before' ) {
                        my $info = {
                            file    => $f,
                            line    => $l,
                            pkg     => $p,
                            version => $ver,    # Version desired
                        };

                        push @version_log, $info;
                    }
                }
                else {
                    if ( $when eq 'before' ) {
                        my $module = _get_module( $arg );

                        if ( $opts{during} ) {
                            my $pad = '  ' x ( $depth - 1 );
                            my $fh = $opts{fh};
                            print $fh "$pad$f, line $l: $module\n";
                        }

                        my $info = {
                            file   => $f,         # File executing require
                            line   => $l,         # Line # of require
                            pkg    => $p,         # Package executing require
                            module => $module,    # Module being required
                            nested => [],         # List of nested requires
                        };

                        push @{ $stack[-1] }, $info;
                        push @stack, $info->{nested};
                    }
                    elsif ( $when eq 'after' ) {
                        pop @stack;
                        my $info = $stack[-1][-1];
                        $info->{rc} = $rc;
                        if ( $err ) {
                            $info->{error} = $err;
                        }
                        else {
                            $info->{version} = _get_version( $info->{module} );
                        }
                    }
                }
            }
        );
    }

    END {
        if ( $opts{after} ) {
            $opts{enabled} = 0;
            my $fh = $opts{fh};
            if ( $opts{dump} ) {
                open $fh, '>', $opts{dump_name}
                  or croak "Can't write $opts{dump_name} ($!)";
            }

            if ( $opts{yaml} ) {
                print $fh Dump( \@load_log );
            }
            else {
                print $fh "\n", _underline( "Loaded Modules" ), "\n";
                _text_out( $fh, \@load_log, 0 );
            }
        }

        if ( $opts{summary} ) {
            my $fh = $opts{fh};
            print $fh "\n", _underline( "Loaded Modules Xref" ), "\n";
            my %loaded = ();
            _gather_deps( \%loaded, \@load_log );
            my $cmp_info = sub {
                return lc $a->{pkg} cmp lc $b->{pkg}
                  || $a->{line} <=> $b->{line};
            };
            for my $module ( sort { lc $a cmp lc $b } keys %loaded ) {
                my $ver = _get_version( $module );
                print $fh $module, defined $ver ? " ($ver)" : '', "\n";

                for my $info ( sort $cmp_info @{ $loaded{$module} } ) {
                    print sprintf( "    %s (%s), line %d\n",
                        $info->{file}, $info->{pkg}, $info->{line} );
                }
            }
        }
    }
}

# sub trace;
#
# my $pkg = __PACKAGE__;
# my @info;
# my $outfh;
# my $indent;
# my $filter = '[.](al|ix)';
#
# # please, define the separator of your platform and send me a mail
# my $dirsep = { MSWin32 => '/', }->{$^O} || '/';
#
# my %opts = (
#     after     => 0,
#     all       => 0,
#     flat      => 0,
#     pretty    => 0,
#     noversion => 0,
#     path      => 0,
#     stdout    => 0,
#     sort      => 0,
#     test      => 0,    # for easy comparaison with the core require
#     trace     => 0,    # non stop trace
#     s_by_s    => 0,    # trace associated to an execution stop
# );
#
# sub import {
#     shift;
#     $opts{$_} = 1 foreach @_;
#     $outfh = $opts{stdout} ? *STDOUT : *STDERR;
#     $opts{after} = 1 if $opts{sort};
#     $opts{after} = 1 if $opts{test};
#     *trace = $opts{s_by_s}
#       ? sub {
#         print STDERR "line ", ( caller( 0 ) )[2], ": ", "@_";
#         <>;
#       }
#       : $opts{trace}
#       ? sub {
#         print STDERR "@_\n";
#       }
#       : sub { };
#     $indent = $opts{flat} ? '' : '   ';
#     if ( $opts{all} ) {
#         print $outfh join( "\n\t", "Already loaded:", keys %INC ) . "\n";
#     }
# }
#
# BEGIN {
#     my $level  = -1;
#     my $prefix = '';
#     *CORE::GLOBAL::require = sub (*) {
#         trace join ', ', ( caller( 0 ) )[ 0, 1, 2, 3, 4 ];
#         # if you uncomment this line, you obtain some strange results???
#         #trace "require's args: @_";
#         my ( $arg, $rstatus );
#         unless ( @_ ) {
#             # this feature described in the documentation
#             # doesn't work on my ActiveState Perl
#             $arg = $_;
#         }
#         else {
#             $arg = $_[0];
#         }
#         unless ( $arg =~ /^[A-Za-z\d_]/ ) {    # certainly a version number
#             $arg = join '.', map { ord } split //, $arg;
#             trace "Convert char to number: $arg";
#         }
#         if ( $arg =~ /^\d[\d.]*$/ ) {
#             trace "required version: $arg";
#             $rstatus = eval { return CORE::require $_[0] };
#             if ( $@ ) {                        # recontextualize
#                 trace "error: $@";
#                 #$@ =~ s/at \(eval \d+\) line \d+/
#                 $@ =~ s/at .* line \d+[.]/
#           sprintf "at %s line %d.",(caller())[1,2]/e;
#                 die $@;
#             }
#             trace "status: $rstatus";
#             return $rstatus;
#         }
#         unless ( $opts{flat} ) {
#             $prefix = $INC{$mod} ? '.' : '+';
#         }
#         else {
#             $prefix = '';
#         }
#         return 1 if $INC{$mod} && $opts{flat};
#         $level++ unless $opts{flat};
#         unless ( $opts{after} ) {
#             print $outfh $indent x $level, "$prefix$arg";
#             print $outfh $indent x $level, " [from: ",
#               join( " ", ( caller() )[ 1, 2 ] ), "]\n";
#         }
#         else {
#             push @info, [ $arg => $level ];
#         }
#         $rstatus = eval { return CORE::require $_[0] };
#         if ( $@ ) {    # recontextualize
#             trace "error: $@";
#             pop @info if $opts{after};
#             $level-- unless $opts{flat};
#             $@
#               =~ s/at .* line \d+[.]/sprintf "at %s line %d.", (caller())[1,2]/e;
#             die $@;
#         }
#         $level-- unless $opts{flat};
#         trace "status: $rstatus";
#         return $rstatus;
#     };
# }
#
# END {
#     trace "END block";
#     return unless $opts{after};
#     return if $opts{test};
#     my ( $mod, $level, $inc, $path, $version );
#     #while (my($k, $v) = each %INC) { trace "$k -> $v"; }
#     foreach ( @info ) {
#         $mod = $_->[0];
#         trace "mod: $mod";
#         if ( $mod =~ /$filter/o or $mod eq __PACKAGE__ ) {
#             $_->[0] = '';
#             next;
#         }
#         $inc = $mod;
#         if ( $mod =~ s![.]pm$!! ) {
#             $mod =~ s!$dirsep!::!g;
#         }
#         else {
#             $inc =~ s!::!$dirsep!g;
#             $inc .= ".pm";
#         }
#         $version = $opts{noversion} ? '' : ${"$mod\::VERSION"}
#           || '(no version number)';
#         $path = $INC{$inc};
#         push @$_, $path, $version;
#     }
#     if ( $opts{sort} ) {
#         $opts{flat} = 1;
#         $indent = $opts{flat} ? '' : '   ';
#         my %dejavu;
#         if ( $opts{path} ) {
#             @info = sort { $a->[2] cmp $b->[2] }
#               grep { !$dejavu{ $_->[2] }++ } @info;
#         }
#         else {
#             @info = sort { $a->[0] cmp $b->[0] }
#               grep { !$dejavu{ $_->[0] }++ } @info;
#         }
#     }
#     print $outfh "=" x 80, "\n" if $opts{pretty};
#     foreach ( @info ) {
#         ( $mod, $level, $path, $version ) = @$_;
#         next unless $mod;
#         if ( $opts{path} ) {
#             print $outfh $indent x $level . "$path\n";
#         }
#         else {
#             print $outfh $indent x $level . "$mod $version\n";
#         }
#     }
#     print $outfh "=" x 80, "\n" if $opts{pretty};
# }
#
# sub DB::DB {
#     if ( $opts{stop} ) {
#         trace "STOP";
#         exit;
#     }
# }
1;
__END__

=head1 NAME

Devel::TraceLoad - Trace loadings of Perl Programs

=head1 SYNOPSIS

    # with perldb
    perl -d:TraceLoad script.pl

    # without perldb
    perl -MDevel::TraceLoad script.pl

    # without perldb and with options
    perl -MDevel::TraceLoad=after,path script.pl

    # with perldb and options
    perl -d:TraceLoad -MDevel::TraceLoad=stop,after,path script.pl

=head1 DESCRIPTION

The module B<Devel::TraceLoad> traces the B<require()>
and the B<use()> appearing in a program.  The trace makes it
possible to know the dependencies of a program with respect to other
programs and in particular of the modules.

The generated report can be obtained in various forms.  The loadings are
indicated in the order in which they are carried out.  The trace can be
obtained either during the execution of the loadings or at end of the
execution.  By default, the trace is generated during the execution and the
overlaps of loadings are marked by indentations.  All the B<require()> are
indicated, even if it is about a B<require()> of a program already charged.
A B<+> indicates that the program is charged for the first time.  A B<.>
indicates that the program was already charged.

When the trace is differed, the number of version of the modules is
indicated.  A differed trace can be sorted and if it is wished the
names of the modules can be replaced by the absolute name of
the files.

The module is close to B<Devel::Modlist> but uses a redefinition of
B<require()> instead of exploiting B<%INC>.  In a will of homogeneity the
module also borrows many things from B<Devel::Modlist>.

=head1 USE

B<Devel::TraceLoad> can be used with or without perldb:

    perl -d:TraceLoad script.pl

    perl -MDevel::TraceLoad script.pl

For the majority of the uses the two possibilities are
equivalent.

=head1 OPTIONS

To pass from the options to the module B<Devel::TraceLoad>
one will write:

    perl -MDevel::TraceLoad=option1[,option2,...]

With this writing the option B<stop> is not taken into
account.  So that B<stop> is taken into account one will write:

    perl -d:TraceLoad -MDevel::TraceLoad=option1[,option2,...]

=over

=item after

The trace is given at the end of the execution.

=item flat

Removes the indentations which indicate nestings of B<require()>.

=item noversion

Removes the indication of version of the loaded modules.

=item path

Indicates the absolute names of the files corresponding to the
modules charged instead of names with modules.

This option functions only when the trace is produced at the end
of the execution, i.e. in the presence of the option B<after>.

=item sort

The trace is provided at the end of the execution and gives a
list sorted alphabetically on the names of module or the paths.

=item stdout

Redirect the trace towards B<STDOUT>. By default the trace is
redirected to B<STDERR>.

=item stop

Stop the program before execution of the first of the program, if
execution is under the perldb control.  Does not allow to see the
loadings carried out by B<require()> and the loadings which are in
B<eval()>.

=back

=head1 BUG

Some modules and pragmas are loaded because of the presence
of B<-MDevel::TraceLoad>. These modules do not appear in the
trace (with the version of Perl on which we made our tests the modules
concerned are Exporter.pm, Carp.pm, vars.pm, warnings::register.pm,
Devel::TraceLoad.pm, warnings.pm).

Version 0.07 no more worked with the ActivePerl that i use at home.  So
the current version is a nearly complete rewrite of the previous
version. This is certainly related to some changes to the require()
implementation. If you have to use Devel::TraceLoad with another
with a Perl under 5.6.1 try version 0.07 of Devel::TraceLoad.

=head1 AUTHORS

Philippe Verdret < pverdret@dalet.com >, on the basis of an idea of
Joshua Pritikin < vishnu@pobox.com >.

=head1 NOTES

The english version of documentation is produced from a machine
translation carried out by C<babel.altavista.com>.

Many thanks to Mooney Christophe < CMOONEY1@motorola.com > for his help
to debug the tests.

=head1 SEE ALSO

B<Devel::Modlist>.

=cut
