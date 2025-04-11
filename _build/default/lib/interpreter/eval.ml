(* File eval.ml *)
open Core.Ast
open Memory
open Stdlib

let rec evalAexp (arith : aExp) (env : env) : int = match arith with
  |Num n -> n
  |Loc s -> lookup s env
  
  |Plus (a1, a2) -> (evalAexp a1 env) + (evalAexp a2 env)
  |Minus (a1, a2) -> (evalAexp a1 env) - (evalAexp a2 env)
  |Mult (a1, a2) -> (evalAexp a1 env) * (evalAexp a2 env)

let rec evalBexp (bexp : bExp) (env : env) : bool = match bexp with
  |Bool b -> b
  |Not b -> not (evalBexp b env)
  |Or (b1, b2) ->
    let r1 = evalBexp b1 env in
    if r1 then true
    else evalBexp b2 env
  |And (b1, b2) ->
    let r1 = evalBexp b1 env in
    if not r1 then false
    else evalBexp b2 env
  |Equal (a1, a2) -> (evalAexp a1 env) = (evalAexp a2 env)
  |Leq (a1, a2) -> (evalAexp a1 env) <= (evalAexp a2 env)

let rec execute (c : com) (env : env) = match c with
  |Skip (_, _) -> env (* No changes *)
  |Eval (s, a, (_, _)) -> 
    let result = evalAexp a env in
    update_env s (result) env
  |Sequence (c1, c2, (_, _)) -> 
    let env_after_c1 = execute c1 env in
    execute c2 env_after_c1
  |Conditional (b, c1, c2, (_, _)) -> 
    if evalBexp b env then execute c1 env
    else execute c2 env
  |While (b, c, (_, _, _)) -> 
    let rec loop env = 
      if evalBexp b env then 
        loop (execute c env)
      else env
    in loop env
  |Print (a, (_, _)) -> 
    print_int (evalAexp a env);
    print_endline "";
    env (* No changes *)