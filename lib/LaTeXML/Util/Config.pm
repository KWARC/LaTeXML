# /=====================================================================\ #
# |  LaTeXML::Util::Config                                              | #
# | Configuration logic for LaTeXML                                     | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                                | #
# | Deyan Ginev <deyan.ginev@nist.gov>                          #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Util::Config;

use strict;
use warnings;
use Carp;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use Pod::Find qw(pod_where);
use Data::Dumper;
use LaTeXML::Util::Pathname;
use LaTeXML::Global;

our $PROFILES_DB={}; # Class-wide, caches all profiles that get used while the server is alive

sub new {
  my ($class,%opts) = @_;
  #TODO: How about defaults in the daemon server use case? Should we support those here?
  #      or are defaults always bad/confusing to allow?
  bless {dirty=>1,opts=>\%opts}, $class;
}


###########################################
#### Command-line reader              #####
###########################################

# TODO: Think of the webapp, port it to this interface
#       Should we have a standardization to the command-line switches?
#       But JSON has no notion of order, so it might be tricky with the math processors
sub read {
  my ($self,$argref) = @_;
  my $opts = $self->{opts};
  local @ARGV = @$argref;
  GetOptions(
	   "output=s"  => \$opts->{destination},
           "destination=s" => \$opts->{destination},
	   "preload=s" => \@{$opts->{preload}},
	   "preamble=s" => \$opts->{preamble},
	   "postamble=s" => \$opts->{postamble},
           "base=s"  => \$opts->{base},
	   "path=s"    => \@{$opts->{paths}},
	   "quiet"     => sub { $opts->{verbosity}--; },
	   "verbose"   => sub { $opts->{verbosity}++; },
	   "strict"    => sub { $opts->{strict} = 1; },
	   "xml"       => sub { $opts->{format} = 'xml'; },
	   "tex"       => sub { $opts->{format} = 'tex'; },
	   "box"       => sub { $opts->{format} = 'box'; },
	   "bibtex"    => sub { $opts->{type}='bibtex'; },
	   "bibliography=s" => \@{$opts->{bibliographies}}, # TODO: Document
	   "sitedirectory=s"=>\$opts->{sitedirectory},
	   "sourcedirectory=s"=>\$opts->{sourcedirectory},
	   "noparse"   => sub { $opts->{noparse} = 1; },
	   "parse"   => sub { $opts->{noparse} = 0; },
	   "format=s"   => \$opts->{format},
	   "profile=s"  => \$opts->{profile},
	   "mode=s"  => \$opts->{profile},
           "source=s"  => \$opts->{source},
           "embed"   => sub { $opts->{whatsin} = 'fragment'; },
	   "whatsin=s" => \$opts->{whatsin},
	   "whatsout=s" => \$opts->{whatsout},
	   "force_ids!" => \$opts->{force_ids},
	   "autoflush=s" => \$opts->{input_limit},
           "timeout=s"   => \$opts->{timeout}, #TODO: JOB and SERVER timeouts!
           "port=s"      => \$opts->{port},
           "local!"       => \$opts->{local},
	   "log=s"       => \$opts->{log},
	   "includestyles"=> sub { $opts->{includestyles} = 1; },
	   "inputencoding=s"=> \$opts->{inputencoding},
	   "post!"      => \$opts->{post},
	   "presentationmathml|pmml"     => sub { addMathFormat($opts,'pmml'); },
	   "contentmathml|cmml"          => sub { addMathFormat($opts,'cmml'); },
	   "openmath|om"                 => sub { addMathFormat($opts,'om'); },
	   "keepXMath|xmath"             => sub { addMathFormat($opts,'xmath'); },
	   "nopresentationmathml|nopmml" => sub { removeMathFormat($opts,'pmml'); },
	   "nocontentmathml|nocmml"      => sub { removeMathFormat($opts,'cmml'); },
	   "noopenmath|noom"             => sub { removeMathFormat($opts,'om'); },
	   "nokeepXMath|noxmath"         => sub { removeMathFormat($opts,'xmath'); },
	   "parallelmath"               => sub { $opts->{parallelmath} = 1;},
	   "stylesheet=s"=>  \$opts->{stylesheet},
           "stylesheetparam=s" => sub {my ($k,$v) = split(':',$_[1]);
                                  $opts->{stylesheetparam}->{$k}=$v;},
	   "css=s"       =>  \@{$opts->{css}},
	   "defaultcss!" =>  \$opts->{defaultcss},
	   "comments!" =>  \$opts->{comments},
	   "VERSION"   => sub { $opts->{showversion}=1;},
	   "debug=s"   => sub { eval "\$LaTeXML::$_[1]::DEBUG=1; "; },
           "documentid=s" => \$opts->{documentid},
	   "mathimages!"                 => \$opts->{mathimages},
	   "mathimagemagnification=f"    => \$opts->{mathimagemag},
	   "plane1!"                     => \$opts->{plane1},
	   "hackplane1!"                 => \$opts->{hackplane1},
	   # For graphics: vaguely similar issues, but more limited.
	   # includegraphics images (eg. ps) can be converted to webimages (eg.png)
	   # picture/pstricks images can be converted to png or possibly svg.
	   "graphicimages!"=>\$opts->{dographics},
	   "graphicsmap=s" =>\@{$opts->{graphicsmaps}},
	   "svg!"       => \$opts->{svg},
	   "pictureimages!"=>\$opts->{picimages},
	   "help"      => sub { $opts->{help} = 1; } ,
	  ) or pod2usage(-message => $opts->{identity}, -exitval=>1, -verbose=>99,
			 -input => pod_where({-inc => 1}, __PACKAGE__),
			 -sections => 'OPTIONS/SYNOPSIS', -output=>\*STDERR);

  pod2usage(-message=>$opts->{identity}, -exitval=>1, -verbose=>99,
	    -input => pod_where({-inc => 1}, __PACKAGE__),
	    -sections => 'OPTIONS/SYNOPSIS', output=>\*STDOUT) if $opts->{help};

  # Check that destination is valid before wasting any time...
  if($opts->{destination} && $opts->{local}){
    $opts->{destination} = pathname_canonical($opts->{destination});
    if(my $dir = pathname_directory($opts->{destination})){
      pathname_mkdir($dir) or croak "Couldn't create destination directory $dir: $!"; }}
  # Removed math formats are irrelevant for conversion:
  delete $opts->{removed_math_formats};

  if($opts->{showversion}){ print STDERR $opts->{identity}."\n"; exit(1); }

  $opts->{source} = $ARGV[0] unless $opts->{source};
  return;
}
sub addMathFormat {
  my($opts,$fmt)=@_;
  $opts->{math_formats} = [] unless defined $opts->{math_formats};
  push(@{$opts->{math_formats}},$fmt) 
    unless grep($_ eq $fmt,@{$opts->{math_formats}}) || $opts->{removed_math_formats}->{$fmt}; }
