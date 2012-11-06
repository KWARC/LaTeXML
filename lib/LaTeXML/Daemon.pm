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
use Carp;
use Encode;
use LaTeXML;
use LaTeXML::Global;
use LaTeXML::Package qw(pathname_is_literaldata);
use LaTeXML::Util::Pathname;
use LaTeXML::Util::WWW;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::Extras;
use LaTeXML::Post;
use LaTeXML::Post::Scan;
binmode(STDERR,":utf8");

#**********************************************************************
our @IGNORABLE = qw(identity timeout profile port preamble postamble port destination log removed_math_formats whatsin whatsout math_formats input_limit input_counter dographics mathimages mathimagemag );
# TODO: Should I change from exclusive to inclusive? What is really important to compare?
# paths, preload, preamble, ... all the LaTeXML->new() params?
# If we're not daemonizing postprocessing we can safely ignore all its options and reuse the conversion objects.

use vars qw($DAEMON_DB);
$DAEMON_DB={}; # Class-wide, caches all daemons that got booted

sub new {
  my ($class,$opts) = @_;
  $opts->check if defined $opts;
  bless {opts=>$opts->options,ready=>0,log=>q{},
         latexml=>undef}, $class;
}

sub prepare_session {
  my ($self,$opts) = @_;
  # TODO: The defaults feature was never used, do we really want it??
  #0. Ensure all default keys are present:
  # (always, as users can specify partial options that build on the defaults)
  #foreach (keys %{$self->{defaults}}) {
  #  $opts->{$_} = $self->{defaults}->{$_} unless exists $opts->{$_};
  #}
  # 1. Ensure option "sanity"
  $opts->check;
  $opts = $opts->options;
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

sub initialize_session {
  my ($self) = @_;
  $self->bind_loging;
  my $latexml;
  eval {
    # Prepare LaTeXML object
    $latexml = new_latexml($self->{opts});
    1;
  };
  if ($@) {#Fatal occured!
    print STDERR "$@\n";
    print STDERR "\nInitialization complete: ".$latexml->getStatusMessage.". Aborting.\n" if defined $latexml;
    # Close and restore STDERR to original condition.
    $self->{log} = $self->flush_loging;
    $self->{ready}=0; return;
  } else {
    # Demand errorless initialization
    my $init_status = $latexml->getStatusMessage;
    if ($init_status =~ /error/i) {
      print STDERR "\nInitialization complete: ".$init_status.". Aborting.\n";
      $self->{log} = $self->flush_loging; 
      $self->{ready}=0;
      return;
    }
  }

  # Save latexml in object:
  $self->{log} = $self->flush_loging;
  $self->{latexml} = $latexml;
  $self->{ready}=1;
}

sub convert {
  my ($self,$source) = @_;
  # Initialize session if needed:
  $self->initialize_session unless $self->{ready};
  if (! $self->{ready}) { # We can't initialize, return error:
    return {result=>undef,log=>$self->{log},status=>"Initialization failed.",status_code=>3};
  }

  $self->bind_loging;
  my ($status,$status_code)=(undef,undef);
  # Inform of identity, increase conversion counter
  my $opts = $self->{opts};
  print STDERR "\n",$opts->{identity},"\n" if $opts->{verbosity} >= 0;

  # Handle What's IN?
  # 1. Math profile should get a mathdoc() wrapper
  if ($opts->{whatsin} eq "math") {
    $source = "literal:".MathDoc($source);
  }

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
    my $mode = ($opts->{type} eq 'auto') ? 'TeX' : $opts->{type};
    $digested = $latexml->digestFile($source,preamble=>$opts->{'preamble_wrapper'},
                                            postamble=>$opts->{'postamble_wrapper'},
                                            mode=>$mode,
                                            noinitialize=>1);
    # Clean up:
    delete $opts->{'preamble_wrapper'};
    delete $opts->{'postamble_wrapper'};
    # Now, convert to DOM and output, if desired.
    if ($digested) {
      local $LaTeXML::Global::STATE = $$latexml{state};
      if ($opts->{format} eq 'tex') {
        $serialized = LaTeXML::Global::UnTeX($digested);
      } elsif ($opts->{format} eq 'box') {
        $serialized = $digested->toString;
      } else { # Default is XML
        $dom = $latexml->convertDocument($digested);
      }
    }
    alarm(0);
    1;
  };
  my $eval_report = $@;
  $status = $latexml->getStatusMessage;
  $status_code = $latexml->getStatusCode;
  # End daemon run, by popping frame:
  $latexml->withState(sub {
    my($state)=@_; # Remove current state frame
    $state->popDaemonFrame;
    $$state{status} = {};
  });
  if ($eval_report) {#Fatal occured!
    if ($eval_report =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
      print STDERR $eval_report."\n";
      print STDERR "Fatal:conversion:timeout Conversion timed out after ".$opts->{timeout}." seconds!\n";
      print STDERR "\nConversion incomplete (timeout): ".$status.".\n";
    } else {
      print STDERR $eval_report."\n";
      print STDERR "\nStatus:conversion:".($status_code||'0')." \n";
      print STDERR "Conversion complete: ".$status.".\n";
    }
    # Close and restore STDERR to original condition.
    my $log=$self->flush_loging;
    return {result=>undef,log=>$log,status=>$status,status_code=>$status_code};
  }
  print STDERR "\nStatus:conversion:".($status_code||'0')." \n";
  print STDERR "Conversion complete: ".$status.".\n";

  if ($serialized) {
      # If serialized has been set, we are done with the job
      my $log = $self->flush_loging;
      return {result=>$serialized,log=>$log,status=>$status,'status_code'=>$status_code};
  } # Else, continue with the regular XML workflow...
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
  } else { # 3. No need to do anything for document whatsout (it's default)
  }
  # Serialize result for direct use:
  undef $serialized;
  if (defined $result) {
    if ($opts->{format} =~ 'x(ht)?ml') {
      $serialized = $result->toString(1);
    } elsif ($opts->{format} =~ /^html/) {
      if ($result =~ /LaTeXML/) { # Special for documents
        $serialized = $result->getDocument->toStringHTML;
      } else { # Regular for fragments
	  $serialized = $result->toString(1);
      }
    }

    if ($opts->{post} && ($result =~ /LibXML/)) { # LibXML nodes need an extra encoding pass?
	                       # But only for post-processing ?!
	                       # TODO: Why?!?! Find what is fishy here
	$serialized = encode('UTF-8',$serialized);
    }
  }
  my $log = $self->flush_loging;
  return {result=>$serialized,log=>$log,status=>$status,'status_code'=>$status_code};
}

