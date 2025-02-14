import std/[assertions, parseopt, strutils]

type Params* = object
  dac_id*: int
  adc_id*: int
  osc_addr*: string
  arena_mb*: int # Maximum size of session memory in MB.

proc get_params*(): Params =
  result.dac_id = -1
  result.adc_id = -1
  result.osc_addr = "7770"
  result.arena_mb = 512

  for kind, key, val in getopt():
    case kind
    of cmdArgument: discard
    of cmdLongOption, cmdShortOption:
      case key
      of "dac": result.dac_id = val.parse_int
      of "adc": result.adc_id = val.parse_int
      of "osc": result.osc_addr = val
      of "arena": result.arena_mb = val.parse_int
      else: discard
    of cmdEnd: assert(false) # cannot happen
