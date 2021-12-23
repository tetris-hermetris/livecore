## Anything reacting to triggers to produce something discrete/stable.
## This module needs a better name.

import frame, delays, random

proc sample_and_hold*(x, t: float, y: var float): float =
  ## Smooth version of sample & hold borrowed from Faust.
  result = (1.0 - t)*y + t*x
  y = result
lift2(sample_and_hold, float)

proc sample_and_hold_sharp*(x, t: float, y: var float): float =
  ## Good ol' sample & hold.
  result = if unlikely(t > 0.0): x else: y
  y = result
lift2(sample_and_hold_sharp, float)

proc sh*(x, t: float, y: var float): float = sample_and_hold(x, t, y)
lift2(sh, float)

proc timer*(s: var float): float =
  result = s
  s += SAMPLE_PERIOD
lift0(timer, float)

proc stopwatch*(t: float, s: var float): float =
  if unlikely(t > 0.0):
    s = 0.0
  s.timer
lift1(stopwatch, float)

type SH* = array[2, float]

proc sample_and_hold_start*(x, t: float, s: var SH): float =
  ## Sample when trigger crosses zero in positive direction.
  let p = t.prime(s[0])
  result = if unlikely(p <= 0.0 and t > 0.0): x else: s[1]
  s[1] = result
lift2(sample_and_hold_start, SH)

proc sample_and_hold_end*(x, t: float, s: var SH): float =
  ## Sample when trigger crosses zero in negative direction.
  let p = t.prime(s[0])
  result = if unlikely(p > 0.0 and t <= 0.0): x else: s[1]
  s[1] = result
lift2(sample_and_hold_end, SH)

proc sequence*(seq: openArray[float], t: float, s: var int): float =
  if unlikely(t > 0.0):
    s += 1
  if unlikely(s > seq.high):
    s = 0
  result = seq[s]

proc sequence*(seq: openArray[Frame], t: Frame, s: var array[CHANNELS, int]): Frame =
  for ch in 0..<CHANNELS:
    if unlikely(t[ch] > 0.0):
      s[ch] += 1
    if unlikely(s[ch] > seq.high):
      s[ch] = 0
    result[ch] = seq[s[ch]][ch]

type Choose* = int

proc choose*[T](xs: openArray[T], t: float, s: var Choose): T =
  if unlikely(t > 0.0):
    s = rand(xs.high)
  xs[s.min(xs.high)]

proc choose*[T](xs: openArray[T], t: float, ps: openArray[float],
    s: var Choose): T =
  if unlikely(t > 0.0):
    var r = rand(1.0)
    var z = 0.0
    for p in ps: z += p
    for i in 0..min(xs.high, ps.high):
      let p = ps[i] / z
      if p < r:
        r -= p
      else:
        s = i
        break
  xs[s.min(xs.high)]

proc maytrig*(t, p: float): float =
  if unlikely(t > 0.0):
    if rand(1.0) < p:
      return t
  return 0.0
lift2(maytrig)
