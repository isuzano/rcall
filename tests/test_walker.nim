# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

import std/unittest
import std/os
import std/strutils
import std/sequtils
import std/times
import rcall/app

when not defined(windows):
  import std/posix

proc splitNonEmptyLines(s: string): seq[string] =
  s.splitLines().filterIt(it.len > 0)

suite "rcall walker":
  test "text matches file recursively":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_a_" & suffix)
    createDir(root)
    createDir(root / "src")
    writeFile(root / "src" / "config.c", "")

    let outPath = getTempDir() / ("rcall_test_walk_out1_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err1_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@["config", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 0
    check lines.anyIt(it.contains("config.c\t0\tname"))
    check readFile(errPath).len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "text matches file by internal content":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_c_" & suffix)
    createDir(root)
    createDir(root / "notes")
    writeFile(root / "notes" / "memo.txt", "author: iuri suzano\nisuzano appears here\n")

    let outPath = getTempDir() / ("rcall_test_walk_out3_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err3_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@["isuzano", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 0
    check lines.anyIt(it.contains("memo.txt\t2\tcontent"))
    check readFile(errPath).len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "explicit path and ignored symlink":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_b_" & suffix)
    createDir(root)
    createDir(root / "docs")
    createDir(root / "real")
    writeFile(root / "docs" / "configuration.md", "")
    writeFile(root / "real" / "config-real.txt", "")

    let symlinkPath = root / "docs_link"
    try:
      createSymlink(root / "docs", symlinkPath)
    except OSError:
      discard

    let outPath = getTempDir() / ("rcall_test_walk_out2_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err2_" & suffix & ".txt")

    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)

    let code = runApp(@["config", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 0
    check lines.allIt(not it.contains("docs_link"))
    check lines.allIt(it == it.strip())

    removeFile(outPath)
    removeFile(errPath)

  test "default ignored dirs can be disabled":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_d_" & suffix)
    createDir(root)
    createDir(root / ".git")
    writeFile(root / ".git" / "config", "needle-content\n")

    let outPath1 = getTempDir() / ("rcall_test_walk_out4a_" & suffix & ".txt")
    let errPath1 = getTempDir() / ("rcall_test_walk_err4a_" & suffix & ".txt")
    var outFile1: File
    var errFile1: File
    doAssert open(outFile1, outPath1, fmWrite)
    doAssert open(errFile1, errPath1, fmWrite)
    let code1 = runApp(@["needle", root], outFile1, errFile1)
    close(outFile1)
    close(errFile1)
    let lines1 = splitNonEmptyLines(readFile(outPath1))
    check code1 == 1
    check lines1.len == 0

    let outPath2 = getTempDir() / ("rcall_test_walk_out4b_" & suffix & ".txt")
    let errPath2 = getTempDir() / ("rcall_test_walk_err4b_" & suffix & ".txt")
    var outFile2: File
    var errFile2: File
    doAssert open(outFile2, outPath2, fmWrite)
    doAssert open(errFile2, errPath2, fmWrite)
    let code2 = runApp(@["--no-default-ignore", "needle", root], outFile2, errFile2)
    close(outFile2)
    close(errFile2)
    let lines2 = splitNonEmptyLines(readFile(outPath2))
    check code2 == 0
    check lines2.anyIt(it.contains(".git/config"))

    removeFile(outPath1)
    removeFile(errPath1)
    removeFile(outPath2)
    removeFile(errPath2)

  test "case-sensitive mode is respected":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_e_" & suffix)
    createDir(root)
    writeFile(root / "Config.txt", "Config line\n")

    let outPath1 = getTempDir() / ("rcall_test_walk_out5a_" & suffix & ".txt")
    let errPath1 = getTempDir() / ("rcall_test_walk_err5a_" & suffix & ".txt")
    var outFile1: File
    var errFile1: File
    doAssert open(outFile1, outPath1, fmWrite)
    doAssert open(errFile1, errPath1, fmWrite)
    let code1 = runApp(@["config", root], outFile1, errFile1)
    close(outFile1)
    close(errFile1)
    let lines1 = splitNonEmptyLines(readFile(outPath1))
    check code1 == 0
    check lines1.len > 0

    let outPath2 = getTempDir() / ("rcall_test_walk_out5b_" & suffix & ".txt")
    let errPath2 = getTempDir() / ("rcall_test_walk_err5b_" & suffix & ".txt")
    var outFile2: File
    var errFile2: File
    doAssert open(outFile2, outPath2, fmWrite)
    doAssert open(errFile2, errPath2, fmWrite)
    let code2 = runApp(@["--case-sensitive", "config", root], outFile2, errFile2)
    close(outFile2)
    close(errFile2)
    let lines2 = splitNonEmptyLines(readFile(outPath2))
    check code2 == 1
    check lines2.len == 0

    removeFile(outPath1)
    removeFile(errPath1)
    removeFile(outPath2)
    removeFile(errPath2)

  test "file symlink is searchable":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_f_" & suffix)
    createDir(root)
    writeFile(root / "target.txt", "needle-in-target\n")

    let linkPath = root / "alias.txt"
    try:
      createSymlink(root / "target.txt", linkPath)
    except OSError:
      discard

    let outPath = getTempDir() / ("rcall_test_walk_out6_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err6_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["needle-in-target", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 0
    check lines.anyIt(it.contains("target.txt\t1\tcontent"))
    check lines.anyIt(it.contains("alias.txt\t1\tcontent"))

    removeFile(outPath)
    removeFile(errPath)

  test "returns 1 when no matches are found":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_g_" & suffix)
    createDir(root)
    writeFile(root / "notes.txt", "no useful tokens here\n")

    let outPath = getTempDir() / ("rcall_test_walk_out7_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err7_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["definitely_not_present_token", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 1
    check lines.len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "supports multiple root paths":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_multi_" & suffix)
    let rootA = root / "src"
    let rootB = root / "tests"
    createDir(root)
    createDir(rootA)
    createDir(rootB)
    writeFile(rootA / "match-a.txt", "token-a\n")
    writeFile(rootB / "match-b.txt", "token-b\n")

    let outPath = getTempDir() / ("rcall_test_walk_out_multi_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err_multi_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["match", rootA, rootB], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 0
    check lines.anyIt(it.contains("match-a.txt"))
    check lines.anyIt(it.contains("match-b.txt"))

    removeFile(outPath)
    removeFile(errPath)

  test "deduplicates matches across overlapping roots":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_overlap_" & suffix)
    let srcRoot = root / "src"
    createDir(root)
    createDir(srcRoot)
    writeFile(srcRoot / "unique-match.txt", "token-overlap\n")

    let outPath = getTempDir() / ("rcall_test_walk_out_overlap_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err_overlap_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["unique-match", root, srcRoot], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    let hitCount = lines.countIt(it.contains("unique-match.txt"))
    check code == 0
    check hitCount == 1

    removeFile(outPath)
    removeFile(errPath)

  test "warns when file is unreadable":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_h_" & suffix)
    createDir(root)
    let unreadable = root / "secret.txt"
    writeFile(unreadable, "needle-hidden\n")
    try:
      setFilePermissions(unreadable, {})
    except OSError:
      discard

    var probe: File
    let canStillRead = open(probe, unreadable, fmRead)
    if canStillRead:
      close(probe)

    let outPath = getTempDir() / ("rcall_test_walk_out8_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err8_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["needle-hidden", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let errText = readFile(errPath)
    when not defined(windows):
      let isPrivileged = getuid() == 0
    else:
      let isPrivileged = false

    if (not canStillRead) and (not isPrivileged):
      check code == 1
      check errText.contains("Warning: skipped unreadable file:")
    else:
      # Privileged environments (or permissive FS) may still read the file.
      # In this case, only assert stable execution.
      check code in [0, 1]

    try:
      setFilePermissions(unreadable, {fpUserRead, fpUserWrite})
    except OSError:
      discard

    removeFile(outPath)
    removeFile(errPath)

  test "binary file with null byte is skipped for content search":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_i_" & suffix)
    createDir(root)
    let binaryPath = root / "blob.bin"
    writeFile(binaryPath, "abc\0needle-in-binary\n")

    let outPath = getTempDir() / ("rcall_test_walk_out9_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err9_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["needle-in-binary", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 1
    check lines.len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "binary-like control-heavy file is skipped for content search":
    let suffix = $epochTime()
    let root = getTempDir() / ("rcall_test_tree_j_" & suffix)
    createDir(root)
    let binaryLikePath = root / "control-heavy.dat"
    var payload = ""
    for i in 1 .. 500:
      payload.add(char(1))
    payload.add("needle-control-heavy\n")
    writeFile(binaryLikePath, payload)

    let outPath = getTempDir() / ("rcall_test_walk_out10_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err10_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["needle-control-heavy", root], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    check code == 1
    check lines.len == 0

    removeFile(outPath)
    removeFile(errPath)

  test "invalid root path emits warning":
    let suffix = $epochTime()
    let missingRoot = getTempDir() / ("rcall_test_missing_root_" & suffix)

    let outPath = getTempDir() / ("rcall_test_walk_out11_" & suffix & ".txt")
    let errPath = getTempDir() / ("rcall_test_walk_err11_" & suffix & ".txt")
    var outFile: File
    var errFile: File
    doAssert open(outFile, outPath, fmWrite)
    doAssert open(errFile, errPath, fmWrite)
    let code = runApp(@["anything", missingRoot], outFile, errFile)
    close(outFile)
    close(errFile)

    let lines = splitNonEmptyLines(readFile(outPath))
    let errText = readFile(errPath)
    check code == 1
    check lines.len == 0
    check errText.contains("Warning: invalid root path:")

    removeFile(outPath)
    removeFile(errPath)
