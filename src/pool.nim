## Pooling makes state management easier when you don't need to micromanage state
## continuity.

import
  dsp/[
    frame, delays, envelopes, events, filters, metro, modules, noise, osc, soundpipe
  ]

const
  medium_pool = 0x40
  small_pool = 0x10

type
  Data = object
    adsr: array[medium_pool, ADSR]
    autowah: array[small_pool, AutoWah]
    bigverb: array[small_pool, BigVerb]
    biquad: array[medium_pool, BiQuad]
    bitcrush: array[small_pool, BitCrush]
    blsaw: array[medium_pool, BlSaw]
    blsquare: array[medium_pool, BlSquare]
    bltriangle: array[medium_pool, BlTriangle]
    brown_noise: array[medium_pool, BrownNoise]
    chaos_noise: array[medium_pool, ChaosNoise]
    clock: array[small_pool, Clock]
    compressor: array[small_pool, Compressor]
    delay: array[medium_pool, Delay[1.seconds]]
    diode: array[medium_pool, Diode]
    fm: array[medium_pool, FM]
    jcrev: array[small_pool, JCRev]
    long_delay: array[small_pool, Delay[30.seconds]]
    maygate: array[medium_pool, MayGate]
    metro: array[medium_pool, Metro]
    peaklim: array[medium_pool, PeakLimiter]
    pink_noise: array[medium_pool, PinkNoise]
    rline: array[medium_pool, RLine]
    sample: array[medium_pool, float]
    sequence: array[medium_pool, int]
    transition: array[medium_pool, Transition]
  Index = object
    sample,
      adsr,
      autowah,
      bigverb,
      biquad,
      bitcrush,
      blsaw,
      blsquare,
      bltriangle,
      brown_noise,
      chaos_noise,
      clock,
      compressor,
      delay,
      diode,
      fm,
      jcrev,
      long_delay,
      maygate,
      metro,
      peaklim,
      pink_noise,
      rline,
      sequence,
      transition : int
  Pool* = object
    data: Data
    index: Index

var pool: ptr Pool

proc init*(s: var Pool) =
  pool = s.addr
  pool.index.addr.zero_mem(Index.size_of)

template def0(op, t) =
  proc op*(): float =
    result = op(pool.data.t[pool.index.t])
    pool.index.t += 1
  lift0(op)

template def0(op) = def0(op, op)

template def1(op, t) =
  proc op*(a: float): float =
    result = op(a, pool.data.t[pool.index.t])
    pool.index.t += 1
  lift1(op)

template def1(op) = def1(op, op)

template def2(op, t) =
  proc op*(a, b: float): float =
    result = op(a, b, pool.data.t[pool.index.t])
    pool.index.t += 1
  lift2(op)

template def2(op) = def2(op, op)

template def3(op, t) =
  proc op*(a, b, c: float): float =
    result = op(a, b, c, pool.data.t[pool.index.t])
    pool.index.t += 1
  lift3(op)

template def3(op) = def3(op, op)

template def4(op) =
  proc op*(a, b, c, d: float): float =
    result = op(a, b, c, d, pool.data.op[pool.index.op])
    pool.index.op += 1
  lift4(op)

template def5(op) =
  proc op*(a, b, c, d, e: float): float =
    result = op(a, b, c, d, e, pool.data.op[pool.index.op])
    pool.index.op += 1
  lift5(op)

def0(brown, brown_noise)
def0(pink_noise)
def1(blsaw)
def1(bltriangle)
def1(dmetro, metro)
def1(jcrev)
def1(osc, sample)
def1(metro)
def1(rline)
def1(saw, sample)
def1(tri, sample)
def2(blsquare)
def2(chaos_noise)
def2(impulse, sample)
def2(maygate)
def2(phsclk, sample)
def2(square, sample)
def2(tline, transition)
def2(tquad, transition)
def3(bitcrush)
def3(bqbpf, biquad)
def3(bqhpf, biquad)
def3(bqlpf, biquad)
def3(bqnotch, biquad)
def3(diode)
def3(fm)
def3(gaussian, sample)
def4(autowah)
def4(peaklim)
def5(adsr)
def5(compressor)

proc bigverb*(x, feedback, lpfreq: Frame): Frame =
  result = bigverb(x, feedback, lpfreq, pool.data.bigverb[pool.index.bigverb])
  pool.index.bigverb += 1

proc delay*(x, dt: float): float =
  result = delay[1.seconds](x, dt, pool.data.delay[pool.index.delay])
  pool.index.delay += 1
lift2(delay)

proc fb*(x, dt, k: float): float =
  result = fb[1.seconds](x, dt, k, pool.data.delay[pool.index.delay])
  pool.index.delay += 1
lift3(fb)

proc long_delay*(x, dt: float): float =
  result = delay[30.seconds](x, dt, pool.data.long_delay[pool.index.long_delay])
  pool.index.long_delay += 1
lift2(long_delay)

proc long_fb*(x, dt, k: float): float =
  result = fb[30.seconds](x, dt, k, pool.data.long_delay[pool.index.long_delay])
  pool.index.long_delay += 1
lift3(long_fb)

proc sequence*(seq: openArray[float], t: float): float =
  result = sequence(seq, t, pool.data.sequence[pool.index.sequence])
  pool.index.sequence += 1

proc sequence*(seq: openArray[Frame], t: Frame): Frame =
  for i in 0..<CHANNELS:
    result[i] = sequence(seq[i], t[i])