sub removeMathFormat {
  my($opts,$fmt)=@_;
  @{$opts->{math_formats}} = grep($_ ne $fmt, @{$opts->{math_formats}});
  $opts->{removed_math_formats}->{$fmt}=1; }


###########################################
#### Options Object Hashlike API      #####
###########################################
sub get {
  my ($self,$key,$value) = @_;
  $self->{opts}->{$key};
}
sub set {
  my ($self,$key,$value) = @_;
  $self->{dirty}=1;
  $self->{opts}->{$key} = $value;
}
sub delete {
  my ($self, $key) = @_;
  $self->{dirty}=1;
  delete $self->{opts}->{$key};
}
sub exists {
  my ($self, $key) = @_;
  exists $self->{opts}->{$key};
}
sub keys {
  my ($self) = @_;
  keys %{$self->{opts}};
}
sub options {
  my ($self) = @_;
  $self->{opts};
}
sub clone {
  my ($self)=@_;
  LaTeXML::Util::Config->new(%{$self->options});
}

###########################################
#### Option Sanity Checking           #####
###########################################

# Perform all option sanity checks
sub check {
  my ($self) = @_;
  return unless $self->{dirty};
  # 1. Resolve profile
  $self->obey_profile;
  # 2. Place sane defaults where needed
  $self->prepare_options;
}

