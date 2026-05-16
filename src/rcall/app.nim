# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import std/syncio
import std/os
import std/sets
import std/algorithm
import rcall/cli
import rcall/types
import rcall/walker
import rcall/output

proc runApp*(args: seq[string], outStream: File = stdout, errStream: File = stderr): int =
  let parsed = parseCli(args)
  if not parsed.ok:
    writeError(errStream, parsed.err)
    writeHelp(errStream, "rcall")
    return 2

  let opts = parsed.options
  if opts.showHelp:
    writeHelp(outStream, opts.programName)
    return 0

  var allMatches: seq[MatchEntry] = @[]
  var seen: HashSet[(string, int, MatchKind)]
  var warnings: seq[string] = @[]
  for root in opts.roots:
    let matches = collectMatches(
      opts.term,
      root,
      opts.ignoreDirs,
      opts.useDefaultIgnore,
      opts.ignoreCase,
      warnings
    )
    for entry in matches:
      let key = (entry.path, entry.line, entry.kind)
      if key notin seen:
        seen.incl(key)
        allMatches.add(entry)

  for warning in warnings:
    writeWarning(errStream, warning)

  allMatches.sort(proc(a, b: MatchEntry): int =
    let pathCmp = system.cmp(a.path, b.path)
    if pathCmp != 0:
      return pathCmp
    let lineCmp = system.cmp(a.line, b.line)
    if lineCmp != 0:
      return lineCmp
    return system.cmp($a.kind, $b.kind)
  )

  writeMatches(outStream, allMatches)
  if allMatches.len == 0:
    return 1
  return 0

proc runMain*(): int =
  runApp(commandLineParams())
