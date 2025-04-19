open Core.Ast

type smt_result =
  | Unsat of string option
  | Sat of (string * int) list
  | Unknown

let parse_smt_output output =
  let lines =
    output
    |> String.split_on_char '\n'
    |> List.map String.trim
    |> List.filter (fun s -> s <> "")
  in
  match lines with
    |"unsat" :: rest ->
      let error_msg = List.find_opt (fun line -> String.starts_with ~prefix:"(error " line) rest
      in begin match error_msg with
        |Some line ->
          let parts = String.split_on_char '"' line in
          if List.length parts >= 2 then
            Unsat (Some (List.nth parts 1))
          else
            Unsat (Some line)  (* Fallback if malformed error *)
        |None -> Unsat None
      end
    |"sat" :: rest ->
      let content = String.concat " " (List.map String.trim rest) in
      let re = Str.regexp "define-fun[ \t]+\\([^ \t]+\\)[ \t]*()[ \t]*Int[ \t]*\\([0-9]+\\)" in
      let pairs = ref [] in
      let pos = ref 0 in
      begin try
          while true do
            ignore (Str.search_forward re content !pos);
            let name = Str.matched_group 1 content in
            let value = int_of_string (Str.matched_group 2 content) in
            pairs := (name, value) :: !pairs;
            pos := Str.match_end ()
          done;
          assert false  (* Unreachable *)
        with Not_found ->
          Sat (List.rev !pairs)
      end
  | _ -> Unknown

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

let send_to_z3 pre weakest entries = 
  (* Convert entries in exists not *)
  let message = 
    (List.fold_left (fun acc loc -> Printf.sprintf "(declare-const %s Int)\n%s" loc acc) "" entries) ^
    Printf.sprintf "(assert %s)\n" (z3_of_math (Mnot (Mimplies (pre, weakest)))) ^
    "(check-sat)\n(get-model)" in
  
  let oc = open_out "z3_files/formula" in
  (* create or truncate file, return channel *)
  Printf.fprintf oc "%s\n" message;
  (* write something *)
  close_out oc;

  match parse_smt_output (run "z3 z3_files/formula") with
    |Unsat _ -> "Sat"
    |Sat model ->
      let model_str = List.fold_left (fun acc (var, value) -> Printf.sprintf "%s%s = %d\n" acc var value) "" model in
      Printf.sprintf "Unsat\nExample:\n%s" model_str
    |Unknown -> "Unknown"