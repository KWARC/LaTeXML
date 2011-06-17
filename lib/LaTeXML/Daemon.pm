# /=====================================================================\ #
# |  LaTeXML::Daemon                                                    | #
# | Extends the LaTeXML object with daemon methods                      | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <d.ginev@jacobs-university.de>                  #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Daemon;
use strict;
use LaTeXML::Global;
use LaTeXML::Error;
use LaTeXML::State;
use LaTeXML::Stomach;
use LaTeXML::Document;
use LaTeXML::Model;
use LaTeXML::Object;
use LaTeXML::MathParser;
use LaTeXML::Util::Pathname;
use LaTeXML::Bib;
use LWP;
use LWP::Simple;
use Encode;
our @ISA = (qw(LaTeXML));

#**********************************************************************



__END__

=pod 

=head1 NAME

C<LaTeXML::Daemon> - Daemonized digestion routines for the C<LaTeXML> class.

=head1 SYNOPSIS

    use LaTeXML::Daemon;
    my $daemon = LaTeXML::Daemon->new(%options);
    my ($result,$errors,$status) = $daemon->convert($tex);

Also see the utility daemon servers C<latexmls> and C<latexmld>, 
which utilize this module.

=head1 DESCRIPTION

The C<LaTeXML::Daemon> class inherits from the main C<LaTeXML> class, 
adding four daemonized digestion routines, essentially skipping the 
initialization steps of the different C<LaTeXML::State> objects.

=head2 METHODS

=over 4

=item C<< $box = $latexml->digestBibTeXFileDaemonized($bibfile,$mode); >>

Digests a BibTeX file, skipping the initialization steps 
of C<LaTeXML::digestBibTeXFile>
Warning: Untested!

=item C<< $box = $latexml->digestFileDaemonized($file,$mode); >>

Digests a file, skipping the initialization steps 
of C<LaTeXML::digestFile>
Adds {document} wrapper in fragment mode.

=item C<< $box = $latexml->digestStringDaemonized($string,$mode); >>

Digests a string, skipping the initialization steps 
of C<LaTeXML::digestString>
Adds {document} wrapper in fragment mode.

=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
