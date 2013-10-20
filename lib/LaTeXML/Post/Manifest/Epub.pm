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

our $container_content = <<'EOL';
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
EOL

sub process {
  my($self,$doc,$root)=@_;
  return $doc if $self->{finished};
  # Run a single time, even if there are multiple document fragments
  $self->{finished} = 1;

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
  my $OEBPS_dir = catdir($directory,'OEBPS');
  # 3.1 OEBPS/content.opf XML Spine
  my $opf = XML::LibXML::Document->new( '1.0', 'UTF-8' );
  my $package = $opf->createElementNS( "http://www.idpf.org/2007/opf", 'package' );
  $opf->setDocumentElement($package);
  my $metadata = $package->addNewChild(undef,'metadata');
  my $manifest = $package->addNewChild(undef,'manifest');
  my $spine = $package->addNewChild(undef,'spine');
  $spine->setAttribute('toc','ncx');
  my $OEBPS_text = catdir($OEBPS_dir,'Text');
  opendir(my $textdir_fh, $OEBPS_text);
  my @text_files = grep {/\.xhtml$/} readdir($textdir_fh);
  foreach my $text_file(@text_files) {
    # TODO: Add in narrative order
    my $itemref = $spine->addNewChild(undef,'itemref');
    $itemref->setAttribute('idref',$text_file);
  }

  open my $opf_fh, ">", pathname_concat($OEBPS_dir,'content.opf');
  print $opf_fh $opf->toString(1);
  close $opf_fh;

  # 3.2 OEBPS/toc.ncx XML ToC
  # 3.3 OEBPS/Text - XHTML files
  # 3.4. Images??? Others?
  return $doc;
}

1;