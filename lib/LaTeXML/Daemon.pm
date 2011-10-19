# /=====================================================================\ #
# |  LaTeXML::Daemon                                                    | #
# | Wrapper for LaTeXML processing with daemon-ish methods              | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <d.ginev@jacobs-university.de>                  #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Daemon;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Pod::Usage;
use LaTeXML;
use LaTeXML::Util::Pathname;
use LaTeXML::Util::WWW;
use LaTeXML::Util::Extras;
use LaTeXML::Post;
use LaTeXML::Post::Scan;
use LaTeXML::Util::ObjectDB;
use Carp;
use Data::Compare;
use feature "switch";

#**********************************************************************
our @IGNORABLE = qw(identity input_counter input_limit profile);

sub new {
  my ($class,$opts) = @_;
  binmode(STDERR,":utf8");
  prepare_options(undef,$opts);
  bless {defaults=>$opts,opts=>undef,ready=>0,
         latexml=>undef, digested_preamble=>undef}, $class;
}

sub prepare_session {
  my ($self,$opts) = @_;
  #0. Ensure all default keys are present:
  # (always, as users can specify partial options that build on the defaults)
  foreach (keys %{$self->{defaults}}) {
    $opts->{$_} = $self->{defaults}->{$_} unless exists $opts->{$_};
  }
  #TODO: Some options like paths and includes are additive, we need special treatment there
  #1. Check if there is some change from the current situation:
  my $nothingtodo=1 if Compare($opts, $self->{opts}, { ignore_hash_keys => [@IGNORABLE] });
  #1.1. If no change, nothing to do
  unless ($nothingtodo) {
    #1.2. If some change, prepare and set options:
    $self->prepare_options($opts);
    $self->{opts} = $opts;
  }
  # ... and initialize a session:
  $self->initialize_session unless ($nothingtodo && $self->{ready});
  return;
}

sub prepare_options {
  my ($self,$opts) = @_;
  undef $self unless ref $self; # Only care about daemon objects, ignore when invoked as static sub
  $opts->{timeout} = 600 unless defined $opts->{timeout}; # 10 minute timeout default
  $opts->{verbosity} = 0 unless defined $opts->{verbosity};
  $opts->{preload} = [] unless defined $opts->{preload};
  $opts->{paths} = ['.'] unless defined $opts->{paths};
  $opts->{dographics} = 1 unless defined $opts->{dographics};
  @{$opts->{paths}} = map {pathname_canonical($_)} @{$opts->{paths}};
  if ($opts->{post}) {
    # Fall back to default post processors if no preferences:
    %{$opts->{procs_post}}=%{$self->{defaults}->{procs_post}} if (defined $self && (! keys %{$opts->{procs_post}}));
    # Fall back to pmml as default
    $opts->{procs_post}->{'pmml'}=1 if (! keys %{$opts->{procs_post}});
  }
  # Any post switch implies post:
  $opts->{post}=1 if (keys %{$opts->{procs_post}});
  $opts->{parallelmath}=0 unless (keys %{$opts->{procs_post}} > 1);
  # Default: scan and crossref on, other advanced off
  $opts->{prescan}=undef unless defined $opts->{prescan};
  $opts->{dbfile}=undef unless defined $opts->{dbfile};
  $opts->{scan}=1 unless defined $opts->{scan};
  $opts->{index}=1 unless defined $opts->{index};
  $opts->{split}=undef unless defined $opts->{split};
  $opts->{splitat}='section' unless defined $opts->{splitat};
  $opts->{splitpath}=undef unless defined $opts->{splitpath};
  $opts->{splitnaming}='id' unless defined $opts->{splitnaming};
  $opts->{crossref}=1 unless defined $opts->{crossref};
  $opts->{sitedir}=undef unless defined $opts->{sitedir};
  $opts->{numbersections}=1 unless defined $opts->{numbersections};
  $opts->{urlstyle}='server' unless defined $opts->{urlstyle};
}

