import std/strformat
import std/random
import math
import std/logging

type
    Model* = tuple
        names: seq[string]
        c: seq[float]
        s: seq[float]
        x: seq[float]

func range(m: Model): HSlice[int, int] = return low(m.c)..high(m.c)

func meanPolicy*(m: Model): float =
    var w = 0.0
    for i in m.range:
        result += m.s[i]*m.c[i]*m.x[i]
        w += m.s[i]*m.c[i]
    return result/w


proc alliances(m: Model, a: int, b: int, xb_new: float): tuple[forA: float, forB: float] =
    for i in m.range:
        let da = abs(m.x[i]-m.x[a])
        let db = abs(m.x[i]-m.x[b])
        if abs(m.x[i]-xb_new) < abs(m.x[i]-m.x[b]):
            result.forA += m.s[i]*m.c[i] * db/(1+da)
        else:
            result.forB += m.s[i]*m.c[i] * da/(1+db)


proc dU(m: Model, a: int, b: int, x_b_new: float, sec: float = 1.0): float =
    let d = m.s[a]*m.s[b]*m.c[b]*(abs(m.x[b]-m.x[a]) - abs(x_b_new-m.x[a]))
    result = d


proc contest*(m: var Model, a: int, b: int) =
    if abs(m.x[a]-m.x[b]) < 0.001:
        return

    let n_a = m.names[a]
    let n_b = m.names[b]

    info(fmt"CONTEST {n_a}({m.x[a]:.3f}) vs {n_b}({m.x[b]:.3f})")

    let allies = m.alliances(a, b, m.x[a])
    let x_a_fail = m.x[a] + (m.x[b]-m.x[a])*allies.forB/(allies.forA+allies.forB)
    let x_b_fail = m.x[b] + (m.x[a]-m.x[b])*allies.forA/(allies.forA+allies.forB)
    let p_ab = allies.forA^2 / (allies.forA^2 + allies.forB^2)

    let u_a_win = m.dU(a, b, x_b_fail)
    let u_a_lose = m.dU(a, a, x_a_fail)
    let E_a_clash = p_ab * u_a_win + (1.0-p_ab)*u_a_lose

    let u_b_win = m.dU(b, a, x_a_fail)
    let u_b_lose = m.dU(b, b, x_b_fail)
    let E_b_clash = (1-p_ab)*u_b_win + p_ab*u_b_lose

    let x_b_comp = (m.x[b]+x_b_fail)/2
    let E_b_comp = m.dU(b, b, x_b_comp)
    let E_a_comp = m.dU(a, b, x_b_comp)

    let p_b_move = 1-m.s[b];
    let x_b_opt = m.meanPolicy()
    let E_a_sq = p_b_move*m.dU(a, b, x_b_opt)
    let E_a_chall = if E_b_clash < E_b_comp: E_a_comp else: E_a_clash

    info(fmt"  A: U={u_a_win:.2f}/{u_a_lose:.2f}, B: U={u_b_win:.2f}/{u_b_lose:.2f}")
    info(fmt"  P_ab={p_ab:.2f}, chall: {E_a_chall:.4f}, clash: {E_a_clash:.4f}/{E_b_clash:.4f}, sq: {E_a_sq:.4f}, comp: {E_a_comp:.4f}/{E_b_comp:.4f}")

    if E_a_chall > E_a_sq:
        info(fmt"  {n_a}({m.x[a]:.3f}) challenges {n_b}({m.x[b]:.3f})")
        if E_b_clash < E_b_comp:
            m.x[b] = x_b_comp
            info(fmt"    {n_b} compromises: x_{n_b} -> {m.x[b]:.3f}")
        else:
            info(fmt"    {n_b} resists")
            if rand(1.0) < p_ab:
                m.x[b] = x_b_fail
                info(fmt"        {n_a} wins: x_{n_b} -> {m.x[b]:.3f}")
            else:
                m.x[a] = x_a_fail
                info(fmt"        {n_a} loses: x_{n_a} -> {m.x[a]:.3f}")
    else:
        info(fmt"  {n_a} does not challenge {n_b}")
        if rand(1.0) < p_b_move:
            m.x[b] += (x_b_opt-m.x[b])*rand(1.0)
            info(fmt"    {n_b} moves: x_b -> {m.x[b]:.3f}")
        else:
            info(fmt"    {n_b} stays put")



proc simFull*(model: var Model, tMax: int = 100) =
    var pairs = newSeqOfCap[(int,int)](model.c.len^2)
    for a in model.range:
        for b in model.range:
            pairs.add((a,b))

    var k = 3
    for t in 1..tMax:
        shuffle(pairs)

        var m = model.meanPolicy()
        for (a,b) in pairs:
            if a == b or model.s[a] == 0 or model.s[b] == 0:
                continue
            model.contest(a, b)

        let m2 = model.meanPolicy()
        info(fmt"meanPolicy: {t} {k} {m2}")
        if m == m2:
            k -= 1
            if k == 0:
                break
        else:
            k = 5
        m = m2


proc simRandom*(m: var Model) =
    for t in 1..1000:
        let a = rand(m.range)
        let b = rand(m.range)
        if a == b:
            continue
        m.contest(a, b)
        info(fmt"meanPolicy: {t} {m.meanPolicy()}")