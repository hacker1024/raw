# Introduction
A package for writing, reading, and debuggging binary data.

## Issues & contributing
  * Found a bug? Create an issue [in Github](https://github.com/terrier989/dart-raw/issues).
  * Contributing code? Create a pull request [in Github](https://github.com/terrier989/dart-raw/issues).

## Features
### Create "struct-like" classes

```dart
class MyStruct extends SelfCodec {
  int intField = 0;
  String stringField = "";
  
  @override
  void encodeSelf(RawWriter writer) {
    writer.writeInt32(intField);
    writer.writeUint32(stringField.length, Endian.little);
    writer.writeUtf8(stringField);
  }
  
  @override
  void decodeSelf(RawReader reader) {
    intField = reader.readInt32();
    final stringLength = reader.readUint32(Endian.little);
    stringField = reader.readUtf(stringLength);
  }
}
```

### Supported primitives
The following data types are supported:
  * Fixed-length types
    * Unsigned/signed integers
      * `uint8` / `int8`
      * `uint16` / `int16`
      * `uint32` / `int32`
    * Floating- point values
      * `float32`
      * `float64`
    * Variable-length integers
      * `VarUint`
      * `VarInt`
  * Variable-length types
      * List<int>
      * ByteData
      * Strings
        * `Utf8` / `Utf8NullEnding`
  * Zeroes

### Helpers for testing
Library _"package:raw/test_helpers.dart"_ contains matchers that use _DebugHexEncoder_.

#### byteListEquals

```dart
import 'package:test/test.dart';
import 'package:raw/raw_test.dart';

void main() {
  test("an example", () {
    final value = [9,8,7];
    final expected = [1,2,3];
    expect(value, byteListEquals(expected));
    
    // Output:
    // 0x0000: 0908 07
    //     (0) ^^^^ ^^
    //         0102 03
  });
}
```

#### selfEncoderEquals

```dart
class MyStruct extends SelfCodec {
  // ...
}

void main() {
  test("an example", () {
    final value = new MyStruct();
    final expected = [
      // ...
    ];
    expect(alue, selfEncoderEquals(expected));
  });
}
```

### Hex support
#### DebugHexDecoder

_DebugHexDecoder_ is able to import hex formats such as:
  * "0000000: 0123 4567 89ab cdef 0123 4567 89ab cdef ................"
  * "0000010: 012345678 ............ # comment"
  * "012345678abcdef // no prefix"

#### DebugHexEncoder
_DebugHexEncoder_ converts bytes to the following format:
```
0x0000: 0123 4567 89ab cdef  0123 4567 89ab cdef
    (0)
0x0010: 0123 4567 89ab cdef  0123 4567 89ab cdef
   (16)
```

If expected byte list is specified, bytes are converted to the following format:
```
0x0000: 0123 5555 89ab cdef  0123 4567 89ab cdef
    (0)      ^ ^^                                 <-- index of the first error: 0x02 (decimal: 2)
             4 67
0x0010: 0123 4567 89ab cdef  0123 4567 89
   (16)                                  ^^ ^^^^  <-- index of the first error: 0x0D (decimal: 13)
                                         ab cdef
```