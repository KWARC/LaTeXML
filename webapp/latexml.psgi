#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
my $FILE_BASE;
BEGIN {
    $FILE_BASE = dirname(__FILE__);
}
use lib $FILE_BASE."/../blib/lib";

use File::Path;
use Encode;
use JSON::XS qw(encode_json decode_json);
use URI::Escape;
use Data::Dumper;

use LaTeXML::Util::Config;
use LaTeXML::Util::Pathname;
use LaTeXML::Converter;

sub parse_request_body {
    my $env = shift;

    my $ct = $env->{CONTENT_TYPE};
    my $cl = $env->{CONTENT_LENGTH};
    if (!$ct && !$cl) {
        return; # GET Request
    }

    my $input = $env->{'psgi.input'};
    my $body = '';
    my $spin = 0;
    while ($cl) {
        $input->read(my $chunk, $cl < 8192 ? $cl : 8192);
        my $read = length $chunk;
        $cl -= $read;
        $body .= $chunk;
        
        if ($read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
        }
    }

    # Parse the body:
    # Split, and make sure keys with no values get an empty string stub
    my $parameters = [ map {scalar(@{$_})==1 ? (@{$_},'') : @{$_}}
      map { [split(/=/,$_)] } map {split(/\&/,$_)} $body ];
    return $parameters;
}
sub parse_request_query {
  my $env = shift;
  my $body = $env->{QUERY_STRING};
  # Split, and make sure keys with no values get an empty string stub
  my $parameters = [ map {scalar(@{$_})==1 ? (@{$_},'') : @{$_}}
      map { [split(/=/,$_)] } map {split(/\&/,$_)} $body ];
  return $parameters;
}


my $app = sub {
  my $env = shift;
  # 1. Read request
  my $parameters;
  my $source;
  if ( $env->{REQUEST_METHOD} ne 'POST') {
    # 1.1. Invalid request?
    return [
      '400',
      [ 'Content-Type' => 'application/json; charset=utf-8' ],
      [ encode_json({
        result=>'',
        status=>'Fatal:http:request Bad Request, HTTP POST with form-data required',
        status_code=>3,
        log=>"Fatal:http:request Bad Request, HTTP POST with form-data required\nStatus:conversion:3\n"
        })]];
  }
  
  # 1.2 Prepare parameters
  my $get_params = parse_request_query($env);
  my $post_params = parse_request_body($env);
  # print STDERR "GET: ",Dumper($get_params);
  # print STDERR "POST: ",Dumper($post_params);
  if (scalar((grep {defined} @$post_params)) == 1) {
    $source = $post_params->[0];
    $post_params=[];
  } elsif ((scalar(@$post_params) == 2) && ($post_params->[0] !~ /^tex|source$/)) {
    $source = $post_params->[0].$post_params->[1];
    $post_params=[];
  }
  # We need to be careful to preserve the parameter order, so use arrayrefs
  my @all_params = (@$get_params, @$post_params);
  my $opts = [];
  # Ugh, disallow 'null' as a value!!! (TODO: Smarter fix??)
  while (my ($key,$value) = splice(@all_params,0,2)) {
    $value = '' if ($value && ($value  eq 'null'));
    if ($key =~ /^(tex)|(source)$/) {
      # TeX is data, separate
      $source = $value unless defined $source;
      next;
    } elsif ($key=~/local|path/) {
      # You don't get to specify harddrive info in the web service
      next;
    }
    push @$opts, ($key,uri_unescape($value));
  }

  $source = uri_unescape($source);
  push @$opts, ('source', $source); # Set in options hash, to e.g. guess bibTeX jobs
  # 2. Convert
  my $config = LaTeXML::Util::Config->new();
  $config->read_keyvals($opts);
  $config->set('local', (($env->{'SERVER_NAME'} eq 'localhost') || ($env->{'SERVER_NAME'} eq '127.0.0.1')));
  my $base = $config->get('base');
  my $saved_cdir;
  if ($base && !pathname_is_url($base)) {
    my $canonical_base = pathname_canonical($base);
    if ($canonical_base ne pathname_cwd()) {
      chdir $canonical_base
       or croak("Fatal:server:chdir Can't chdir to $canonical_base: $!");
       $saved_cdir = $LaTeXML::Util::Pathname::Pathname_CWD;
      $LaTeXML::Util::Pathname::Pathname_CWD=$canonical_base;
    }
  }

  # We now have a LaTeXML config object - $config.
  my $converter = LaTeXML::Converter->get_converter($config);
  #Override/extend with session-specific options in $opt:
  $converter->prepare_session($config);
  # If there are no protocols, use literal: as default:
  if (!$source) {
    return [
      '200',
      [ 'Content-Type' => 'application/json; charset=utf-8' ],
      [ encode_json({result => '', status => "Fatal:input:empty No TeX provided on input", status_code=>3,
                           log => "Status:conversion:3\nFatal:input:empty No TeX provided on input"})]];
  } else {
    #$source = "literal:".$source unless (pathname_is_url($source));
    #Send a request:
    my $response = $converter->convert($source);
    my ($result, $status, $status_code, $log);
    if (defined $response) {
      ($result, $status, $status_code, $log) = map { $response->{$_} } qw(result status status_code log);
    }
    # Delete converter if Fatal occurred
    undef $converter unless defined $result;
    if (defined $saved_cdir) {
      $LaTeXML::Util::Pathname::Pathname_CWD = $saved_cdir;
      chdir $saved_cdir;
    }
    # 3. Return conversion results
    # print STDERR "Result: \n",$result,"\n";
    # print STDERR "Log: \n",$log,"\n";
    # print STDERR "Status: \n",$status,"\n"; 
    return [
      '200',
      [ 'Content-Type' => 'application/json; charset=utf-8' ],
      [ encode_json({result=>$result,status=>$status,status_code=>$status_code,log=>$log}) ]
    ];
  }
};

__END__