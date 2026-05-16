# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import std/unittest
import std/os
import std/strutils
import std/times
import rcall/app

proc readAll(path: string): string =
  if not fileExists(path):
    return ""
  return readFile(path)

suite "rcall cli":
  test "rcall without arguments returns usage error":
    let suffix = $epochTime()
    let outPath = getTempDir() / ("rcall_test_noargs_out_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_noargs_err_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@[], outFile, errFile)
    close(outFile)
    close(errFile)

    check code == 2
    check readAll(errPath).contains("Usage:")

    removeFile(outPath)
    removeFile(errPath)

  test "rcall --help returns success":
    let suffix = $epochTime()
    let outPath = getTempDir() / ("rcall_test_help_out_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_help_err_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@["--help"], outFile, errFile)
    close(outFile)
    close(errFile)

    check code == 0
    check readAll(outPath).contains("Usage:")
    check readAll(errPath).len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "double-dash allows text starting with hyphen":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_dashtext_" & suffix)
    createDir(root)
    writeFile(root / "notes.txt", "--my-strange-text appears here\n")

    let outPath = getTempDir() / ("rcall_test_dashtext_out_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_dashtext_err_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@["--", "--my-strange-text", root], outFile, errFile)
    close(outFile)
    close(errFile)

    check code == 0
    check readAll(outPath).contains("notes.txt\t1\tcontent")
    check readAll(errPath).len == 0

    removeFile(outPath)
    removeFile(errPath)
