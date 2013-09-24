# -*- CPERL -*-
#**********************************************************************
# Test cases for LaTeXML
#**********************************************************************
#use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use Data::Dumper;
use Test::More tests=>2;

eval {require Test::LeakTrace; 1;};
if ($@) {
  plan(skip_all=>"Test::LeakTrace not installed."); }
else {
  use Test::LeakTrace;
  # New API
  no_leaks_ok {
    use LaTeXML::Util::Config;
    use LaTeXML::Converter;

    my $config = LaTeXML::Util::Config->new(profile=>'math');
    my $converter = LaTeXML::Converter->get_converter($config);
    $converter->prepare_session($config);
    my $response = $converter->convert("a+b=i");
  };

  # Classic
  no_leaks_ok {
    use LaTeXML;
    my $latexml = LaTeXML->new(preload=>[], searchpaths=>[], includeComments=>0, verbosity=>-2);
    my $dom = $latexml->digestFile('literal:$a+b=c$');
  };
}
1;