sub obey_profile {
  my ($self) = @_;
  $self->{dirty}=1;
  my  $profile = lc($self->{opts}->{profile})||'custom';
  # Look at the PROFILES_DB or find a profiles file (otherwise fallback to custom)
  my $profile_opts={};
  if ($profile ne 'custom') {
    if (defined $PROFILES_DB->{$profile}) {
      %$profile_opts = %{$PROFILES_DB->{$profile}}
    } elsif (my $file = pathname_find($profile.'.opt',paths=>[],
                                      types=>[], installation_subdir=>'Profiles')) {
      my $conf_tmp = LaTeXML::Util::Config->new;
      $conf_tmp->read(_read_options_file($file));
      $profile_opts = $conf_tmp->options;
    } else {
      # Throw an error, fallback to custom
      croak ("Error:unexpected:$profile Profile $profile was not recognized, reverting to 'custom'");
      $self->{opts}->{profile} = 'custom';
      $profile='custom';
    }
  }

  my $opts = $self->{opts};
  # Merge the new options with the profile defaults:
  for my $key (grep {defined $opts->{$_}} (CORE::keys %$opts)) {
    if ($key =~ /^p(ath|reload)/) { # Paths and preloads get merged in
      $profile_opts->{$key} = [] unless defined $profile_opts->{$key};
      foreach my $entry (@{$opts->{$key}}) {
        my $new=1;
        foreach (@{$profile_opts->{$key}}) {
          if ($entry eq $_) { $new=0; last; }
        }
        # If new to the array, push:
        push (@{$profile_opts->{$key}}, $entry) if ($new);
      }
    } else { # The other options get overwritten
      $profile_opts->{$key} = $opts->{$key};
    }
  }
  %$opts=%$profile_opts; # Move back into the user options
}

