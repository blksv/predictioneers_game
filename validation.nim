import sequtils
import std/sugar
import std/algorithm
import std/strformat
import std/parsecsv
import std/strutils

import model

proc toFile[T](s: seq[T], name: string) =
    var f: File
    discard f.open(name, fmWrite)
    for v in s:
        f.writeLine(v)
    f.close()


var csv: CsvParser
csv.open("deu3.csv", separator='\t', quote='"')
csv.readHeaderRow()
# echo csv.headers[8]      # voting type
# echo csv.headers[13..42] # positions
# echo csv.headers[43..72] # salience
# echo csv.headers[74]     # outcome

let names = toSeq(csv.headers[13..42]).map(v => v[1..^1])

discard csv.readRow()
let c = block:
    let gdp = toSeq(csv.row[13..42]).map(v => parseFloat(v))
    gdp.map(v => v / max(gdp))


const nRuns = 10
var num = 0
var hits = 0
var err = 0.0
var errors: seq[float] = @[]
while csv.readRow():
    if csv.row[74] == "":
        continue
    num += 1
    let initialModel: Model = (
        names: names,
        c: c,
        s: toSeq(csv.row[43..72]).map(v => (if v == "": 0.0 else: parseFloat(v)/100.0)),
        x: toSeq(csv.row[13..42]).map(v => (if v == "": 0.0 else: parseFloat(v)/100.0)),
    )
    let outcome = parseFloat(csv.row[74])/100.0
    let dichotomy = initialModel.x.filter(v => v != 0 and v != 1.0).len == 0 and (outcome in [0.0, 1.0])
    var results = newSeqOfCap[float](nRuns)
    var s = 0.0
    for k in 1..nRuns:
        var model = initialModel
        model.sim_full()
        let m = model.meanPolicy()
        results.add(m)
        s += m
        stderr.writeLine(fmt"{num}: {k}/{nRuns} {m:.3f} avg {s/float(k):.3f} actual {outcome} hits {hits/num:.3f} err {(err/float(num)):.3f}")
    results.sort()
    let median = results[int(nRuns/2)]
    err += abs(median-outcome)
    errors.add(abs(median-outcome))
    if abs(median-outcome) < (if dichotomy: 0.5 else: 0.1):
        hits += 1
    stderr.writeLine(fmt"!!! {num}: avg {s/float(nRuns)} median {results[int(nRuns/2)]} actual {outcome}")

errors.sort()
errors.toFile("errors.dat")
stderr.writeLine(fmt"median error: {errors[int(num/2)]}")
