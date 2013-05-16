# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML Client-Server processing
#**********************************************************************
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use TestLaTeXML;
# For each test $name there should be $name.xml and $name.log
# (the latter from a previous `good' run of 
#  latexmlc {$triggers} $name
#).
eval {require Marpa::R2; 1;};
if ($@) {
	plan(skip_all=>"Marpa::R2 not installed.");
} else {
	TODO: {
		local $TODO = ' Marpa tests not yet inspected...';
		latexml_tests('t/daemon/marpa');
	}
}

#**********************************************************************
1;