# TODO: Best way to throw errors when options don't work out? 
#       How about in the case of Extras::ReadOptions?
#       Error() and Warn() would be neat, but we have to make sure STDERR is caught beforehand.
#       Also, there is no eval() here, so we might need a softer handling of Error()s.
sub prepare_options {
  my ($self) = @_;
  my $opts = $self->{opts};
  #======================================================================
  # I. Sanity check and Completion of Core options.
  #======================================================================
  $opts->{timeout} = 600 unless defined $opts->{timeout}; # 10 minute timeout default
  $opts->{dographics} = 1 unless defined $opts->{dographics}; #TODO: Careful, POST overlap!
  $opts->{verbosity} = 10 unless defined $opts->{verbosity};
  $opts->{preload} = [] unless defined $opts->{preload};
  $opts->{paths} = ['.'] unless defined $opts->{paths};
  @{$opts->{paths}} = map {pathname_canonical($_)} @{$opts->{paths}};
  foreach my $pathname(('destination','sourcedirectory','sitedirectory')) {
    #TODO: Switch away from this rude absolute treatment when we support URLs
    # (or could we still leverage this by a smart pathname_cwd?)
    $opts->{$pathname} = pathname_absolute($opts->{$pathname},pathname_cwd()) if defined $opts->{$pathname};
  }

  $opts->{whatsin} = 'document' unless defined $opts->{whatsin};
  $opts->{whatsout} = 'document' unless defined $opts->{whatsout};
  $opts->{type} = 'auto' unless defined $opts->{type};

  # Destination extension might indicate the format:
  if ((!defined $opts->{format}) && (defined $opts->{destination})){
    if ($opts->{destination}=~/\.xhtml$/) {
      $opts->{format}='xhtml';
    } elsif ($opts->{destination}=~/\.html$/) {
      $opts->{format}='html';
    } elsif ($opts->{destination}=~/\.html5$/) {
      $opts->{format}='html5';
    } elsif ($opts->{destination}=~/\.xml$/) {
      $opts->{format}='xml';
    }}

  # Unset destinations unless local conversion has been requested:
  if (!$opts->{local} && ($opts->{destination} || $opts->{log} || $opts->{postdest} || $opts->{postlog})) 
    {carp "I/O from filesystem not allowed without --local!\n".
       " Will revert to sockets!\n";
     undef $opts->{destination}; undef $opts->{log};
     undef $opts->{postdest}; undef $opts->{postlog};}
  #======================================================================
  # II. Sanity check and Completion of Post options.
  #======================================================================
  # Any post switch implies post (TODO: whew, lots of those, add them all!):
  $opts->{post}=1 if ( (! defined $opts->{post}) && ($opts->{math_formats} && scalar(@{$opts->{math_formats}}) ) ||
    ($opts->{stylesheet}) || ($opts->{format} && ($opts->{format}=~/html/i)));
                       # || ... || ... || ...
  if ($opts->{post}) { # No need to bother if we're not post-processing

    # Default: scan and crossref on, other advanced off
    $opts->{prescan}=undef unless defined $opts->{prescan};
    $opts->{dbfile}=undef unless defined $opts->{dbfile};
    $opts->{scan}=1 unless defined $opts->{scan};
    $opts->{index}=1 unless defined $opts->{index};
    $opts->{crossref}=1 unless defined $opts->{crossref};
    $opts->{sitedirectory}=undef unless defined $opts->{sitedirectory};
    $opts->{sourcedirectory}=undef unless defined $opts->{sourcedirectory};
    $opts->{numbersections}=1 unless defined $opts->{numbersections};
    $opts->{navtoc}=undef unless defined $opts->{numbersections};
    $opts->{navtocstyles}={context=>1,normal=>1,none=>1} unless defined $opts->{navtocstyles};
    $opts->{navtoc} = lc($opts->{navtoc}) if defined $opts->{navtoc};
    delete $opts->{navtoc} if ($opts->{navtoc} && ($opts->{navtoc} eq 'none'));
    if($opts->{navtoc}){
      if(!$opts->{navtocstyles}->{$opts->{navtoc}}){
	croak($opts->{navtoc}." is not a recognized style of navigation TOC"); }
      if(!$opts->{crossref}){
	croak("Cannot use option \"navigationtoc\" (".$opts->{navtoc}.") without \"crossref\""); }}
    $opts->{urlstyle}='server' unless defined $opts->{urlstyle};
    $opts->{bibliographies} = [] unless defined $opts->{bibliographies};

    # Validation:
    $opts->{validate} = 1 unless defined $opts->{validate};
    # Graphics:
    $opts->{dographics} = 1 unless defined $opts->{dographics};
    $opts->{mathimages} = undef unless defined $opts->{mathimages};
    $opts->{mathimagemag} = 1.75 unless defined $opts->{mathimagemag};
    $opts->{picimages} = 1 unless defined $opts->{picimages};
    # Split:
    $opts->{split}=undef unless defined $opts->{split};
    $opts->{splitat}='section' unless defined $opts->{splitat};
    $opts->{splitpath}=undef unless defined $opts->{splitpath};
    $opts->{splitnaming}='id' unless defined $opts->{splitnaming};
    $opts->{splitback} = "//ltx:bibliography | //ltx:appendix | //ltx:index" unless defined $opts->{splitback};
    $opts->{splitpaths} =
      {chapter=>"//ltx:chapter | ".$opts->{splitback},
       section=>"//ltx:chapter | //ltx:section | ".$opts->{splitback},
       subsection=>"//ltx:chapter | //ltx:section | //ltx:subsection | ".$opts->{splitback},
       subsubsection=>"//ltx:chapter | //ltx:section | //ltx:subsection | //ltx:subsubsection | ".$opts->{splitback}}
	unless defined $opts->{splitpaths};
    # Format:
    #Default is XHTML, XML otherwise (TODO: Expand)
    $opts->{format}="xml" if ($opts->{stylesheet}) && (!defined $opts->{format});
    $opts->{format}="xhtml" unless defined $opts->{format};
    if (!$opts->{stylesheet}) {
      if ($opts->{format} eq "xhtml") {$opts->{stylesheet} = "LaTeXML-xhtml.xsl";}
      elsif ($opts->{format} eq "html") {$opts->{stylesheet} = "LaTeXML-html.xsl";}
      elsif ($opts->{format} eq "html5") {$opts->{stylesheet} = "LaTeXML-html5.xsl";}
      elsif ($opts->{format} eq "xml") {delete $opts->{stylesheet};}
      else {croak("Unrecognized target format: ".$opts->{format});}
    }
    # Check format and complete math and image options
    if ($opts->{format} eq 'html') {
      $opts->{svg}=0 unless defined $opts->{svg}; # No SVG by default.
      croak("Default html stylesheet only supports math images, not ".join(', ',@{$opts->{math_formats}}))
	if scalar(@{$opts->{math_formats}});
      croak("Default html stylesheet does not support svg") if $opts->{svg};
      $opts->{mathimages} = 1;
      $opts->{math_formats} = [];
    }
    $opts->{dographics} = 1 unless defined $opts->{dographics};
    $opts->{picimages}  = 1 unless defined $opts->{picimages};
    $opts->{svg} = 1 unless defined $opts->{svg};
    # Math Format fallbacks:
    # TODO: Reintroduce defaults?
    # $opts->{math_formats}=[@{$self->{defaults}->{math_formats}}] if (defined $self && (! 
    #                                                                    ( (defined $opts->{math_formats}) &&
    #                                                                      scalar(@{$opts->{math_formats}})
    #                                                                    )));
    # PMML default if all else fails and no mathimages:
    if  (((! defined $opts->{math_formats}) || (!scalar(@{$opts->{math_formats}}))) &&
      (!$opts->{mathimages}))
    {
      push @{$opts->{math_formats}}, 'pmml';
    }
    # use parallel markup if there are multiple formats requested.
    $opts->{parallelmath} = 1 if @{$opts->{math_formats}}>1;
  }
  # If really nothing hints to define format, then default it to XML
  $opts->{format} = 'xml' unless defined $opts->{format};

  $self->{dirty}=0;
}
# TODO: $sourcedir   = $sourcedir   && pathname_canonical($sourcedir);
# TODO: $sitedir     = $sitedir     && pathname_canonical($sitedir);
# TODO: All of the below
# Check for appropriate combination of split, scan, prescan, dbfile, crossref
# if($split && !defined $destination){
#   Error("Must supply --destination when using --split"); }
# if($split){
#   $splitnaming = checkOptionValue('--splitnaming',$splitnaming,
# 				  qw(id idrelative label labelrelative)); 
#   $splitat = checkOptionValue('--splitat',$splitat,keys %splitpaths);
#   $splitpath = $splitpaths{$splitat} unless defined $splitpath;
# }
# if($prescan && !$scan){
#   Error("Makes no sense to --prescan with scanning disabled (--noscan)"); }
# if($prescan && (!defined $dbfile)){
#   Error("Cannot prescan documents (--prescan) without specifying --dbfile"); }
# if(!$prescan && $crossref && ! ($scan || (defined $dbfile))){
#   Error("Cannot cross-reference (--crossref) without --scan or --dbfile "); }
# if($crossref){
#   $urlstyle = checkOptionValue('--urlstyle',$urlstyle,qw(server negotiated file)); }
# if(($permutedindex || $splitindex) && (! defined $index)){
#   $index=1; }
# if(!$prescan && $index && ! ($scan || defined $crossref)){
#   Error("Cannot generate index (--index) without --scan or --dbfile"); }
# if(!$prescan && @bibliographies && ! ($scan || defined $crossref)){
#   Error("Cannot generate bibliography (--bibliography) without --scan or --dbfile"); }
#if((!defined $destination) && ($mathimages || $dographics || $picimages)){
#  Error("Must supply --destination unless all auxilliary file writing is disabled"
#	."(--nomathimages --nographicimages --nopictureimages --nodefaultcss)"); }
#}


