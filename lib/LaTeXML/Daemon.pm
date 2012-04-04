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
use Data::Dumper;
use LaTeXML;
use LaTeXML::Global;
use LaTeXML::Util::Pathname;
use LaTeXML::Util::WWW;
use LaTeXML::Util::Extras;
use LaTeXML::Post;
use LaTeXML::Post::Scan;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::Extras;
use Carp;

#**********************************************************************
our @IGNORABLE = qw(identity profile port preamble postamble port destination log removed_math_formats whatsin whatsout math_formats input_limit input_counter);

sub new {
  my ($class,$opts) = @_;
  binmode(STDERR,":utf8");
  prepare_options(undef,$opts);
  bless {defaults=>$opts,opts=>undef,ready=>0,
         latexml=>undef}, $class;
}

sub prepare_session {
  my ($self,$opts) = @_;
  #0. Ensure all default keys are present:
  # (always, as users can specify partial options that build on the defaults)
  foreach (keys %{$self->{defaults}}) {
    $opts->{$_} = $self->{defaults}->{$_} unless exists $opts->{$_};
  }
  # 1. Ensure option "sanity"
  $self->prepare_options($opts);

  #TODO: Some options like paths and includes are additive, we need special treatment there
  #2. Check if there is some change from the current situation:
  my $opts_tmp={};
  #2.1 Don't compare ignorable options
  foreach (@IGNORABLE) {
    $opts_tmp->{$_} = $opts->{$_};
    if (exists $self->{opts}->{$_}) {
      $opts->{$_} = $self->{opts}->{$_};
    } else {
      delete $opts->{$_};
    }
  }
  #2.2. Compare old and new $opts hash
  my $something_to_do=1 unless LaTeXML::Util::ObjectDB::compare($opts, $self->{opts});
  #2.3. Reinstate ignorables, set new options to daemon:
  $opts->{$_} = $opts_tmp->{$_} foreach (@IGNORABLE);
  $self->{opts} = $opts;

  #3. If there is something to do, initialize a session:
  $self->initialize_session if ($something_to_do || (! $self->{ready}));

  return;
}

sub prepare_options {
  my ($self,$opts) = @_;
  undef $self unless ref $self; # Only care about daemon objects, ignore when invoked as static sub
  $opts->{timeout} = 600 unless defined $opts->{timeout}; # 10 minute timeout default
  $opts->{format} = 'xml' unless defined $opts->{format};
  $opts->{verbosity} = 10 unless defined $opts->{verbosity};
  $opts->{preload} = [] unless defined $opts->{preload};
  $opts->{paths} = ['.'] unless defined $opts->{paths};
  $opts->{dographics} = 1 unless defined $opts->{dographics};
  @{$opts->{paths}} = map {pathname_canonical($_)} @{$opts->{paths}};
  if ($opts->{post}) {
    # Fall back to default post processors if no preferences:
    @{$opts->{math_formats}}=@{$self->{defaults}->{math_formats}} if (defined $self && (! @{$opts->{math_formats}}));
  }
  if ($opts->{format}=~/html/i) { #HTML-like? trigger post and default to pmml
    $opts->{post}=1;
    if (@{$opts->{math_formats}} == 0) {
      push @{$opts->{math_formats}}, 'pmml';
    }
  }
  # use parallel markup if there are multiple formats requested.
  $opts->{parallelmath} = 1 if @{$opts->{math_formats}}>1;

  # Any post switch implies post:
  $opts->{post}=1 if (scalar(@{$opts->{math_formats}}) || ($opts->{stylesheet}));
  $opts->{parallelmath}=0 unless (@{$opts->{math_formats}} > 1);
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
  $opts->{navtoc}=undef unless defined $opts->{numbersections};
  $opts->{urlstyle}='server' unless defined $opts->{urlstyle};
  $opts->{type} = 'auto' unless defined $opts->{type};
  $opts->{bibliographies} = [] unless defined $opts->{bibliographies};

  $opts->{whatsin} = 'document' unless defined $opts->{whatsin};
  $opts->{whatsout} = 'document' unless defined $opts->{whatsout};
}

