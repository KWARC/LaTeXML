# /=====================================================================\ #
# |  LaTeXML::Post::Manifest                                            | #
# | Manifest creation for EPUB                                          | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
package LaTeXML::Post::Manifest::Epub;
use strict;
use warnings;

use base qw(LaTeXML::Post::Manifest);
use LaTeXML::Util::Pathname;
use File::Spec::Functions qw(catdir);
use UUID::Tiny ':std';
use POSIX qw(strftime);

our $container_content = <<'EOL';
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
EOL

sub new {
  my ($class, %options) = @_;
  my $self = $class->SUPER::new(%options);
  return $self; }

use Data::Dumper;
sub initialize {
  my ($self,$doc) = @_;
  my $directory = $self->{siteDirectory};
  # TODO: Fish out any existing unique identifier for the book
  #       the UUID is the fallback default
  $self->{'unique-identifier'} = create_uuid_as_string();
  # 1. Create mimetype declaration
  open my $epub_fh, ">", pathname_concat($directory, 'mimetype');
  print $epub_fh 'application/epub+zip';
  close $epub_fh;
  # 2. Create META-INF metadata directory
  my $meta_inf_dir = catdir($directory, 'META-INF');
  mkdir $meta_inf_dir;
  # 2.1. Add the container.xml description
  open my $container_fh, ">" . pathname_concat($meta_inf_dir, 'container.xml');
  print $container_fh $container_content;
  close $container_fh;

  # 3. Create OPS content container
  my $OPS_directory = catdir($directory, 'OPS');
  # 3.1 OPS/content.opf XML Spine
  my $opf = XML::LibXML::Document->new('1.0', 'UTF-8');
  my $package = $opf->createElementNS("http://www.idpf.org/2007/opf", 'package');
  $opf->setDocumentElement($package);
  $package->setAttribute('unique-identifier', 'pub-id');
  $package->setAttribute('version',           '3.0');

  # Metadata
  my $document_metadata = $self->{db}->lookup("ID:".$self->{db}->{document_id});
  my $document_title = $document_metadata->getValue('title');
  $document_title = $document_title->textContent if $document_title;
  my $document_authors = $document_metadata->getValue('authors')||[];
  $document_authors = [ map {$_->textContent} @$document_authors ];
  my $document_language = $document_metadata->getValue('language') || 'en';

  my $metadata = $package->addNewChild(undef, 'metadata');
  $metadata->setNamespace("http://purl.org/dc/elements/1.1/", "dc",  0);
  $metadata->setNamespace("http://www.idpf.org/2007/opf",     'opf', 0);
  my $title = $metadata->addNewChild("http://purl.org/dc/elements/1.1/", "title");
  $title->appendText($document_title);
  foreach my $document_author (@$document_authors) {
    my $author = $metadata->addNewChild("http://purl.org/dc/elements/1.1/", "creator");
    $author->appendText($document_author); }
  my $language = $metadata->addNewChild("http://purl.org/dc/elements/1.1/", "language");
  $language->appendText($document_language);
  my $modified = $metadata->addNewChild(undef, "meta");
  $modified->setAttribute('property','dcterms:modified');
  my $now_string = strftime "%Y-%m-%dT%H:%M:%SZ", localtime; # CCYY-MM-DDThh:mm:ssZ
  $modified->appendText($now_string);
  my $identifier = $metadata->addNewChild("http://purl.org/dc/elements/1.1/", "identifier");
  $identifier->setAttribute('id',         'pub-id');
  $identifier->appendText($self->{'unique-identifier'});
  # Manifest
  my $manifest = $package->addNewChild(undef, 'manifest');
  my $nav_item = $manifest->addNewChild(undef, 'item');
  $nav_item->setAttribute('id',         'nav');
  $nav_item->setAttribute('href',       'nav.xhtml');
  $nav_item->setAttribute('properties',       'nav');
  $nav_item->setAttribute('media-type', 'application/xhtml+xml');
  # Spine
  my $spine = $package->addNewChild(undef, 'spine');
  # 3.2 OPS/nav.xhtml
  my $nav = XML::LibXML::Document->new('1.0', 'UTF-8');
  my $nav_html = $opf->createElementNS("http://www.w3.org/1999/xhtml", 'html');
  $nav->setDocumentElement($nav_html);
  $nav_html->setNamespace("http://www.idpf.org/2007/ops", "epub",  0);
  my $nav_head = $nav_html->addNewChild(undef,'head');
  my $nav_title = $nav_head->addNewChild(undef,'title');
  $nav_title->appendText($document_title);
  my $nav_body = $nav_html->addNewChild(undef,'body');
  my $nav_nav = $nav_body->addNewChild(undef,'nav');
  $nav_nav->setAttribute('epub:type','toc');
  $nav_nav->setAttribute('id','toc');
  my $nav_map = $nav_nav->addNewChild(undef,'ol');

  $self->{OPS_directory} = $OPS_directory;
  $self->{opf}           = $opf;
  $self->{opf_spine}     = $spine;
  $self->{opf_manifest}  = $manifest;
  $self->{nav}           = $nav;
  $self->{nav_map} = $nav_map;
  return; }

