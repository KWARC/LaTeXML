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

use Data::Dumper;

use XML::LibXSLT;
use XML::LibXML;
use LaTeXML::Util::Pathname;
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
  $tex = '$ '.$tex.' $'; }

my $texdoc = <<"EODOC";
\\begin{document}
$tex
\\end{document}
EODOC
return $texdoc;
}

sub GetMath {
  my ($source) = @_;
  my $math_xpath = '//*[local-name()="math" or local-name()="Math"]';
  return unless defined $source;
  my @mnodes = $source->findnodes($math_xpath);
  my $math_count = scalar(@mnodes);
  my $math = $mnodes[0] if $math_count;
  if ($math_count > 1) {
    my $math_found = 0;
    while ($math_found != $math_count) {
      $math_found = $math->findnodes('.'.$math_xpath)->size;
      $math_found++ if ($math->localname =~ /^math$/i);
      $math = $math->parentNode if ($math_found != $math_count);
    }
  }
  return $math;
}

sub GetEmbeddable {
  my ($doc) = @_;
  return unless defined $doc;
  my ($embeddable) = $doc->findnodes('//*[@class="document"]');
  if ($embeddable) {
    # Only one child? Then get it, must be a inline-compatible one!
    while (($embeddable->nodeName eq 'div') && (scalar(@{$embeddable->childNodes}) == 1) &&
	   ($embeddable->getAttribute('class') =~ /^main|content|document|para$/) && 
	   (! defined $embeddable->getAttribute('style'))) {
      if (defined $embeddable->firstChild) {
	$embeddable=$embeddable->firstChild;
      } else {
	last;
      }
    }
    # Is the root a <p>? Make it a span then, if it has only math/text/spans - it should be inline
    # For MathJax-like inline conversion mode
    # TODO: Make sure we are schema-complete wrt nestable inline elements, and maybe find a smarter way to do this?
    if (($embeddable->nodeName eq 'p') &&
	((@{$embeddable->childNodes}) == (grep {$_->nodeName =~ /math|text|span/} $embeddable->childNodes))) {
      $embeddable->setNodeName('span');
      $embeddable->setAttribute('class','text');
    }

    # Copy over document namespace declarations:
    foreach ($doc->getDocumentElement->getNamespaces) {
      $embeddable->setNamespace( $_->getData , $_->getLocalName, 0 );
    }
    # Also, copy the prefix attribute, for RDFa:
    my $prefix = $doc->getDocumentElement->getAttribute('prefix');
    $embeddable->setAttribute('prefix',$prefix) if ($prefix);
  }
  return $embeddable||$doc;
}

1;

__END__

=pod

=head1 NAME

C<LaTeXML::Extras> - Extra goodies supporting LaTeXML's processing

=head1 SYNOPSIS

    my $full_tex_doc = MathDoc($math_snippet);
    my $mathml_math_snippet = GetMath($xhtml_doc);
    my $body_div_snippet = GetEmbeddable($xhtml_doc);

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

=back

=head1 AUTHOR

Bruce Miller <bruce.miller@nist.gov>
Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
