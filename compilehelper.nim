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
import ospaths

proc pathToVersion*(path: string): string =
  result = path.splitPath()[1]

proc getNimBinPath*(basePath: string): string =
  result = basePath / "bin"

proc getBuildCommand*(binPath, name, nimblePath: string): string =
  result = subex("$# c") % [binPath / "nim"]
  for dir in walkDirs(nimblePath / "*"):
    result &= subex(" -p:$#") % [dir]
  result &= " " & name

proc getNimVersion*(path: string): string =
  let (res, code) = execCmdEx subex("$# --version") % [
    path.getNimBinPath() / "nim"]
  discard code
  result = res

proc existsNimCommands*(path: string): bool =
  let binPath = path.getNimBinPath()
  result = (binPath / "nim").existsFile() and (binPath / "nimble").existsFile()
