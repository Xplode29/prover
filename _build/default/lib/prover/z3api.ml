open Core.Ast

let rec z3_of_aExp = function
  |Num n -> string_of_int n
  |Loc l -> l
  |Plus (a1, a2) -> Printf.sprintf "(+ %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Minus (a1, a2) -> Printf.sprintf "(- %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Mult (a1, a2) -> Printf.sprintf "(* %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)

let rec z3_of_math math = match math with
  |Mtrue -> "true"
  |Mfalse -> "false"

  |Mequals (a1, a2) -> Printf.sprintf "(= %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Mleq (a1, a2) -> Printf.sprintf "(<= %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Mless (a1, a2) -> Printf.sprintf "(< %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Mgre (a1, a2) -> Printf.sprintf "(> %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)
  |Mgeq (a1, a2) -> Printf.sprintf "(>= %s %s)" (z3_of_aExp a1) (z3_of_aExp a2)

  |Mand (m1, m2) -> Printf.sprintf "(and %s %s)" (z3_of_math m1) (z3_of_math m2)
  |Mor (m1, m2) -> Printf.sprintf "(or %s %s)" (z3_of_math m1) (z3_of_math m2)
  
  |Mnot m -> Printf.sprintf "(not %s)" (z3_of_math m)
  |Mimplies (m1, m2) -> Printf.sprintf "(=> %s %s)" (z3_of_math m1) (z3_of_math m2)

  |Mforall (s, m) -> Printf.sprintf "(forall (%s) %s)" s (z3_of_math m)
  |Mexists (s, m) -> Printf.sprintf "(exists (%s) %s)" s (z3_of_math m)

let run cmd =
  let inp = Unix.open_process_in cmd in
  let r = In_channel.input_all inp in
  In_channel.close inp; r

let send_to_z3 message = 
  print_endline "\n---------------CORRECTION-----------------";
  let oc = open_out "z3_files/formula" in
  (* create or truncate file, return channel *)
  Printf.fprintf oc "%s\n" message;
  (* write something *)
  close_out oc;

  let ps_output = run "z3 z3_files/formula" in
  print_endline ps_output;
  print_endline "------------------END---------------------\n";
