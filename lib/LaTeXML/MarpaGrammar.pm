# /=====================================================================\ #
# | LaTeXML::MarpaGrammar                                               | #
# | A Marpa::R2 grammar for mathematical expressions                    | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <deyan.ginev@nist.gov>                          #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

## Mantra in Programming: Premature optimisation is the root of all evil
##         =>
## In Grammar Design: Premature disambiguation is the root of all evil

package LaTeXML::MarpaGrammar;
use strict;

# Startup actions: import the constructors
{ BEGIN{ use LaTeXML::MathParser qw(:constructors); 
#### $::RD_TRACE=1;
}}

use Data::Dumper;
use Marpa::R2;
use LaTeXML::MathSemantics;
use LaTeXML::Global;
our $parses = 0;
our $RULES = [
              # I. Operators
              # I.1. Infix operators
              # I.1.0. Concatenation - Left and Right
              ['Factor', [qw/FactorArgument _ Factor/],'concat_apply_right'], # Semantics: FA always function
              ['Factor', [qw/Factor _ FactorArgument/],'concat_apply_left'], # Semantics: FA always scalar
              # The asymetry in the above two rules makes '2a f(x)' ungrammatical
              # So we add:
              ['Factor', [qw/Factor _ Factor/],'concat_apply_factor'], # Semantics: Make sure NO atoms!
              # But if we are not careful, we will allow too many parses for ' f(x)f(y)'
              # But then again we also need to consider (f \circ g) x 

              # I.1.1. Infix Operator - Factors
              ['Factor',['FactorArgument']],
              ['Factor',[qw/Factor _ MULOP _ FactorArgument/],'infix_apply_factor'],

              # I.1.2. Infix Operator - Additives
              ['Term',['Factor']],
              ['Term',['TermArgument']],
              ['Term',[qw/Term _ ADDOP _ Factor/],'infix_apply_term'],
              ['Term',[qw/Term _ ADDOP _ TermArgument/],'infix_apply_term'],

              # I.1.3. Infix Operator - Type Constructors
              ['Type',[qw/FactorArgument _ ARROW _ FactorArgument/],'infix_apply_type'],
              ['Type',[qw/Type _ ARROW _ FactorArgument/],'infix_apply_type'],

              # I.1.4. Infix Logical Operators
              ['Formula',['FormulaArgument']],
              ['Formula',['Relative']],
              ['Formula',['PostRelative']],
              ['Formula',[qw/Formula _ LOGICOP _ Relative/],'infix_apply_formula'],
              ['Formula',[qw/Formula _ LOGICOP _ FormulaArgument/],'infix_apply_formula'],

              # I.2. Prefix operators
              # I.2.1. Big Summation
              # Think about this -> it behaves as a Factor argument on the left e.g.
              #    (1-t)\sum ...
              # but never on the right! We should enforce this to avoid confusion? 
              # use a BigTerm category?
              ['Term',['BigTerm']],
              ['BigTerm',[qw/BIGOP _ Factor/],'prefix_apply_term'],
              ['BigTerm',[qw/BIGOP _ TermArgument/],'prefix_apply_term'],
              ['BigTerm',[qw/BIGOP _ BigTerm/],'prefix_apply_term'],
              # I.2.1.2 Operations on BigTerms:
              ['BigTerm', [qw/Factor _ BigTerm/],'concat_apply_factor'],
              ['BigTerm',[qw/Factor _ MULOP _ BigTerm/],'infix_apply_factor'],
              ['Term',[qw/Term _ ADDOP _ BigTerm/],'infix_apply_term'],
              # I.2.2. Prefix ADDOPs (any MULOPs?)
              # TODO: These guys need more thinking...
              #   ... quite confusing interplay, think of -sin x and sin x/y
              #   or tg n!
              # TODO: Maybe add BigTerm as possible argument?
              ['FactorArgument',[qw/PREFIX _ FactorArgument/],'prefix_apply_factor'],
              ['TermArgument',[qw/PREFIX _ TermArgument/],'prefix_apply_term'],
              ['Term',['PreTerm']],
              ['PreTerm',[qw/ADDOP _ FactorArgument/],'prefix_apply_term'],
              ['PreTerm',[qw/ADDOP _ TermArgument/],'prefix_apply_term'],
              # I.2.1.2 Operations on PreTerms:
              ['PreTerm', [qw/PreTerm _ FactorArgument/],'concat_apply_factor'],
              ['PreTerm',[qw/PreTerm _ MULOP _ FactorArgument/],'infix_apply_factor'],
              # Note: the ADDOP operations are inherited from the usual ADDOP rules,
              #       as PreTerm can be cast as Term
              # I.3. Postfix operators (POSTFIX and ADDOPs)
              ['Factor',[qw/FactorArgument _ POSTFIX/],'postfix_apply_factor'],
              ['Term',[qw/TermArgument _ POSTFIX/],'postfix_apply_factor'],
              ['Termlike',['PostTerm']], # Not really Term since we don't want ADDOP to work on the right
              ['PostTerm',[qw/FactorArgument _ ADDOP/],'postfix_apply_factor'],
              ['PostTerm',[qw/TermArgument _ ADDOP/],'postfix_apply_term'],
              # I.2.1.2 Operations on PreTerms:
              ['PostTerm', [qw/FactorArgument _ PostTerm/],'concat_apply_factor'],
              ['PostTerm',[qw/FactorArgument _ MULOP _ PostTerm/],'infix_apply_factor'],

              # II. Relations
              # II.1. Infix relations
              # TODO: How do we deal with term sequences, 1,2,3\in N ?
              ['Termlike',['Term']],
              ['Termlike',['TermSequence']],
              ['Relative',[qw/Termlike _ RELOP _ Termlike/],'infix_apply_relation'],
              ['Relative',[qw/Relative _ RELOP _ Termlike/],'chain_apply_relation'],
              # II.2 Prefix relations
              ['Relative',['PreRelative']],
              ['PreRelative',[qw/RELOP _ Termlike/],'prefix_apply_relation'],
              # II.3 Postfix relations
              ['PostRelative',[qw/Relative _ RELOP/],'postfix_apply_relation'],
              ['PostRelative',[qw/Termlike _ RELOP _ PostRelative/],'chain_apply_relation'],
              # III. Metarelations
              # III.1. Infix Metarelations
              ['RelativeFormula',[qw/RelativeFormulaArgument/]],
              ['RelativeFormula',[qw/Formula _ METARELOP _ Formula/],'infix_apply_formula'],
              ['RelativeFormula',[qw/RelativeFormula _ METARELOP _ Formula/],'chain_apply_formula'],

              # IV. Modifiers
              # IV.1. Infix Modifier
              # IV.1.1. Infix Modifier - Generic
	            # Modified terms should only appear in sequences, hence entries
              # Hm, not really, they can appear anywhere with ease, as long as 
              # the relation ops are from different domains, so that there is a unique reading
              ['Entry',[qw/FactorArgument _ RELOP _ Term/],'infix_apply_entry'],
              # a := (1<3) should be grammatical
              ['Entry',[qw/FactorArgument _ RELOP _ FormulaArgument/],'infix_apply_entry'],
	            # So, allow them everywhere and let them explode:
              # ... or not ... we need something smart here
              #['FactorArgument',[qw/FactorArgument _ RELOP _ Term/],'infix_apply_term'],
              #['TermArgument',[qw/TermArgument _ RELOP _ Term/],'infix_apply_term'],
              #['FormulaArgument',[qw/FormulaArgument _ RELOP _ Term/],'infix_apply_formula'],

      	      # IV.1.2. Infix Modifier - Typing
              #['Entry',[qw/FactorArgument _ COLON _ Type/],'infix_apply'],
              ['FactorArgument',[qw/FactorArgument _ COLON _ Type/],'infix_apply_term'],
              ['TermArgument',[qw/TermArgument _ COLON _ Type/],'infix_apply_term'],
              ['FormulaArgument',[qw/FormulaArgument _ COLON _ Type/],'infix_apply_formula'],

              # V. Fences
              ['FactorArgument',[qw/OPEN _ Term _ CLOSE/],'fenced'],
              ['FormulaArgument',[qw/OPEN _ Formula _ CLOSE/],'fenced'],
              ['RelativeFormulaArgument',[qw/OPEN _ RelativeFormula _ CLOSE/],'fenced'], # Examples???
              ['ADDOP',[qw/OPEN _ ADDOP _ CLOSE/],'fenced'], # (-) ?? TODO: what about the other ops?
              ['FactorArgument',[qw/OPEN _ Vector _ CLOSE/],'fenced'], # vectors are factors
              ['TermArgument',[qw/OPEN _ Sequence _ CLOSE/],'fenced'], # objects are terms

              # VI. Sequence structures
              # VI.1. Vectors:
              ['Entry', ['Term']],
              ['Vector',[qw/Entry _ PUNCT _ Entry/],'infix_apply'],
              ['Vector',[qw/Vector _ PUNCT _ Entry/],'infix_apply'],
              # VI.2. General sequences:
              # VI.2.1 Base case: elements
              ['Element',['Formula']],
              ['Element',['ADDOP']], # implicitly includes logicop
              ['Element',['MULOP']],
              ['Element',['RELOP']],
              ['Element',['PREFIX']],
              ['Element',['POSTFIX']],
              ['Element',['METARELOP']],
              # VI.2.2 Recursive case: sequences
              ['Sequence',[qw/Vector _ PUNCT _ Element/],'infix_apply'],
              ['Sequence',[qw/Entry _ PUNCT _ Element/],'infix_apply'],
              ['Sequence',[qw/Element _ PUNCT _ Entry/],'infix_apply'],
              ['Sequence',[qw/Sequence _ PUNCT _ Entry/],'infix_apply'],
              # Yuck! Vector adjustments to avoid multiple parses
              ['Sequence',[qw/Element _ PUNCT _ Element/],'infix_apply'],
              ['Sequence',[qw/Sequence _ PUNCT _ Element/],'infix_apply'],

              # VI.3. Term sequences - TODO: what are these really? progressions?
              ['TermSequence',[qw/Term _ PUNCT _ Term/],'infix_apply'],
              ['TermSequence',[qw/TermSequence _ PUNCT _ Term/],'infix_apply'],

              # VII. Scripts
	            # VII.1. Post scripts
              (map { my $script=$_;
                map { my $op=$_; {lhs=>$op, rhs=>[$op,'_',$script],action=>'postscript_apply',rank=>2} }
                    qw/FactorArgument TermArgument FormulaArgument RelativeFormulaArgument
                      PREFIX POSTFIX ADDOP LOGICOP MULOP RELOP METARELOP ARROW BIGOP/;
                } qw/SUPOP POSTSUPERSCRIPT POSTSUBSCRIPT/),
              # VII.1.2. Merge adjacent SUPOPs
              ['SUPOP',[qw/SUPOP _ SUPOPTerminal/],'extend_operator'],
              # VII.2. Pre/Float scripts
              (map { my $script=$_;
                map { my $op=$_; [$op, [$script,'_',$op],'prescript_apply'] }
                    qw/FactorArgument TermArgument FormulaArgument RelativeFormulaArgument
                      PREFIX POSTFIX ADDOP LOGICOP MULOP RELOP METARELOP ARROW BIGOP/;
              } qw/FLOATSUPERSCRIPT FLOATSUBSCRIPT/),

              # VIII. Transfix operators
              ['FactorArgument',[qw/VERTBAR _ Term _ VERTBAR/],'fenced'],

              # IX. Special cases:
              # IX.1. Trailing equals (should it really be grammatical?)
              # TODO: Produces bad markup, figure out how to make <none> elements
              ['TrailingEquals',[qw/Formula _ EQUALS/],'infix_apply_formula'],
              ['TrailingEquals',[qw/Term _ EQUALS/],'infix_apply_relation'],

              # X. Lexicon adjustments
              ['FactorArgument',['ATOM'],'first_arg_term'],
              ['FormulaArgument',['ATOM'],'first_arg_formula'],
              ['FactorArgument',['UNKNOWN'],'first_arg_term'],
              ['FormulaArgument',['UNKNOWN'],'first_arg_formula'],
              ['FactorArgument',['NUMBER'],'first_arg_number'],
              ['RELOP',['EQUALS']],
              # Terminals... TODO: make this into a map and/or rethink
              ['RELOP',['RELOPTerminal']],
              ['METARELOP',['METARELOPTerminal']],
              ['METARELOP',['EQUALS']],
              ['METARELOP',['VERTBAR']],
              ['ADDOP',['LOGICOP']], # Boolean algebra, lattices
              ['ADDOP',['ADDOPTerminal']],
              ['MULOP',['MULOPTerminal']],
              ['MULOP',['VERTBAR']],
              ['LOGICOP',['LOGICOPTerminal']],
              ['ARROW',['ARROWTerminal']],
              ['SUPOP',['SUPOPTerminal']],
              ['PREFIX',['TRIGFUNCTION']],
              ['PREFIX',['OPFUNCTION']],
              ['PREFIX',['LIMITOP']],
              ['PREFIX',['OPERATOR']],
              ['BIGOP',['SUMOP']],
              ['BIGOP',['INTOP']],
              # XI. Start:
              ['Start',['Termlike'],'finalize'],
              ['Start',['Formula'],'finalize'],
              ['Start',['RelativeFormula'],'finalize'],
              ['Start',['Vector'],'finalize'],
              ['Start',['TrailingEquals'],'finalize'],
              ['Start',['Sequence'],'finalize']
];

