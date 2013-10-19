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

use LaTeXML::Post::Writer;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use IO::String;

use Data::Dumper;

# Options:
#   whatsout: determine what shape and size we want to pack into
#             admissible: document (default), fragment, math, archive
#   siteDirectory: the directory to compress into a ZIP archive
sub new {
  my($class,%options)=@_;
  my $self = $class->SUPER::new(%options);
  $$self{siteDirectory}  = $options{siteDirectory};
  $$self{whatsout} = $options{whatsout};
  $$self{format} = $options{format};
  $$self{writer} =  LaTeXML::Post::Writer->new(%options);
  $$self{finished} = 0;
  $self; }

sub process {
  my($self,$doc,$root)=@_;
  return unless defined $doc;
  return $doc if $self->{finished};
  # Run a single time, even if there are multiple document fragments
  $self->{finished} = 1;
  
  my $whatsout = $self->{whatsout};
  if ((! $whatsout) || ($whatsout eq 'document')) {} # Document is no-op
  elsif ($whatsout eq 'fragment') {
    # If we want an embedable snippet, unwrap to body's "main" div
    $doc = GetEmbeddable($doc); }
  elsif ($whatsout eq 'math') {
    # Math output - least common ancestor of all math in the document
    $doc = GetMath($doc); }
  elsif ($whatsout eq 'archive') {
    # First, write down the $doc, make sure it has a nice extension if .zip requested
    my $destination = $doc->getDestination;
    if ($destination =~ /^(.+)\.(zip|epub|mobi)$/) {
      my $ext = _format_to_extension($self->{format});
      $doc->setDestination("$1.$ext"); }
    $self->{writer}->process($doc,$root);
    # Then archive the site directory
    my $directory = $self->{siteDirectory};
    $doc = GetArchive($directory);
    # Should we empty the site directory???
    Fatal("I/O",$self,$doc,"Writing archive to IO::String handle failed") unless defined $doc; 
  }
  return $doc; }

sub GetArchive {
  my ($directory) = @_;
  # Zip and send back
  my $archive = Archive::Zip->new();
  my $payload='';
  $archive->addTree($directory,'',sub{/^[^.]/ && (!/zip|gz|epub|tex|mobi|~$/)});
  my $content_handle = IO::String->new($payload);
  undef $payload unless ($archive->writeToFileHandle( $content_handle ) == AZ_OK);
  return $payload; }

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
    $math; }
  elsif ($math_count == 0) {
    GetEmbeddable($source); }
  else {
    $math; }}

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
        $embeddable=$embeddable->firstChild; }
      else {
        last; }
    }
    # Is the root a <p>? Make it a span then, if it has only math/text/spans - it should be inline
    # For MathJax-like inline conversion mode
    # TODO: Make sure we are schema-complete wrt nestable inline elements, and maybe find a smarter way to do this?
    if (($embeddable->nodeName eq 'p') && ((@{$embeddable->childNodes}) == (grep {$_->nodeName =~ /math|text|span/} $embeddable->childNodes))) {
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
  return $embeddable||$doc; }

sub _format_to_extension {
  my $format = shift;
  my $extension = lc($format);
  $extension =~ s/\d//g;
  $extension =~ s/^epub|mobi$/xhtml/;
  return $extension; }

1;

