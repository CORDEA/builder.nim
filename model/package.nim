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

import nimblepkg/common

const
  unknownVersion = "-"

type
  Package* = object
    name*: string
    url*: string
    meth*: string

  FetchResult* = object
    installResultCode*: int
    installResult*: string
    url*: string
    packageInfo*: PackageInfo

proc newFetchResult*(res, url: string, code: int, info: PackageInfo): FetchResult =
  result = FetchResult(
    installResultCode: code,
    installResult: res,
    url: url,
    packageInfo: info)

proc newEmptyFetchResult*(name, url, msg: string): FetchResult =
  var info = PackageInfo()
  info.name = name
  info.version = unknownVersion
  result = FetchResult(
    installResultCode: 1,
    installResult: msg,
    url: url,
    packageInfo: info)

proc isUnknownVersion*(version: string): bool =
  result = version == unknownVersion