sub initialize_session {
  my ($self) = @_;
  # Prepare LaTeXML object
  my $latexml= new_latexml($self->{opts});
  # Demand errorless initialization
  my $init_status = $latexml->getStatusMessage;
  croak $init_status unless ($init_status !~ /error/i);
  # Load preamble:
  my $digested_preamble;
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($self->{opts}->{timeout});
    $digested_preamble = load_preamble($self->{opts},$latexml,$self->{digested_preamble});
    alarm(0);
    1;
  };
  if ($@) { #Fatal error
    if ($@ =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
      print STDERR "$@\n";
      print STDERR "Fatal error: preamble conversion timeout after ".$self->{opts}->{timeout}." seconds!\n";
      print STDERR "\nPreamble conversion incomplete (timeout): ".$latexml->getStatusMessage.".\n";
    } else {
      print STDERR "$@\n";
      print STDERR "\nPreamble conversion complete: ".$latexml->getStatusMessage.".\n";
    }
  }
  # Save in object:
  $self->{latexml} = $latexml;
  $self->{digested_preamble} = $digested_preamble;
  $self->{ready}=1;
}

sub convert {
  my ($self,$source) = @_;
  # Tie STDERR to log:
  my $log=q{}; my $status=q{};
  open(LOG,">",\$log) or croak "Can't redirect STDERR to log! Dying...";
  *ERRORIG=*STDERR;
  *STDERR = *LOG;

  # Initialize session if needed:
  $self->initialize_session unless $self->{ready};

  # Inform of identity, increase conversion counter
  my $opts = $self->{opts};
  print STDERR $opts->{identity}."\n" if $opts->{verbosity} >= 0;
  $opts->{input_counter}++;

  # Prepare content and determine source type
  my $content = $self->prepare_content($source);

  # Prepare daemon frame
  my $latexml = $self->{latexml};
  $latexml->withState(sub {
                        my($state)=@_; # Sandbox state
                        # Save preamble information for further use:
                        $state->assignValue('_preamble_loaded',$opts->{preamble},'global');
                        $state->assignValue('_authlist',$opts->{authlist},'global');
                        $state->pushDaemonFrame; });

  # First read and digest whatever we're given.
  my ($digested,$dom,$serialized);
  # Digest source:
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    if ($opts->{source_type} eq 'url') {
      $digested = $latexml->digestString($content,preamble=>$opts->{'fragment_preamble'},
                                         postamble=>$opts->{'fragment_postamble'},source=>$source,noinitialize=>1);
    } elsif ($opts->{source_type} eq 'file') {
      if ($opts->{type} eq 'bibtex') {
        # TODO: Do we want URL support here?
        $digested = $latexml->digestBibTeXFile($content,preamble=>$opts->{'fragment_preamble'},
                                               postamble=>$opts->{'fragment_postamble'},noinitialize=>1);
      } else {
        $digested = $latexml->digestFile($content,preamble=>$opts->{'fragment_preamble'},
                                         postamble=>$opts->{'fragment_postamble'},noinitialize=>1);
      }}
    elsif ($opts->{source_type} eq 'string') {
      $digested = $latexml->digestString($content,preamble=>$opts->{'fragment_preamble'},
                                         postamble=>$opts->{'fragment_postamble'},noinitialize=>1);
    }
    
    # Now, convert to DOM and output, if desired.
    if ($digested) {
      $digested = LaTeXML::List->new($self->{digested_preamble},$digested)
        if defined $self->{digested_preamble};
      local $LaTeXML::Global::STATE = $$latexml{state};
      if ($opts->{format} eq 'tex') {
        $serialized = LaTeXML::Global::UnTeX($digested);
      } elsif ($opts->{format} eq 'box') {
        $serialized = $digested->toString;
      } else {
        $dom = $latexml->convertDocument($digested);
        $serialized = $dom->toString(1) unless $opts->{post};
      }}
    alarm(0);
    1;
  };
   if ($@) {#Fatal occured!
    if ($@ =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
      print STDERR "$@\n";
      print STDERR "Fatal error: main conversion timeout after ".$opts->{timeout}." seconds!\n";
      print STDERR "\nConversion incomplete (timeout): ".$latexml->getStatusMessage.".\n";
    } else {
      print STDERR "$@\n";
      print STDERR "\nConversion complete: ".$latexml->getStatusMessage.".\n";
    }
    # Close and restore STDERR to original condition.
    close LOG;
    *STDERR=*ERRORIG;
    $self->{ready}=0; return {result=>undef,log=>$log,status=>$latexml->getStatusMessage};
  }
  print STDERR "\nConversion complete: ".$latexml->getStatusMessage.".\n";
  $status = $latexml->getStatusMessage;
  # End daemon run, by popping frame:
  $latexml->withState(sub {
                        my($state)=@_; # Remove current state frame
                        $state->popDaemonFrame;
                        $$state{status} = {};
                      });

  my $result = $dom;
  $result = $self->convert_post($dom) if ($opts->{post} && $dom && (!$opts->{noparse}));

  # Close and restore STDERR to original condition.
  close LOG;
  *STDERR=*ERRORIG;
  delete $opts->{source_type};
  my $return = {result=>$result,log=>$log,status=>$status};
}

