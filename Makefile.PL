use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Devel::TraceLoad',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Devel/TraceLoad.pm',
    ABSTRACT_FROM => 'lib/Devel/TraceLoad.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'version'      => 0,
        'Test::More'   => 0,
        'Test::Deep'   => '0.096',
        'Scalar::Util' => 0,
        'Data::Dumper' => 0,
        'File::Spec'   => 0,
        'File::Path'   => 0,
        'File::Temp'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Devel-TraceLoad-*' },
);
