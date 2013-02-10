# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML
#**********************************************************************
#use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLaTeXML;

my @missing = grep {defined} map {`kpsewhich $_.def` ? undef : $_ } qw(ly1enc t2aenc t2benc t2cenc);
if(@missing){
		plan(skip_all=>"TeX encoding definitions ".join(", ",@missing)." not installed.");
} else { 
	latexml_tests("t/encoding");
}