########## Helper routines: ############

sub convert_post {
  my ($self,$dom) = @_;
  my $opts = $self->{opts};
  my ($style,$parallel,$proctypes,$format,$verbosity,$defaultcss,$embed) = 
    map {$opts->{$_}} qw(stylesheet parallelmath procs_post format verbosity defaultcss embed);
  $verbosity = $verbosity||0;
  my %PostOPS = (verbosity=>$verbosity,siteDirectory=>".");
  #Postprocess
  #Default is XHTML, XML otherwise (TODO: Expand)
  $format="xml" if ($style);
  $format="xhtml" unless (defined $format);
  if (!$style) {
    given ($format) {
      when ("xhtml") {$style = "LaTeXML-xhtml.xsl";}
      when ("html") {$style = "LaTeXML-html.xsl";}
      when ("html5") {$style = "LaTeXML-html5.xsl";}
      when ("xml") {undef $style;}
      default {Error("Unrecognized target format: $format");}
    }}
  my @css=();
  unshift (@css,"core.css") if ($defaultcss);
  $parallel = $parallel||0;
  my $doc;
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    $doc = LaTeXML::Post::Document->new($dom,nocache=>1);
    alarm(0);
    1;
  };
  if ($@) {                     #Fatal occured!
    if ($@ =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
      print STDERR "$@\n";
      print STDERR "Fatal error: postprocessing couldn't create document: timeout after "
        . $opts->{timeout} . " seconds!\n";
    } else {
      print STDERR "Fatal: Post-processor crashed! $@\n";
    }
    #Since this is postprocessing, we don't need to do anything
    #   just avoid crashing... and exit
    undef $doc;
    return undef;
  }

  my @procs=();
  #TODO: Add support for the following:
  my $dbfile = $opts->{dbfile};
  if (defined $dbfile && !-f $dbfile) {
    if (my $dbdir = pathname_directory($dbfile)) {
      pathname_mkdir($dbdir);
    }
  }
  my $DB = LaTeXML::Util::ObjectDB->new(dbfile=>$dbfile,%PostOPS);
  my @bibliographies = undef;
  ### Advanced Processors:
  if ($opts->{split}) {
    require 'LaTeXML/Post/Split.pm';
    push(@procs,LaTeXML::Post::Split->new(split_xpath=>$opts->{splitpath},splitnaming=>$opts->{splitnaming},
                                          %PostOPS)); }
  our $scanner = ($opts->{scan} || $DB) && LaTeXML::Post::Scan->new(db=>$DB,%PostOPS);
  if ($opts->{scan}) {
    push(@procs,$scanner);
  }
  if (!$opts->{prescan}) {
    if ($opts->{index}) {
      require 'LaTeXML/Post/MakeIndex.pm';
      push(@procs,LaTeXML::Post::MakeIndex->new(db=>$DB, permuted=>$opts->{permutedindex},
                                                split=>$opts->{splitindex}, scanner=>$scanner,
                                                %PostOPS)); }
  if (@bibliographies) {
    require 'LaTeXML/Post/MakeBibliography.pm';
    push(@procs,LaTeXML::Post::MakeBibliography->new(db=>$DB, bibliographies=>[@bibliographies],
						     split=>$opts->{splitbibliography}, scanner=>$scanner,
						     %PostOPS)); }
  if ($opts->{crossref}) {
    require 'LaTeXML/Post/CrossRef.pm';
    push(@procs,LaTeXML::Post::CrossRef->new(db=>$DB,urlstyle=>$opts->{urlstyle},format=>$format,
					     ($opts->{numbersections} ? (number_sections=>1):()),
					     ($opts->{navtoc} ? (navigation_toc=>$opts->{navtoc}):()),
					     %PostOPS)); }

  if ($opts->{mathimages}) {
    require 'LaTeXML/Post/MathImages.pm';
    push(@procs,LaTeXML::Post::MathImages->new(magnification=>$opts->{mathimagemag},%PostOPS));
  }
  if ($opts->{picimages}) {
    require 'LaTeXML/Post/PictureImages.pm';
    push(@procs,LaTeXML::Post::PictureImages->new(%PostOPS));
  }
  if ($opts->{dographics}) {
    # TODO: Rethink full-fledged graphics support
    require 'LaTeXML/Post/Graphics.pm';
    my @g_options=();
    push(@procs,LaTeXML::Post::Graphics->new(@g_options,%PostOPS));
  }

  require LaTeXML::Post::MathML;
  require LaTeXML::Post::OpenMath;
  require LaTeXML::Post::PurgeXMath;
  my @mprocs=();

  push (@mprocs, LaTeXML::Post::MathML::Presentation->new(%PostOPS)) if $proctypes->{'pmml'};
  push (@mprocs, LaTeXML::Post::MathML::Content->new(%PostOPS)) if $proctypes->{'cmml'};
  push (@mprocs, LaTeXML::Post::OpenMath->new(%PostOPS)) if $proctypes->{'openmath'};
  my $main = shift(@mprocs);
  $main->setParallel(@mprocs) if $parallel;
  $main->keepTeX if ($$proctypes{'keepTeX'} && $parallel);
  push(@procs,$main);
  push(@procs,@mprocs) unless $parallel;
  push(@procs, LaTeXML::Post::PurgeXMath->new(%PostOPS)) unless $$proctypes{'keepXMath'};

  require LaTeXML::Post::XSLT;
  my @csspaths=();
#  if (@css) {
#    foreach my $css (@css) {
#      $css .= '.css' unless $css =~ /\.css$/;
#      # Dance, if dest is current dir, we'll find the old css before the new one!
#      my @csssources = map {pathname_canonical($_)}
#                            pathname_findall($css,types=>['css'],
#                                            (),
#                                            installation_subdir=>'style');
#      my $csspath = pathname_absolute($css,pathname_directory('.'));
#      while (@csssources && ($csssources[0] eq $csspath)) {
#        shift(@csssources);
#      }
#      my $csssource = shift(@csssources);
#      pathname_copy($csssource,$csspath)  if $csssource && -f $csssource;
#      push(@csspaths,$csspath);
#    }}

  push(@procs,LaTeXML::Post::XSLT->new(stylesheet=>$style,
					 parameters=>{number_sections
						      =>("true()"),
                                                      (@csspaths ? (CSS=>[@csspaths]):()),},
                                       %PostOPS)) if $style;
  }
  my $postdoc;
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    ($postdoc) = LaTeXML::Post::ProcessChain($doc,@procs);
    $DB->finish;
    alarm(0);
    1;
  };
  if ($@) {                     #Fatal occured!
    if ($@ =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
      print STDERR "$@\n";
      print STDERR "Fatal error: postprocessing timeout after ".$opts->{timeout}." seconds!\n";
    } else {
      print STDERR "Fatal: Post-processor crashed! $@\n";
    }
    return;
  }

  return $postdoc;
}

