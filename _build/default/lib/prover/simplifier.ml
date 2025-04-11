open Core.Ast

let rec subArith s expr arith = match arith with
  |Num i -> Num i
  |Loc l when l = s -> expr
  |Loc l -> Loc l

  |Plus (a1, a2) -> Plus (subArith s expr a1, subArith s expr a2)
  |Minus (a1, a2) -> Minus (subArith s expr a1, subArith s expr a2)
  |Mult (a1, a2) -> Mult (subArith s expr a1, subArith s expr a2)
let rec subMath loc expr m = match m with
  |Mtrue -> Mtrue
  |Mfalse -> Mfalse

  |Mequals (a1, a2) -> Mequals (subArith loc expr a1, subArith loc expr a2)
  |Mleq (a1, a2) -> Mleq (subArith loc expr a1, subArith loc expr a2)
  |Mless (a1, a2) -> Mless (subArith loc expr a1, subArith loc expr a2)
  |Mgre (a1, a2) -> Mgre (subArith loc expr a1, subArith loc expr a2)
  |Mgeq (a1, a2) -> Mgeq (subArith loc expr a1, subArith loc expr a2)

  |Mand (m1, m2) -> Mand (subMath loc expr m1, subMath loc expr m2)
  |Mor (m1, m2) -> Mor (subMath loc expr m1, subMath loc expr m2)
  |Mnot m -> Mnot (subMath loc expr m)
  |Mimplies (m1, m2) -> Mimplies (subMath loc expr m1, subMath loc expr m2)
  |Mforall (loc, m) -> Mforall (loc, subMath loc expr m)
  |Mexists (loc, m) -> Mexists (loc, subMath loc expr m)

let get_pre = function
  | Skip (pre, _) -> pre
  | Print (_, (pre, _)) -> pre
  | Eval (_, _, (pre, _)) -> pre
  | Sequence (_, _, (pre, _)) -> pre
  | Conditional (_, _, _, (pre, _)) -> pre
  | While (_, _, (pre, _, _)) -> pre
let get_post = function
  | Skip (_, post) -> post
  | Print (_, (_, post)) -> post
  | Eval (_, _, (_, post)) -> post
  | Sequence (_, _, (_, post)) -> post
  | Conditional (_, _, _, (_, post)) -> post
  | While (_, _, (_, _, post)) -> post
let set_post com post = match com with
  | Skip (pre, _) -> Skip (pre, post)
  | Print (arith, (pre, _)) -> Print (arith, (pre, post))
  | Eval (loc, arith, (pre, _)) -> Eval (loc, arith, (pre, post))
  | Sequence (c1, c2, (pre, _)) -> Sequence (c1, c2, (pre, post))
  | Conditional (b, c1, c2, (pre, _)) -> Conditional (b, c1, c2, (pre, post))
  | While (b, c, (pre, inv, _)) -> While (b, c, (pre, inv, post))

let rec simplify_arith = function
  |Num i -> Num i
  |Loc l -> Loc l

  |Plus (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) -> Num (i + j)
    |(Num 0, a) -> a
    |(a, Num 0) -> a
    |(a1, a2) -> Plus (a1, a2)
  end
  |Minus (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with 
    |(Num i, Num j) -> Num (i - j)
    |(a, Num 0) -> a
    |(a1, a2) when a1 = a2 -> Num 0
    |(a1, a2) -> Minus (a1, a2)
  end
  |Mult (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) -> Num (i * j)
    |(Num 0, _) -> Num 0
    |(_, Num 0) -> Num 0
    |(Num 1, a) -> a
    |(a, Num 1) -> a
    |(a1, a2) -> Mult (a1, a2)
  end
let rec simplify_expression = function
  |Mtrue -> Mtrue
  |Mfalse -> Mfalse

  |Mequals (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) when i = j -> Mtrue
    |(Num _, Num _) -> Mfalse
    |(a1, a2) when a1 = a2 -> Mtrue
    |(a1, a2) -> Mequals (a1, a2)
  end

  |Mleq (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) when i <= j -> Mtrue
    |(Num _, Num _) -> Mfalse
    |(a1, a2) when a1 = a2 -> Mtrue
    |(a1, a2) -> Mleq (a1, a2)
  end
  |Mgeq (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) when i <= j -> Mtrue
    |(Num _, Num _) -> Mfalse
    |(a1, a2) when a1 = a2 -> Mtrue
    |(a1, a2) -> Mleq (a1, a2)
  end

  |Mless (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) when i < j -> Mtrue
    |(Num _, Num _) -> Mfalse
    |(a1, a2) when a1 = a2 -> Mfalse
    |(a1, a2) -> Mless (a1, a2)
  end
  |Mgre (a1, a2) -> begin
    match (simplify_arith a1, simplify_arith a2) with
    |(Num i, Num j) when i < j -> Mtrue
    |(Num _, Num _) -> Mfalse
    |(a1, a2) when a1 = a2 -> Mfalse
    |(a1, a2) -> Mgre (a1, a2)
  end

  |Mand (m1, m2) -> begin
    match (simplify_expression m1, simplify_expression m2) with
    |Mtrue, m -> m
    |m, Mtrue -> m
    |Mfalse, _ -> Mfalse
    |_, Mfalse -> Mfalse
    |m1, m2 when m1 = m2 -> m1
    |m1, m2 -> Mand (m1, m2)
  end

  |Mor (m1, m2) -> begin 
    match (simplify_expression m1, simplify_expression m2) with
    |Mtrue, _ -> Mtrue
    |_, Mtrue -> Mtrue
    |Mfalse, m -> m
    |m, Mfalse -> m
    |m1, m2 when m1 = m2 -> m1
    |m1, m2 -> Mor (m1, m2)
  end

  |Mnot m -> begin
    match (simplify_expression m) with
    |Mfalse -> Mtrue
    |Mtrue -> Mfalse
    |m -> Mnot m
  end

  |Mimplies (m1, m2) -> begin 
    match (simplify_expression m1, simplify_expression m2) with
    |(Mfalse, _) -> Mtrue
    |(_, Mtrue) -> Mtrue
    |(m1, m2) when m1 = m2 -> Mtrue
    |(m1, m2) -> Mimplies (m1, m2)
  end

  |Mforall (s, m) -> Mforall (s, simplify_expression m)
  |Mexists (s, m) -> Mexists (s, simplify_expression m)
