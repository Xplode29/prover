open Interp.Main
open Stdlib
open Core.Ast

let () = 
  if Array.length Sys.argv <> 2 then failwith "Usage: ./main <filename>";
  let (Prog (c, pre, post, entries)) = compile (Sys.argv.(1)) in

  (* runProg (Prog (c, pre, post, entries)); *)

  let weakest = Prover.Simplifier.simplify_expression (Prover.Hoares.wp c post) in
  Printf.printf "Precondition: %s\n" (string_of_math pre);
  Printf.printf "Postcondition: %s\n" (string_of_math post);
  Printf.printf "Weakest precondition: %s\n" (string_of_math weakest);

  Prover.Z3api.send_to_z3 (
    Printf.sprintf "(assert (forall (%s) \n %s\n))\n(check-sat)\n" 
      (List.fold_left (fun acc loc -> "(" ^ loc ^ " Int) " ^ acc) "" entries) 
      (Prover.Z3api.z3_of_math (Mimplies (pre, weakest)))
  );