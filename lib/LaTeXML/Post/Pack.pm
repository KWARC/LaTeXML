# /=====================================================================\ #
# |  LaTeXML::Post::Pack                                                | #
# | Packs the requested output (document, fragment, math, archive)      | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
package LaTeXML::Post::Pack;
use strict;
use warnings;
use LaTeXML::Post;
use base qw(LaTeXML::Post::Processor);

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use IO::String;

# Options:
#   whatsout: determine what shape and size we want to pack into
#             admissible: document (default), fragment, math, archive
#   siteDirectory: the directory to compress into a ZIP archive
sub new {
  my($class,%options)=@_;
  my $self = $class->SUPER::new(%options);
  $$self{siteDirectory}  = $options{siteDirectory};
  $$self{whatsout} = $options{whatsout};
  $self; }

sub process {
  my($self,$doc,$root)=@_;
  return unless defined $doc;
  my $whatsout = $self->{whatsout};
  if ((! $whatsout) || ($whatsout eq 'document')) {} # Document is no-op
  elsif ($whatsout eq 'fragment') {
    # If we want an embedable snippet, unwrap to body's "main" div
    $doc = GetEmbeddable($doc); }
  elsif ($whatsout eq 'math') {
    # Math output - least common ancestor of all math in the document
    $doc = GetMath($doc); }
  elsif (($whatsout eq 'archive') || ($whatsout eq 'zip')) {
    my $directory = $self->{siteDirectory};
    $doc = GetArchive($directory);
    Fatal("I/O",$self,$doc,"Writing archive to IO::String handle failed") unless defined $doc; 
  }
  return $doc;
}

sub GetArchive {
  my ($self,$directory) = @_;
  # Zip and send back
  my $archive = Archive::Zip->new();
  my $payload='';
  $archive->addTree($directory);
  my $content_handle = IO::String->new($payload);
  undef $payload unless ($archive->writeToFileHandle( $content_handle ) == AZ_OK);
  return $payload;  
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
    $math = $math->parentNode while ($math->nodeName =~ '^t[rd]$');
    $math;
  } elsif ($math_count == 0) {
    GetEmbeddable($source);
  } else {
    $math;
  }
}

sub GetEmbeddable {
  my ($doc) = @_;
  return unless defined $doc;
  my ($embeddable) = $doc->findnodes('//*[@class="ltx_document"]');
  if ($embeddable) {
    # Only one child? Then get it, must be a inline-compatible one!
    while (($embeddable->nodeName eq 'div') && (scalar(@{$embeddable->childNodes}) == 1) &&
     ($embeddable->getAttribute('class') =~ /^ltx_(page_(main|content)|document|para|header)$/) && 
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

