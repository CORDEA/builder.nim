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
import strutils

import model/reason
import model/build
import compilehelper
import logger, git

const
  readme = "README.md"
  templateFile = "template.md"
  tableHeader = "| Name | Version |"
  packagesDirName = "packages"

type
  Publisher* = object
    basePath*: string

  Result* = object
    name*: string
    version*: string
    reason*: Reason

proc getPackagesPath(publisher: Publisher): string =
  result = publisher.basePath / packagesDirName
  discard result.existsOrCreateDir()

proc getLibraryPath(publisher: Publisher, name: string): string =
  result = publisher.getPackagesPath() / name
  discard result.existsOrCreateDir()

proc getFileName(): string =
  result = $(epochTime().toInt()) & ".md"

proc getFilePath(publisher: Publisher, name, fileName: string): string =
  let path = publisher.getLibraryPath name
  result = path / fileName

proc addBuildResult*(publisher: Publisher, name, res: string) =
  let
    fileName = getFileName()
    path = publisher.getFilePath(name, fileName)

  path.writeFile res
  discard add(publisher.getLibraryPath(name), fileName)

proc commit*(publisher: Publisher) =
  discard commit(publisher.basePath, subex("Build on $#") % [$getTime()])

proc publish*(publisher: Publisher, name: string) =
  let path = publisher.getLibraryPath name
  discard push(path, "master")

proc getHeader(binPaths: openArray[string]): string =
  result = templateFile.readFile()
  for path in binPaths:
    result &= getNimVersion(path).forOutput()
    result &= "\n"
  result &= "## Build status\n\n"
  result &= tableHeader.strip()

proc addResults*(publisher: Publisher,
  results: openArray[Job], binPaths: openArray[string]) =
  var
    r = getHeader binPaths
    sep = "|:---:|:---:|"
  for v in binPaths:
    r &= subex(" $# |") % [v.pathToVersion()]
    sep &= ":---:|"
  r &= "\n" & sep & "\n"

  let path = publisher.basePath / readme
  for res in results:
    r &= subex("| $# | $# |") % [res.name, res.libVersion]
    for build in res.builds:
      r &= subex(" $# |") % [build.reason.toMessage()]
    r &= "\n"

  path.writeFile r
  discard add(publisher.basePath, readme)
