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
# date  : 2017-07-09

import os, times, subexes

import model/reason
import compilehelper, git

const
  readme = "README.md"
  templateFile = "template.md"
  tableHeader = """
| Name | Version | Status |
|:---|:---|:---:|
"""

type
  Publisher* = object
    basePath*: string

  Result* = object
    name*: string
    version*: string
    reason*: Reason

proc getPath(publisher: Publisher, name: string): string =
  result = publisher.basePath / name

proc getFileName(): string =
  result = $(epochTime().toInt()) & ".log"

proc getFilePath(publisher: Publisher, name, getFileName: string): string =
  let path = publisher.getPath name
  discard path.existsOrCreateDir()
  result = path / getFileName

proc addBuildResult*(publisher: Publisher, name, res: string) =
  let
    getFileName = getFileName()
    path = publisher.getFilePath(name, getFileName)

  path.writeFile res
  discard add(publisher.getPath(name), getFileName)

proc commit*(publisher: Publisher) =
  discard commit(publisher.basePath, subex("Build on $#") % [$getTime()])

proc publish*(publisher: Publisher, name: string) =
  let path = publisher.getPath name
  discard push(path, "master")

proc getHeader(binPath: string): string =
  result = templateFile.readFile()
  result &= "```\n"
  result &= getNimVersion binPath
  result &= "```\n\n"
  result &= tableHeader

proc addResults*(publisher: Publisher,
  results: openArray[Result], binPath: string) =
  var r = getHeader binPath
  let path = publisher.basePath / readme
  for res in results:
    r &= subex("| $# | $# | $# |\n") % [
      res.name, res.version, res.reason.toMessage()]

  path.writeFile r
  discard add(publisher.basePath, readme)