#Extensions admissible in scripts:
our $SCRIPT_RULES = [
              ['Operator',['MULOP']],
              ['Operator',['ADDOP']],
              ['Operator',['PREFIX']],
              ['Operator',['POSTFIX']],
              ['Operator',['RELOP']],
              ['Operator',['METARELOP']],
              ['Operator',['ARROW']],
              ['Operator',['SUPOP']],
              ['Start',['Operator'],'finalize']
];

sub new {
  my($class,%options)=@_;
  my $grammar = Marpa::R2::Grammar->new(
  {   start   => 'Start',
      actions => 'LaTeXML::MathSemantics',
      action_object => 'LaTeXML::MathSemantics',
      rules=>$RULES,
      default_action=>'first_arg'});
     # default_null_value=>'no nullables in this grammar'});
  my $script_grammar = Marpa::R2::Grammar->new(
  {   start   => 'Start',
      actions => 'LaTeXML::MathSemantics',
      action_object => 'LaTeXML::MathSemantics',
      rules=>[@$RULES,@$SCRIPT_RULES],
      default_action=>'first_arg'});
     # default_null_value=>'no nullables in this grammar'});

  $grammar->precompute();
  $script_grammar->precompute();
  my $self = bless {grammar=>$grammar,script_grammar=>$script_grammar,%options},$class;
  $self; }

