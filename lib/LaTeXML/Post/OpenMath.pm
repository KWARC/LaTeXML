# /=====================================================================\ #
# |  LaTeXML::Post::OpenMath                                            | #
# | OpenMath generator for LaTeXML                                      | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

# ================================================================================
# TODO
#     Scheme for mapping from LaTeXML's "meaning" => cd+name
# Unfortunately, OpenMath's naming scheme is unweildy, unless you are
# completely immersed in the OpenMath world. It is also incomplete in
# the sense that it doesn't cover nearly enough symbols that LaTeXML encounters.
# And, of course, many of those symbols are ambiguous!
#
# So, I think LaTeXML's naming scheme is a worthwhile one to pursue,
# but we DO need to provide a rich but customizable mapping, starting with stuff like:
#    equals => arith1:eq
# ================================================================================
package LaTeXML::Post::OpenMath;
use strict;
use LaTeXML::Common::XML;
use LaTeXML::Post::MathML;
use Encode;
use base qw(LaTeXML::Post::MathProcessor);

our $omURI = "http://www.openmath.org/OpenMath";
our $pres_processor=LaTeXML::Post::MathML::Presentation->new();

sub preprocess {
  my($self,$doc,@nodes)=@_;
  $doc->adjust_latexml_doctype('OpenMath');  # Add OpenMath if LaTeXML dtd.
  $doc->addNamespace($omURI,'om'); }

sub outerWrapper {
  my($self,$doc,$node,@conversion)=@_;
  ['om:OMOBJ',{},@conversion]; }

sub convertNode {
  my($self,$doc,$xmath,$style)=@_;
  Expr($xmath); }

sub combineParallel {
  my($self,$doc,$math,$primary,@secondaries)=@_;
  my $tex = isElementNode($math) && $math->getAttribute('tex');
  (['om:OMATTR',{},
    map( (['om:OMS',{cd=>"Alternate", name=>$$_[0]->getEncodingName}], ['om:OMFOREIGN',{},$$_[1]]),
	 @secondaries),
    ($tex ? (['om:OMS',{cd=>'Alternate', name=>'TeX'}],['om:OMFOREIGN',{},$tex]) : ()),
    $primary ]); }

sub getQName {
  $LaTeXML::Post::DOCUMENT->getQName(@_); }

sub getEncodingName { 'OpenMath'; }
sub rawIDSuffix { '.om'; }

# ================================================================================
our $OMTable={};

sub DefOpenMath {
  my($key,$sub) =@_;
  $$OMTable{$key} = $sub; }

sub Expr {
  my($node)=@_;
  my $result = Expr_aux($node);
  # map any ID here, as well, BUT, since we follow split/scan, use the fragid, not xml:id!
  return $result if (!$node || $node =~ 'XML::LibXML::Text');
  if(my $id = $node->getAttribute('fragid')){
    $$result[1]{'xml:id'}=$id.$LaTeXML::Post::MATHPROCESSOR->IDSuffix; }
  $result; }

# Is it clear that we should just getAttribute('role'),
# instead of the getOperatorRole like in MML?
sub Expr_aux {
  my($node)=@_;
  return OMError("Missing Subexpression") unless $node;
  my $tag = getQName($node)||''; #DG: Suppress warnings if not defined
                                 #(huh?! Possibly due to recursion of the OMSTR treatment!)
  if(!$tag) {
    #leftover when we unwrap a ltx:XMText, we should simply add its text content
    $node->textContent;
  }
  elsif(($tag eq 'ltx:XMath') || ($tag eq 'ltx:XMWrap')){
    my($item,@rest)=  element_nodes($node);
    print STDERR "Warning: got extra nodes for content!\n  ".encode('UTF-8',$node->toString)."\n" if grep (defined, @rest);
    Expr($item); }
  elsif($tag eq 'ltx:XMDual'){
    my($content,$presentation) = element_nodes($node);
    Expr($content); }
  elsif($tag eq 'ltx:XMApp'){
    # Experiment: If XMApp has role ID, we treat it as a "Decorated Symbol"
    if(($node->getAttribute('role')||'') eq 'ID'){
      om_decoratedSymbol($node); }
    else {
      my($op,@args) = element_nodes($node);
      return OMError("Missing Operator") unless $op;
      my $ic = $node->getAttribute('ic')||'variant:default'; #DG: Experiment with notation variants
      my $sub = lookupConverter('Apply',$node->getAttribute('role'),$node->getAttribute('meaning'));
      &$sub($ic,$op,@args); }}
  elsif($tag eq 'ltx:XMTok'){
    my $sub = lookupConverter('Token',$node->getAttribute('role'),$node->getAttribute('meaning'));
    &$sub($node); }
  elsif($tag eq 'ltx:XMHint'){
    (); }
  elsif($tag eq 'ltx:XMArg'){   # Only present if parsing failed!
    Expr($node->firstChild); }
  #DG: Experimental support for ltx:XMText (sTeX ticket #1627)
  elsif($tag eq 'ltx:XMText') { # Text may contain math inside)
    #always an extra <ltx:text> wrapper needs to be unwrapped)
    my $qname = getQName($node->firstChild);
    $node = $node->firstChild if ($qname && ($qname eq 'ltx:text'));
    ['om:OMSTR',{},(grep($_,map(Expr($_),$node->childNodes)))];}
  else {
    ['om:OMSTR',{},$node->textContent]; }}

