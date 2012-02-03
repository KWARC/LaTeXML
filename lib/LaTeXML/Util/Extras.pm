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
  my ($ret,$args) = GetOptions(
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
	   "keepXMath|xmath"             => sub { addMathFormat($opts,'XMath'); },
	   "nopresentationmathml|nopmml" => sub { removeMathFormat($opts,'pmml'); },
	   "nocontentmathml|nocmml"      => sub { removeMathFormat($opts,'cmml'); },
	   "noopenmath|noom"             => sub { removeMathFormat($opts,'om'); },
	   "nokeepXMath|noxmath"         => sub { removeMathFormat($opts,'XMath'); },
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
	  ) or pod2usage(-message => $opts->{identity}, -exitval=>1, -verbose=>0, -output=>\*STDERR);

  pod2usage(-message=>$opts->{identity}, -exitval=>1, -verbose=>2, -output=>\*STDOUT) if $opts->{help};

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

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
