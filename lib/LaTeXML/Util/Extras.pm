# /=====================================================================\ #
# |  LaTeXML::Extras                                                    | #
# |  Extras, Goodies and, well, things without a clear home module      | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <d.ginev@jacobs-university.de>                  #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Util::Extras;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use Pod::Find qw(pod_where);

use XML::LibXSLT;
use XML::LibXML;
use LaTeXML::Util::Pathname;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( &MathDoc &GetMath &GetEmbeddable &InsertIDs &Compare &ReadOptions);

sub MathDoc {
#======================================================================
# TeX Source
#======================================================================
# First read and digest whatever we're given.
    my ($tex) = @_;
# We need to determine whether the TeX we're given needs to be wrapped in \[...\]
# Does it have $'s around it? Does it have a display math environment?
# The most elegant way would be to notice as soon as we start adding to the doc
# and switch to math mode if necessary, but that's tricky.
# Let's just try a manual hack, looking for known switches...
our $MATHENVS = 'math|displaymath|equation*?|eqnarray*?'
  .'|multline*?|align*?|falign*?|alignat*?|xalignat*?|xxalignat*?|gather*?';
$tex =~ s/\A\s+//m; #as usual, strip leading ...
$tex =~ s/\s+\z//m; # ... and trailing space
if(($tex =~ /\A\$/m) && ($tex =~ /\$\z/m)){} # Wrapped in $'s
elsif(($tex =~ /\A\\\(/m) && ($tex =~ /\\\)\z/m)){} # Wrapped in \(...\)
elsif(($tex =~ /\A\\\[/m) && ($tex =~ /\\\]\z/m)){} # Wrapped in \[...\]
elsif(($tex =~ /\A\\begin\{($MATHENVS)\}/m) && ($tex =~ /\\end\{$1\}\z/m)){}
else {
  $tex = '\[ '.$tex.' \]'; }

my $texdoc = <<"EODOC";
\\begin{document}
\\newcounter{equation}
\\newcounter{Unequation}
$tex
\\end{document}
EODOC
return $texdoc;
}

sub GetMath {
  my ($source) = @_;
  return unless defined $source;
  my $math;
  my $mnodes = $source->findnodes('//*[local-name()="math"]');
  if ($mnodes->size <= 1) {
    $math = $source->findnode('//*[local-name()="math"]');
  } else {
    my $ancestor = $source->findnode('//*[local-name()="math"]')->parentNode;
    $ancestor = $ancestor->parentNode while ($ancestor->findnodes('.//*[local-name()="math"]')->size != $mnodes->size);
    $math = $ancestor;
  }
  return $math;
}

sub GetEmbeddable {
  my ($postdoc) = @_;
  return unless defined $postdoc;
  my $docdiv = $postdoc->findnode('//*[@class="document"]');
  return $docdiv;
}

our $id_xslt_dom = XML::LibXML->new()->parse_string(<<'EOT');
<!-- this style sheet introduces automatic IDs to an XHTML document-->
<xsl:stylesheet version="1.0"
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns = "http://www.w3.org/1999/xhtml"
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:svg = "http://www.w3.org/2000/svg"
  xmlns:m = "http://www.w3.org/1998/Math/MathML">

<xsl:output method="xml" encoding="utf-8" omit-xml-declaration="no"
  standalone="yes" doctype-public="-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN"
  doctype-system="http://www.w3.org/TR/MathML2/dtd/xhtml-math11-f.dtd"
  media-type     = 'application/xhtml+xml'
  cdata-section-elements="data" indent="yes"/>
  <xsl:template match="*">
    <xsl:copy>
      <xsl:if test="not(@xml:id) and not(@id)">
        <xsl:attribute name="id">
          <xsl:value-of select="generate-id(.)"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
   </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
EOT
our $id_xslt = XML::LibXSLT->new()->parse_stylesheet($id_xslt_dom);

