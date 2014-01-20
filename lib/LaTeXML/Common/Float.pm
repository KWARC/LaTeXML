# /=====================================================================\ #
# |  LaTeXML::Common::Float                                             | #
# | Representation of floating point objects                            | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
package LaTeXML::Common::Float;
use LaTeXML::Global;
use strict;
use warnings;
use base qw(LaTeXML::Common::Number);

# Strictly speaking, Float isn't part of TeX, but it's handy.

sub toString {
  my ($self) = @_;
  return floatformat($$self[0]); }

sub multiply {
  my ($self, $other) = @_;
  return (ref $self)->new($self->valueOf * (ref $other ? $other->valueOf : $other)); }

sub stringify {
  my ($self) = @_;
  return "Float[" . $$self[0] . "]"; }

# Utility for formatting sane numbers.
sub floatformat {
  my ($n) = @_;
  my $s = sprintf("%.5f", $n);
  $s =~ s/0+$// if $s =~ /\./;
  #  $s =~ s/\.$//;
  $s =~ s/\.$/.0/;    # Seems TeX prints .0 which in odd corner cases, people use?
  return $s; }

#======================================================================
1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Common::Float> - representation of floating point numbers

=head1 DESCRIPTION

represents floating-point numbers,

=head1 AUTHOR

Bruce Miller <bruce.miller@nist.gov>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut

