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
import logger

type
  NimNotFoundError = object of Exception
  ArgumentError = object of ValueError

proc nims(basePath: string): seq[string] =
  result = @[]
  for n in walkDirs(basePath / "*"):
    result.add n

proc compileNimFiles(build: var Build, srcPath, nimDirPath: string): string =
  result = ""
  for path in walkFiles(srcPath / "*.nim"):
    let command = getBuildCommand(
      nimDirPath.getNimBinPath(), path, getDependenciesPath())
    logCmd command
    let (res, code) = execCmdEx command
    log res
    if code == 0:
      build.succeeded()
    else:
      build.failed()
    result &= getLogOutput(command, res)

proc fetchAll(publisher: Publisher, basePath, version: string) =
  let nims = basePath.nims()
  for nim in nims:
    if not nim.existsNimCommands():
      raise newException(NimNotFoundError,
        subex("nim or nimble not found in $#.") % [nim])

  var jobs: seq[Job] = @[]
  for fetchResult in fetch(nims[0]):
    let
      info = fetchResult.packageInfo
      name = info.name

    var job = newJob(name, fetchResult.url, info.version)

    for nim in nims:
      var build = newBuild(nim.pathToVersion())

      job.message = getLogOutputHeader(nim, name, info.version)

      if fetchResult.installResultCode != 0:
        job.message &= fetchResult
          .installResult
          .forOutput()
        build.reason = Reason.installFailed
      else:
        job.message &= build
          .compileNimFiles(info.getResolveSrcPath(), nim)
          .forOutput()

        if build.empty():
          job.message &= "nim script not found.".forOutput()

        if build.allGreen():
          build.reason = Reason.success
        else:
          build.reason = Reason.compileFailed

      job.builds.add build
      publisher.addBuildResult(name, job.message)

    jobs.add job
    removeTempFiles()
  publisher.addResults jobs, nims
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

  if not expandedProjectPath.existsGitProject():
    raise newException(ArgumentError,
      """Need to set git project to "--log-project" option.""")

  putEnv("GIT_TERMINAL_PROMPT", "0")

  let pub = Publisher(basePath: expandedProjectPath)
  fetchAll(pub, expandedBasePath, version)

  putEnv("GIT_TERMINAL_PROMPT", "")
