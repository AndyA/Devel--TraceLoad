use strict;
use warnings;

my @cmd = qw( ls -l );
open(my $ch, '-|', @cmd) or die "Can't open ls ($!)\n";
while (<$ch>) {
    print ">>$_";
}
close($ch) or die "Can't close ls ($!)\n";