########## Helper routines: ############
sub convert_post {
  my ($self,$dom) = @_;
  my $opts = $self->{opts};
  my ($style,$parallel,$math_formats,$format,$verbosity,$defaultcss,$embed) = 
    map {$opts->{$_}} qw(stylesheet parallelmath math_formats format verbosity defaultcss embed);
  $verbosity = $verbosity||0;
  my %PostOPS = (verbosity=>$verbosity,sourceDirectory=>$opts->{sourcedirectory}||'.',siteDirectory=>$opts->{sitedirectory}||".",nocache=>1,destination=>$opts->{destination});
  #Postprocess
  my @css=@{$opts->{css}};
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
      print STDERR "Fatal:post:timeout Postprocessing couldn't create document: timeout after "
        . $opts->{timeout} . " seconds!\n";
    } else {
      print STDERR "Fatal:post:generic Post-processor crashed! $@\n";
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
      if($opts->{graphicsmaps} && scalar(@{$opts->{graphicsmaps}})){
	my @maps = map([split(/\./,$_)], @{$opts->{graphicsmaps}});
	push(@g_options, (graphicsSourceTypes=>[map($$_[0],@maps)],
			  typeProperties=>{map( ($$_[0]=>{destination_type=>($$_[1] || $$_[0])}), @maps)})); }
      push(@procs,LaTeXML::Post::Graphics->new(@g_options,%PostOPS));
    }
    if($opts->{svg}){
      require 'LaTeXML/Post/SVG.pm';
      push(@procs,LaTeXML::Post::SVG->new(%PostOPS)); }
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
    if (@css) {
      foreach my $css (@css) {
	$css .= '.css' unless $css =~ /\.css$/;
	# Dance, if dest is current dir, we'll find the old css before the new one!
	my @csssources = map {pathname_canonical($_)}
	  pathname_findall($css,types=>['css'],
			   (),
			   installation_subdir=>'style');
	my $csspath = pathname_absolute($css,pathname_directory('.'));
	while (@csssources && ($csssources[0] eq $csspath)) {
	  shift(@csssources);
	}
	my $csssource = shift(@csssources);
	pathname_copy($csssource,$csspath)  if $csssource && -f $csssource;
	push(@csspaths,$csspath);
      }
    }
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
      print STDERR "Fatal:post:timeout Postprocessing timed out after ".$opts->{timeout}." seconds!\n";
    } else {
      print STDERR "Fatal:post:generic Post-processor crashed! $@\n";
    }
    return;
  }
  $DB->finish;
  return $postdoc;
}

