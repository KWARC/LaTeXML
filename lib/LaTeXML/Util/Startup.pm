################ LaTeXML startup API #####################

package LaTeXML::Util::Startup;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::Pathname;
use LaTeXML::Daemon;
use Data::Dumper;
$Data::Dumper::Terse = 1;          # don't output names where feasible
$Data::Dumper::Indent = 3;         # turn off all pretty print
use feature qw(switch);

our $DB_FILE = 'LaTeXML_Startup.cache';
#TODO: Eliminate redundant options
our $PROFILES = {
standard => {
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             post=>0, parallelmath=>0, input_counter=>0, input_limit=>0,
             embed=>0, timeout=>60, format=>'xml', base=>q{},
             procs_post=>{}, help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{},
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}], preload=>[], debugs=>[],
             authlist=>{}
            },
fragment => {
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>1,
             post=>1, parallelmath=>1, input_counter=>0, input_limit=>0,
             embed=>1, timeout=>60, format=>'xhtml', base=>q{},
             procs_post=>{pmml=>1,cmml=>1,keepTeX=>1}, help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             fragment_preamble=>'standard_preamble.tex', fragment_postamble=>'standard_postamble.tex',
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{},
             documentid =>q{}, type=>'auto', css => [], paths => [q{.},q{/usr/share/texmf-texlive/tex/latex/nicetext/}], debugs=>[],
             preload=>["LaTeX.pool", "article.cls", "amsmath.sty", "amsthm.sty", "amstext.sty",
                       "amssymb.sty", "eucal.sty","[dvipsnames]color.sty",'url.sty','hyperref.sty','wiki.sty'],
             authlist=>{}, force_ids=>1
            },
math => {
             verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             post=>1, parallelmath=>1, input_counter=>0, input_limit=>0,
             embed=>0, timeout=>60, format=>'xhtml', base=>q{},
             procs_post=>{pmml=>1,cmml=>1,keepTeX=>1},
             help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{}, 
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}],
             preload=>["LaTeX.pool", "article.cls", "amsmath.sty", "amsthm.sty", "amstext.sty", 
                       "amssymb.sty", "eucal.sty","[dvipsnames]color.sty",'url.sty','hyperref.sty'],
             debugs=>[], authlist=>{}
        },

'stex-oregano' => {identity=>"Mojo for LaTeXML, v$version; Profile: stex",
         paths=>['/arXMLiv/trunk/build/contrib/package/webgraphic',
                 '/arXMLiv/trunk/build/contrib/stex/sty',
                 '/arXMLiv/trunk/build/contrib/stex/rnc',
                 '/arXMLiv/trunk/build/contrib/stex/rnc/omdoc',
                 '/arXMLiv/trunk/build/contrib/stex/sty/modules',
                 '/arXMLiv/trunk/build/contrib/stex/sty/statements',
                 '/arXMLiv/trunk/build/contrib/stex/sty/sproof',
                 '/arXMLiv/trunk/build/contrib/stex/sty/omtext',
                 '/arXMLiv/trunk/build/contrib/stex/sty/omdoc',
                 '/arXMLiv/trunk/build/contrib/stex/sty/sref',
                 '/arXMLiv/trunk/build/contrib/stex/sty/presentation',
                 '/arXMLiv/trunk/build/contrib/stex/sty/dcm',
                 '/arXMLiv/trunk/build/contrib/stex/sty/reqdoc',
                 '/arXMLiv/trunk/build/contrib/stex/sty/metakeys',
                 '/arXMLiv/trunk/build/contrib/stex/sty/mikoslides',
                 '/arXMLiv/trunk/build/contrib/stex/sty/problem',
                 '/arXMLiv/trunk/build/contrib/stex/sty/hwexam',
                 '/arXMLiv/trunk/build/contrib/stex/sty/cmath',
                 '/arXMLiv/trunk/build/contrib/stex/sty/etc',
                 '/arXMLiv/trunk/build/contrib/stex/sty/stc-sty',
                 '/arXMLiv/trunk/build/contrib/stex/sty/stc-sty/ded',
                 '/arXMLiv/trunk/build/contrib/stex/sty/stc-sty/ed',
                 '/arXMLiv/trunk/sty'],
         profile=>'fragment',
         stylesheet=>'/arXMLiv/trunk/build/contrib/stex/xsl/omdocpost.xsl',
         nodefaultcss=>1, post=>1, procs_post=>{pmml=>1,openmath=>1},
         preamble=>'http://srv.tntbase.org/repos/cicm/ex/webpre.tex',
         verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
         input_counter=>0, input_limit=>0,
         embed=>0, timeout=>60, format=>'xml', base=>q{},
         help=>0, showversion=>0, summary=>0,icon=>0, inputencoding=>q{},
         documentid =>q{}, type=>'auto', css => [],
         preload=>['.'], debugs=>[], authlist=>{}},

