open Core.Ast
open Simplifier

let rec verif_hoares com pre post = 
  Mand (
    Mand (
      Mimplies (pre, get_pre com),
      Mimplies (get_post com, post)
    ),
    match com with
    |Skip (pre, post) -> Mimplies (pre, post)
    |Print (_, (pre, post)) -> Mimplies (pre, post)

    |Eval (loc, arith, (pre, post)) -> 
      let wp = subMath loc arith post in
      Mimplies (pre, wp)

    |Sequence (c1, c2, (pre, post)) ->
      let cond1 = verif_hoares c1 pre (get_pre c2)
      and cond2 = verif_hoares c2 (get_pre c2) post in
      Mand (cond1, cond2)
    
    |Conditional (b, c1, c2, (pre, post)) ->
      let mCond = math_of_bool b in
      let cond1 = verif_hoares c1 (Mand (pre, mCond)) post
      and cond2 = verif_hoares c2 (Mand (pre, Mnot mCond)) post in
      Mand (cond1, cond2)
    
    |While (b, c, (pre, _ , post)) -> 
      let bCond = math_of_bool b in
      Mand (
        verif_hoares c (Mand (pre, bCond)) pre,
        Mimplies (Mand (pre, Mnot bCond), post)
      )
  )

let rec wp com post = match com with
  |Skip (_, _) -> post
  |Print (_, (_, _)) -> post

  |Eval (loc, arith, (_, _)) -> subMath loc arith post
  
  |Sequence (c1, c2, (_, _)) -> 
    let wp2 = wp c2 post in
    wp c1 wp2
  
  |Conditional (b, c1, c2, (_, _)) ->
    let mCond = math_of_bool b in
    Mand (Mimplies (mCond, wp c1 post), Mimplies (Mnot mCond, wp c2 post))
  
  |While (b, c, (_, inv, _)) ->
    let wp = wp c inv
    and mCond = math_of_bool b in
    Mand (inv, Mand (Mimplies (Mand (mCond, inv), wp), Mimplies (Mand (Mnot mCond, post), post)))

let rec fill_hoares com post = match com with
  |Skip (_, _) -> Skip (post, post)
  |Print (arith, (_, _)) -> Print (arith, (post, post))

  |Eval (loc, arith, (_, _)) -> 
    let wp = subMath loc arith post in
    Eval (loc, arith, (wp, post))
  |Sequence (c1, c2, (_, _)) -> 
    let filled_c2 = fill_hoares c2 post in
    let filled_c1 = fill_hoares c1 (get_pre filled_c2) in
    Sequence (filled_c1, filled_c2, ((get_pre filled_c1), post))
  
  |Conditional (b, c1, c2, (_, _)) ->
    let filled_c2 = fill_hoares c2 post
    and filled_c1 = fill_hoares c1 post
    and mCond = math_of_bool b in
    let wp = Mand (Mimplies (mCond, (get_pre filled_c1)), Mimplies (Mnot mCond, (get_pre filled_c2))) in
    Conditional (b, filled_c1, filled_c2, (wp, post))
  
  |While (b, c, (_, inv, _)) ->
    let filled_c = fill_hoares c inv
    and mCond = math_of_bool b in
    let wp = Mand (Mimplies (Mand (inv, mCond), (get_pre filled_c)), Mimplies (Mand (inv, Mnot mCond), post)) in
    While (b, filled_c, (wp, inv, post))