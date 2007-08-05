use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use Test::SyntheticModule qw/make_module/;

use Devel::TraceLoad::Hook qw/register_require_hook/;

register_require_hook(
    sub {
        my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;
        warn "$when, $depth, $arg, $p, $f, $l\n";
    }
);

my $mod1 = make_module( '' );
my $mod2 = make_module( '' );
my $mod3 = make_module( [ "use $mod1;", "use $mod2;" ] );

eval "use $mod3";

ok 1, 'is OK';
