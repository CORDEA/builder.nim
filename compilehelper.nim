# Copyright 2017 Yoshihiro Tanaka
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

  # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Yoshihiro Tanaka <contact@cordea.jp>
# date  : 2017-07-10

import os, osproc
import strutils, subexes

proc getNimBinPath*(basePath: string): string =
  result = basePath / "bin"

proc getBuildCommand*(nim, name, nimblePath: string): string =
  result = subex("$# c") % [nim]
  for dir in walkDirs(nimblePath / "*"):
    result &= subex(" -p:$#") % [dir]
  result &= " " & name

proc getNimCommand*(version: string): string =
  if version == nil:
    return "nim"
  let v = version.replace(".")
  return subex("nim$#") % [v]

proc getNimVersion*(bin: string): string =
  let (res, code) = execCmdEx bin & " --version"
  discard code
  result = res

proc existsNimCommands*(path: string): bool =
  let binPath = getNimBinPath(path)
  result = (binPath / "nim").existsFile() and (binPath / "nimble").existsFile()
