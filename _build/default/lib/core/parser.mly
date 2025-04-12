/* File parser.mly */

%{
open Ast
%}

%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LCROCHET RCROCHET

%token <int> INT
%token <string> LOC
%token PLUS MINUS TIMES DIV

%token TRUE FALSE
%token NOT OR AND
%token EQUAL NEQ LESS LEQ MORE MEQ

%token IMPLIES FORALL EXISTS DOT

%token SKIP
%token EVAL
%token SEQ
%token WHILE DO
%token IF ELSE
%token PRINT

%token ENTRY PRE POST PROG COMMA

%token EOF

%left PLUS MINUS /* lowest precedence */
%left TIMES /* medium precedence */

%start <Ast.prog> main /* the entry point */

%%

main:
  LPAREN ENTRY LBRACKET entries = loc_list RBRACKET RPAREN
  LPAREN PRE LCROCHET pre = math RCROCHET RPAREN
  LPAREN POST LCROCHET post = math RCROCHET RPAREN

  LPAREN PROG RPAREN
  c = hoares_commands
  LPAREN DIV PROG RPAREN
  EOF { Prog (c, pre, post, entries) }
;

loc_list:
  | s = LOC COMMA l = loc_list { (s::l) }
  | s = LOC { [s] }
;

arith:
  (* Arithmetic variables *)
  | LPAREN e = arith RPAREN { e }
  | s = LOC { Loc s }

  | i = INT { Num i }

  | e1 = arith PLUS e2 = arith { Plus (e1, e2) }
  | e1 = arith MINUS e2 = arith { Minus (e1, e2) }
  | e1 = arith TIMES e2 = arith { Mult (e1, e2) }
;

bool:
  (* Boolean variables *)
  | LPAREN e = bool RPAREN { e }

  | TRUE { Bool true }
  | FALSE { Bool false }

  | NOT b = bool { Not b }
  | b1 = bool OR b2 = bool { Or (b1, b2) }
  | b1 = bool AND b2 = bool { And (b1, b2) }

  | a1 = arith EQUAL a2 = arith { Equal (a1, a2) }
  | a1 = arith NEQ a2 = arith { Not (Equal (a1, a2)) }


  | a1 = arith LEQ a2 = arith { Leq (a1, a2) }
  | a1 = arith LESS a2 = arith { And (Leq (a1, a2), Not (Equal (a1, a2))) }
  | a1 = arith MORE a2 = arith { Not (Leq (a1, a2)) }
  | a1 = arith MEQ a2 = arith { Or (Not (Leq (a1, a2)), Equal (a1, a2)) }
;

math:
  | LPAREN m = math RPAREN { m }

  | TRUE { Mtrue }
  | FALSE { Mfalse }

  | NOT m = math { Mnot m }
  | m1 = math OR m2 = math { Mor (m1, m2) }
  | m1 = math AND m2 = math { Mand (m1, m2) }
  | m1 = math IMPLIES m2 = math { Mimplies (m1, m2) }

  | FORALL s = LOC DOT m = math { Mforall (s, m) }
  | EXISTS s = LOC DOT m = math { Mexists (s, m) }
  
  | a1 = arith EQUAL a2 = arith { Mequals (a1, a2) }
  | a1 = arith NEQ a2 = arith { Mnot (Mequals (a1, a2)) }

  | a1 = arith LEQ a2 = arith { Mleq (a1, a2) }
  | a1 = arith LESS a2 = arith { Mless (a1, a2) }
  | a1 = arith MORE a2 = arith { Mgre (a1, a2) }
  | a1 = arith MEQ a2 = arith { Mgeq (a1, a2) }
;

command:
  | LPAREN c = command RPAREN { c }

  | SKIP { fun pre post -> Skip (pre, post) }
  | PRINT a = arith { fun pre post -> Print (a, (pre, post)) }

  | s = LOC EVAL a = arith { fun pre post -> Eval (s, a, (pre, post)) }

  | IF b = bool DO LPAREN c1 = hoares_commands RPAREN ELSE LPAREN c2 = hoares_commands RPAREN { fun pre post -> Conditional (b, c1, c2, (pre, post)) }
  | IF b = bool DO LPAREN c1 = hoares_commands RPAREN { fun pre post -> Conditional (b, c1, Skip (pre, post), (pre, post)) }
  
  | WHILE b = bool DO LBRACKET inv = math RBRACKET LPAREN c = hoares_commands RPAREN { fun pre post -> While (b, c, (pre, inv, post)) }
  
  | c1 = hoares_commands SEQ c2 = hoares_commands { fun pre post -> Sequence (c1, c2, (pre, post)) }
;

hoares_commands:
  | LCROCHET pre = math RCROCHET c = command LCROCHET post = math RCROCHET { c pre post }
  | LCROCHET pre = math RCROCHET c = command { c pre Mfalse }
  | c = command LCROCHET post = math RCROCHET { c Mfalse post }
  | c = command { c Mfalse Mfalse }