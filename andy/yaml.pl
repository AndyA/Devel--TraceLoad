#!/usr/bin/perl
#
#  yaml
#
#  Created by Andy Armstrong on 2007-08-03.
#  Copyright (c) 2007 Hexten. All rights reserved.

use strict;
use warnings;
use YAML;

$| = 1;

my $obj = [
    {
        'rc'      => 1,
        'version' => '1.03',
        'pkg'     => 'main',
        'file'    => 'andy/t.pl',
        'nested'  => [],
        'module'  => 'strict',
        'line'    => 3
    },
    {
        'rc'      => 1,
        'version' => '1.03',
        'pkg'     => 'main',
        'file'    => 'andy/t.pl',
        'nested'  => [],
        'module'  => 'warnings',
        'line'    => 4
    },
    {
        'rc'      => 1,
        'version' => '0.5565',
        'pkg'     => 'main',
        'file'    => 'andy/t.pl',
        'nested'  => [
            {
                'rc'      => 1,
                'version' => undef,
                'pkg'     => 'lib',
                'file' =>
                  '/System/Library/Perl/5.8.6/darwin-thread-multi-2level/lib.pm',
                'nested' => [],
                'module' => 'Config',
                'line'   => 6
            },
            {
                'rc'      => 1,
                'version' => '1.03',
                'pkg'     => 'lib',
                'file' =>
                  '/System/Library/Perl/5.8.6/darwin-thread-multi-2level/lib.pm',
                'nested' => [],
                'module' => 'strict',
                'line'   => 8
            }
        ],
        'module' => 'lib',
        'line'   => 5
    },
    {
        'rc'      => 1,
        'version' => '0.0.3',
        'pkg'     => 'main',
        'file'    => 'andy/t.pl',
        'nested'  => [
            {
                'rc'      => 1,
                'version' => '1.03',
                'pkg'     => 'Spork',
                'file'    => 'andy/Spork.pm',
                'nested'  => [],
                'module'  => 'strict',
                'line'    => 3
            },
            {
                'rc'      => 1,
                'version' => '1.03',
                'pkg'     => 'Spork',
                'file'    => 'andy/Spork.pm',
                'nested'  => [],
                'module'  => 'warnings',
                'line'    => 4
            },
            {
                'rc'      => 1,
                'version' => '1.03',
                'pkg'     => 'Spork',
                'file'    => 'andy/Spork.pm',
                'nested'  => [],
                'module'  => 'Carp',
                'line'    => 5
            },
            {
                'rc'      => 1,
                'version' => '2.06',
                'pkg'     => 'Spork',
                'file'    => 'andy/Spork.pm',
                'nested'  => [],
                'module'  => 'base',
                'line'    => 7
            },
            {
                'rc'      => 1,
                'version' => '1.01',
                'pkg'     => 'Spork',
                'file'    => 'andy/Spork.pm',
                'nested'  => [],
                'module'  => 'vars',
                'line'    => 9
            }
        ],
        'module' => 'Spork',
        'line'   => 11
    },
    {
        'rc'      => 1,
        'version' => undef,
        'pkg'     => 'main',
        'file'    => 'andy/t.pl',
        'nested'  => [],
        'module'  => '5.6.1',
        'line'    => 7
    }
];

END {
    print Dump( $obj );
}