#bibtex => {identity=>"Mojo for LaTeXML, v$version; Profile: bibtex"}, #TODO
linguistic => { verbosity=>0,  strict=>0,  comments=>1,  noparse=>0,  includestyles=>0,
             noparse=>1, post=>0, parallelmath=>0, input_counter=>0, input_limit=>0,
             embed=>0, timeout=>60, format=>'xml', base=>q{},
             procs_post=>{}, help=>0, showversion=>0, preamble=>q{}, preamble_loaded=>q{},
             stylesheet=>q{},defaultcss=>1,summary=>0,icon=>0, inputencoding=>q{},
             documentid =>q{}, type=>'auto', css => [], paths => [q{.}], preload=>[], debugs=>[],
             authlist=>{}}
};

sub new {
  ($class,%opts) = @_;
  my $dbfile = $opts{dbfile}||$DB_FILE;
  if(defined $dbfile && !-f $dbfile){
    if(my $dbdir = pathname_directory($dbfile)){
      pathname_mkdir($dbdir); }}
  my $DB = LaTeXML::Util::ObjectDB->new(dbfile=>$dbfile);
  foreach (keys %$PROFILES) { # Cash profiles in DB
    next if defined $DB->lookup("profile:$_");
    $DB->register("profile:$_",%{$PROFILES->{$_}});
  }
  if (defined $options->{profiles}) {# Also cash $options' profiles in DB
    foreach (keys %{$options->{profiles}}) {
      next if defined $DB->lookup("profile:$_");
      $DB->register("profile:$_",%{$options->{profiles}->{$_}});
    }}
  bless {daemons=>{},db=>$DB}, $class;}

###########################################
#### Daemon Management #####
###########################################


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
  my $p_opt = $self->{db}->lookup("profile:$profile");
  $self->boot_custom($p_opt->as_hashref);
}

sub boot_custom {
  my ($self,$opt) = @_;
  #TODO: Do we need some care and attention for $opt here?
  return LaTeXML::Daemon->new(%$opt);
}

###########################################
#### User Management #####
###########################################

