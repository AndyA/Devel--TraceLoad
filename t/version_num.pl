# perl -Ilib -MDevel::TraceLoad t/version_num.pl
require v5.5.0;
require 5.6.0;
require 5.005_03;
# Can't locate  in @INC (@INC contains: C:/Perl/lib C:/Perl/site/lib .) at t\version_num.pl line 9.
my $version = 5.5.1;
require $version;
#Can't locate v5.5.1 in @INC (@INC contains: C:/Perl/lib C:/Perl/site/lib .) at t\version_num.pl line 12.
$version = 'v5.5.1';
require $version;

__END__
Can't locate  in @INC (@INC contains: C:/Perl/lib C:/Perl/site/lib .) at t\ve
rsion_num.pl line 7.
