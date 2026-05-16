# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import std/syncio
import rcall/types
import rcall/errors

proc usageText*(programName: string): string =
  "Usage:\n" &
  "  " & programName & " TEXT [PATH ...]\n" &
  "  " & programName &
  " [--ignore list] [--no-default-ignore] [--ignore-case|--case-sensitive] TEXT [PATH ...]\n" &
  "  " & programName & " -h | --help\n" &
  "\n" &
  "Options:\n" &
  "  --ignore list         Comma-separated directory names to ignore.\n" &
  "  --no-default-ignore   Disable built-in ignored directories.\n" &
  "  --ignore-case         Case-insensitive matching (default).\n" &
  "  --case-sensitive      Case-sensitive matching.\n" &
  "  -h, --help            Show this help message.\n" &
  "\n" &
  "Output format:\n" &
  "  path<TAB>line<TAB>kind\n" &
  "  line is 0 for name-based matches.\n" &
  "  kind is one of: name, content.\n" &
  "\n" &
  "Exit codes:\n" &
  "  0  At least one match found.\n" &
  "  1  No matches found.\n" &
  "  2  Usage/argument error.\n"

proc writeHelp*(stream: File, programName: string) =
  stream.write(usageText(programName))

proc writeError*(stream: File, err: AppError) =
  stream.write("Error: " & err.message & "\n")

proc writeWarning*(stream: File, message: string) =
  stream.write("Warning: " & message & "\n")

proc writeMatches*(stream: File, matches: seq[MatchEntry]) =
  for entry in matches:
    case entry.kind
    of mkName:
      stream.write(entry.path & "\t0\tname\n")
    of mkContent:
      stream.write(entry.path & "\t" & $entry.line & "\tcontent\n")
