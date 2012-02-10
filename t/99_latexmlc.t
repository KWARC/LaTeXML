# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML Client-Server processing
#**********************************************************************
use FindBin;
use lib "$FindBin::Bin/lib";
use TestDaemon;

# For each test $name there should be $name.xml and $name.log
# (the latter from a previous `good' run of 
#  latexmlc {$triggers} $name
#).

daemon_tests('t/daemon/profiles');
#daemon_tests('t/daemon/formats');
#daemon_tests('t/daemon/runtimes');
#daemon_tests('t/daemon/complex');
#daemon_tests('t/daemon/api');

#**********************************************************************
1;
