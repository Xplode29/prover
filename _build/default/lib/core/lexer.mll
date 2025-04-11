(* File lexer.mll *)

{
open Parser        (* The type token is defined in parser.mli *)
exception Eof
}

let white = [' ' '\t']+
let digit = ['0'-'9']
let int = '-'? digit+
let letter = ['a'-'z' 'A'-'Z']
let string = letter+

rule read = parse
  | white { read lexbuf }     (* skip blanks *)
  | ['\n' ] { read lexbuf }

  | '(' { LPAREN } | ')' { RPAREN }
  | '[' { LBRACKET } | ']' { RBRACKET }
  | '{' { LCROCHET } | '}' { RCROCHET }

(* Arithmetic Expressions *)
  | '+' { PLUS }
  | '-' { MINUS }
  | '*' { TIMES }
  | '/' { DIV }

(* Boolean Expressions *)
  | "true" { TRUE }
  | "false" { FALSE }
  | '!' { NOT } | "not" { NOT }
  | "&&" { AND } | "and" { AND }
  | "||" { OR } | "or" { OR }

(* Math expressions *)
  | "forall" { FORALL }
  | "exists" { EXISTS }
  | "=>" { IMPLIES }
  | "." { DOT }

(* Comparators *)
  | '=' { EQUAL }
  | "!=" { NEQ }
  | '<' { LESS }
  | "<=" { LEQ }
  | '>' { MORE }
  | ">=" { MEQ }

(* Commands *)
  | "skip" { SKIP }
  | "<-" { EVAL }
  | ';' { SEQ }
  | "if" { IF }
  | "else" { ELSE }
  | "while" { WHILE }
  | "do" { DO }

  | "print" { PRINT }

(* Program structure *)
  | "entry" { ENTRY }
  | "pre" { PRE }
  | "post" { POST }
  | "prog" { PROG }

  | ',' { COMMA }

  | int as lxm { INT (int_of_string lxm) }
  | string as lxm { LOC (lxm) }

  | eof { EOF }