sub new_latexml {
  my $opts = shift;
  my $latexml = LaTeXML->new(preload=>[@{$opts->{preload}}], searchpaths=>[@{$opts->{paths}}],
                          graphicspaths=>['.'],
			  verbosity=>$opts->{verbosity}, strict=>$opts->{strict},
			  includeComments=>$opts->{comments},inputencoding=>$opts->{inputencoding},
			  includeStyles=>$opts->{includestyles},
			  documentid=>$opts->{documentid},
			  nomathparse=>$opts->{noparse});
  if(my @baddirs = grep {! -d $_} @{$opts->{paths}}){
    warn $opts->{identity}.": these path directories do not exist: ".join(', ',@baddirs)."\n"; }

  $latexml->withState(sub {
                        my($state)=@_;
                        $latexml->initializeState('TeX.pool', @{$$latexml{preload} || []});
                      });
  return $latexml;
}

sub load_preamble {
  my ($opts,$latexml,$original) = @_;
  my $digested = undef;
  # Preload the preamble if any (and not loaded)
  if ($opts->{preamble} && ($opts->{preamble_loaded} ne $opts->{preamble})) {
    #TODO: It is difficult to digest 2 files via LaTeXML into 1 XML output right now...
    my $response=auth_get($opts->{preamble},$opts->{authlist});
    if ($response->is_success) {
      my $content = $response->content;
      $digested = $latexml->digestString($content,source=>$opts->{preamble},noinitialize=>1);
      $opts->{preamble_loaded} = $opts->{preamble};
    } else {
      if ($opts->{preamble}=~/\s|\\/) {#Guess it's a string?
        $digested = $latexml->digestString($opts->{preamble},source=>"Anonymous string",noinitialize=>1);
      } else {
        if (!$opts->{local}) { carp "File preamble allowed only when 'local' is enabled!"; return; }
        $digested = $latexml->digestFile($opts->{preamble},noinitialize=>1);
        $opts->{preamble_loaded} = $opts->{preamble};
      }}
  }
  # Demand errorless conversion:
  my $init_status = $latexml->getStatusMessage;
  croak $init_status unless ($init_status !~ /error/i);
  $digested = $original unless defined $digested;
  return $digested;
}

