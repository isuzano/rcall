# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

version       = "0.1.0"
author        = "Iuri Suzano"
description   = "Minimal recursive file/directory name search CLI"
license       = "MIT"
srcDir        = "src"
bin           = @["rcall"]

requires "nim >= 2.0.0"

task test, "Run test suite":
  exec "nim c -r --hints:off --path:src tests/test_cli.nim"
  exec "nim c -r --hints:off --path:src tests/test_walker.nim"
