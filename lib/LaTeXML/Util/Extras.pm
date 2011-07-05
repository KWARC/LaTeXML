################ LaTeXML Extras and Goodies #####################

package LaTeXML::Util::Extras;
use XML::LibXSLT;
use XML::LibXML;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( &MathDoc &GetMath &GetEmbeddable &InsertIDs);

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
  my $bodyel = $postdoc->findnode('//*[local-name()="body"]');
  return unless $bodyel;
  my $topdiv;
  # Doing monkey hoops is very annoying, why won't LibXML
  # just fix their XPath support already?!
  foreach ($bodyel->childNodes) {
    $topdiv=$_;
    last if ($topdiv->nodeName eq 'div');
  }
  my $contentdiv;
  foreach ($topdiv->childNodes) {
    $contentdiv=$_;
    last if ($contentdiv->nodeName eq 'div');
  }
  my $maindiv;
  foreach ($contentdiv->childNodes) {
    $maindiv=$_;
    last if ($maindiv->nodeName eq 'div');
  }
  # Assign the top division to the post-document holder
  # Copy over all <html> attributes to the maindiv, so that we keep namespaces:
  my $htmlel = $postdoc->findnode('//*[local-name()="html"]');
  $htmlel->unbindNode;
  $htmlel->removeChildNodes;
  $htmlel->setNodeName('div');
  $htmlel->setAttribute('class','document');
  $maindiv->unbindNode;
  foreach ($maindiv->childNodes) {
    $_->unbindNode;
    $htmlel->addChild($_);
  }
  return $htmlel;
}

our $id_xslt_dom = XML::LibXML->load_xml(no_blanks=>1, string => <<'EOT');
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
      <xsl:if test="not(@id)">
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
  return LaTeXML::Post::Document->new($id_xslt->transform(shift->getDocument));
}

1;

__END__

=pod

=head1 NAME

C<LaTeXML::Extra> - Extra goodies supporting LaTeXML's processing

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<< foo >>

bar

=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