### This is from t/lib/TestDaemon.pm and ideally belongs in Util::Pathname
sub _read_options_file {
  my $opts = [];
  unless (open (OPT,"<",shift)) {
    Error("unexpected:IO:$_ Could not open $_");
    return;
  }
  while (<OPT>) {
    next if /^#/;
    chomp;
    /(\S+)\s*=\s*(.*)/;
    my ($key,$value) = ($1,$2||'');
    $value =~ s/\s+$//;
    $value = $value ? "=$value" : '';
    push @$opts, "--$key".$value;
  }
  close OPT;
  $opts;
}


1;

__END__

=pod

=head1 NAME

C<LaTeXML::Util::Config> - Configuration logic for LaTeXML

=head1 SYNPOSIS

TODO

=head1 DESCRIPTION

TODO

=head2 METHODS

TODO

=head1 OPTIONS

=head2 SYNOPSIS

latexmls/latexmlc [options]

 Options:
 --destination=file specifies destination file, requires --local.
 --output=file      [obsolete synonym for --destination]
 --preload=module   requests loading of an optional module;
                    can be repeated
 --preamble=file    loads a tex file containing document frontmatter.
                    MUST! include \begin{document} or equivalent
 --postamble=file   loads a tex file containing document backmatter.
                    MUST! include \end{document} or equivalent
 --includestyles    allows latexml to load raw *.sty file;
                    by default it avoids this.
 --base=dir         Specifies the base directory that the server
                    operates in. Useful when converting documents
                    that employ relative paths.
 --path=dir         adds dir to the paths searched for files,
                    modules, etc; 
 --log=file         specifies log file, reuqires --local
                    default: STDERR
 --autoflush=count  Automatically restart the daemon after 
                    "count" inputs. Good practice for vast batch 
                    jobs. (default: 100)
 --timeout=secs     Set a timeout value for inactivity.
                    Default is 60 seconds, set 0 to disable.
                    Also used to terminate processing jobs
 --port=number      Specify server port (default: 3354)
 --local            Request a local server (default: off)
                    Required for the --log and --destination switches
                    Required for processing filenames on input
 --documentid=id    assign an id to the document root.
 --quiet            suppress messages (can repeat)
 --verbose          more informative output (can repeat)
 --strict           makes latexml less forgiving of errors
 --bibtex           processes the file as a BibTeX bibliography.
 --xml              requests xml output (default).
 --tex              requests TeX output after expansion.
 --box              requests box output after expansion
                    and digestion.
 --noparse          suppresses parsing math (default: off)
 --parse          enables parsing math (default: on)
 --profile=name     specify profile as defined in LaTeXML::Util::Startup
                    Supported: standard|math|fragment|...
                    (default: standard)
 --mode=name        Alias for profile
 --whatsin=chunk    Defines the provided input chunk, choose from
                    document (default), fragment and formula
 --whatsout=chunk   Defines the expected output chunk, choose from
                    document (default), fragment and formula

 --post             requests a followup post-processing
 --embed            requests an embeddable XHTML snippet
                    (requires: --post,--profile=fragment)
                    DEPRECATED: Use --whatsout=fragment
                    TODO: Remove completely
 --stylesheet       specifies a stylesheet,
                    to be used by the post-processor.
 --css=cssfile           adds a css stylesheet to html/xhtml
                         (can be repeated)
 --nodefaultcss          disables the default css stylesheet
 --sitedirectory=dir     specifies the base directory of the site
 --sourcedirectory=dir   specifies the base directory of the
                           original TeX source
 --mathimages            converts math to images
                         (default for html format)
 --nomathimages          disables the above
 --mathimagemagnification=mag specifies magnification factor
 --pmml             converts math to Presentation MathML
                    (default for xhtml format)
 --cmml             converts math to Content MathML
 --openmath         converts math to OpenMath
 --keepXMath        keeps the XMath of a formula as a MathML
                    annotation-xml element
 --nocomments       omit comments from the output
 --inputencoding=enc specify the input encoding.
 --VERSION          show version number.
 --debug=package    enables debugging output for the named
                    package
 --help             shows this help message.

