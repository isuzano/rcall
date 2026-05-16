# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import rcall/types
import rcall/errors
import std/strutils

type
  CliParseResult* = object
    ok*: bool
    options*: CliOptions
    err*: AppError

proc success(options: CliOptions): CliParseResult =
  CliParseResult(ok: true, options: options)

proc failure(err: AppError): CliParseResult =
  CliParseResult(ok: false, err: err)

proc parseCli*(args: seq[string], programName = "rcall"): CliParseResult =
  if args.len == 0:
    return failure(usageError("missing TEXT"))

  if args.len == 1 and (args[0] == "-h" or args[0] == "--help"):
    return success(CliOptions(
      showHelp: true,
      programName: programName,
      ignoreDirs: @[],
      useDefaultIgnore: true,
      ignoreCase: true
    ))

  var useDefaultIgnore = true
  var ignoreCase = true
  var customIgnore: seq[string] = @[]
  var positional: seq[string] = @[]
  var parseOptions = true

  var i = 0
  while i < args.len:
    let arg = args[i]
    if parseOptions and arg == "--":
      parseOptions = false
      i.inc
      continue

    if not parseOptions:
      positional.add(arg)
      i.inc
      continue

    if arg == "--no-default-ignore":
      useDefaultIgnore = false
      i.inc
      continue

    if arg == "--ignore-case":
      ignoreCase = true
      i.inc
      continue

    if arg == "--case-sensitive":
      ignoreCase = false
      i.inc
      continue

    if arg == "--ignore":
      if i + 1 >= args.len:
        return failure(usageError("missing value for --ignore"))
      for token in args[i + 1].split(','):
        let trimmed = token.strip()
        if trimmed.len > 0:
          customIgnore.add(trimmed)
      i.inc(2)
      continue

    if arg.startsWith("--ignore="):
      let raw = arg.substr("--ignore=".len)
      for token in raw.split(','):
        let trimmed = token.strip()
        if trimmed.len > 0:
          customIgnore.add(trimmed)
      i.inc
      continue

    if arg.startsWith("-"):
      return failure(invalidArgumentError("unknown option: " & arg))

    positional.add(arg)
    i.inc

  if positional.len == 0:
    return failure(usageError("missing TEXT"))

  let termValue = positional[0]
  if termValue.len == 0:
    return failure(invalidArgumentError("TEXT cannot be empty"))

  var roots: seq[SearchRoot] = @[]
  if positional.len == 1:
    roots.add(SearchRoot(value: "."))
  else:
    for i in 1 ..< positional.len:
      roots.add(SearchRoot(value: positional[i]))

  return success(CliOptions(
    showHelp: false,
    term: SearchTerm(value: termValue),
    roots: roots,
    programName: programName,
    ignoreDirs: customIgnore,
    useDefaultIgnore: useDefaultIgnore,
    ignoreCase: ignoreCase
  ))
