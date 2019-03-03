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

import 'dart:typed_data';

import 'package:raw/raw.dart';
import 'package:test/test.dart';

void main() {
  group("SelfEncoder: ", () {
    test("==", () {
      var a = _ExampleStructWriter([1, 2]);
      var b = _ExampleStructWriter([1, 2]);
      expect(a, equals(b));

      // Non-equal value
      b = _ExampleStructWriter([1, 3]);
      expect(a, isNot(equals(b)));

      // Non-equal length
      b = _ExampleStructWriter([1]);
      expect(a, isNot(equals(b)));
      b = _ExampleStructWriter([1, 2, 3]);
      expect(a, isNot(equals(b)));
    });

    test("hashCode", () {
      var hashCount = 0;
      const maxBits = 32;
      const mod = 1 << 22;
      final hashCodeMap = Map<int, int>();

      // Zero buffer
      final byteData = ByteData(1000);
      var example = _ExampleHashCode(byteData);

      // 1 000 hashCodes,
      for (var i = 0; i < byteData.lengthInBytes; i++) {
        hashCount++;

        // Calculate new hashCode, truncate to 16-bits
        example.length = i;
        var hashCode = example.hashCode;

        // Check the number of bits
        expect(hashCode >> maxBits, 0);

        // Check that we don't have a collision
        hashCode = hashCode % mod;
        final previous = hashCodeMap[hashCode];
        expect(previous, isNull,
            reason:
                "collision: i=$i, hash=$hashCode,  current=$hashCount, previous=$previous");

        // Add to set of hashCodes
        hashCodeMap[hashCode] = hashCount;
      }

      // Fill buffer:
      // [1, 2, ..., 1000]
      for (var i = 0; i < byteData.lengthInBytes; i++) {
        byteData.setUint8(i, (1 + i) % 256);
      }

      // 3 000 hashCodes
      for (var i = 1; i < byteData.lengthInBytes; i++) {
        hashCount++;

        // Calculate new hashCode
        example.length = i;
        var hashCode = example.hashCode;

        // Check the number of bits
        expect(hashCode >> maxBits, 0);

        // Check that we don't have a collision
        hashCode = hashCode % mod;
        final previous = hashCodeMap[hashCode];
        expect(previous, isNull,
            reason:
                "collision: i=$i, hash=$hashCode, current=$hashCount, previous=$previous");

        // Add to set of hashCodes
        hashCodeMap[hashCode] = hashCount;
      }

      // Change a single byte
      expect(example.toByteDataViewOrCopy().getUint8(0), 1);
      byteData.setUint8(0, 0);
      expect(example.toByteDataViewOrCopy().getUint8(0), 0);

      // 1 000 hashCodes
      for (var i = 2; i < byteData.lengthInBytes; i++) {
        hashCount++;

        // Calculate new hashCode, truncate to 16-bits
        example.length = i;
        var hashCode = example.hashCode;

        // Check the number of bits
        expect(hashCode >> maxBits, 0);

        // Check that we don't have a collision
        hashCode = hashCode % mod;
        final previous = hashCodeMap[hashCode];
        expect(previous, isNull,
            reason:
                "collision: i=$i, hash=$hashCode, current=$hashCount, previous=$previous");

        // Add to set of hashCodes
        hashCodeMap[hashCode] = hashCount;
      }
    });

    test("toImmutableByteData", () {
      final a = _ExampleStructWriter([1, 2, 3]);
      final byteData = a.toByteDataViewOrCopy();
      final uint8List = Uint8List.view(
        byteData.buffer,
        0,
        byteData.lengthInBytes,
      );
      expect(uint8List, orderedEquals([1, 2, 3]));
    });

    test("toImmutableBytes", () {
      final a = _ExampleStructWriter([1, 2, 3]);
      expect(a.toUint8ListViewOrCopy(), orderedEquals([1, 2, 3]));
    });
  });
}

class _ExampleStructWriter extends RawEncodable {
  final List<int> bytes;

  _ExampleStructWriter(this.bytes);

  @override
  void encodeRaw(RawWriter writer) {
    writer.writeBytes(bytes);
  }
}

class _ExampleHashCode extends RawEncodable {
  final ByteData byteData;
  int length = 0;

  _ExampleHashCode(this.byteData);

  @override
  void encodeRaw(RawWriter writer) {
    throw UnimplementedError();
  }

  @override
  ByteData toByteDataViewOrCopy() => ByteData.view(byteData.buffer, 0, length);
}
