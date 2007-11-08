use strict;
use warnings;

use inc::Module::Install;

name 'Devel-TraceLoad';
all_from 'lib/Devel/TraceLoad.pm';

build_requires 'Test::More' => 0;
build_requires 'Test::Deep' => '0.096';

requires 'Scalar::Util' => 0;
requires 'Data::Dumper' => 0;
requires 'File::Spec'   => 0;
requires 'File::Path'   => 0;
requires 'File::Temp'   => 0;
license 'perl';
perl_version '5.008';

WriteAll;

# # use ExtUtils::MakeMaker;
#
# # eval ' use ExtUtils::MakeMaker::Coverage ';
#
# WriteMakefile(
#     ( MM->can( ' signature_target ' ) ? ( SIGN => 1 ) : () ),
#     NAME          => ' Devel::TraceLoad ',
#     AUTHOR        => ' Andy Armstrong <andy@hexten.net>',
#     LICENSE       => ' perl ',
#     VERSION_FROM  => ' lib / Devel / TraceLoad . pm ',
#     ABSTRACT_FROM => ' lib / Devel / TraceLoad . pm ',
#     PL_FILES      => {},
#     PREREQ_PM     => {
#         ' Scalar::Util ' => 0,
#         ' Data::Dumper ' => 0,
#         ' File::Spec '   => 0,
#         ' File::Path '   => 0,
#         ' File::Temp '   => 0,
#     },
#     dist  => { COMPRESS => ' gzip - 9 f ', SUFFIX => ' gz ', },
#     clean => { FILES    => ' Devel-TraceLoad- *'
# },
# );