sub process {
  my ($self, @docs) = @_;
  $self->initialize($docs[0]);
  foreach my $doc (@docs) {
    # Add each document to the spine manifest
    if (my $destination = $doc->getDestination) {
      my (undef, $name, $ext) = pathname_split($destination);
      my $file = "$name.$ext";
      my $relative_destination = pathname_relative($destination, $self->{OPS_directory});

      # Add to manifest
      my $manifest = $self->{opf_manifest};
      my $item = $manifest->addNewChild(undef, 'item');
      $item->setAttribute('id',         $file);
      $item->setAttribute('href',       $relative_destination);
      $item->setAttribute('media-type', "application/xhtml+xml");
      # Add to spine
      my $spine = $self->{opf_spine};
      my $itemref = $spine->addNewChild(undef, 'itemref');
      $itemref->setAttribute('idref', $file);

      # Add to navigation
      my $nav_map = $self->{nav_map};
      my $nav_li = $nav_map->addNewChild(undef,'li');
      my $nav_a = $nav_li->addNewChild(undef,'a');
      $nav_a->setAttribute('href',$file);
      $nav_a->appendText($file); } }
  $self->finalize;
}

sub finalize {
  my ($self) = @_;
  #Index all CSS files (written already)
  my $OPS_directory = $self->{OPS_directory};
  opendir(my $ops_handle, $OPS_directory);
  my @files = readdir($ops_handle);
  closedir $ops_handle;
  my @styles = grep { /\.css$/ && -f pathname_concat($OPS_directory, $_) } @files;
  my @images = grep { /\.png$/ && -f pathname_concat($OPS_directory, $_) } @files;
  my $manifest = $self->{opf_manifest};
  # TODO: Other externals are future work
  foreach my $style (@styles) {
    my $style_item = $manifest->addNewChild(undef, 'item');
    $style_item->setAttribute('id',         $style);
    $style_item->setAttribute('href',       "./$style");
    $style_item->setAttribute('media-type', 'text/css'); }
  foreach my $image (@images) {
    my $image_item = $manifest->addNewChild(undef, 'item');
    $image_item->setAttribute('id',         $image);
    $image_item->setAttribute('href',       "./$image");
    $image_item->setAttribute('media-type', 'image/png'); }

  # Write the content.opf file to disk
  my $directory = $self->{siteDirectory};
  open my $opf_fh, ">", pathname_concat($OPS_directory, 'content.opf');
  print $opf_fh $self->{opf}->toString(1);
  close $opf_fh;

  # Write toc.ncx file to disk
  open my $nav_fh, ">", pathname_concat($OPS_directory, 'nav.xhtml');
  print $nav_fh $self->{nav}->toString(1);
  close $nav_fh;

  return (); }

1;