In I<math> C<profile>, latexmls accepts one TeX formula on input.
    In I<standard> and I<fragment> C<profile>, latexmls accepts one I<texfile>
    filename per line on input, but only when --local is specified.
    If I<texfile> has an explicit extension of C<.bib>, it is processed
    as a BibTeX bibliography.

    Note that the profiles come with a variety of preset options. To customize your
    own conversion setup, use --whatsin=math|fragment|document instead, respectively,
    as well as --whatsout=math|fragment|document.

    For reliable communication and a stable conversion experience, invoke latexmls
    only through the latexmlc client.

=head2 DETAILS

=over 4

=item C<--destination>=I<file>

Requires: C<--local>
Specifies the destination file; by default the XML is written to STDOUT.

=item C<--preload>=I<module>

Requests the loading of an optional module or package.  This may be useful if the TeX code
    does not specificly require the module (eg. through input or usepackage).
    For example, use C<--preload=LaTeX.pool> to force LaTeX mode.

=item C<--preamble>=I<file>

Requests the loading of a tex file with document frontmatter, to be read in before the converted document, 
    but after all --preload entries.

Note that the given file MUST contain \begin{document} or an equivalent environment start,
    when processing LaTeX documents.

If the file does not contain content to appear in the final document, but only macro definitions and 
    setting of internal counters, it is more appropriate to use --preload instead.