sub prepare_content {
  my ($self,$source)=@_;
  $source=~s/\n$//g; # Eliminate trailing new lines

  my $opts=$self->{opts};
  given ($opts->{source_type}) {
    when ("string") {return $source;}
    when ("file") { if ($opts->{local}) {
                    my $file = pathname_find($source,types=>['tex',q{}]);
                    $file = pathname_canonical($file) if $file;
                    #Recognize bibtex case
                    $opts->{type} = 'bibtex' if ($opts->{type} eq 'auto') && ($file =~ /\.bib$/);
                    return $file; }
                  else {print STDERR "File input only allowed when 'local' is enabled,"
                                    ."falling back to string input..";
                        $opts->{source_type}="string"; return $source; }}
    when ("url") {  my $response = auth_get($source,$opts->{authlist});
                  if ($response->is_success) {return $response->content;} else {
                  print STDERR "TODO: Flag a retrieval error and do something smart?"; return undef;}}
    default { # Guess the input type:
      my @source_lines = split(/\n/,$source);
      if (scalar(@source_lines)>1) {$opts->{source_type}="string"; return $source; }
      if ($opts->{local}) {
        my $file = pathname_find($source,types=>['tex',q{}]);
        $file = pathname_canonical($file) if $file;
        #Recognize bibtex case
        $opts->{type} = 'bibtex' if ($opts->{type} eq 'auto') && ($file =~ /\.bib$/);
        if ($file) {$opts->{source_type}="file"; return $file; }
      }
      my $response = auth_get($source,$opts->{authlist});
      if ($response->is_success) {$opts->{source_type}="url"; return $response->content; }
      $opts->{source_type}="string"; return $source;
    }
  }
}

1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Daemon> - Daemon object and API for LaTeXML and LaTeXMLPost conversion.

=head1 SYNOPSIS

    use LaTeXML::Daemon;
    my $daemon = LaTeXML::Daemon->new($opts);
    $daemon->prepare_session($opts);
    my ($result,$status,$log) = $daemon->convert($tex);

=head1 DESCRIPTION

A Daemon object represents a converter instance and can convert files on demand, until dismissed.

