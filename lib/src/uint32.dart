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

/// Replaces specific bits in a 32-bit unsigned integer.
///
/// Bits are specified by:
///   * `shift` - Bitmask left-shift (0,1, ..., 30, 31)
///   * `bitmask` - For example, 0xF for 4 bits.
int transformUint32Bits(int uint32, int shift, int bitmask, int newValue) {
  if (bitmask | newValue != bitmask) {
    throw ArgumentError.value(newValue, "newValue", "too many bits");
  }
  return ((0xFFFFFFFF ^ (bitmask << shift)) & uint32) | (newValue << shift);
}

/// Replaces a single bit in a 32-bit unsigned integer.
int transformUint32Bool(int uint32, int shift, bool newValue) {
  return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) |
      ((newValue ? 1 : 0) << shift);
}

/// Returns specific bits in a 32-bit unsigned integer.
///
/// Bits are specified by:
///   * `shift` - Bitmask left-shift (0,1, ..., 30, 31)
///   * `bitmask` - For example, 0xF for 4 bits.
///
/// Example:
///   viewUint32(0xF0A0, 8, 0xF) // --> 0xA
int extractUint32Bits(int uint32, int shift, int mask) {
  return mask & (uint32 >> shift);
}

/// Return a single bit in a 32-bit unsigned integer.
///
/// Example:
///   viewUint32Bool(0xF010, 8) // --> true
bool extractUint32Bool(int uint32, int shift) {
  return 0x1 & (uint32 >> shift) != 0;
}
