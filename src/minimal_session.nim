## Where the creativity blossoms.

import dsp/frame

type State* = object

proc control*(s: var State, cc: var Controllers, n: var Notes,
    frame_count: int) {.nimcall, exportc, dynlib.} =
  discard

proc audio*(s: var State, cc: var Controllers, n: var Notes,
    input: Frame): Frame {.nimcall, exportc, dynlib.} =
  discard

proc load*(s: var State) {.nimcall, exportc, dynlib.} =
  discard

proc unload*(s: var State) {.nimcall, exportc, dynlib.} =
  discard
