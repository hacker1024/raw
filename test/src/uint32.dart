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

import 'package:raw/raw.dart';
import 'package:test/test.dart';

void main() {
  test("extractUint32bits", () {
    expect(extractUint32Bits(0x12345678, 0, 0xF), 0x8);
    expect(extractUint32Bits(0x12345678, 0, 0xFF), 0x78);
    expect(extractUint32Bits(0x12345678, 4, 0xF), 0x7);
    expect(extractUint32Bits(0x12345678, 4, 0xFF), 0x67);
  });
  test("transformUint32bits", () {
    expect(transformUint32Bits(0x12345678, 0, 0xF, 0xA), 0x1234567A);
    expect(transformUint32Bits(0x12345678, 0, 0xFF, 0xAB), 0x123456AB);
    expect(transformUint32Bits(0x12345678, 4, 0xF, 0xA), 0x123456A8);
    expect(transformUint32Bits(0x12345678, 4, 0xFF, 0xAB), 0x12345AB8);
  });
  test("extractUint32bool", () {
    expect(extractUint32Bool(0x0, 0), false);
    expect(extractUint32Bool(0x1, 0), true);
    expect(extractUint32Bool(0x101, 4), false);
    expect(extractUint32Bool(0x111, 4), true);
  });
  test("transformUint32bool", () {
    expect(transformUint32Bool(0x101, 4, false), 0x101);
    expect(transformUint32Bool(0x111, 4, false), 0x101);
    expect(transformUint32Bool(0x101, 4, true), 0x111);
    expect(transformUint32Bool(0x111, 4, true), 0x111);
  });
}
