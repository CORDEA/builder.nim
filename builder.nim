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
# date  : 2017-07-08

import os, osproc, ospaths
import subexes, pegs
import parseopt2, strutils

import model/build
import model/package, model/reason
import publisher, git
import fetcher, resolver
import compilehelper

type
  NimNotFoundError = object of Exception
  ArgumentError = object of ValueError

proc getOutputHeader(bin, name, version: string): string =
  result = "---\n"
  result &= getNimVersion(bin) & "\n"
  result &= subex("$# v$#\n") % [name, version]
  result &= "---\n\n"

proc installFailedResult(build: Build): Result =
  result = Result(
    name: build.name,
    version: build.libVersion,
    reason: Reason.installFailed)

proc handleResult(build: Build, buildResults: var seq[Result]) =
  if build.allGreen():
    buildResults.add Result(
      name: build.name,
      version: build.libVersion,
      reason: Reason.success)
  else:
    buildResults.add Result(
      name: build.name,
      version: build.libVersion,
      reason: Reason.compileFailed)

proc compileOutputs(build: var Build, res, command: string) =
  build.message &= "+ " & command & "\n"
  build.message &= res & "\n"

proc compileNimFiles(build: var Build, srcPath, bin: string) =
  for path in walkFiles(srcPath / "*.nim"):
    let
      command = getBuildCommand(bin, path, getDependenciesPath())
      (res, code) = execCmdEx command
    if code == 0:
      build.succeeded()
    else:
      build.failed()
    compileOutputs(build, res, command)

proc fetchAll(publisher: Publisher, basePath, version: string) =
  let bin = getNimBinPath(basePath) / getNimCommand(version)
  var buildResults: seq[Result] = @[]
  for fetchResult in fetch(basePath):
    let
      info = fetchResult.packageInfo
      name = info.name

    var build = newBuild(name, info.version)
    build.message = getOutputHeader(bin, name, info.version)
    if fetchResult.installResultCode != 0:
      build.message &= fetchResult.installResult
      buildResults.add build.installFailedResult()
    else:
      build.compileNimFiles(info.getResolveSrcPath(), bin)

      if build.empty():
        build.message &= "nim file not found."
      else:
        build.message &= build.message

      handleResult(build, buildResults)
    removeTempFiles()
    publisher.addBuildResult(name, build.message)
  publisher.addResults buildResults, bin
  publisher.commit()

proc getExpandPath(path: string): string =
  result = path.replace("~", getEnv("HOME"))

proc existsGitProject(path: string): bool =
  result = (path / ".git").existsDir()

when isMainModule:
  var
    basePath: string
    version: string
    projectPath: string = ""
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      basePath = key
    of cmdLongOption, cmdShortOption:
      case key
      of "v", "version":
        version = val
      of "log-project":
        projectPath = val
      else:
        discard
    else:
      discard

  let
    expandedBasePath = basePath.getExpandPath()
    expandedProjectPath = projectPath.getExpandPath()

  if not expandedBasePath.existsNimCommands():
    raise newException(NimNotFoundError, "h")

  if not expandedProjectPath.existsGitProject():
    raise newException(ArgumentError, "h")

  let pub = Publisher(basePath: expandedProjectPath)
  fetchAll(pub, expandedBasePath, version)
