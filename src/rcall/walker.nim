# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import std/os
import std/algorithm
import std/strutils
import rcall/types

const
  maxDepth = 1024
  defaultIgnoredDirs = [".git", "node_modules", "build", "dist", ".cache"]

proc shouldIgnoreDir(name: string, ignoredDirs: seq[string]): bool =
  for ignored in ignoredDirs:
    if name == ignored:
      return true
  return false

proc containsWithCase(haystack, needle: string, ignoreCase: bool, needleLower: string): bool =
  if ignoreCase:
    return haystack.toLowerAscii().contains(needleLower)
  return haystack.contains(needle)

proc looksBinaryChunk(chunk: openArray[char], n: int): bool =
  if n <= 0:
    return false

  var suspicious = 0
  for i in 0 ..< n:
    let c = chunk[i]
    let b = int(c.uint8)
    if b == 0:
      return true

    if (b < 32 and c notin {'\t', '\n', '\r'}) or b == 127:
      suspicious.inc

  return suspicious * 100 div n > 10

proc isLikelyBinaryFile(path: string): bool =
  var f: File
  try:
    if not open(f, path, fmRead):
      return false

    defer:
      close(f)

    var probe: array[4096, char]
    let n = f.readBuffer(addr probe[0], probe.len)
    return looksBinaryChunk(probe, n)
  except OSError:
    return false

proc fileMatchLine(
  path: string,
  term: string,
  ignoreCase: bool,
  termLower: string,
  warnings: var seq[string]
): int =
  if isLikelyBinaryFile(path):
    return 0

  var f: File
  try:
    if not open(f, path, fmRead):
      warnings.add("skipped unreadable file: " & path)
      return 0

    defer:
      close(f)

    var lineNo = 0
    for line in f.lines:
      lineNo.inc
      if containsWithCase(line, term, ignoreCase, termLower):
        return lineNo

    return 0
  except OSError:
    warnings.add("skipped unreadable file: " & path)
    return 0

proc traverseDir(
  root: string,
  term: string,
  depth: int,
  ignoredDirs: seq[string],
  ignoreCase: bool,
  termLower: string,
  warnings: var seq[string],
  matches: var seq[MatchEntry]
) =
  if depth > maxDepth:
    return

  var entries: seq[(PathComponent, string)] = @[]
  try:
    for kind, relPath in walkDir(root, relative = true, checkDir = true):
      entries.add((kind, relPath))
  except OSError:
    return

  entries.sort(proc(a, b: (PathComponent, string)): int = system.cmp(a[1], b[1]))

  for entry in entries:
    let kind = entry[0]
    let relPath = entry[1]
    let fullPath = root / relPath
    let name = splitPath(fullPath).tail

    if kind == pcLinkToDir:
      continue

    var matched = false
    var matchKind = mkName
    var matchLine = 0

    if containsWithCase(name, term, ignoreCase, termLower):
      matched = true
      matchKind = mkName
    elif kind == pcFile or kind == pcLinkToFile:
      let lineNo = fileMatchLine(fullPath, term, ignoreCase, termLower, warnings)
      if lineNo > 0:
        matched = true
        matchKind = mkContent
        matchLine = lineNo

    if matched:
      matches.add(MatchEntry(path: fullPath, kind: matchKind, line: matchLine))

    if kind == pcDir and not shouldIgnoreDir(name, ignoredDirs):
      traverseDir(fullPath, term, depth + 1, ignoredDirs, ignoreCase, termLower, warnings, matches)

proc collectMatches*(
  term: SearchTerm,
  root: SearchRoot,
  customIgnoreDirs: seq[string],
  useDefaultIgnore: bool,
  ignoreCase: bool,
  warnings: var seq[string]
): seq[MatchEntry] =
  var matches: seq[MatchEntry] = @[]
  var ignoredDirs: seq[string] = @[]

  if useDefaultIgnore:
    for d in defaultIgnoredDirs:
      ignoredDirs.add(d)

  for d in customIgnoreDirs:
    if d.len > 0 and d notin ignoredDirs:
      ignoredDirs.add(d)

  let termLower = if ignoreCase: term.value.toLowerAscii() else: ""

  var rootInfo: FileInfo
  try:
    rootInfo = getFileInfo(root.value, followSymlink = false)
  except OSError:
    warnings.add("invalid root path: " & root.value)
    return matches

  if rootInfo.kind == pcLinkToDir or rootInfo.kind == pcLinkToFile:
    return matches

  if rootInfo.kind == pcDir:
    traverseDir(root.value, term.value, 0, ignoredDirs, ignoreCase, termLower, warnings, matches)
  return matches