sub initialize_session {
  my ($self) = @_;
  # Prepare LaTeXML object
  my $latexml= new_latexml($self->{opts});
  # Demand errorless initialization
  my $init_status = $latexml->getStatusMessage;
  croak $init_status unless ($init_status !~ /error/i);
  # Save latexml in object:
  $self->{latexml} = $latexml;
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
  unless ($self->{ready}) {
    # Close and restore STDERR to original condition.
    close LOG;
    *STDERR=*ERRORIG;
    $self->{ready}=0; return {result=>undef,log=>$log};
  }

  # Inform of identity, increase conversion counter
  my $opts = $self->{opts};
  print STDERR $opts->{identity}."\n" if $opts->{verbosity} >= 0;

  # Handle What's IN?
  # 1. Math profile should get a mathdoc() wrapper
  if ($opts->{whatsin} eq "math") {
    $source = MathDoc($source);
  }

  # Prepare content and determine source type
  my $content = $self->prepare_content($source);

  # Prepare daemon frame
  my $latexml = $self->{latexml};
  $latexml->withState(sub {
                        my($state)=@_; # Sandbox state
                        $state->assignValue('_authlist',$opts->{authlist},'global');
                        $state->pushDaemonFrame; });

  # Check on the wrappers:
  if ($opts->{whatsin} eq 'fragment') {
    $opts->{'preamble_wrapper'} = $opts->{preamble}||'standard_preamble.tex';
    $opts->{'postamble_wrapper'} = $opts->{postamble}||'standard_postamble.tex';
  }
  # First read and digest whatever we're given.
  my ($digested,$dom,$serialized);
  # Digest source:
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    if ($opts->{source_type} eq 'url') {
      $digested = $latexml->digestString($content,preamble=>$opts->{'preamble_wrapper'},
                                         postamble=>$opts->{'postamble_wrapper'},source=>$source,noinitialize=>1);
    } elsif ($opts->{source_type} eq 'file') {
      if ($opts->{type} eq 'bibtex') {
        # TODO: Do we want URL support here?
        $digested = $latexml->digestBibTeXFile($content);
      } else {
        $digested = $latexml->digestFile($content,preamble=>$opts->{'preamble_wrapper'},
                                         postamble=>$opts->{'postamble_wrapper'},noinitialize=>1);
      }}
    elsif ($opts->{source_type} eq 'string') {
      $digested = $latexml->digestString($content,preamble=>$opts->{'preamble_wrapper'},
                                         postamble=>$opts->{'postamble_wrapper'},noinitialize=>1);
    }

    # Clean up:
    delete $opts->{source_type};
    delete $opts->{'preamble_wrapper'};
    delete $opts->{'postamble_wrapper'};
    # Now, convert to DOM and output, if desired.
    if ($digested) {
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

  #Experimental: add id's everywhere if wnated in XHTML
  $result = InsertIDs($result)
      if ($opts->{force_ids} && $opts->{format} eq 'xhtml');

  # Handle What's OUT?
  # 1. If we want an embedable snippet, unwrap to body's "main" div
  if ($opts->{whatsout} eq 'fragment') {
    $result = GetEmbeddable($result);
  } elsif ($opts->{whatsout} eq 'math') {
    # 2. Fetch math in math profile:
    $result = GetMath($result);
  } # 3. Nothing to do in document whatsout (it's default)

  # Close and restore STDERR to original condition.
  close LOG;
  *STDERR=*ERRORIG;
  my $return = {result=>$result,log=>$log,status=>$status};
}

########## Helper routines: ############

sub convert_post {
  my ($self,$dom) = @_;
  my $opts = $self->{opts};
  my ($style,$parallel,$math_formats,$format,$verbosity,$defaultcss,$embed) = 
    map {$opts->{$_}} qw(stylesheet parallelmath math_formats format verbosity defaultcss embed);
  $verbosity = $verbosity||0;
  our %PostOPS = (verbosity=>$verbosity,siteDirectory=>".",nocache=>1,destination=>'.');
  #Postprocess
  #Default is XHTML, XML otherwise (TODO: Expand)
  $format="xml" if ($style);
  $format="xhtml" unless (defined $format);
  if (!$style) {
    if ($format eq "xhtml") {$style = "LaTeXML-xhtml.xsl";}
    elsif ($format eq "html") {$style = "LaTeXML-html.xsl";}
    elsif ($format eq "html5") {$style = "LaTeXML-html5.xsl";}
    elsif ($format eq "xml") {undef $style;}
    else {Error("Unrecognized target format: $format");}
  }
  my @css=();
  unshift (@css,"core.css") if ($defaultcss);
  $parallel = $parallel||0;
  my $doc;
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    $doc = LaTeXML::Post::Document->new($dom,%PostOPS);
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
  ### Advanced Processors:
  if ($opts->{split}) {
    require 'LaTeXML/Post/Split.pm';
    push(@procs,LaTeXML::Post::Split->new(split_xpath=>$opts->{splitpath},splitnaming=>$opts->{splitnaming},
                                          %PostOPS)); }
  my $scanner = ($opts->{scan} || $DB) && LaTeXML::Post::Scan->new(db=>$DB,%PostOPS);
  push(@procs,$scanner) if $opts->{scan};
  if (!($opts->{prescan})) {
    if ($opts->{index}) {
      require 'LaTeXML/Post/MakeIndex.pm';
      push(@procs,LaTeXML::Post::MakeIndex->new(db=>$DB, permuted=>$opts->{permutedindex},
                                                split=>$opts->{splitindex}, scanner=>$scanner,
                                                %PostOPS)); }
    if (@{$opts->{bibliographies}}) {
      require 'LaTeXML/Post/MakeBibliography.pm';
      push(@procs,LaTeXML::Post::MakeBibliography->new(db=>$DB, bibliographies=>$opts->{bibliographies},
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

    my @mprocs=();
    ###    # If XMath is not first, it must be at END!  Or... ???
    foreach my $fmt (@$math_formats) {
      if($fmt eq 'xmath'){
	require 'LaTeXML/Post/XMath.pm';
	push(@mprocs,LaTeXML::Post::XMath->new(%PostOPS)); }
      elsif($fmt eq 'pmml'){
	require 'LaTeXML/Post/MathML.pm';
	if(defined $opts->{linelength}){
	  push(@mprocs,LaTeXML::Post::MathML::PresentationLineBreak->new(
                    linelength=>$opts->{linelength},
                    ($opts->{plane1} ? (plane1=>1):()),
                    ($opts->{hackplane1} ? (hackplane1=>1):()),
                    %PostOPS)); }
	else {
	  push(@mprocs,LaTeXML::Post::MathML::Presentation->new(
                    ($opts->{plane1} ? (plane1=>1):()),
                    ($opts->{hackplane1} ? (hackplane1=>1):()),
                    %PostOPS)); }}
      elsif($fmt eq 'cmml'){
	require 'LaTeXML/Post/MathML.pm';
	push(@mprocs,LaTeXML::Post::MathML::Content->new(%PostOPS)); }
      elsif($fmt eq 'om'){
	require 'LaTeXML/Post/OpenMath.pm';
	push(@mprocs,LaTeXML::Post::OpenMath->new(%PostOPS)); }
    }
###    $keepXMath  = 0 unless defined $keepXMath;
### OR is $parallelmath ALWAYS on whenever there's more than one math processor?
    if($parallel) {
      my $main = shift(@mprocs);
      $main->setParallel(@mprocs);
      push(@procs,$main); }
    else {
      push(@procs,@mprocs); }


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
					 parameters=>{
                                                      (@csspaths ? (CSS=>[@csspaths]):()),
                                                      ($opts->{stylesheetparam} ? (%{$opts->{stylesheetparam}}):())},
					 %PostOPS)) if $style;
  }

  # Do the actual post-processing:
  my $postdoc;
  eval {
    local $SIG{'ALRM'} = sub { die "alarm\n" };
    alarm($opts->{timeout});
    ($postdoc) = LaTeXML::Post::ProcessChain($doc,@procs);
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
  $DB->finish;
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

sub prepare_content {
  my ($self,$source)=@_;
  $source=~s/\n$//g; # Eliminate trailing new lines
  my $opts=$self->{opts};
  if (defined $opts->{source_type}) {
    if ($opts->{source_type} eq "string") {return $source;}
    elsif ($opts->{source_type} eq "file") {
      if ($opts->{local}) {
	my $file = pathname_find($source,types=>['tex',q{}]);
	$file = pathname_canonical($file) if $file;
	#Recognize bibtex case
	$opts->{type} = 'bibtex' if ($opts->{type} eq 'auto') && ($file =~ /\.bib$/);
	return $file; }
      else {print STDERR "File input only allowed when 'local' is enabled,"
	      ."falling back to string input..";
	    $opts->{source_type}="string"; return $source; }}
    elsif ($opts->{source_type} eq "url") {
      my $response = auth_get($source,$opts->{authlist});
      if ($response->is_success) {return $response->content;} else {
	print STDERR "TODO: Flag a retrieval error and do something smart?"; return undef;}}
  }
  else { # Guess the input type:
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

Top-level preparation routine that prepares both a correct options object
    and an initialized LaTeXML object,
    using the "initialize_options" and "initialize_session" routines, when needed.

Contains optimization checks that skip initializations unless necessary.

Also adds support for partial option specifications during daemon runtime,
     falling back on the option defaults given when daemon object was created.

=item C<< $daemon->initialize_session($opts); >>

Given an options hash reference $opts, initializes a session by creating a new LaTeXML object 
      with initialized state and loading a daemonized preamble (if any).

Sets the "ready" flag to true, making a subsequent "convert" call immediately possible.

=item C<< $daemon->prepare_options($opts); >>

Given an options hash reference $opts, performs a set of assignments of meaningful defaults
    (when needed) and normalizations (for relative paths, etc).

=item C<< my ($result,$status,$log) = $daemon->convert($tex); >>

Converts a TeX input string $tex into the LaTeXML::Document object $result.

Supplies detailed information of the conversion log ($log),
         as well as a brief conversion status summary ($status).

=back

=head2 INTERNAL ROUTINES

=over 4

=item C<< my $latexml = new_latexml($opts); >>

Creates a new LaTeXML object and initializes its state.

=item C<< my $content = $self->prepare_content($source); >>

Determines the source type (URL, file or string) and returns the retrieved content.

The determined input type is saved as a "source_type" field in the daemon object.

=item C<< my $postdoc = $daemon->convert_post($dom); >>

Post-processes a LaTeXML::Document object $dom into a final format,
               based on the preferences specified in $self->{opts}.

Typically used only internally by C<convert>.

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
