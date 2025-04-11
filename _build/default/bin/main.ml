open Interp.Main
open Stdlib

let () = 
  if Array.length Sys.argv <> 2 then failwith "Usage: ./main <filename>";
  let (Prog (c, pre, post, entries)) = compile (Sys.argv.(1)) in

  runProg (Prog (c, pre, post, entries));

  let filled = Prover.Hoares.fill_hoares c post in
  let formula = Prover.Simplifier.simplify_expression (Prover.Hoares.verif_hoares filled pre post) in
  Prover.Z3api.send_to_z3 (
    (List.fold_left (fun acc loc -> "(declare-const " ^ loc ^ " Int)\n" ^ acc) "" entries) ^
    (Printf.sprintf "(assert %s)\n" (Prover.Z3api.z3_of_math formula)) ^
    "(check-sat)\n"
  );