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

our $container_content = <<'EOL';
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
EOL

sub new {
  my($class,%options)=@_;
  my $self = $class->SUPER::new(%options);
  $self->initialize;
  return $self; }

sub initialize {
  my ($self) = @_;
  my $directory = $self->{siteDirectory};

  # 1. Create mimetype declaration
  open my $epub_fh, ">", pathname_concat($directory,'mimetype');
  print $epub_fh 'application/epub+zip';
  close $epub_fh;
  # 2. Create META-INF metadata directory
  my $meta_inf_dir = catdir($directory,'META-INF');
  mkdir $meta_inf_dir;
  # 2.1. Add the container.xml description
  open my $container_fh, ">". pathname_concat($meta_inf_dir,'container.xml');
  print $container_fh $container_content;
  close $container_fh;

  # 3. Create OEBPS content container
  my $OEBPS_directory = catdir($directory,'OEBPS');
  # 3.1 OEBPS/content.opf XML Spine
  my $opf = XML::LibXML::Document->new( '1.0', 'UTF-8' );
  my $package = $opf->createElementNS( "http://www.idpf.org/2007/opf", 'package' );  
  $opf->setDocumentElement($package);
  $package->setAttribute('unique-identifier','BookID');
  $package->setAttribute('version','2.0');
  # Metadata
  my $metadata = $package->addNewChild(undef,'metadata');
  $metadata->setNamespace("http://purl.org/dc/elements/1.1/","dc",0);
  $metadata->setNamespace("http://www.idpf.org/2007/opf",'opf',0);
  my $identifier = $metadata->addNewChild("http://purl.org/dc/elements/1.1/","identifier");
  $identifier->setAttribute('id','BookID');
  $identifier->setAttribute('opf:scheme','UUID');
  $identifier->appendText(create_uuid_as_string());
  # Manifest
  my $manifest = $package->addNewChild(undef,'manifest');
  my $ncx_item = $manifest->addNewChild(undef,'item');
  $ncx_item->setAttribute('id','ncx');
  $ncx_item->setAttribute('href','toc.ncx');
  $ncx_item->setAttribute('media-type','application/x-dtbncx+xml');
  #TODO: Index all CSS files (written already)
  # <item id="stylesheet.css" href="Styles/stylesheet.css" media-type="text/css"/>
  # Spine
  my $spine = $package->addNewChild(undef,'spine');
  $spine->setAttribute('toc','ncx');
  my $OEBPS_text = catdir($OEBPS_directory,'Text');

  # 3.2 OEBPS/toc.ncx XML ToC
  # 3.3 OEBPS/Text - XHTML files
# 3.4. Images??? Others?

  $self->{OEBPS_directory} = $OEBPS_directory;
  $self->{opf} = $opf;
  $self->{opf_spine} = $spine;
  $self->{opf_manifest} = $manifest;
  return; }

sub process {
  my($self,$doc,$root)=@_;
  # Add each document to the spine manifest
  if(my $destination = $doc->getDestination) {
    my (undef,$name,$ext) = pathname_split($destination);
    my $file = "$name.$ext";
    my $relative_destination = pathname_relative($destination,$self->{OEBPS_directory});

    my $manifest = $self->{opf_manifest};
    my $item = $manifest->addNewChild(undef,'item');
    $item->setAttribute('id',$file);
    $item->setAttribute('href',$relative_destination);
    $item->setAttribute('media-type',"application/xhtml+xml");
    my $spine = $self->{opf_spine};
    my $itemref = $spine->addNewChild(undef,'itemref');
    $itemref->setAttribute('idref',$file); }

  return $doc; }

sub finalize {
  my ($self) = @_;
  # Write the .opf file to disk
  my $directory = $self->{siteDirectory};
  my $OEBPS_dir = catdir($directory,'OEBPS');
  open my $opf_fh, ">", pathname_concat($OEBPS_dir,'content.opf');
  print $opf_fh $self->{opf}->toString(1);
  close $opf_fh; 
  return (); }

1;