sub parse {
  my ($self,$rule,$lexref) = @_;
  my $rec;
  if ($rule =~ /script/) {
    $rec = Marpa::R2::Recognizer->new( { grammar => $self->{script_grammar},
                                         ranking_method => 'high_rule_only'} );
  } else {
    $rec = Marpa::R2::Recognizer->new( { grammar => $self->{grammar},
                                         ranking_method => 'high_rule_only'} );
  }
  my @unparsed = split(' ',$$lexref);
  # Insert concatenation
  @unparsed = map (($_, '_::'), @unparsed);
  pop @unparsed;
  #print STDERR "\n\n";
  my $failed = 0;
  my $rec_events = undef;
  while (@unparsed) {
    my $next = shift @unparsed;
    my ($category,$lexeme,$id) = split(':',$next);
    # Issues: 
    # 1. More specific lexical roles for fences, =, :, others...?
    if ($category eq 'METARELOP') {
      $category = 'COLON' if ($lexeme eq 'colon');
    } elsif ($category eq 'RELOP') {
      $category = 'EQUALS' if ($lexeme eq 'equals');
    }

    $category.='Terminal' if $category =~ /^(((META)?REL|ADD|LOGIC|MUL|SUP)OP)|ARROW$/;
    #print STDERR "$category:$lexeme:$id\n";
    $rec_events = $rec->read($category,$lexeme.':'.$id);
    if (! defined $rec_events) {
      $failed = 1; last;
    }
  }

  my @values = ();
  $$lexref = q{}; # Reset this , so that we are consistent with the RecDescent behaviour
  if (!$failed) {
    my $value_ref;
    do {
      $value_ref = undef;
      eval { local $SIG{__DIE__} = undef; $value_ref = $rec->value(); 1; };
      print STDERR "$@\n" if ($LaTeXML::MarpaGrammar::DEBUG);
      push @values, ${$value_ref} if (defined $value_ref);
      if ($@ =~ /PRUNE$/) {
        undef $@; $value_ref=[];
      }
    } while ((!$@) && (defined $value_ref));
    if ($@) {
      # Was left Incomplete??
      $$lexref = join(' ',grep($_ ne '_::', @unparsed));
    }
  } else {
    # Can't recognize it...print out the issue:
    $$lexref = join(' ',grep($_ ne '_::', @unparsed));
  }
  (@values>1) ? (['ltx:XMApp',{meaning=>"cdlf-set"},New('cdlf-set',undef,omcd=>"cdlf"),@values]) : (shift @values);
}

1;

# DLMF:
# (-)^n for (-1)^n
# f^n (x) = [ f (x) ] ^ n usually
# also f ( f ( ... f x ) ) 
# f^-1 (x) = [inv(f)] (x)
# (d/dx) ^ n, (-)^n is compositional
# (z \frac{d}{dx})^n  and also (\frac{d}{dz} z)^n

# Grobner bases (lookup!)
# a := ( 3 > 1)
# a \neq 2 > 1
