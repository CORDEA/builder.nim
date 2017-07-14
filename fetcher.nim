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
import logger

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
  result = basePath.getNimBinPath() / (subex("nimble --nimbleDir:$# $# -y") % [
    path, subcommand])

proc removeTempFiles*() =
  let pat = getBasePath() / "*"
  for path in walkDirs(pat):
    path.removeDir()
  getDependenciesPath().removeDir()

proc existsRepository(url: string): bool =
  let (res, code) = execCmdEx subex("""curl -Is -o /dev/null -w "%{http_code}" $#""") % [
    url]
  discard code
  result = res.strip() == "200"

iterator fetch*(basePath: string): FetchResult =
  var cmd = getNimbleCommand(basePath, "refresh")
  logCmd cmd
  var (res, code) = execCmdEx cmd
  log res
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

    if not package.url.existsRepository():
      yield newEmptyFetchResult(package.name,
        subex("$# not found.") % [package.url])
      continue

    try:
      discard doDownload(
        package.url,
        path,
        anyVersion,
        getDownloadMethod(package.meth),
        options)
    except NimbleError:
      let msg = getCurrentExceptionMsg()
      yield newEmptyFetchResult(package.name, msg)
      continue

    let info = resolve(path, options)
    cmd = subex("$# $#") % [
      getNimbleCommand(basePath, "install -d"), package.name]
    logCmd cmd
    (res, code) = execCmdEx cmd
    log res

    yield newFetchResult(res, code, info)