=item C<--postamble>=I<file>

Requests the loading of a tex file with document backmatter, to be read in after the converted document.

Note that the given file MUST contain \end{document} or an equivalent environment end,
    when processing LaTeX documents.

=item C<--includestyles>

This optional allows processing of style files (files with extensions C<sty>,
    C<cls>, C<clo>, C<cnf>).  By default, these files are ignored  unless a latexml
    implementation of them is found (with an extension of C<ltxml>).

These style files generally fall into two classes:  Those
    that merely affect document style are ignorable in the XML.
    Others define new markup and document structure, often using
    deeper LaTeX macros to achieve their ends.  Although the omission
    will lead to other errors (missing macro definitions), it is
    unlikely that processing the TeX code in the style file will
    lead to a correct document.

=item C<--path>=I<dir>

Add I<dir> to the search paths used when searching for files, modules, style files, etc;
    somewhat like TEXINPUTS.  This option can be repeated.

=item C<--log>=I<file>

Requires: C<--local>
Specifies the log file; be default any conversion messages are printed to STDERR.

=item C<--autoflush>=I<count>

Automatically restart the daemon after converting "count" inputs.
    Good practice for vast batch jobs. (default: 100)
    
=item C<--timeout>=I<secs>

Set an inactivity timeout value in seconds. If the daemon is not given any input
    for the timeout period it will automatically self-destruct.
    The default value is 60 seconds, set to 0 to disable.

=item C<--port>=I<number>

Specify server port (default: 3334 for math, 3344 for fragment and 3354 for standard)

=item C<--local>

Request a local server (default: off)
    Required for the C<--log> and C<--destination> switches
    Required for processing filenames on input, as well as for any filesystem access.
    If switched off, the only means of communication with the server is via the respective socket.
    Caveat: When C<--local> is disabled, fatal errors cause an empty output at the moment.

=item C<--documentid>=I<id>

Assigns an ID to the root element of the XML document.  This ID is generally
    inherited as the prefix of ID's on all other elements within the document.
    This is useful when constructing a site of multiple documents so that
    all nodes have unique IDs.

=item C<--quiet>

Reduces the verbosity of output during processing, used twice is pretty silent.

=item C<--verbose>

Increases the verbosity of output during processing, used twice is pretty chatty.
    Can be useful for getting more details when errors occur.

=item C<--strict>

Specifies a strict processing mode. By default, undefined control sequences and
    invalid document constructs (that violate the DTD) give warning messages, but attempt
    to continue processing.  Using C<--strict> makes them generate fatal errors.

=item C<--bibtex>

Forces latexml to treat the file as a BibTeX bibliography.
    Note that the timing is slightly different than the usual
    case with BibTeX and LaTeX.  In the latter case, BibTeX simply
    selects and formats a subset of the bibliographic entries; the
    actual TeX expansion is carried out when the result is included
    in a LaTeX document.  In contrast, latexml processes and expands
    the entire bibliography; the selection of entries is done
    during post-processing.  This also means that any packages
    that define macros used in the bibliography must be
    specified using the C<--preload> option.

