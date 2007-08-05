use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Spec;

use lib qw(t/lib);
use Test::SyntheticModule qw/make_module/;

use Devel::TraceLoad::Hook qw/register_require_hook/;

{
    my @calls = ();
    register_require_hook( sub { push @calls, [@_] } );
    sub get_calls { @calls }
    sub reset_calls { @calls = () }
}

my @schedule;

BEGIN {
    my $is_absolute_name = code(
        sub {
            my $name = shift;
            return File::Spec->file_name_is_absolute( $name )
              ? 1
              : ( 0, "$name is not absolute" );
        }
    );

    my $is_relative_name = code(
        sub {
            my $name = shift;
            return ( defined $name
                  && length( $name )
                  && !File::Spec->file_name_is_absolute( $name ) )
              ? 1
              : ( 0, "$name is not relative" );
        }
    );

    my $is_version     = re( qr{ ^ \d+ (?: [.] \d+ )* $ }x );
    my $is_eval        = re( qr{ ^ \( eval \s+ \d+ \) }x );
    my $is_line_number = re( qr{ ^ \d+ $ }x );
    my $is_source_name = re( qr{ [.] (?: t | pl | pm ) $ }x );
    my $is_syn_package = re( qr{ ^ Synthetic::\w+ $}x );

    @schedule = (
        # require
        {
            name  => 'Simple require',
            setup => sub {
                my ( $name, $file ) = make_module( '' );
                require $file;
            },
            expect => [
                [
                    'before',          1,
                    $is_absolute_name, 'main',
                    $is_source_name,   $is_line_number
                ],
                [
                    'after', 1, $is_absolute_name, 'main', $is_source_name,
                    $is_line_number, 1, ''
                ]
            ]
        },
        {
            name  => 'Bareword require',
            setup => sub {
                my $name = make_module( '' );
                eval "require $name";
                die $@ if $@;
            },
            expect => [
                [
                    'before',          1,
                    $is_relative_name, 'main',
                    $is_eval,          $is_line_number
                ],
                [
                    'after', 1, $is_relative_name, 'main', $is_eval,
                    $is_line_number, 1, ''
                ]
            ]
        },
        {
            name  => 'Version require',
            setup => sub {
                require 5;
            },
            expect => [
                [
                    'before',        1,
                    $is_version,     'main',
                    $is_source_name, $is_line_number
                ],
                [
                    'after', 1, $is_version, 'main', $is_source_name,
                    $is_line_number, 1, ''
                ]
            ]
        },
        {
            name  => 'Via topical',
            setup => sub {
                my ( $name, $file ) = make_module( '' );
                require for $file;
            },
            expect => [
                [
                    'before',          1,
                    $is_absolute_name, 'main',
                    $is_source_name,   $is_line_number
                ],
                [
                    'after', 1, $is_absolute_name, 'main', $is_source_name,
                    $is_line_number, 1, ''
                ]
            ]
        },
        # use
        {
            name  => 'Simple use',
            setup => sub {
                my $name = make_module( '' );
                eval "use $name";
                die $@ if $@;
            },
            expect => [
                [
                    'before',          1,
                    $is_relative_name, 'main',
                    $is_eval,          $is_line_number
                ],
                [
                    'after', 1, $is_relative_name, 'main', $is_eval,
                    $is_line_number, 1, ''
                ]
            ]
        },
        {
            name  => 'Nested use',
            setup => sub {
                my $mod1 = make_module( '' );
                my $mod2 = make_module( '' );
                my $name = make_module( [ "use $mod1;", "use $mod2;" ] );
                eval "use $name";
                die $@ if $@;
            },
            expect => [
                [
                    'before',          1,
                    $is_relative_name, 'main',
                    $is_eval,          $is_line_number
                ],
                [
                    'before',          2,
                    $is_relative_name, $is_syn_package,
                    $is_absolute_name, $is_line_number
                ],
                [
                    'after',           2,
                    $is_relative_name, $is_syn_package,
                    $is_absolute_name, $is_line_number,
                    1,                 ''
                ],
                [
                    'before',          2,
                    $is_relative_name, $is_syn_package,
                    $is_absolute_name, $is_line_number
                ],
                [
                    'after',           2,
                    $is_relative_name, $is_syn_package,
                    $is_absolute_name, $is_line_number,
                    1,                 ''
                ],
                [
                    'after', 1, $is_relative_name, 'main', $is_eval,
                    $is_line_number, 1, ''
                ]
            ]
        },
        {
            name  => 'Failure',
            setup => sub {
                my $name = 'Synthetic::Some::Module::Which::We::Hope::Is::Missing';
                eval "use $name";
                die $@ if $@;
            },
            expect => [
                [
                    'before',          1,
                    $is_relative_name, 'main',
                    $is_eval,          $is_line_number
                ],
                [
                    'after', 1, $is_relative_name, 'main', $is_eval,
                    $is_line_number, undef, re(qr{^ Can't \s+ locate }x)
                ]
            ],
            error => qr{}x,
        },
    );

    plan tests => @schedule * 2;
}

for my $test ( @schedule ) {
    my $name = $test->{name};

    reset_calls();
    eval { $test->{setup}->() };
    if ( my $err = $test->{error} ) {
        like $@, $err, "$name: error OK";
    }
    else {
        ok !$@, "$name: no error OK";
    }
    my @calls = get_calls();
    unless ( cmp_deeply( \@calls, $test->{expect}, "$name: capture matches" ) )
    {
        use Data::Dumper;
        ( my $var = $name ) =~ s/\s+/_/g;
        diag( Data::Dumper->Dump( [ \@calls ], [$var] ) );
    }
}