sub InsertIDs {
  my $doc = shift;
  return unless defined $doc;
  return LaTeXML::Post::Document->new($id_xslt->transform($doc->getDocument));
}

sub ReadOptions {
  my ($opts,$argref) = @_;
  local @ARGV = @$argref;
  $opts->{math_formats} = [] unless defined $opts->{math_formats};
  GetOptions(
	   "output=s"  => sub {$opts->{destination} = $_[1];},
           "destination=s" => sub {$opts->{destination} = $_[1];},
	   "preload=s" => sub { push @{$opts->{preload}}, $_[1]},
	   "preamble=s" => sub {$opts->{preamble} = $_[1];},
           "base=s"  => sub {$opts->{base} = $_[1];},
	   "path=s"    => sub { push @{$opts->{paths}}, $_[1]},
	   "quiet"     => sub { $opts->{verbosity}--; },
	   "verbose"   => sub { $opts->{verbosity}++; },
	   "strict"    => sub { $opts->{strict} = 1; },
	   "xml"       => sub { $opts->{format} = 'xml'; },
	   "tex"       => sub { $opts->{format} = 'tex'; },
	   "box"       => sub { $opts->{format} = 'box'; },
	   "bibtex"    => sub { $opts->{type}='bibtex'; },
	   "noparse"   => sub { $opts->{noparse} = 1; },
	   "format=s"   => sub { $opts->{format} = $_[1]; },
	   "profile=s"  => sub { $opts->{profile} = $_[1]; },
	   "mode=s"  => sub { $opts->{profile} = $_[1]; },
           "source=s"  => sub { $opts->{source} = $_[1]; },
           "embed"   => sub { $opts->{embed} = 1; },
           "noembed"   => sub { $opts->{embed} = 0; },
	   "autoflush=s" => sub { $opts->{input_limit} = $_[1]; },
           "timeout=s"   => sub { $opts->{timeout} = $_[1]; },
           "port=s"      => sub { $opts->{port} = $_[1]; },
           "local"       => sub { $opts->{local} = 1; },
           "nolocal"       => sub { $opts->{local} = 0; },
	   "log=s"       => sub { $opts->{log} = $_[1]; },
           "summary"    => sub { $opts->{summary} = 1; },
           "nosummary"    => sub { $opts->{summary} = 0; },
	   "includestyles"=> sub { $opts->{includestyles} = 1; },
	   "inputencoding=s"=> sub { $opts->{inputencoding} = $_[1]; },
	   "post"      => sub { $opts->{post} = 1; },
	   "nopost"      => sub { $opts->{post} = 0; },
	   "presentationmathml|pmml"     => sub { addMathFormat($opts,'pmml'); },
	   "contentmathml|cmml"          => sub { addMathFormat($opts,'cmml'); },
	   "openmath|om"                 => sub { addMathFormat($opts,'om'); },
	   "keepXMath|xmath"             => sub { addMathFormat($opts,'xmath'); },
	   "nopresentationmathml|nopmml" => sub { removeMathFormat($opts,'pmml'); },
	   "nocontentmathml|nocmml"      => sub { removeMathFormat($opts,'cmml'); },
	   "noopenmath|noom"             => sub { removeMathFormat($opts,'om'); },
	   "nokeepXMath|noxmath"         => sub { removeMathFormat($opts,'xmath'); },
	   "parallelmath"               => sub { $opts->{parallelmath} = 1;},
	   "stylesheet=s"=>  sub {$opts->{stylesheet} = $_[1];},
           "styleparam=s" => sub {my ($k,$v) = split(':',$_[1]);
                                  $opts->{styleparam}->{$k}=$v;},
	   "css=s"       =>  sub {$opts->{css}=$_[1];},
	   "defaultcss" =>  sub {$opts->{defaultcss} = 1;},
	   "nodefaultcss" =>  sub {$opts->{defaultcss} = 0;},
	   "comments" =>  sub { $opts->{comments} = 1; },
	   "nocomments"=> sub { $opts->{comments} = 0; },
	   "VERSION"   => sub { $opts->{showversion}=1;},
	   "debug=s"   => sub { eval "\$LaTeXML::$_[1]::DEBUG=1; "; },
           "documentid=s" => sub { $opts->{documentid} = $_[1];},
	   "plane1!"                     => \$opts->{plane1},
	   "hackplane1!"                 => \$opts->{hackplane1},
	   "svg"       => \$opts->{svg},
	   "help"      => sub { $opts->{help} = 1; } ,
	  ) or pod2usage(-message => $opts->{identity}, -exitval=>1, -verbose=>99, -sections => ['EXECUTABLES'],
                         -input => pod_where({-inc => 1}, __PACKAGE__), -output=>\*STDERR);

  pod2usage(-message=>$opts->{identity}, -exitval=>1, -verbose=>99, -sections => ['OPTIONS/OVERVIEW'],
            -input => pod_where({-inc => 1}, __PACKAGE__), -output=>\*STDOUT) if $opts->{help};
  if (!$opts->{local} && ($opts->{destination} || $opts->{log} || $opts->{postdest} || $opts->{postlog})) 
    {carp "I/O from filesystem not allowed without --local!\n".
       " Will revert to sockets!\n";
     undef $opts->{destination}; undef $opts->{log};
     undef $opts->{postdest}; undef $opts->{postlog};}
  
  # Check that destination is valid before wasting any time...
  if($opts->{destination}){
    $opts->{destination} = pathname_canonical($opts->{destination});
    if(my $dir =pathname_directory($opts->{destination})){
      pathname_mkdir($dir) or croak "Couldn't create destination directory $dir: $!"; }}
  
  # HOWEVER, any post switch implies post:
  $opts->{math_formats} = [] if ((defined $opts->{post}) && ($opts->{post} == 0));
  $opts->{post}=1 if (@{$opts->{math_formats}});
  # Removed math formats are irrelevant for conversion:
  delete $opts->{removed_math_formats};

  if($opts->{showversion}){ print STDERR $opts->{identity}."\n"; exit(1); }

  $opts->{source} = $ARGV[0] unless $opts->{source};
  return;
}

