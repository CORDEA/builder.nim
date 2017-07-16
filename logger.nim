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
# date  : 2017-07-12

import subexes

import model/package
import compilehelper

proc getLogOutput*(command, output: string): string =
  result = subex("+ $#\n") % [command]
  result &= output

proc logCmd*(command: string) =
  echo subex("+ $#") % [command]

proc log*(output: string) =
  echo output

proc forOutput*(command: string): string =
  result = "```\n"
  result &= command
  result &= "\n```\n"

proc getLogOutputHeader*(nimDirPath, name, version: string): string =
  if version.isUnknownVersion():
    result = subex("# $#") % [name]
  else:
    result = subex("# $# v$#") % [name, version]
  result &= "\n\n"
  result &= getNimVersion(nimDirPath).forOutput()
  result &= "\n"
  result &= "## Log\n\n"
