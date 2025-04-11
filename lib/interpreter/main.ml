open Core.Ast
open Eval
open Memory

let parse (s : string) : prog =
  let lexbuf = Lexing.from_string s in
  let ast = Core.Parser.main Core.Lexer.read lexbuf in
  ast

let compile file_name =
  (* open_in_bin works correctly on Unix and Windows *)
  let ch = open_in_bin file_name in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;

  parse s

let runProg (Prog (c, _, _, entries)) = 
  let start_env = List.fold_left (
    fun env loc -> 
      Printf.printf "Enter %s : " loc;
      Stdlib.flush stdout;
      let result = Scanf.scanf "%d\n" (fun x -> x) in
      update_env loc (result) env
  ) empty_env entries in
  print_endline "---------------EXECUTION------------------";
  let env = execute c start_env in
  print_endline "\n------------------END---------------------";
  print_endline "Program terminated successfully !";
  print_endline "Final environment:";
  print_string (string_of_env env)