sub addMathFormat {
  my($opts,$fmt)=@_;
  push(@{$opts->{math_formats}},$fmt) 
    unless grep($_ eq $fmt,@{$opts->{math_formats}}) || $opts->{removed_math_formats}->{$fmt}; }
sub removeMathFormat {
  my($opts,$fmt)=@_;
  @{$opts->{math_formats}} = grep($_ ne $fmt, @{$opts->{math_formats}});
  $opts->{removed_math_formats}->{$fmt}=1; }



1;

__END__

=pod

=head1 NAME

C<LaTeXML::Extras> - Extra goodies supporting LaTeXML's processing

=head1 SYNOPSIS

    my $full_tex_doc = MathDoc($math_snippet);
    my $mathml_math_snippet = GetMath($xhtml_doc);
    my $body_div_snippet = GetEmbeddable($xhtml_doc);
    my $xhtml_doc_with_ids = InsertIDs($xhtml_doc);

=head1 DESCRIPTION

This class contains all additional functionality that does not fit into the core LaTeXML processing 
     and is too specific or minor to have its own LaTeXML::Util class.

=head2 METHODS

=over 4

=item C<< my $full_tex_doc = MathDoc($math_snippet); >>

Given an expression in TeX's math mode, this routine constructs a LaTeX
       document fragment containing the formula.
       (= no preamble or document class, useful for fragment mode daemonized processing)

=item C<< my $mathml_math_snippet = GetMath($xhtml_doc); >>

Extracts the first MathML math XML snippet in an XHTML document, provided as a
    LaTeXML::Document object.

=item C<< my $body_div_snippet = GetEmbeddable($xhtml_doc); >>

