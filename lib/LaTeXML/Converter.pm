# /=====================================================================\ #
# |  LaTeXML::Converter                                                 | #
# | LaTeXML Object-oriented Processing API                              | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <d.ginev@jacobs-university.de>                  #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Converter;
use strict;
use warnings;

use Pod::Usage;
use Carp;
use Encode;
use Data::Dumper;

use LaTeXML::Package qw(pathname_is_literaldata);
use LaTeXML::Util::Pathname;
use LaTeXML::Util::WWW;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::Extras;
use LaTeXML::Post::Scan;

#**********************************************************************
#our @IGNORABLE = qw(timeout profile port preamble postamble port destination log removed_math_formats whatsin whatsout math_formats input_limit input_counter dographics mathimages mathimagemag );

# Switching to white-listing options that are important for new_latexml:
our @COMPARABLE = qw(preload paths verbosity strict comments inputencoding includestyles documentid mathparse);
our %DAEMON_DB = () unless keys %DAEMON_DB;

sub new {
  my ($class,$config) = @_;
  $config = $LaTeXML::Util::Config->new() unless (defined $config);
  # The daemon should be setting the identity:
  $config->check;
  bless {opts=>$config->options,ready=>0,log=>q{},runtime=>{},
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
  my $opts_comparable = { map { $_ => $opts->{$_} } @COMPARABLE };
  my $self_opts_comparable = { map { $_ => $self->{opts}->{$_} } @COMPARABLE };
  #TODO: Some options like paths and includes are additive, we need special treatment there
  #2.2. Compare old and new $opts hash
  my $something_to_do;
  $something_to_do= LaTeXML::Util::ObjectDB::compare($opts_comparable, $self_opts_comparable) ? 0 : 1;
  #2.3. Set new options in converter:
  $self->{opts} = $opts;

  #3. If there is something to do, initialize a session:
  $self->initialize_session if ($something_to_do || (! $self->{ready}));

  return;
}

sub initialize_session {
  my ($self) = @_;
  $self->{runtime} = {};
  $self->bind_log;
  # Empty the package namespace
  foreach my $subname (keys %LaTeXML::Package::Pool::) {
    delete $LaTeXML::Package::Pool::{$subname};
  }

  my $latexml;
  my $init_eval_return = eval {
    # Prepare LaTeXML object
    $latexml = new_latexml($self->{opts});
    1;
  };
  local $@ = 'Fatal:conversion:unknown Session initialization failed! (Unknown reason)' if ((!$init_eval_return) && (!$@));
  if ($@) {#Fatal occured!
    print STDERR "$@\n";
    print STDERR "\nInitialization complete: ".$latexml->getStatusMessage.". Aborting.\n" if defined $latexml;
    # Close and restore STDERR to original condition.
    $self->{log} = $self->flush_log;
    $self->{ready}=0;
    return;
  } else {
    # Demand errorless initialization
    my $init_status = $latexml->getStatusMessage;
    if ($init_status =~ /error/i) {
      print STDERR "\nInitialization complete: ".$init_status.". Aborting.\n";
      $self->{log} = $self->flush_log; 
      $self->{ready}=0;
      return;
    }
  }

  # Save latexml in object:
  $self->{log} = $self->flush_log;
  $self->{latexml} = $latexml;
  $self->{ready}=1;
  return;
}

sub convert {
  my ($self,$source) = @_;
  # Initialize session if needed:
  $self->{runtime} = {};
  $self->initialize_session unless $self->{ready};
  if (! $self->{ready}) { # We can't initialize, return error:
    return {result=>undef,log=>$self->{log},status=>"Initialization failed.",status_code=>3};
  }

  $self->bind_log;
  # Inform of identity, increase conversion counter
  my $opts = $self->{opts};
  my $runtime = $self->{runtime};
  ($runtime->{status},$runtime->{status_code})=(undef,undef);
  print STDERR "\n$LaTeXML::Version::IDENTITY\n" if $opts->{verbosity} >= 0;
  print STDERR "processing started ".localtime()."\n" if $opts->{verbosity} >= 0;
  # Handle What's IN?
  # 1. Math should get a mathdoc() wrapper
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
  my $convert_eval_return = eval {
    local $SIG{'ALRM'} = sub { die "Fatal:conversion:timeout Conversion timed out after ".$opts->{timeout}." seconds!\n"; };
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
      require LaTeXML::Global;
      local $LaTeXML::Global::STATE = $latexml->{state};
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
  local $@ = 'Fatal:conversion:unknown TeX to XML conversion failed! (Unknown Reason)' if ((!$convert_eval_return) && (!$@));
  my $eval_report = $@;
  $runtime->{status} = $latexml->getStatusMessage;
  $runtime->{status_code} = $latexml->getStatusCode;
  # End daemon run, by popping frame:
  $latexml->withState(sub {
    my($state)=@_; # Remove current state frame
    $state->popDaemonFrame;
    $state->{status} = {};
  });
  if ($eval_report) {#Fatal occured!
    $runtime->{status_code} = 3;
    print STDERR $eval_report."\n";
    print STDERR "\nConversion complete: ".$runtime->{status}.".\n";
    print STDERR "Status:conversion:".($runtime->{status_code}||'0')."\n";
    # Close and restore STDERR to original condition.
    my $log=$self->flush_log;
    # Hope to clear some memory:
    $self->sanitize($log) if ($runtime->{status_code} == 3);
    return {result=>undef,log=>$log,status=>$runtime->{status},status_code=>$runtime->{status_code}};
  }
  print STDERR "\nConversion complete: ".$runtime->{status}.".\n";
  print STDERR "Status:conversion:".($runtime->{status_code}||'0')." \n";
  if ($runtime->{status_code} == 3) {
    # Terminate on Fatal errors
    print STDERR " \n\nIt is Fatal!!!\n";
    my $log = $self->flush_log;
    $serialized = $dom->toString unless defined $serialized;
    $self->sanitize($log) if ($runtime->{status_code} == 3);
    return {result=>$serialized,log=>$log,status=>$runtime->{status},'status_code'=>$runtime->{status_code}};
  }
  if ($serialized) {
      # If serialized has been set, we are done with the job
      my $log = $self->flush_log;
      # Hope to clear some memory:
      $digested=undef;
      $dom=undef;
      $self->sanitize($log) if ($runtime->{status_code} == 3);
      return {result=>$serialized,log=>$log,status=>$runtime->{status},'status_code'=>$runtime->{status_code}};
  } # Else, continue with the regular XML workflow...
  my $result = $dom;

  if ($opts->{post} && $dom) {
    my $post_eval_return = eval {
      local $SIG{'ALRM'} = sub { die "alarm\n" };
      alarm($opts->{timeout});
      $result = $self->convert_post($dom);
      alarm(0);
      1;
    };
    local $@ = 'Fatal:conversion:unknown Post-processing failed! (Unknown Reason)'
      if ((!$post_eval_return) && (!$@));
    if ($@) {                     #Fatal occured!
      $runtime->{status_code} = 3;
      if ($@ =~ "Fatal:perl:die alarm") { #Alarm handler: (treat timeouts as fatals)
        print STDERR "Fatal:post:timeout Postprocessing timeout after "
        . $opts->{timeout} . " seconds!\n";
      } else {
        print STDERR "Fatal:post:generic Post-processor crashed! $@\n";
      }
      #Since this is postprocessing, we don't need to do anything
      #   just avoid crashing...
    $result = undef;
    }
  }

  # Handle What's OUT?
  # 1. If we want an embedable snippet, unwrap to body's "main" div
  if ($opts->{whatsout} eq 'fragment') {
    $result = GetEmbeddable($result);
  } elsif ($opts->{whatsout} eq 'math') {
    # 2. Fetch math out:
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
  }
  print STDERR "Status:conversion:".($runtime->{status_code}||'0')." \n";
  my $log = $self->flush_log;
  # Hope to clear some memory:
  $digested=undef;
  $dom=undef;
  $result=undef;
  $self->sanitize($log) if ($runtime->{status_code} == 3);
  return {result=>$serialized,log=>$log,status=>$runtime->{status},'status_code'=>$runtime->{status_code}};
}

###########################################
####       Converter Management       #####
###########################################
sub get_converter {
  my ($self,$conf) = @_;
  $conf->check; # Options are fully expanded
  # TODO: Make this more flexible via an admin interface later
  my $key = $conf->get('cache_key');
  my $d = $DAEMON_DB{$key};
  if (! defined $d) {
    $d = LaTeXML::Converter->new($conf->clone);
    $DAEMON_DB{$key}=$d;
  }
  return $d;
}

###########################################
####       Helper routines            #####
###########################################
sub convert_post {
  my ($self,$dom) = @_;
  my $opts = $self->{opts};
  my $runtime = $self->{runtime};
  my ($xslt,$parallel,$math_formats,$format,$verbosity,$defaultcss,$embed) = 
    map {$opts->{$_}} qw(stylesheet parallelmath math_formats format verbosity defaultcss embed);
  $verbosity = $verbosity||0;
  my %PostOPS = (verbosity=>$verbosity,sourceDirectory=>$opts->{sourcedirectory}||'.',siteDirectory=>$opts->{sitedirectory}||".",nocache=>1,destination=>$opts->{destination});
  #Postprocess
  my @css=@{$opts->{css}};
  unshift (@css,"core.css") if $defaultcss || ((!defined $defaultcss) && (!defined $xslt));
  $parallel = $parallel||0;
  
  my $doc = LaTeXML::Post::Document->new($dom,%PostOPS);
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
    require LaTeXML::Post::Split;
    push(@procs,LaTeXML::Post::Split->new(split_xpath=>$opts->{splitpath},splitnaming=>$opts->{splitnaming},
                                          %PostOPS)); }
  my $scanner = ($opts->{scan} || $DB) && (LaTeXML::Post::Scan->new(db=>$DB,%PostOPS));
  push(@procs,$scanner) if $opts->{scan};
  if (!($opts->{prescan})) {
    if ($opts->{index}) {
      require LaTeXML::Post::MakeIndex;
      push(@procs,LaTeXML::Post::MakeIndex->new(db=>$DB, permuted=>$opts->{permutedindex},
                                                split=>$opts->{splitindex}, scanner=>$scanner,
                                                %PostOPS)); }
    if (@{$opts->{bibliographies}}) {
      require LaTeXML::Post::MakeBibliography;
      push(@procs,LaTeXML::Post::MakeBibliography->new(db=>$DB, bibliographies=>$opts->{bibliographies},
						       split=>$opts->{splitbibliography}, scanner=>$scanner,
						       %PostOPS)); }
    if ($opts->{crossref}) {
      require LaTeXML::Post::CrossRef;
      push(@procs,LaTeXML::Post::CrossRef->new(db=>$DB,urlstyle=>$opts->{urlstyle},format=>$format,
					       ($opts->{numbersections} ? (number_sections=>1):()),
					       ($opts->{navtoc} ? (navigation_toc=>$opts->{navtoc}):()),
					       %PostOPS)); }
    if ($opts->{mathimages}) {
      require LaTeXML::Post::MathImages;
      push(@procs,LaTeXML::Post::MathImages->new(magnification=>$opts->{mathimagemag},%PostOPS));
    }
    if ($opts->{picimages}) {
      require LaTeXML::Post::PictureImages;
      push(@procs,LaTeXML::Post::PictureImages->new(%PostOPS));
    }
    if ($opts->{dographics}) {
      # TODO: Rethink full-fledged graphics support
      require LaTeXML::Post::Graphics;
      my @g_options=();
      if($opts->{graphicsmaps} && scalar(@{$opts->{graphicsmaps}})){
        my @maps = map([split(/\./,$_)], @{$opts->{graphicsmaps}});
        push(@g_options, (graphics_types=>[map($$_[0],@maps)],
			     type_properties=>{map( ($$_[0]=>{destination_type=>($$_[1] || $$_[0])}), @maps)})); }
        push(@procs,LaTeXML::Post::Graphics->new(@g_options,%PostOPS));
    }
    if($opts->{svg}){
      require LaTeXML::Post::SVG;
      push(@procs,LaTeXML::Post::SVG->new(%PostOPS)); }
    my @mprocs=();
    ###    # If XMath is not first, it must be at END!  Or... ???
    foreach my $fmt (@$math_formats) {
      if($fmt eq 'xmath'){
        require LaTeXML::Post::XMath;
        push(@mprocs,LaTeXML::Post::XMath->new(%PostOPS)); }
      elsif($fmt eq 'pmml'){
        require LaTeXML::Post::MathML;
        if(defined $opts->{linelength}){
          push(@mprocs,LaTeXML::Post::MathML::PresentationLineBreak->new(
                    linelength=>$opts->{linelength},
                    (defined $opts->{plane1} ? (plane1=>$opts->{plane1}):(plane1=>1)),
                    ($opts->{hackplane1} ? (hackplane1=>1):()),
                    %PostOPS)); }
        else {
          push(@mprocs,LaTeXML::Post::MathML::Presentation->new(
                    (defined $opts->{plane1} ? (plane1=>$opts->{plane1}):(plane1=>1)),
                    ($opts->{hackplane1} ? (hackplane1=>1):()),
                    %PostOPS)); }}
      elsif($fmt eq 'cmml'){
        require LaTeXML::Post::MathML;
        push(@mprocs,LaTeXML::Post::MathML::Content->new(
          (defined $opts->{plane1} ? (plane1=>$opts->{plane1}):(plane1=>1)),
          ($opts->{hackplane1} ? (hackplane1=>1):()),
          %PostOPS)); }
      elsif($fmt eq 'om'){
        require LaTeXML::Post::OpenMath;
        push(@mprocs,LaTeXML::Post::OpenMath->new(
          (defined $opts->{plane1} ? (plane1=>$opts->{plane1}):(plane1=>1)),
          ($opts->{hackplane1} ? (hackplane1=>1):()),
          %PostOPS)); }
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
	# TODO: No! Multi-file setups need special treatment...
	#       Switch to ZIP output here?
	#       Should ZIP be supported within Converter already?
	#       But, no... we don't want to ZIP if we're on the same filesystem...
	#       Maybe return a list of resources to be included? That sounds good!!!
        pathname_copy($csssource,$csspath)  if $csssource && -f $csssource;
        push(@csspaths,$csspath);
      }
    }
    push(@procs,LaTeXML::Post::XSLT->new(stylesheet=>$xslt,
					 parameters=>{
            (@csspaths ? (CSS=>[@csspaths]):()),
            ($opts->{xsltparameter} ? (%{$opts->{xsltparameter}}):())},
					 %PostOPS)) if $xslt;
  }

  # Do the actual post-processing:
  my $postdoc;
  my $latexmlpost = LaTeXML::Post->new(verbosity=>$verbosity||0);
  ($postdoc) = $latexmlpost->ProcessChain($doc,@procs);
  $DB->finish;

  $runtime->{status}.= "\nPost: ".$latexmlpost->getStatusMessage;
  $runtime->{status_code} =($runtime->{status_code} > $latexmlpost->getStatusCode) ?
    $runtime->{status_code} : $latexmlpost->getStatusCode;

  print STDERR "\nPostprocessing complete: ".$latexmlpost->getStatusMessage."\n";
  print STDERR "processing finished ".localtime()."\n" if $verbosity >= 0;
  return $postdoc;
}

