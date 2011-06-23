################ LaTeXML startup API #####################

package LaTeXML::Util::Startup;
use LaTeXML::Daemon;

our $PROFILES = {
standard => {
             identity => "Mojo for LaTeXML, v$version",
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             errlog=>0, post=>0, parallelmath=>0, input_counter=>0, input_limit=>0,
             local=>0, embed=>0, timeout=>60, format=>'xml',
             destination=>q{}, postdest=>q{}, log=>q{}, postlog=>q{}, base=>q{},
             procs_post=>{}, help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{},
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}], preload=>[], debugs=>[],
             authlist=>{}
            },
fragment => {
             identity => "Mojo for LaTeXML, v$version",
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             errlog=>0, post=>0, parallelmath=>0, input_counter=>0, input_limit=>0,
             local=>0, embed=>1, timeout=>60, format=>'xml',
             destination=>q{}, postdest=>q{}, log=>q{}, postlog=>q{}, base=>q{},
             procs_post=>{}, help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             fragment_preamble=>'standard_preamble.tex', fragment_postamble=>'standard_postamble.tex',
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{},
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}], preload=>[], debugs=>[],
             authlist=>{}
            },
math => {
             identity => "Mojo for LaTeXML, v$version",
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             errlog=>0, post=>1, parallelmath=>1, input_counter=>0, input_limit=>0,
             local=>0, embed=>0, timeout=>60, format=>'xml',
             destination=>q{}, postdest=>q{}, log=>q{}, postlog=>q{}, base=>q{},
             procs_post=>{pmml=>1,cmml=>1,keepTeX=>1},
             help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{}, 
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}],
             preload=>["LaTeX.pool", "article.cls", "amsmath.sty", "amsthm.sty", "amstext.sty", 
                       "amssymb.sty", "eucal.sty"],
             debugs=>[], authlist=>{}
        },
stex => {},#TODO
bibtex => {} #TODO
};

sub new {bless {daemons=>{},profiles=>$PROFILES}, shift;}

sub find_daemon {
  my ($self,$opt) = @_;
  my  $profile = lc($opt->{profile})||'custom';
  # TODO: Make this more flexible via an admin interface later
  my $d = $self->{daemons}->{$profile};
  if (! defined $d) {
    #Boot a daemon of this profile:
    if ($profile ne 'custom') {
      $d = $self->boot_profile($profile);
      $self->{daemons}->{$profile}=$d;
    } else {
      $d = $self->boot_custom($opt);
    }
  }
  return $d;
}

sub boot_profile {
  my ($self,$profile) = @_;
  #Start with the options set for this profile
  my $p_opt = $self->{profiles}->{$profile};
  $self->boot_custom($p_opt);
}

sub boot_custom {
  my ($self,$opt) = @_;
  #TODO: Do we need some care and attention for $opt here?
  return LaTeXML::Daemon->new(%$opt);
}

1;