Extracts the body <div> element of an XHTML document produced by LaTeXML's stylesheet for XHTML, 
    provided as a LaTeXML::Document object.

=item C<< my $xhtml_doc_with_ids = InsertIDs($xhtml_doc); >>

Inserts pseudo-random identifiers in any XHTML document, provided as a
    LaTeXML::Document object on input.

Uses XSLT's "generate-id()" mechanism.

=item C<< my $bool = Compare($a, $b); >>

Compares to hashrefs $a and $b, assuming they represent LaTeXML Options objects.
    Returns true if they are identical, False if different.

=back

=head1 OPTIONS

=head2 OVERVIEW

latexmls/latexmlc [options]

 Options:
 --destination=file specifies destination file, requires --local.
 --output=file      [obsolete synonym for --destination]
 --postdest=file    specifies destination file for postprocessing,
                    requires --local, --post
 --preload=module   requests loading of an optional module;
                    can be repeated
 --includestyles    allows latexml to load raw *.sty file;
                    by default it avoids this.
 --preamble=file    loads a tex file containing document frontmatter.
                    Useful for fragment profile.
 --base=dir         Specifies the base directory that the server
                    operates in. Useful when converting documents 
                    that employ relative paths.
 --path=dir         adds dir to the paths searched for files,
                    modules, etc; 
 --log=file         specifies log file, reuqires --local
                    default: STDERR
 --postlog=file     specifies log file for postprocessing, 
                    requires --local, --post 
                    default is appending to the --log file.
 --summary          print a one line summary message of 
                    the conversion outcome
 --autoflush=count  Automatically restart the daemon after 
                    "count" inputs. Good practice for vast batch 
                    jobs. (default: 10000)
 --timeout=secs     Set a timeout value for inactivity.
                    Default is 60 seconds, set 0 to disable.
 --port=number      Specify server port (default: 3334 for math, 
                    3344 for fragment and 3354 for standard)
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
 --profile=name     specify profile as defined in LaTeXML::Util::Startup
                    Supported: standard|math|fragment|...
                    (default: standard)
 --mode=name        Alias for profile
 --post             requests a followup post-processing
 --embed            requests an embeddable XHTML snippet
                    (requires: --post,--profile=fragment)
 --stylesheet       specifies a stylesheet,
                    to be used by the post-processor.
 --css=cssfile           adds a css stylesheet to html/xhtml
                         (can be repeated)
 --nodefaultcss          disables the default css stylesheet
 --pmml             converts math to Presentation MathML
                    (default for xhtml format)
 --cmml             converts math to Content MathML
 --openmath         converts math to OpenMath 
 --parallelmath     requests parallel math markup for MathML
                    (off by default)
 --keepTeX          keeps the TeX source of a formula as a MathML
                    annotation element (requires --parallelmath)
 --keepXMath        keeps the XMath of a formula as a MathML
                    annotation-xml element (requires --parallelmath)
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

Each communication session allows local option overwriting on the first sent line.
The input will be read until a line containing "END OF REQUEST" is found. Please
take this into account to avoid hanging.

=head2 DETAILS

=over 4

=item C<--destination>=I<file>

Requires: C<--local>

Specifies the destination file; by default the XML is written to STDOUT.
The Daemon allows using the #name, #dir and #ext patterns as variables for
the base of the source filename, the source directory and the source file extension.

Example: C<--destination>=I<#dir/#name.xml>

=item C<--postdest>=I<file>

Requires: C<--local>, C<--post>

Behaves like C<--destination>, for the post-processing target. C<#dir>,C<#name>,C<#ext> patterns can be used.

If omitted and C<--destination> is not provided, but C<--post> is specified, 
the output will be returned via the socket. If C<--destination> is present, 
but C<--postdest> is omitted, the default will substitute the extension 
from C<.tex.xml> or C<.xml> to C<.xhtml>. If the C<--destination> extension is different, 
C<.xhtml> will be simply appended.

Note that for output formats different from .xhtml one should always specify
the C<--postdest> option.