sub new_latexml {
  my ($opts) = @_;

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
  require LaTeXML;
  my $latexml = LaTeXML->new(preload=>[@pre], searchpaths=>[@{$opts->{paths}}],
                          graphicspaths=>['.'],
			  verbosity=>$opts->{verbosity}, strict=>$opts->{strict},
			  includeComments=>$opts->{comments},
			  inputencoding=>$opts->{inputencoding},
			  includeStyles=>$opts->{includestyles},
			  documentid=>$opts->{documentid},
			  mathparse=>$opts->{mathparse});
  if(my @baddirs = grep {! -d $_} @{$opts->{paths}}){
    warn "\n$LaTeXML::Version::IDENTITY : these path directories do not exist: ".join(', ',@baddirs)."\n"; }

  $latexml->withState(sub {
      my($state)=@_;
      $latexml->initializeState('TeX.pool', @{$latexml->{preload} || []});
      $state->assignValue(FORBIDDEN_IO=>(!$opts->{local}));
  });

  # TODO: Do again, need to do this in a GOOD way as well:
  $latexml->digestFile($_,noinitialize=>1) foreach (@str_pre);

  return $latexml;
}

sub bind_log {
  # TODO: Move away from global file handles, they will inevitably end up causing problems..
  my ($self) = @_;
  if (! $LaTeXML::Converter::DEBUG) { # Debug will use STDERR for logs
    # Tie STDERR to log:
    my $log_handle;
    open($log_handle,">",\$self->{log}) or croak "Can't redirect STDERR to log! Dying...";
    *STDERR_SAVED=*STDERR;
    *STDERR = *$log_handle;
    binmode(STDERR,':encoding(UTF-8)');
    $self->{log_handle} = $log_handle;
  }
  return;
}