sub new_latexml {
  my $opts = shift;

  # TODO: Do this in a GOOD way to support filepath/URL/string snippets
  # If we are given string preloads, load them and remove them from the preload list:
  my $preloads = $opts->{preload};
  my (@pre,@str_pre);
  foreach my $pre(@$preloads) {
    if (pathname_is_literaldata($pre)) {
      push @str_pre, $pre;
    } else {
      push @pre, $pre;
    }
  }

  my $latexml = LaTeXML->new(preload=>[@pre], searchpaths=>[@{$opts->{paths}}],
                          graphicspaths=>['.'],
			  verbosity=>$opts->{verbosity}, strict=>$opts->{strict},
			  includeComments=>$opts->{comments},
			  inputencoding=>$opts->{inputencoding},
			  includeStyles=>$opts->{includestyles},
			  documentid=>$opts->{documentid},
			  nomathparse=>$opts->{noparse});
  if(my @baddirs = grep {! -d $_} @{$opts->{paths}}){
    warn $opts->{identity}.": these path directories do not exist: ".join(', ',@baddirs)."\n"; }

  $latexml->withState(sub {
      my($state)=@_;
      $latexml->initializeState('TeX.pool', @{$$latexml{preload} || []});
      $state->assignValue(FORBIDDEN_IO=>(!$opts->{local}));
  });

  # TODO: Do again, need to do this in a GOOD way as well:
  $latexml->digestFile($_,noinitialize=>1) foreach (@str_pre);

  return $latexml;
}

sub bind_loging {
  # TODO: Move away from global file handles, they will inevitably end up causing problems..
  my ($self) = @_;
  # Tie STDERR to log:
  open(LOG,">",\$self->{log}) or croak "Can't redirect STDERR to log! Dying...";
  *ERRORIG=*STDERR;
  *STDERR = *LOG;
}
sub flush_loging {
  my ($self) = @_;
  # Close and restore STDERR to original condition.
  close LOG;
  *STDERR=*ERRORIG;
  my $log = $self->{log};
  $self->{log}=q{};
  return $log;
}

###########################################
#### Daemon Management                #####
###########################################
sub get_converter {
  my ($self,$conf) = @_;
  $conf->check; # Options are fully expanded
  # TODO: Make this more flexible via an admin interface later
  my $profile = $conf->get('profile')||'custom';
  my $d = $DAEMON_DB->{$profile};
  if (! defined $d) {
    $d = LaTeXML::Daemon->new($conf->clone);
    $DAEMON_DB->{$profile}=$d;
  }
  return $d;
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
    $hashref = $daemon->convert($tex);
    my ($result,$log,$status) = map {$hashref->{$_}} qw(result log status);

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

=item C<< my ($result,$status,$log) = $daemon->convert($tex); >>

Converts a TeX input string $tex into the LaTeXML::Document object $result.

Supplies detailed information of the conversion log ($log),
         as well as a brief conversion status summary ($status).
=back

=head2 INTERNAL ROUTINES

=over 4

=item C<< my $latexml = new_latexml($opts); >>

Creates a new LaTeXML object and initializes its state.

=item C<< my $postdoc = $daemon->convert_post($dom); >>

Post-processes a LaTeXML::Document object $dom into a final format,
               based on the preferences specified in $self->{opts}.

Typically used only internally by C<convert>.

=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
