(* File memory.ml *)
module StringMap = Map.Make(String)
module IntMap = Map.Make(Int)

type var = int

type env = var StringMap.t

(* Basic functions *)
let empty_env : env = StringMap.empty

let lookup loc (e: env) = 
  try 
    StringMap.find loc e 
  with Not_found -> failwith ("Variable " ^ loc ^ " not found")

let update_env loc value (e: env) = StringMap.add loc value e

let string_of_env (e: env) = 
  (StringMap.fold (fun k v acc -> acc ^ k ^ " -> " ^ string_of_int v ^ "\n") e "")