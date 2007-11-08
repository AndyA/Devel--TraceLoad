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

WriteAll(sign => 1);
