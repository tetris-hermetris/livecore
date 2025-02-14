## Fundamental audio frame constants, types and operations.

import atomics, math

const SAMPLE_RATE_INT* = 48000

const
  CHANNELS* = 2
  SAMPLE_RATE* = SAMPLE_RATE_INT.float
  SAMPLE_PERIOD* = 1.0 / SAMPLE_RATE
  SAMPLE_ANGULAR_PERIOD* = TAU * SAMPLE_PERIOD

proc seconds*(t: Natural): Natural =
  t * SAMPLE_RATE_INT

proc seconds*(t: float): float =
  t * SAMPLE_RATE

type
  Frame* = array[CHANNELS, float]
  Controllers* = array[0x100, Atomic[float]]
  Notes* = array[0x10, Atomic[uint16]]

converter to_frame*(x: float): Frame =
  for i in 0..<CHANNELS:
    result[i] = x

converter to_frames*[N](xs: array[N, float]): array[N, Frame] =
  for i in xs.low..xs.high:
    result[i] = xs[i].to_frame

template lift0*(op) =
  proc `op stereo`*(): Frame =
    for i in 0..<CHANNELS:
      result[i] = op()

template lift1*(op) =
  proc op*(a: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i])

template lift2*(op) =
  proc op*(a, b: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i])

template lift3*(op) =
  proc op*(a, b, c: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i])

template lift4*(op) =
  proc op*(a, b, c, d: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i], d[i])

template lift5*(op) =
  proc op*(a, b, c, d, e: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i], d[i], e[i])

template lift1_as*(op, name) =
  proc name*(a: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i])

template lift2_as*(op, name) =
  proc name*(a, b: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i])

template lift3_as*(op, name) =
  proc name*(a, b, c: Frame): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i])

template lift0*(op: untyped, T: typedesc) =
  proc op*(s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(s[i])

template lift1*(op: untyped, T: typedesc) =
  proc op*(a: Frame, s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], s[i])

template lift2*(op: untyped, T: typedesc) =
  proc op*(a, b: Frame, s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], s[i])

template lift3*(op: untyped, T: typedesc) =
  proc op*(a, b, c: Frame, s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i], s[i])

template lift4*(op: untyped, T: typedesc) =
  proc op*(a, b, c, d: Frame, s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i], d[i], s[i])

template lift5*(op: untyped, T: typedesc) =
  proc op*(a, b, c, d, e: Frame, s: var array[CHANNELS, T]): Frame =
    for i in 0..<CHANNELS:
      result[i] = op(a[i], b[i], c[i], d[i], e[i], s[i])

proc safe_div(a: float, b: float): float =
  if unlikely(b == 0.0):
    result = 0.0
  else:
    result = a / b

proc safe_mod(a: float, b: float): float =
  if unlikely(b == 0.0):
    result = 0.0
  else:
    result = a mod b

proc mul*(a, b: float): float = a * b
proc add*(a, b: float): float = a + b
proc sub*(a, b: float): float = a - b
proc neg*(a: float): float = -a

lift2(`*`)
lift2(mul)

lift2(`+`)
lift2(add)

lift1(`-`)
lift1(neg)
lift2(`-`)
lift2(sub)

lift2_as(safe_div, `/`)
lift2_as(safe_div, `div`)

lift2_as(safe_mod, `%`)
lift2_as(safe_mod, `mod`)

lift1(sin)
lift1(cos)
lift1(tan)
lift1(ceil)
lift1(floor)
lift1(round)
lift1(log2)
lift1(log10)
lift2(pow)
lift1(sqrt)
lift1(exp)

proc sinc*(x: float): float =
  if unlikely(x == 0.0): 1.0 else: sin(x)/x

lift1(sinc)

proc project*(x, a, b, c, d: float): float = (d - c) * (x - a) / (b - a) + c
proc scale*(x, a, b: float): float = x.project(0.0, 1.0, a, b)
proc biscale*(x, a, b: float): float = x.project(-1.0, 1.0, a, b)
proc circle*(x: float): float = x.biscale(-PI, PI)
proc uni*(x: float): float = x.biscale(0.0, 1.0)
proc bi*(x: float): float = x.scale(-1.0, 1.0)

proc db2amp*(x: float): float = 20.0 * x.log10
proc amp2db*(x: float): float = 10.0.pow(x / 20.0)

proc freq2midi*(x: float): float = 69.0 + 12.0 * log2(x / 440.0)
proc midi2freq*(x: float): float = 440.0 * 2.0.pow((x - 69.0) / 12.0)

proc quantize*(x, step: float): float = (x / step).round * step
proc step*(x, step: float): float = x.quantize(step)

proc recip*(x: float): float = 1.0 / x

lift5(project)
lift3(scale)
lift3(biscale)
lift1(circle)
lift1(uni)
lift1(bi)
lift1(db2amp)
lift1(amp2db)
lift1(freq2midi)
lift1(midi2freq)
lift2(quantize)
lift2(step)
lift1(recip)

proc `@`*(x: float): float = midi2freq(x)
lift1(`@`)

proc `%%`*(x, y: float): float = quantize(x, y)
lift2(`%%`)

const silence* = 0.0
