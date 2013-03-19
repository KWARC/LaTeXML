# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML
#**********************************************************************
#use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use Test::Builder;
use Test::LeakTrace;
# Note that this is a singlet; the same Builder is shared.
my $Test=Test::Builder->new();
$Test->expected_tests(1);
TODO: {
no_leaks_ok {
 use LaTeXML;
 } 'load LaTeXML without leaks';
my $latexml;
# no_leaks_ok {
#  	$latexml = LaTeXML->new(preload=>[], searchpaths=>[], includeComments=>0,
#  				verbosity=>-2);
#  	} 'instantiate LaTeXML object without leaks';
# no_leaks_ok {
#  $latexml->digestFile('literal:$a+b=c$');
# } 'Convert sample snippet without leaks';
}
1;