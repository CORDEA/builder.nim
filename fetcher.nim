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
import subexes, strutils, sequtils
import json, marshal

import nimblepkg/options
import nimblepkg/download
import nimblepkg/version
import nimblepkg/common
import nimblepkg/cli

import model/package
import compilehelper
import resolver, git

const
  jsonName = "packages_official.json"
  builderBaseDir = "nimbuilder"

proc `[]`(t: JsonNode, key: string): JsonNode =
  result = if t.hasKey(key): json.`[]`(t, key) else: nil

proc to[T: object](node: JsonNode, data: var T) =
  for k, v in data.fieldPairs:
    when v is string:
      var key = k
      if key == "meth":
        key = "method"
      v = node[key].getStr
    elif v is seq:
      if node[k] == nil:
        v = @[]
      else:
        v = node[k]
          .elems
          .map(proc(x: JsonNode): string = x.str)
    else:
      node[k].to v

proc getBasePath(): string =
  result = getTempDir() / builderBaseDir
  discard result.existsOrCreateDir()

proc getNimblePath(): string =
  result = getBasePath() / ".nimble"

proc getDependenciesPath*(): string =
  result = getNimblePath() / "pkgs"

proc getNimbleCommand(basePath, subcommand: string): string =
  let path = getNimblePath()
  result = "GIT_TERMINAL_PROMPT=0 " &
    getNimBinPath(basePath) / (subex("nimble --nimbleDir:$# $# -y") % [
    path, subcommand])

proc removeTempFiles*() =
  let pat = getBasePath() / "*"
  for path in walkDirs(pat):
    path.removeDir()
  getDependenciesPath().removeDir()

iterator fetch*(basePath: string): FetchResult =
  var (res, code) = execCmdEx getNimbleCommand(basePath, "refresh")
  let
    jsonStr = (getNimblePath() / jsonName).readFile()
    json = parseJson jsonStr

  let packages = json.elems.map(proc(x: JsonNode): Package =
    var pkg: Package
    x.to pkg
    return pkg
  )

  removeTempFiles()

  var options = initOptions()
  options.nimbleDir = getNimblePath()
  options.forcePrompts = ForcePrompt.forcePromptYes
  let anyVersion = parseVersionRange("")

  for package in packages:
    let path = getBasePath() / package.name
    discard doDownload(
      package.url,
      path,
      anyVersion,
      DownloadMethod.git,
      options)

    (res, code) = execCmdEx subex("$# $#") % [
      getNimbleCommand(basePath, "install -d"), package.name]

    let info = resolve(path, options)
    yield FetchResult(
      installResultCode: code,
      installResult: res,
      packageInfo: info)
