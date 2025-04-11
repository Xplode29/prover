
(* The type of tokens. *)

type token = 
  | WHILE
  | TRUE
  | TIMES
  | SKIP
  | SEQ
  | RPAREN
  | RCROCHET
  | RBRACKET
  | PROG
  | PRINT
  | PRE
  | POST
  | PLUS
  | OR
  | NOT
  | NEQ
  | MORE
  | MINUS
  | MEQ
  | LPAREN
  | LOC of (string)
  | LESS
  | LEQ
  | LCROCHET
  | LBRACKET
  | INT of (int)
  | IMPLIES
  | IF
  | FORALL
  | FALSE
  | EXISTS
  | EVAL
  | EQUAL
  | EOF
  | ENTRY
  | ELSE
  | DOT
  | DO
  | DIV
  | COMMA
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val main: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.prog)
