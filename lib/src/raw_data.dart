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

import 'raw_reader.dart';
import 'raw_writer.dart';
import 'raw_value.dart';

/// A simple [RawEncodable] that holds bytes.
class RawData extends RawEncodable {
  static final RawData empty = RawData(const []);

  final List<int> bytes;

  const RawData(this.bytes);

  factory RawData.decode(RawReader reader, int length) {
    if (length == 0) {
      return empty;
    }
    return RawData(reader.readUint8ListViewOrCopy(length));
  }

  @override
  int encodeRawCapacity() => bytes.length;

  @override
  void encodeRaw(RawWriter writer) {
    writer.writeBytes(bytes);
  }

  String toString() => "[Raw data with length ${bytes.length}]";
}
