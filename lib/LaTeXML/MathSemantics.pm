package LaTeXML::MathSemantics;
use Scalar::Util qw(blessed);
use Data::Dumper;
# Startup actions: import the constructors
{ BEGIN{ use LaTeXML::MathParser qw(:constructors); }}

sub new {
  my ($class,@args) = @_;
  bless {steps=>[]}, $class; }

# I. Basic
sub finalize { print STDERR "\n\nFinal state:\n",Dumper($_[0]->{atoms}),"\n\n"; $_[1];}
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
sub concat_apply {
 my ( $state, $t1, $c, $t2, $type) = @_;
 #print STDERR "ConcApply: ",Dumper($lhs)," <--- ",Dumper($rhs),"\n\n";
 my $app = Apply(New('concatenation',undef,role=>"MULOP",omcd=>"underspecified"),$t1,$t2); 
 $app->[1]->{'cat'}=$type;
 $app; }
## 2. Intermediate layer, records categories on resulting XML:
sub concat_apply_factor {
  my ( $state, $t1, $c, $t2) = @_;
  # Only for NON-atomic structures!
  Marpa::R2::Context::bail('PRUNE') unless (((ref $t1) eq 'ARRAY') && ((ref $t2) eq 'ARRAY'));
  concat_apply($state, $t1, $c, $t2,'factor');
}
sub concat_apply_left {
  my ( $state, $t1, $c, $t2) = @_;
  # if t2 is an atom - mark as scalar or fail if inconsistent
  if ($state->mark_or_fail($t2,'scalar') && $state->mark_or_fail($t1,'scalar')) {
    # Just in case, do the same for $t1:
    concat_apply($state, $t1, $c, $t2,'factor');
  } else {
    Marpa::R2::Context::bail('PRUNE');
  }
}
sub concat_apply_right {
  my ( $state, $t1, $c, $t2) = @_;  
  # if t1 is an atom - mark as function or fail if inconsistent
  if ($state->mark_or_fail($t1,'function') && $state->mark_or_fail($t2,'scalar')) {
    # Just in case, do the same for $t2, which is a scalar if atom:
    my $app =  Apply($t1,$t2);
    $app->[1]->{'cat'}='factor';
    $app;
  } else {
    Marpa::R2::Context::bail('PRUNE');
  }
}

sub infix_apply {
  my ( $state, $t1, $c, $op, $c2, $t2, $type) = @_;
  my $app = ApplyNary(MaybeLookup($op),$t1,$t2); 
  $app->[1]->{'cat'}=$type;
  $app;}
sub infix_apply_factor { $app = infix_apply(@_,'factor'); }
sub infix_apply_term { infix_apply(@_,'term'); }
sub infix_apply_type {  infix_apply(@_,'type'); }
# TODO: Should we do something smarter for chains?
sub infix_apply_relation { infix_apply(@_,'relation'); }
sub chain_apply_relation { infix_apply(@_,'relation'); }
sub infix_apply_formula { infix_apply(@_,'formula'); }
sub chain_apply_formula { infix_apply(@_,'formula'); }
sub infix_apply_entry { infix_apply(@_,'entry'); }

sub extend_operator {
  my ( $state, $base, $c, $ext_lex) = @_;
  my $extension = MaybeLookup($ext_lex);
  my $merged = $base->cloneNode(1);
  $merged->appendText($extension->textContent);
  $merged; }

# III. Prefix

sub prefix_apply {
  my ( $state, $op, $c, $t,$type) = @_;
  my $app = ApplyNary(MaybeLookup($op),$t); 
  $app->[1]->{'cat'}=$type; 
  $app;}
sub prefix_apply_factor { prefix_apply(@_,'factor'); }
sub prefix_apply_term { prefix_apply(@_,'term'); }
sub prefix_apply_relation { prefix_apply(@_,'relation'); }
sub prefix_apply_formula { prefix_apply(@_,'formula'); }

# IV. Postfix

sub postfix_apply_factor {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'factor'); }
sub postfix_apply_term {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'term'); }
sub postfix_apply_relation {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'relation'); }
sub postfix_apply_formula {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'formula'); }
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
  Marpa::R2::Context::bail('PRUNE') unless defined $arg;
  return $arg if ref $arg;
  my ($lex,$id) = split(/:/,$arg);
  my $xml = Lookup($id);
  $xml = $xml ? ($xml->cloneNode(1)) : undef;
  return $xml;
}

sub mark_or_fail {
  my ($state,$t2,$value) = @_;
  if (blessed($t2)) {
    my $lex = $t2->textContent;
    my $current = $state->{atoms}->{$lex};
    if (defined $current) {
      return undef if ($current ne $value);
    } else {
        $state->{atoms}->{$lex} = $value;
    }
  }
  1;
}

1;