=item C<--preload>=I<module>

Requests the loading of an optional module or package.  This may be useful if the TeX code
does not specificly require the module (eg. through input or usepackage).
For example, use C<--preload=LaTeX.pool> to force LaTeX mode.

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
The Daemon allows using the C<#name>, C<#dir> and C<#ext> patterns as variables for
the base of the source filename, the source directory and the source file extension.
An example would be: C<--log=#dir/#name.log>

=item C<--postlog>=I<file>

Requires: C<--local>, C<--post>

Behaves like C<--log>, but reports on the status of the post-processing exclusively.
The C<#name>,C<#dir> and C<#ext> patterns can be used.
Default is merging this log at the original C<--log> target

=item C<--summary>

Return a one line summary message of the conversion outcome. The message is always sent back
via the socket, strictly after any other return values possible.

=item C<--autoflush>=I<count>

Automatically restart the daemon after converting "count" inputs.
Good practice for vast batch jobs. (default: 10000)

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

Requests TeX output for debugging purposes;  processing is only carried out through expansion and digestion.
This may not be quite valid TeX, since Unicode may be introduced.

=item C<--box>

Requests Box output for debugging purposes;  processing is carried out through expansion and digestions,
and the result is printed.

=item C<--profile>

fragment: Parses frontmatter and \begin{document}...\end{document} fragments.
          Assumes that the documentclass is fixed (if any), which achieves a big speedup,
          since no state reinitialization is necessary. Use the C<--preload> switch
          to load the document class when invoking the daemon.
          Example: C<latexmls --preload=LaTeX.pool --preload=article.cls --profile=fragment>

standard: Default, turns on the classic, unoptimized processing of documents as performed by latexml.
          This is suitable for processing sets of heterogeneous documents, but is slower in general.
          Example: C<latexmls --profile=standard>

math:     Like latexmlmath, parses a single TeX formula per line.
          Example: C<latexmls --profile=math --pmml --keepTeX --parallelmath>

=item C<--post>

Request post-processing of converted XML to XHTML. Default behaviour is
creating XHTML output with Presentational MathML.

=item C<--embed>

Requests an embeddable XHTML div (requires: --post, --profile=fragment), respectively the
top division of the document's body.
Caveat: This experimental mode is enabled only for fragment profile and post-processed
documents (to XHTML). Also, this option can not be used if an explicit --destination
or --postdest are provided.

=item C<--pmml>

Requests conversion of math to Presentation MathML.
Conversion is the default for xhtml format.

=item C<--cmml>

Requests or disables conversion of math to Content MathML.
Conversion is disabled by default.
B<Note> that this conversion is only partially implemented.

=item C<--openmath>

Requests or disables conversion of math to OpenMath.
Conversion is disabled by default.
B<Note> that this conversion is not yet supported in C<latexmls>.

=item C<--keepTeX>

By default, when any of the MathML or OpenMath conversions
are used, the source TeX formula will be removed;
This option preserves it as a MathML annotation in parallel markup.
B<Note> that C<--parallelmath> and C<--pmml> or C<--cmml> are required.

=item C<--keepXMath>

By default, when any of the MathML or OpenMath conversions
are used, the intermediate math representation will be removed;
This option preserves it as a MathML annotation in parallel markup.
B<Note> that C<--parallelmath> and C<--pmml> or C<--cmml> are required.

=item C<--parallelmath>

Requests or disables parallel math markup.
Parallel markup is the default for xhtml formats when multiple math
formats are requested.

This method uses the MathML C<semantics> element with additional formats
appearing as C<annotation>'s.
The first math format requested must be either Presentation or Content MathML;
additional formats may be MathML or OpenMath.

If this option is disabled and multiple formats are requested, the
representations are simply stored as separate children of the C<Math> element.


=item C<--stylesheet>=I<file>

Sets a stylesheet of choice to be used by the postprocessor. Requires C<--post>

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

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