=head2 METHODS

=over 4

=item C<< my $daemon = LaTeXML::Daemon->new($opts); >>

Creates a new daemon object with a given options hash reference $opts.
        $opts specifies the default fallback options for any conversion job with this daemon.

=item C<< $daemon->prepare_session($opts); >>

RECOMMENDED preparation routine for EXTERNAL use (also see Synopsis).

Top-level preparation routine that prepares both a correct options object and an initialized LaTeXML object,
          using the "initialize_options" and "initialize_session" routines, when needed.
Contains optimization checks that skip initializations unless necessary.
Also adds support for partial option specifications during daemon runtime,
     falling back on the option defaults given when daemon object was created.

=item C<< $daemon->initialize_session($opts); >>

Given an options hash reference $opts, initializes a session by creating a new LaTeXML object 
      with initialized state and loading a daemonized preamble (if any).
Sets the "ready" flag to true, making a subsequent "convert" call immediately possible.

=item C<< $daemon->prepare_options($opts); >>

Given an options hash reference $opts, performs a set of assignments of meaningful defaults (when needed)
      and normalizations (for relative paths, etc).

=item C<< my ($result,$status,$log) = $daemon->convert($tex); >>

Converts a TeX input string $tex into the LaTeXML::Document object $result.
Supplies detailed information of the conversion log ($log),
         as well as a brief conversion status summary ($status).

=back

=head2 INTERNAL ROUTINES

=over 4

=item C<< my $latexml = new_latexml($opts); >>

Creates a new LaTeXML object and initializes its state.

=item C<< my $digested_pre = load_preamble($opts,$latexml,$previous_digested); >>

Loads a daemon preamble (if needed), adding its definitions to the LaTeXML state and
      maintaining a list of digested boxes.

=item C<< my $content = $self->prepare_content($source); >>

Determines the source type (URL, file or string) and returns the retrieved content.
The determined input type is saved as a "source_type" field in the daemon object.

=item C<< my $postdoc = $daemon->convert_post($dom); >>

Post-processes a LaTeXML::Document object $dom into a final format,
               based on the preferences specified in $self->{opts}.
Typically used within "convert".

=back

=head2 CUSTOMIZATION OPTIONS

 Options: key=>value pairs
 preload => [modules]   optional modules to be loaded
 includestyles          allows latexml to load raw *.sty file;
                        off by default.
 preamble => [files]    loads tex files with document frontmatter.
 postamble => [files]   loads tex files with document backmatter. (TODO)

 paths => [dir]         paths searched for files,
                        modules, etc;
 log => file            specifies log file, reuqires 'local'
                        default log output: STDERR
 documentid => id       assign an id to the document root. (TODO)
 timeout => seconds     designate an expiration time limit
                        for the conversion job
 verbosity => level     verbosity of reporting, 0 or negative
                        for silent, positive for increasing detail
 strict                 makes latexml less forgiving of errors
 type => bibtex         processes the file as a BibTeX bibliography.
 format => box|xml|tex  output format
                        (Boxes, XML document or expanded TeX document)
 noparse                suppresses parsing math (default: off)
 post                   requests a followup post-processing
 embed                  requests an embeddable XHTML snippet
                        (requires: 'post')
 stylesheet => file     specifies a stylesheet,
                        to be used by the post-processor.
 css => [cssfiles]      css stylesheets to html/xhtml
 nodefaultcss           disables the default css stylesheet
 post_procs->{pmml}     converts math to Presentation MathML
                        (default for xhtml format)
 post_procs->{cmml}     converts math to Content MathML
 post_procs->{openmath} converts math to OpenMath 
 parallelmath           requests parallel math markup for MathML
                        (off by default)
 post_procs->{keepTeX}  keeps the TeX source of a formula as a MathML
                        annotation element (requires 'parallelmath')
 post_procs->{keepXMath} keeps the XMath of a formula as a MathML
                         annotation-xml element (requires 'parallelmath')
 nocomments              omit comments from the output
 inputencoding => enc    specify the input encoding.
 debug => package        enables debugging output for the named
                         package

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