sub users {
  my ($self) = @_;
  [ sort map {s/^user://; $_;} grep {/^user:/} grep defined, $self->{db}->getKeys ];
}

sub exists_user {
  my ($self,$user) = @_;
  return defined $self->{db}->lookup("user:$user");
}

sub summary_user {
  my ($self,$user) = @_;
  my $entry = $self->{db}->lookup("user:$user");
  my $summary = '<table class="summary"><tr><th>Property</th><th>Value</th></tr>';
  foreach ($entry->getKeys){
    next if $_ =~ /^pass|key$/; #No pass|key display
    $summary .= "<tr><td>$_</td><td>".Dumper($entry->getValue($_))."</td></tr>\n";
  }
  $summary.="</table>";
  $summary;
}

sub verify_user {
  my ($self,$user,$pass) = @_;
  my $user_entry = $self->{db}->lookup("user:$user");
  if (defined $user_entry && ($pass eq $user_entry->getValue('pass'))) {
    return $user_entry->getValue('role')||1;
  }
  return 0;
}

sub modify_user {
  my ($self,$user,$pass,$role,$default) = @_;
  return "Error: Username can't be empty!\n" unless $user;
  my $user_entry = $self->{db}->lookup("user:$user");
  $role = 'standard' unless $role;
  $default = 'standard' unless $default;
  if (!$user_entry) { #New:
    return "Error: Username and Password can't be empty!\n" unless $user && $pass;
    $self->{db}->register("user:$user",pass=>$pass,role=>$role,default=>$default);
    return "Successfully added user $user with role:$role, default profile:$default!\n";
  } else { #Modify:
    $pass = $user_entry->getValue('pass') unless $pass;
    $role = $user_entry->getValue('role') unless $role;
    $default = $user_entry->getValue('default') unless $default;

    $user_entry->setValues(pass=>$pass,role=>$role,default=>$default);
    return "Successfully modified user $user!\n";
  }
}

sub delete_user {
  my ($self,$user) = @_;
  $self->{db}->purge("user:$user");
  return "Successfully deleted user $user!\n";
}

sub lookup_user_property {
 my ($self,$user,$prop) = @_;
 my $user_entry = $self->{db}->lookup("user:$user");
 return undef unless defined $user_entry;
 $user_entry->getValue($prop);
}

###########################################
#### Profile Management #####
###########################################


sub modify_profile {
  my($self,$profile,$opts) = @_;
  $self->{db}->register("profile:$profile",%$opts);
}

sub get_profile {
  my ($self,$profile) = @_;
  my $p_entry = $self->{db}->lookup("profile:$profile");
  return $p_entry->as_hashref if defined $p_entry;
  undef;
}

sub profiles {
  my ($self) = @_;
  [ sort map {s/^profile://; $_;} grep {/^profile:/} grep defined, $self->{db}->getKeys ];
}

our $profile_templates = {
                  # Arrayrefs:
                  css => 'arrayref|text',
                  paths => 'arrayref|text',
                  preload => 'arrayref|text',
                  debugs => 'arrayref|text',
                  # Hashrefs:
                  procs_post => 'hashref|pmml:bool,cmml:bool,keepTeX:bool,keepXMath:bool',
                  authlist => 'hashref|user:text,pass:pass',
                  # Bools:
                  noparse => 'bool',
                  defaultcss => 'bool',
                  local => 'bool',
                  comments => 'bool',
                  icon => 'bool',
                  embed => 'bool',
                  post => 'bool',
                  summary => 'bool',
                  parallelmath => 'bool',
                  showversion => 'bool',
                  strict => 'bool',
                  includestyles => 'bool',
                  'force_ids' => 'bool',
                  # Text:
                  stylesheet => 'text',
                  inputencoding => 'text',
                  base => 'text',
                  preamble => 'text',
                  documentid => 'text',
                  # Number:
                  input_limit => 'number',
                  timeout => 'number',#Do we want this?
                  # Choice:
                  format => 'select|xml,tex,box',
                  verbosity => 'select|-5,-1,0,1,5',
                  type => 'select|auto,bib'
};

sub summary_profile {
  my ($self,$profile) = @_;
  my $entry = $self->{db}->lookup("profile:$profile");
  my $summary = '<div class="left-div"><table class="form-table">';
  my @keys = sort $entry->getKeys;
  my $split_when = int(scalar(@keys)/2)+1;
  foreach my $e(@keys) {
    my $t = $profile_templates->{$e};
    $summary.= inner_handle($e,$t,$entry);
    $split_when--;
    unless ($split_when) {  $summary.='</table></div><div class="right-div"><table class="form-table">';}
  }
  $summary.='</table></div><div class="left-div"><table class="form-table"><tr><td></td><td class="input"><input type="submit" value="Save" /></td></tr>';
  $summary.='</table></div>';
}

sub inner_handle {
  my ($e,$t,$entry,$flag) = @_;
  my ($type, $spec) = split(/\|/,$t);
  my $summary = q{};
  given ($type) {
    when ('bool') {    $summary .= "<tr><td>$e</td><td class=\"input\"><select name=\"$e\">";
                       if ($entry->getValue($e)||$flag) {
                         $summary .= "<option value=\"1\">yes</option><option value=\"0\">no</option>";
                       } else {
                         $summary .= "<option value=\"0\">no</option><option value=\"1\">yes</option>";
                       }
                       $summary.="</td></tr>\n"; }
    when ('text') { $summary .= "<tr><td>$e</td><td class=\"input\"><input name=\"$e\"></td></tr>\n"; }
    when ('pass') { $summary .= "<tr><td>$e</td><td class=\"input\"><input type=\"password\" name=\"$e\"></td></tr>\n"; }
    when ('number') { $summary .= "<tr><td>$e</td><td class=\"input\"><input name=\"$e\"></td></tr>\n"; }
    when ('select') {
      $summary .= "<tr><td>$e</td><td class=\"input\"><select name=\"$e\">";
      my $sel = $entry->getValue($e);
      foreach (split(',',$spec)) {
        if ($sel ne $_ ) {
          $summary .= "<option value=\"$_\">$_</option>";
        } else {
          $summary .= "<option value=\"$_\" selected>$_</option>";
        }
      }
      $summary.="</td></tr>\n"; }
    when ('arrayref') {
      my $current = $entry->getValue($e);
      $summary .= "<tr><td>$e";
      $summary .= "</td><td class=\"input\"><input name=\"$e\" value=\"$_\"></td></tr><tr><td>\n" foreach @$current||('');
      $summary.= "</td><td></td></tr>";
    }
    when ('hashref') {
      my $current = $entry->getValue($e);
      $summary .= "<tr><td><b>$e</b><td></td></tr>";
      foreach (split(/,/,$spec)) {
        my ($in_e,$in_t) = split(/:/,$_);
        $summary .= inner_handle($in_e,$in_t,$entry,$current->{$in_e});
      }
      $summary .= "<tr><td><b>------</b><td></td></tr>";
    }
    default {}
  }
  $summary;
}

sub template_profile {
  my ($self,$profile,$value) = @_;
  # Add template for adding a new profile
}
###########################################
#### Statistics #####
###########################################


sub status {
  my ($self) = @_;
  #TODO: Provide info on the status of the DB, table of booted daemons with their profiles, etc.
  $self->{db}->status;
}

 #TODO: Also provide an interface for examining and changing the options of existing daemons

1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Util::Startup> - Provide an API for starting and maintaining a stash of LaTeXML converters

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<< foo >>

bar

=back

=head2 CUSTOMIZATION OPTIONS

 TODO?  --timeout=secs     Set a timeout value for inactivity.
                    Default is 60 seconds, set 0 to disable.


=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
