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

  print_endline "\n---------------CORRECTION-----------------";
  print_endline (Prover.Z3api.send_to_z3 pre weakest entries);
  print_endline "------------------END---------------------\n";