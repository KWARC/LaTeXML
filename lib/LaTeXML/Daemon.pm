# /=====================================================================\ #
# |  LaTeXML::Daemon                                                    | #
# | Extends the LaTeXML object with daemon methods                      | #
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

use LaTeXML;
use LaTeXML::Util::Pathname;
use LaTeXML::Util::ObjectDB;
use LaTeXML::Util::WWW;
use LaTeXML::Post;
use LaTeXML::Post::Writer;
use LaTeXML::Post::Scan;
use Carp;
use Data::Compare;

#**********************************************************************
our @IGNORABLE = qw(identity input_counter input_limit);

sub new {
  my ($class,%opts) = @_;
  bless {defaults=>\%opts,opts=>undef,ready=>0,
         latexml=>undef, digested_preamble=>undef}, $class;
}

sub prepare_session {
  my ($self,%opts) = @_;
  #0. Make sure all default keys are present, via bootstrapping with the defaults:
  foreach (keys %{$self->{defaults}}) {
    $opts{$_} = $self->{defaults}->{$_} unless exists $opts{$_};
  }
  #1. Check if there is some change from the current situation:
  my $nothingtodo=1 if Compare(\%opts, $self->{opts}, { ignore_hash_keys => [@IGNORABLE] });
  #1.1. If no, nothing to do
  return if $nothingtodo;
  #1.2. If yes, reset opts:
  undef $self->{opts};
  $self->{opts}=\%opts;
  # ... and initialize a session:
  $self->initialize_session;
  return;
}

sub initialize_session {
  my ($self) = @_;
  my $opts = $self->{opts};
  $opts = $self->{defaults} unless (defined $self->{opts});
  @{$opts->{paths}} = map {pathname_canonical($_)} @{$opts->{paths}};
  # Any post switch implies post:
  $opts->{post}=1 if (keys %{$opts->{procs_post}});
  
  binmode(STDERR,":utf8");
  # Prepare LaTeXML object
  my $latexml= new_latexml($self->{opts});
  # Demand errorless initialization
  my $init_status = $latexml->getStatusMessage;
  croak $init_status unless ($init_status !~ /error/i);


  my $digested_preamble = load_preamble($self->{opts},$latexml,$self->{opts}->{preamble_loaded});
  $self->{latexml} = $latexml;
  $self->{digested_preamble} = $digested_preamble;
  $self->{ready}=1;
}

sub convert {
  my ($self,$source) = @_;
  # Install signal-handlers
  local $SIG{'ALRM'} = 'dotimeout';
  local $SIG{'TERM'} = 'doterm';
  local $SIG{'INT'} = 'doterm';
  # Prepare options if needed
  $self->initialize_session unless $self->{ready};

  # Inform of identity, increase conversion counter
  print STDERR $opts->{identity}."\n" if $opts->{verbosity} >= 0;
  my $opts = $self->{opts};
  $opts->{input_counter}++;

  #Source type: File, String or URL?
  ($opts->{source_type},$source) = $self->source_type($source) unless defined $opts->{source_type};

  #Recognize bibtex case
  $opts->{type} = 'bibtex' if ($opts->{type} eq 'auto') && ($source =~ /\.bib$/);
  ##############################3
  # First read and digest whatever we're given.
  my $digested;
  # Preload the preamble if any (and not loaded)
  $digested_preamble = load_preamble($opts,$latexml,$digested_preamble);
  # Prepare daemon frame
  $latexml->withState(sub {
                        my($state)=@_; # Sandbox state
                        # Save preamble information for further use:
                        $state->assignValue('_preamble_loaded',$opts->{preamble},'global');
                        $state->assignValue('_authlist',$opts->{authlist},'global');
                        $state->pushDaemonFrame; });
  # Prepare preamble and postamble in fragment mode
  my ($serialized,$dom,$modepre,$modepost);
  if ($opts->{mode} eq 'fragment') {
    $modepre='standard_preamble.tex';
    $modepost='standard_postamble.tex';
  }
  # Digest source:
  eval {
    if ($isURL) {
      $digested = $latexml->digestString($response->content,preamble=>$modepre,postamble=>$modepost,source=>$source,noinitialize=>1);
    } elsif ($isFile) {
      if ($opts->{type} eq 'bibtex') {
        # TODO: Do we want URL support here?
        $digested = $latexml->digestBibTeXFile($source,preamble=>$modepre,postamble=>$modepost,noinitialize=>1);
      } else {
        $digested = $latexml->digestFile($source,preamble=>$modepre,postamble=>$modepost,noinitialize=>1);
      }}
    elsif ($isString) {
      $source = mathdoc($source) if ($opts->{mode} eq "math");
      $digested = $latexml->digestString($source,preamble=>$modepre,postamble=>$modepost,noinitialize=>1);
    }
    # ========================================
    # Now, convert to DOM and output, if desired.
    if ($digested) {
      $digested = LaTeXML::List->new($digested_preamble,$digested) if defined $digested_preamble;
      local $LaTeXML::Global::STATE = $$latexml{state};
      if ($opts->{format} eq 'tex') {
        $serialized = LaTeXML::Global::UnTeX($digested);
      } elsif ($opts->{format} eq 'box') {
        $serialized = $digested->toString;
      } else {
        $dom = $latexml->convertDocument($digested);
        $serialized = $dom->toString(1);
      }
    }
    1;

####################################################33
###########################################3
  #END:
  delete $opts->{source_type};
  #self->{log} ??
  ($result,$log,$status);
}

sub source_type {
  my ($self,$source)=@_;
  my $opts=$self->{opts};
  $source=~s/\n$//g; # Eliminate trailing new lines
  my @source_lines = split(/\n/,$source);
  return ("string",$source) if (scalar(@source_lines)>1);
  if ($opts->{local}) {
    my $file = pathname_find($source,types=>['tex',q{}]);
    $file = pathname_canonical($file) if $file;
    return ("file",$file) if $file;
  }
  $response = auth_get($source,$opts->{authlist});
  return ("url",$response) if $response->is_success;
  return ("string",$source);
}


########## Helper routines: ############

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
    } else {
      if (!$opts->{local}) { carp "File preamble allowed only when 'local' is enabled!"; return; }
      $digested = $latexml->digestFile($opts->{preamble},noinitialize=>1);
    }
    $opts->{preamble_loaded} = $opts->{preamble};
  }
  $digested = $original unless defined $digested;
  return $digested;
}


__END__

=pod 

=head1 NAME

C<LaTeXML::Daemon> - Daemon object and API for LaTeXML and LaTeXMLPost conversion.

=head1 SYNOPSIS

    use LaTeXML::Daemon;
    my $daemon = LaTeXML::Daemon->new(%options);
    $daemon->setOptions(%opts);
    my ($result,$errors,$status) = $daemon->convert($tex);

=head1 DESCRIPTION

A Daemon object represents a converter instance and can convert files on demand, until dismissed.

=head2 METHODS

=over 4

=item C<< my $daemon = LaTeXML::Daemon->new(%options); >>

=item C<< $daemon->setOptions(%opts);  >>

=item C<< my ($result,$errors,$status) = $daemon->convert($tex); >>

Converts $tex into $result and supplies detailed information of detected errors and status.

=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
