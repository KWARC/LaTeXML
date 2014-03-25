# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML
#**********************************************************************
#use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use Data::Dumper;
use Test::More;

eval {use Test::LeakTrace; 1;};
if ($@) {
  plan(skip_all=>"Test::LeakTrace not installed."); }
if ($XML::LibXML::VERSION < 2.0106) {
  plan(skip_all=>"Leaky XML::LibXML, please update to 2.0106 or newer."); }
else {
  plan(tests=>1);
  use Test::LeakTrace;
  # New API
  no_leaks_ok {
    use LaTeXML::Common::Config;
    use LaTeXML;

    my $config = LaTeXML::Common::Config->new(profile=>'math');
    my $converter = LaTeXML->get_converter($config);
    $converter->prepare_session($config);
    my $response = $converter->convert("literal:a+b=i");
  };
}
1;
