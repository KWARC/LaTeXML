package LaTeXML::MathSemantics;

# Startup actions: import the constructors
{ BEGIN{ use LaTeXML::MathParser qw(:constructors); }}

sub new {
  my ($class,@args) = @_;
  bless {steps=>[]}, $class; }

# I. Basic

sub first_arg {
  my ($state,$arg) = @_;
  MaybeLookup($arg); }

# DG: If we don't extend Marpa, we need custom routines to preserve
# grammar category information
sub first_arg_role {
  my ($role,$parse) = @_;
  return $parse if ref $parse;
  my ($lex,$id) = split(/:/,$_[1]);
  my $xml = Lookup($id);
  $xml = $xml ? ($xml->cloneNode(1)) : undef;
  $xml->setAttribute('role',$role) if $xml;
  $xml; }
sub first_arg_number {
  my ($state,$parse) = @_;
  first_arg_role('NUMBER',$parse); }
sub first_arg_term {
  my ($state,$parse) = @_;
  first_arg_role('term',$parse); }
sub first_arg_formula {
  my ($state,$parse) = @_;
  first_arg_role('formula',$parse); }

# II. Infix

sub chain_apply {
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  ApplyNary(MaybeLookup($op),$t1,$t2); }
sub infix_apply {
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  ApplyNary(MaybeLookup($op),$t1,$t2); }
sub concat_apply {
 my ( $state, $t1, $c, $t2) = @_;
 #print STDERR "ConcApply: ",Dumper($lhs)," <--- ",Dumper($rhs),"\n\n";
 Apply(New('concatenation',undef,role=>"MULOP",omcd=>"underspecified"),$t1,$t2); }
## 2. Intermediate layer, records categories on resulting XML:
sub concat_apply_factor {
  my $app = concat_apply(@_);
  $app->[1]->{'cat'}='factor';
  $app; }
sub infix_apply_factor {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='factor';
  $app; }
use Data::Dumper;
sub infix_apply_term {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='term';
  $app; }
sub infix_apply_type {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='type';
  $app; }
sub infix_apply_relation {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='relation';
  $app; }
sub chain_apply_relation {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='relation';
  $app; }
sub infix_apply_formula {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='formula';
  $app; }
sub infix_apply_entry {
  my $app = infix_apply(@_);
  $app->[1]->{'cat'}='entry';
  $app; }

sub extend_operator {
  my ( $state, $base, $c, $ext_lex) = @_;
  my $extension = MaybeLookup($ext_lex);
  my $merged = $base->cloneNode(1);
  $merged->appendText($extension->textContent);
  $merged; }

# III. Prefix

sub prefix_apply {
  my ( $state, $op, $c, $t) = @_;
  ApplyNary(MaybeLookup($op),$t); }
sub prefix_apply_factor {
  my $app = prefix_apply(@_);
  $app->[1]->{'cat'}='factor'; 
  $app; }
sub prefix_apply_term {
  my $app = prefix_apply(@_);
  $app->[1]->{'cat'}='term';
  $app; }
  sub prefix_apply_relation {
  my $app = prefix_apply(@_);
  $app->[1]->{'cat'}='relation';
  $app; }
sub prefix_apply_formula {
  my $app = prefix_apply(@_);
  $app->[1]->{'cat'}='formula';
  $app; }

# IV. Postfix

sub postfix_apply_factor {
  my ($state, $t, $c, $postop) = @_;
  my $app = prefix_apply($state,$postop,$c,$t);
  $app->[1]->{'cat'}='factor';
  $app; }
sub postfix_apply_term {
  my ($state, $t, $c, $postop) = @_;
  my $app = prefix_apply($state,$postop,$c,$t);
  $app->[1]->{'cat'}='term';
  $app; }
sub postfix_apply_relation {
  my ($state, $t, $c, $postop) = @_;
  my $app = prefix_apply($state,$postop,$c,$t);
  $app->[1]->{'cat'}='formula';
  $app; }
sub postfix_apply_formula {
  my ($state, $t, $c, $postop) = @_;
  my $app = prefix_apply($state,$postop,$c,$t);
  $app->[1]->{'cat'}='formula';
  $app; }
# V. Scripts
sub postscript_apply {
  my ( $state, $base, $c, $script) = @_;
  NewScript(MaybeLookup($base),MaybeLookup($script)); }
sub prescript_apply {
  my ( $state, $script, $c, $base) = @_;
  NewScript(MaybeLookup($base),MaybeLookup($script)); }

# VI. Transfix:
sub set {
  my ( $state, undef, undef, $t, undef, undef, undef, $f ) = @_;
  Apply(New('Set'),$t,$f); }

sub fenced {
  my ($state, $open, undef, $t, undef, $close) = @_;
  $open=~/^([^:]+)\:/; $open=$1;
  $close=~/^([^:]+)\:/; $close=$1;
  Fence($open,MaybeLookup($t),$close); }

sub fenced_empty {
  # TODO: Semantically figure out list/function/set context,
  # and place the correct OpenMath symbol instead!
 my ($state, $open, $c, $close) = @_;
 $open=~/^([^:]+)\:/; $open=$1;
 $close=~/^([^:]+)\:/; $close=$1;
 Fence($open,New('empty',undef,role=>"ATOM",omcd=>"underspecified"),$close); }

### Helpers, ideally should reside in MathParser:

sub MaybeLookup {
  my ($arg) = @_;
  return $arg if ref $arg;
  my ($lex,$id) = split(/:/,$arg);
  my $xml = Lookup($id);
  $xml = $xml ? ($xml->cloneNode(1)) : undef;
  return $xml;
}

1;
