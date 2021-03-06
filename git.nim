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

import os, osproc, subexes
import pegs

import logger

proc push*(path, branch: string): int =
  let cmd = subex("cd $# && git push origin $#") % [
    path, branch]
  logCmd cmd
  let (res, code) = execCmdEx cmd
  log res
  return code

proc commit*(path, message: string): int =
  let cmd = subex("""cd $# && git commit -m "$#"""") % [
    path, message]
  logCmd cmd
  let (res, code) = execCmdEx cmd
  log res
  return code

proc add*(path, name: string): int =
  let cmd = subex("""cd $# && git add $#""") % [
    path, name]
  logCmd cmd
  let (res, code) = execCmdEx cmd
  log res
  return code
