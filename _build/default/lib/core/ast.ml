(* File ast.ml *)

type location = string

type aExp = 
  |Num of int
  |Loc of location
  |Plus of aExp * aExp
  |Minus of aExp * aExp
  |Mult of aExp * aExp

type bExp = 
  |Bool of bool
  |Not of bExp
  |Or of bExp * bExp
  |And of bExp * bExp
  
  |Equal of aExp * aExp
  |Leq of aExp * aExp

type math = 
  |Mtrue
  |Mfalse

  |Mequals of aExp * aExp
  |Mless of aExp * aExp
  |Mleq of aExp * aExp
  |Mgre of aExp * aExp
  |Mgeq of aExp * aExp

  |Mand of math * math
  |Mor of math * math
  |Mnot of math

  |Mimplies of math * math
  |Mforall of string * math (* forall i. A *)
  |Mexists of string * math (* exists i. A *)

type com =
  |Skip of (math * math)
  |Print of aExp * (math * math)

  |Eval of location * aExp * (math * math)
  |Sequence of com * com * (math * math)
  |Conditional of bExp * com * com * (math * math)
  |While of bExp * com * (math * math * math) (* condition, command, pre, invariant, post *)

type prog = Prog of com * math * math * (location list)

let rec math_of_bool b = match b with
  |Bool true -> Mtrue
  |Bool false -> Mfalse

  |And (Leq (a1, a2), Not (Equal (a3, a4))) when a3 = a1 && a2 = a4 -> Mless (a1, a2)
  |Not (Leq (a1, a2)) -> Mgre (a1, a2)
  |Or (Not (Leq (a1, a2)), Equal (a3, a4)) when a3 = a1 && a2 = a4 -> Mgeq (a1, a2)

  |Equal (a1, a2) -> Mequals (a1, a2)
  |Leq (a1, a2) -> Mleq (a1, a2)

  |Not b -> Mnot (math_of_bool b)
  |Or (b1, b2) -> Mor (math_of_bool b1, math_of_bool b2)
  |And (b1, b2) -> Mor (math_of_bool b1, math_of_bool b2)

let rec string_of_aExp = function
  | Num n -> string_of_int n
  | Loc l -> l
  | Plus (a1, a2) -> "(" ^ string_of_aExp a1 ^ " + " ^ string_of_aExp a2 ^ ")"
  | Minus (a1, a2) -> "(" ^ string_of_aExp a1 ^ " - " ^ string_of_aExp a2 ^ ")"
  | Mult (a1, a2) -> "(" ^ string_of_aExp a1 ^ " * " ^ string_of_aExp a2 ^ ")"
let rec string_of_bExp = function
  | Bool b -> string_of_bool b
  | Not b -> "not (" ^ string_of_bExp b ^ ")"
  | Or (b1, b2) -> "(" ^ string_of_bExp b1 ^ " or " ^ string_of_bExp b2 ^ ")"
  | And (b1, b2) -> "(" ^ string_of_bExp b1 ^ " and " ^ string_of_bExp b2 ^ ")"
  | Equal (a1, a2) -> "(" ^ string_of_aExp a1 ^ " = " ^ string_of_aExp a2 ^ ")"
  | Leq (a1, a2) -> "(" ^ string_of_aExp a1 ^ " <= " ^ string_of_aExp a2 ^ ")"
let rec string_of_math = function
  | Mtrue -> "true"
  | Mfalse -> "false"
  
  | Mequals (a1, a2) -> "(" ^ string_of_aExp a1 ^ " = " ^ string_of_aExp a2 ^ ")"
  | Mleq (a1, a2) -> "(" ^ string_of_aExp a1 ^ " <= " ^ string_of_aExp a2 ^ ")"
  | Mless (a1, a2) -> "(" ^ string_of_aExp a1 ^ " < " ^ string_of_aExp a2 ^ ")"
  | Mgeq (a1, a2) -> "(" ^ string_of_aExp a1 ^ " >= " ^ string_of_aExp a2 ^ ")"
  | Mgre (a1, a2) -> "(" ^ string_of_aExp a1 ^ " > " ^ string_of_aExp a2 ^ ")"

  | Mand (m1, m2) -> "(" ^ string_of_math m1 ^ " and " ^ string_of_math m2 ^ ")"
  | Mor (m1, m2) -> "(" ^ string_of_math m1 ^ " or " ^ string_of_math m2 ^ ")"
  | Mnot m -> "not (" ^ string_of_math m ^ ")"
  | Mimplies (m1, m2) -> "(" ^ string_of_math m1 ^ " => " ^ string_of_math m2 ^ ")"

  | Mforall (s, m) -> "(forall " ^ s ^ ". " ^ string_of_math m ^ ")"
  | Mexists (s, m) -> "(exists " ^ s ^ ". " ^ string_of_math m ^ ")"
let rec string_of_com c = 
  "(" ^ begin
  match c with
  | Skip (pre, post) -> "{" ^ string_of_math pre ^ "} skip {" ^ string_of_math post ^ "}"
  | Print (a, (pre, post)) -> "{" ^ string_of_math pre ^ "} print(" ^ string_of_aExp a ^ ") {" ^ string_of_math post ^ "}"
  | Eval (l, a, (pre, post)) -> "{" ^ string_of_math pre ^ "} " ^ l ^ " := " ^ string_of_aExp a ^ " {" ^ string_of_math post ^ "}"
  | Sequence (c1, c2, (pre, post)) -> "{" ^ string_of_math pre ^ "} " ^ string_of_com c1 ^ "; " ^ string_of_com c2 ^ " {" ^ string_of_math post ^ "}"
  | Conditional (b, c1, c2, (pre, post)) -> "{" ^ string_of_math pre ^ "} if " ^ string_of_bExp b ^ " then " ^ string_of_com c1 ^ " else " ^ string_of_com c2 ^ " {" ^ string_of_math post ^ "}"
  | While (b, c, (pre, inv, post)) -> "{" ^ string_of_math pre ^ "} while " ^ string_of_bExp b ^ " do " ^ string_of_com c ^ " {" ^ string_of_math inv ^ "} {" ^ string_of_math post ^ "}"
  end ^ ")"
let string_of_prog (Prog (c, _, _, _)) = string_of_com c