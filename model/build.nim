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

import reason

type
  Job* = object
    name*: string
    url*: string
    libVersion*: string
    message*: string
    builds*: seq[Build]

  Build* = object
    nimVersion*: string
    reason*: Reason
    logFilePath*: string
    successes: int
    failures: int

proc newJob*(name, url, version: string): Job =
  result = Job(
    name: name,
    url: url,
    libVersion: version,
    message: "",
    builds: @[])

proc newBuild*(version: string): Build =
  result = Build(
    nimVersion: version,
    reason: Reason.unknown,
    logFilePath: "",
    successes: 0,
    failures: 0)

proc succeeded*(build: var Build) =
  build.successes += 1

proc failed*(build: var Build) =
  build.failures += 1

proc empty*(build: Build): bool =
  result = (build.successes + build.failures) == 0

proc allGreen*(build: Build): bool =
  result = build.failures == 0
