import sequtils
import std/sugar
import std/algorithm
import std/strformat
import std/strutils
import std/syncio
import std/parseopt
import std/logging

import model

proc `/`(s: seq[float], v: float): seq[float] = return s.mapIt(it / v)

var logFile = ""
var inputFile = ""
var resultsFile = ""
var nRuns = 1

for (kind, key, val) in getopt():
    case kind
        of cmdArgument:
            inputFile = key
        of cmdLongOption, cmdShortOption:
            case key
                of "log": logFile = val
                of "results": resultsFile = val
                of "runs", "r": nRuns = parseInt(val)
        of cmdEnd: assert(false)

if inputFile == "":
    echo "Usage: main [--runs|-r:nRuns] [--log:logFile] [--results:resultsFile] inputFile"
    quit()

if logFile != "":
    var fileLog = newFileLogger(logFile, fmtStr="")
    addHandler(fileLog)


var m: Model
for ln in lines(inputFile):
    if ln.startsWith("#"):
        continue
    let actor = ln.split(" ").filter(v => v != "")
    m.names.add(actor[0])
    m.x.add(parseFloat(actor[1]))
    m.c.add(parseFloat(actor[2]))
    m.s.add(parseFloat(actor[3]))

let xScale = max(m.x)
m.x = m.x / xScale
m.c = m.c / max(m.c)
m.s = m.s / max(m.s)

var s = 0.0
var results = newSeqOfCap[float](nRuns)
for k in 1..nRuns:
    var model = m
    model.sim_full()
    let m = model.meanPolicy()*xScale
    results.add(m)
    s += m
    stderr.writeLine(fmt"{k}/{nRuns} {m:.3f}")

results.sort()
stderr.writeLine(fmt"RESULT: mean {s/float(nRuns):.3f} median {results[int(nRuns/2)]:.3f}")

if resultsFile != "":
    var f: File
    assert(f.open(resultsFile, fmWrite))
    for v in results:
        f.writeLine(v)
    f.close()