sub lookupConverter {
  my($mode,$role,$name)=@_;
  $name = '?' unless $name;
  $role = '?' unless $role;
  $$OMTable{"$mode:$role:$name"} || $$OMTable{"$mode:?:$name"}
    || $$OMTable{"$mode:$role:?"} || $$OMTable{"$mode:?:?"}; }

# ================================================================================
# Helpers
sub OMError {
  my($msg)=@_;
  ['om:OME',{},
   ['om:OMS',{name=>'unexpected', cd=>'moreerrors'}],
   ['om:OMS',{},$msg]]; }

# Experimental; for an XMApp with role=ID, we treat it as a ci
	# or ultimately as csymbol, if it had defining attributes,
	# but we format its contents as pmml
sub om_decoratedSymbol {
  my($item)=@_;
  my $id=$item->getAttribute('xml:id');
  #Assuming id="cvar.X" is always supplied, distinguish between a given name
  #i.e. name="X" and a defaulted one i.e. name="name.cvar.X" where X is \d+
  my $name=$id;
  $name=~s/^cvar\.//;
  $name="name.cvar.$name" if ($name=~/^\d+$/);
  my $pmml=$pres_processor->pmml_tpo($item,'text');
  my $pmml_nommath=$pmml->[2];
  ['om:OMATTR',{id=>"$id"},
   ['om:OMATP',{},
    ['om:OMS',{name=>'PMML',cd=>'OMPres'}],
    ['om:OMFOREIGN',{},$pmml_nommath]],
   ['om:OMV',{name=>$name}]]; }
# ================================================================================
# Tokens

# Note: In general, there needs to be a lot more support/analysis.
# Here, we simply assume that the token is a variable if there's no CD!!!
# See comments above about meaning.
# With the gradual refinement of meaning, in the lack of a mapping,
# we'll just presume that the cd defaults to latexml...
DefOpenMath('Token:?:?',    sub { 
  my($token)=@_;
  if(my $meaning = $token->getAttribute('meaning')){
    my $cd = $token->getAttribute('omcd') || 'latexml';
    ['om:OMS',{name=>$meaning, cd=>$cd}]; }
  else {
    my $name = $token->getAttribute('name') || $token->textContent;
    ['om:OMV',{name=>$name}]; }});

# NOTE: Presence of '.' distinguishes float from int !?!?
DefOpenMath('Token:NUMBER:?',sub {
  my($node)=@_;
  my $value = $node->getAttribute('meaning'); # name attribute (may) holds actual value.
  $value = $node->textContent unless defined $value;
  if($value =~ /\./){
    ['om:OMF',{dec=>$value}]; }
  else {
    ['om:OMI',{},$value]; }});

DefOpenMath('Token:SUPERSCRIPTOP:?',sub {
   ['om:OMS',{name=>'superscript',cd=>'ambiguous'}];});
DefOpenMath('Token:SUBSCRIPTOP:?',sub {
   ['om:OMS',{name=>'subscript',cd=>'ambiguous'}];});

DefOpenMath("Token:?:\x{2062}", sub {
  ['om:OMS',{name=>'times', cd=>'arith1'}]; });

# ================================================================================
# Applications.

# Generic

 # DefOpenMath('Apply:?:?', sub {
 #   my($op,@args)=@_;
 #   ['om:OMA',{},map(Expr($_),$op,@args)]; });

#DG: Adding support for IC Variants (see Christine Mueller's PhD thesis)
# TODO: Revise me!
DefOpenMath('Apply:?:?', sub {
  my($ic,$op,@args)=@_;
  ['om:OMA',
   ($ic ne 'variant:default') ? {ic=>$ic}:{},
   map(Expr($_),$op,@args)]; });

# NOTE: No support for OMATTR here...

#NOTE: Experimental sketch for generic binding symbols
sub findElements_internal {
 my ($type,$name, $attr, @children) = @_;
 if ($name eq $type) {
   [$name, $attr, @children];
 }
 else {
   map(findElements_internal($type,@$_),grep(ref $_,@children));
 }}

DefOpenMath('Apply:BINDER:?', sub {
  my($ic,$op,$bvars,$expr)=@_;
  my $bvarspost = Expr($bvars);
  #Recursively fish out all OMV elements:
  my @vars = findElements_internal('om:OMV',@$bvarspost);
  ['om:OMBIND',{},
   Expr($op),
   ['om:OMBVAR',{},@vars], # Presumably, these yield OMV
   Expr($expr)]});

# NOTE: Sketch of what OMBIND support might look like.
# Currently, no such construct is created in LaTeXML...
DefOpenMath('Apply:LambdaBinding:?', sub {
  my($ic,$op,$expr,@vars)=@_;
  ['om:OMBIND',{},
   ['om:OMS',{name=>"lambda", cd=>'fns1'},
    ['om:OMBVAR',{},map(Expr($_),@vars)], # Presumably, these yield OMV
    Expr($expr)]]; });
# ================================================================================
1;
