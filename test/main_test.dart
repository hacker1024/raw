// Copyright 2019 dart-raw authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'src/hex.dart' as hex;
import 'src/raw_reader.dart' as raw_reader;
import 'src/raw_writer.dart' as raw_writer;
import 'src/raw_value.dart' as self_codec;
import 'src/uint32.dart' as uint32;

void main() {
  hex.main();
  raw_writer.main();
  raw_reader.main();
  self_codec.main();
  uint32.main();
}