=item C<--xml>

Requests XML output; this is the default.

=item C<--tex>

Requests TeX output for debugging purposes;
    processing is only carried out through expansion and digestion.
    This may not be quite valid TeX, since Unicode may be introduced.

=item C<--box>

Requests Box output for debugging purposes;
    processing is carried out through expansion and digestions,
    and the result is printed.

=item C<--profile>

Variety of shorthand profiles, described in detail at LaTeXML::Util::Startup.
Example: C<latexmlc --profile=math 1+2=3>

=item C<--post>

Request post-processing. Enabled by default is processing graphics and cross-referencing.


=item C<--embed>

TODO: Deprecated, use --whatsout=fragment
Requests an embeddable XHTML div (requires: --post --format=xhtml),
    respectively the top division of the document's body.
    Caveat: This experimental mode is enabled only for fragment profile and post-processed
    documents (to XHTML).

=item C<--mathimages>, C<--nomathimages>

Requests or disables the conversion of math to images.
Conversion is the default for html format.

=item C<--mathimagemagnification=>I<factor>

Specifies the magnification used for math images, if they are made.
Default is 1.75.

=item C<--pmml>

Requests conversion of math to Presentation MathML.
    Presentation MathML is the default math processor for the XHTML/HTML/HTML5 formats.
    Will enable C<--post>.

=item C<--cmml>

Requests or disables conversion of math to Content MathML.
    Conversion is disabled by default.
    B<Note> that this conversion is only partially implemented.
    Will enable C<--post>.

=item C<--openmath>

Requests or disables conversion of math to OpenMath.
    Conversion is disabled by default.
    B<Note> that this conversion is not yet supported in C<latexmls>.
    Will enable C<--post>.

=item C<--xmath> and C<--keepXMath>

By default, when any of the MathML or OpenMath conversions
    are used, the intermediate math representation will be removed;
    Explicitly specifying --xmath|keepXMath preserves this format.
    Will enable C<--post>.

=item C<--stylesheet>=I<file>

Sets a stylesheet of choice to be used by the postprocessor.
    Will enable C<--post>.

=item C<--css>=I<cssfile>

Adds I<cssfile> as a css stylesheet to be used in the transformed html/xhtml.
    Multiple stylesheets can be used; they are included in the html in the
    order given, following the default C<core.css>
    (but see C<--nodefaultcss>). Some stylesheets included in the distribution are
  --css=navbar-left   Puts a navigation bar on the left.
                      (default omits navbar)
  --css=navbar-right  Puts a navigation bar on the left.
  --css=theme-blue    A blue coloring theme for headings.
  --css=amsart        A style suitable for journal articles.

=item C<--nodefaultcss>

Disables the inclusion of the default C<core.css> stylesheet.

=item C<--nocomments>

Normally latexml preserves comments from the source file, and adds a comment every 25 lines as
    an aid in tracking the source.  The option --nocomments discards such comments.

=item C<--sitedirectory=>I<dir>

Specifies the base directory of the overall web site.
Pathnames in the database are stored in a form relative
to this directory to make it more portable.

=item C<--sourcedirectory>=I<source>

Specifies the directory where the original latex source is located.
Unless LaTeXML is run from that directory, or it can be determined
from the xml filename, it may be necessary to specify this option in
order to find graphics and style files.

=item C<--inputencoding=>I<encoding>

Specify the input encoding, eg. C<--inputencoding=iso-8859-1>.
    The encoding must be one known to Perl's Encode package.
    Note that this only enables the translation of the input bytes to
    UTF-8 used internally by LaTeXML, but does not affect catcodes.
    In such cases, you should be using the inputenc package.
    Note also that this does not affect the output encoding, which is
    always UTF-8.

=item C<--VERSION>

Shows the version number of the LaTeXML package..

=item C<--debug>=I<package>

Enables debugging output for the named package. The package is given without the leading LaTeXML::.

=item C<--help>

Shows this help message.

=back

=head1 AUTHOR

Bruce Miller <bruce.miller@nist.gov>
Deyan Ginev <d.ginev@nist.gov>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
