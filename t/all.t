#!/usr/local/bin/perl
# Usage examples, from the root dir:
# For generating the reference results:
# make test TEST_FILES=t/all.t TEST_SAVE=1 
# 
# make test TEST_FILES=t/all.t TEST_CMD=t/require_use.pl TEST_VERBOSE=1 TEST_SAVE=1 TEST_TRACE=1
# In a dos term:
# pmake test "TEST_FILES=t/all.t TEST_SAVE=1"

use strict;
use warnings;
BEGIN { push @INC, './t' }	
use Test::Wrapper;

my $TRACE = $ENV{TEST_TRACE};
my $PREFIX = '=> ';
sub trace {
    return unless $TRACE; 
    print STDERR "$PREFIX@_\n";
}
trace "$ENV{VERSION}\n";

my @tests = defined($ENV{TEST_CMD}) && $ENV{TEST_CMD} ne ''? ($ENV{TEST_CMD}) : ();
@tests = <t/*.pl> unless @tests; # all .pl by default
unless (@tests) {
    die "no file to test";
}
trace "Programs to test: @tests";

my $t = 0;
my $num = @tests;
trace "Total number of tests: $num";

#perl -MDevel::TraceLoad=after,path script.pl
# if some options are needed:
my %CmdOpts = (
		Default => '-MDevel::TraceLoad=after,noversion',
		'' => '',
		);
my $test = '';
foreach my $prog (@tests) {
#    $DB::single = 1;
    unless (-s $prog) {
	warn "'$prog' not found";
	next;
    }
    $test = Test::Wrapper->new({
	Program => $prog,
	Range => ++$t . ".." . $num,
	CmdOpts => $CmdOpts{$prog} || $CmdOpts{Default}
	});
    $test->result($prog);
    my $file = $prog;
    $file =~ s![.](pl|t)!.ref!;
    if ($ENV{TEST_SAVE}) { # save the result in a file.ref
	print STDERR "\n";
	print STDERR "Save execution result of '$prog' in '$file'\n";
	print STDERR "\n";
	print STDERR $test->result;
	open OUT, "> $file" or die "$!";
	print OUT $test->result;
	print "ok result saved\n";
    } else {
	if (-s $file) {
	    open my $result, "$file" or die "can't open '$file' ($!)";
	    $test->expected($result);
	    # remove 'in @INC.*' 
	    # named parameters will be better
	    print $test->test($t, undef, undef, undef, undef, 'in @INC.*', 'in @INC.*');
	}
    }
}
