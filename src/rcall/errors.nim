# SPDX-FileCopyrightText: 2026 Iuri Suzano <iuri@astware.bar>
# SPDX-License-Identifier: MIT

type
  AppError* = object
    message*: string

proc usageError*(message: string): AppError =
  AppError(message: message)

proc invalidArgumentError*(message: string): AppError =
  AppError(message: message)