sub flush_log {
  my ($self) = @_;
  # Close and restore STDERR to original condition.
  if (! $LaTeXML::Converter::DEBUG) {
    close $self->{log_handle};
    *STDERR=*STDERR_SAVED;
  }
  my $log = $self->{log};
  $self->{log}=q{};
  return $log;
}

sub sanitize {
  my ($self,$log)=@_;
  if ($log =~ m/^Fatal:internal/m) {
    # TODO : Anything else? Clean up the whole stomach etc?
    $self->{latexml}->withState(sub {
      my($state)=@_; # Remove current state frame
      my $stomach = $state->getStomach;
      undef $stomach;
    });
    $self->{ready} = 0;
  }
}

1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Converter> - Converter object and API for LaTeXML and LaTeXMLPost conversion.

=head1 SYNOPSIS

    use LaTeXML::Converter;
    my $converter = LaTeXML::Converter->get_converter($config);
    my $converter = LaTeXML::Converter->new($config);
    $converter->prepare_session($opts);
    $converter->initialize_session; # TODO: should be internal only
    $hashref = $converter->convert($tex);
    my ($result,$log,$status) = map {$hashref->{$_}} qw(result log status);

=head1 DESCRIPTION

A Converter object represents a converter instance and can convert files on demand, until dismissed.

