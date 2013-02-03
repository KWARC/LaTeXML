# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML Client-Server processing
#**********************************************************************
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use TestDaemon;

# For each test $name there should be $name.xml and $name.log
# (the latter from a previous `good' run of 
#  latexmlc {$triggers} $name
#).

if (! $ENV{STEXSTYDIR}) {
	plan(skip_all=>" sTeX bindings not found, set your STEXSTYDIR env var to test.");
} else {
	daemon_tests('t/daemon/profiles/stex');
}

#**********************************************************************
1;
