# /=====================================================================\ #
# |  LaTeXML::Util::WWW                                                 | #
# | Web Utilities for LaTeXML                                           | #
# |=====================================================================| #
# | NOT Part of LaTeXML:                                                | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev (d.ginev@jacobs-university.de)                  #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Util::WWW;
use strict;
use LWP;
use LWP::Simple;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( &auth_get);

sub auth_get {
  my ($url,$authlist) = @_;
  my $browser = LWP::UserAgent->new;
  my $response=$browser->get($url);
  my $realm = $response->www_authenticate;
  return $response unless $realm;
  # Prompt for username pass for this location:
  my $req; my $tries=3;
  my ($uname,$pass) = @{$$authlist{$realm}} if $$authlist{$realm};
  if (!$uname) {
    print STDERR "Enter authentication info for realm: $realm\n URL: $url\n";
    while (!($response && $response->is_success) && $tries>0) { # 3 tries
      $uname = prompt('Username: ');
      $pass = prompt('Password: ', -e => '*');
      $req = HTTP::Request->new(GET => $url);
      $req->authorization_basic($uname, $pass);
      $response = $browser->request($req);
      $tries--;
    }
    $$authlist{$realm}=[$uname,$pass] if $response->is_success;
  } else {
    $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($uname, $pass);
    $response = $browser->request($req);
  }
  $response;
}

#======================================================================
1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Util::WWW>  - auxiliaries for web-scalability of LaTeXML's IO

=head1 SYNOPSIS

    my $response = auth_get($url,$authlist);

=head1 DESCRIPTION

Utilities for enabling general interaction with the World Wide Web in LaTeXML's Input/Output.

Still in development, more functionality is expected at a later stage.

=head2 METHODS

=over 4

=item C<< my $response = auth_get($url,$authlist); >>

Given an authentication list, attempts a get request on a given URL ($url) and returns the $response.

If no authentication is possible automatically, the routine prompts the user for credentials.

=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