=head2 METHODS

=over 4

=item C<< my $converter = LaTeXML::Converter->new($config); >>

Creates a new converter object for a given LaTeXML::Util::Config object, $config.

=item C<< my $converter = LaTeXML::Converter->get_converter($config); >>

Either creates, or looks up a cached converter for the $config configuration object.

=item C<< $converter->prepare_session($opts); >>

Top-level preparation routine that prepares both a correct options object
    and an initialized LaTeXML object,
    using the "initialize_options" and "initialize_session" routines, when needed.

Contains optimization checks that skip initializations unless necessary.

Also adds support for partial option specifications during daemon runtime,
     falling back on the option defaults given when converter object was created.

=item C<< my ($result,$status,$log) = $converter->convert($tex); >>

Converts a TeX input string $tex into the LaTeXML::Document object $result.

Supplies detailed information of the conversion log ($log),
         as well as a brief conversion status summary ($status).
=back

=head2 INTERNAL ROUTINES

=over 4

=item C<< $converter->initialize_session($opts); >>

Given an options hash reference $opts, initializes a session by creating a new LaTeXML object 
      with initialized state and loading a daemonized preamble (if any).

Sets the "ready" flag to true, making a subsequent "convert" call immediately possible.

=item C<< my $latexml = new_latexml($opts); >>

Creates a new LaTeXML object and initializes its state.

=item C<< my $postdoc = $converter->convert_post($dom); >>

Post-processes a LaTeXML::Document object $dom into a final format,
               based on the preferences specified in $self->{opts}.

Typically used only internally by C<convert>.

=item C<< $converter->bind_log; >>

Binds STDERR to a "log" field in the $converter object

=item C<< my $log = $converter->flush_log; >>

Flushes out the accumulated conversion log into $log,
         reseting STDERR to its usual stream.

=back

=head1 AUTHOR

Bruce Miller <bruce.miller@nist.gov>
Deyan Ginev <deyan.ginev@nist.gov>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
