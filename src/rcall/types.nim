# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

type
  MatchKind* = enum
    mkName,
    mkContent

  SearchTerm* = object
    value*: string

  SearchRoot* = object
    value*: string

  CliOptions* = object
    showHelp*: bool
    term*: SearchTerm
    roots*: seq[SearchRoot]
    programName*: string
    ignoreDirs*: seq[string]
    useDefaultIgnore*: bool
    ignoreCase*: bool

  MatchEntry* = object
    path*: string
    kind*: MatchKind
    line*: int
