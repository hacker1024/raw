import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'raw_annotator.dart';
import 'raw_writer.dart';

class RawReader {
  final bool isCopyOnRead;
  final ByteData _byteData;
  int index;
  final RawAnnotator annotator;

  RawReader.withByteData(
    this._byteData, {
    this.index: 0,
    this.isCopyOnRead: true,
    this.annotator,
  });

  factory RawReader.withBytes(List<int> bytes,
      {RawAnnotator annotator, bool isCopyOnRead: true}) {
    ByteData byteData;
    if (bytes is Uint8List) {
      // Use existing buffer
      byteData = new ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
    } else {
      // Allocate a new buffer
      byteData = new ByteData(bytes.length);

      // Copy bytes to the new buffer
      final writer = new RawWriter.withByteData(byteData, isExpanding: false);
      writer.writeBytes(bytes);
    }
    return new RawReader.withByteData(
      byteData,
      annotator: annotator,
      isCopyOnRead: isCopyOnRead,
    );
  }

  /// Returns the number of bytes remaining.
  int get availableLengthInBytes => _byteData.lengthInBytes - index;

  /// Returns true if there are no more bytes available.
  bool get isEndOfBytes => index == _byteData.lengthInBytes;

  /// Returns a view at the buffer.
  ByteData bufferAsByteData([int index = 0, int length]) {
    if (index == 0 && length == null) {
      return _byteData;
    }
    final byteData = this._byteData;
    length ??= byteData.lengthInBytes - index;
    return new ByteData.view(
        byteData.buffer, byteData.offsetInBytes + index, length);
  }

  /// Returns a view at the buffer.
  Uint8List bufferAsUint8List([int index = 0, int length]) {
    final byteData = this._byteData;
    length ??= byteData.lengthInBytes - index;
    return new Uint8List.view(
        byteData.buffer, byteData.offsetInBytes + index, length);
  }

  /// Returns the number of bytes before the next zero byte.
  int lengthUntilZero({int maxLength}) {
    final byteData = this._byteData;
    final start = this.index;
    maxLength ??= _byteData.lengthInBytes - start;
    final end = start + maxLength;
    for (var i = start; i < end; i++) {
      if (byteData.getUint8(i) == 0) {
        return i - start;
      }
    }
    return -1;
  }

  /// Previews a future uint16 without advancing in the byte list.
  int previewUint16(int index, [Endian endian = Endian.big]) {
    return _byteData.getUint16(this.index + index, endian);
  }

  /// Previews a future uint32 without advancing in the byte list.
  int previewUint32(int index, [Endian endian = Endian.big]) {
    return _byteData.getUint32(this.index + index, endian);
  }

  /// Previews a future uint8 without advancing in the byte list.
  int previewUint8(int index) {
    return _byteData.getUint8(this.index + index);
  }

  /// Reads an ASCII string.
  String readAscii(int length) {
    final bytes = readUint8ListViewOrCopy(length);
    return new String.fromCharCodes(bytes);
  }

  /// Reads a null-terminated ASCII string.
  String readAsciiNullEnding({int maxLength}) {
    final length = lengthUntilZero(maxLength: maxLength);
    return readAscii(length);
  }

  /// Returns the next bytes. Length is determined by the argument.
  /// The method always returns a new copy of the bytes.
  ByteData readByteDataCopy(int length) {
    final byteData = this._byteData;
    final result = new ByteData(length);
    var i = 0;

    // If 128 or more bytes, we read in 4-byte chunks.
    // This should be faster.
    //
    // This constant is just a guess of a good minimum.
    if (length >> 7 != 0) {
      final optimizedDestination = new Uint32List.view(
          result.buffer, result.offsetInBytes, result.lengthInBytes);
      while (i + 3 < length) {
        // Copy in 4-byte chunks.
        // We must use host endian during reading.
        optimizedDestination[i] = byteData.getUint32(index + i, Endian.host);
        i += 4;
      }
    }
    for (; i < result.lengthInBytes; i++) {
      result.setUint8(i, byteData.getUint8(index + i));
    }
    this.index = index + length;
    return result;
  }

  /// Returns the next bytes. Length is determined by the argument.
  ///
  /// If [isCopyOnRead] is true, the method will return a new copy of the bytes.
  /// Otherwise the method will return a view at the bytes.
  ByteData readByteDataViewOrCopy(int length) {
    final byteData = this._byteData;
    final index = this.index;
    if (length == null) {
      length = availableLengthInBytes;
    } else if (length > byteData.lengthInBytes - index) {
      throw new ArgumentError.value(length, "length");
    }
    if (isCopyOnRead) {
      return readByteDataCopy(length);
    }
    // We can return a view
    return new ByteData.view(
      byteData.buffer,
      byteData.offsetInBytes + index,
      length,
    );
  }

  /// Reads a 64-bit signed integer as _Int64_ (from _'package:fixnum'_).
  /// Increments index by 8.
  Int64 readFixInt64([Endian endian = Endian.big]) {
    final bytes = readUint8ListCopy(8);
    if (endian == Endian.little) {
      return new Int64.fromBytes(bytes);
    } else {
      return new Int64.fromBytesBigEndian(bytes);
    }
  }

  /// Reads a 32-bit floating-point value.
  /// Increments index by 4.
  double readFloat32([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getFloat32(index, endian);
    this.index = index + 4;
    return value;
  }

  /// Reads a 64-bit floating-point value.
  /// Increments index by 8.
  double readFloat64([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getFloat64(index, endian);
    this.index = index + 8;
    return value;
  }

  /// Reads a 32-bit signed integer.
  /// Increments index by 2.
  int readInt16([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getInt16(index, endian);
    this.index = index + 2;
    return value;
  }

  /// Reads a 32-it signed integer.
  /// Increments index by 4.
  int readInt32([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getInt32(index, endian);
    this.index = index + 4;
    return value;
  }

  /// Reads an 8-bit signed integer.
  /// Increments index by 1.
  int readInt8() {
    final index = this.index;
    final value = _byteData.getInt8(index);
    this.index = index + 1;
    return value;
  }

  /// Returns a new RawReader that is backed by a span of this RawReader.
  RawReader readRawReader(int length) {
    final byteData = this._byteData;
    final index = this.index;
    final result = new RawReader.withByteData(new ByteData.view(
        byteData.buffer, byteData.offsetInBytes + index, length));
    this.index = index + length;
    return result;
  }

  /// Reads a 16-bit unsigned integer.
  /// Increments index by 2.
  int readUint16([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getUint16(index, endian);
    this.index = index + 2;
    return value;
  }

  /// Reads a 32-bit unsigned integer.
  /// Increments index by 4.
  int readUint32([Endian endian = Endian.big]) {
    final index = this.index;
    final value = _byteData.getUint32(index, endian);
    this.index = index + 4;
    return value;
  }

  /// Reads an 8-bit unsigned integer.
  /// Increments index by 1.
  int readUint8() {
    final index = this.index;
    final value = _byteData.getUint8(index);
    this.index = index + 1;
    return value;
  }

  /// Returns the next bytes. Length is determined by the argument.
  /// The method always returns a new copy of the bytes.
  Uint8List readUint8ListCopy([int length]) {
    if (length == null) {
      length = availableLengthInBytes;
    } else if (length > _byteData.lengthInBytes - index) {
      throw new ArgumentError.value(length, "length");
    }
    final result = new Uint8List(length);
    var i = 0;

    // If 128 or more bytes, we read in 4-byte chunks.
    // This should be faster.
    //
    // This constant is just a guess of a good minimum.
    if (length >> 7 != 0) {
      final optimizedDestination = new Uint32List.view(
        result.buffer,
        result.offsetInBytes,
        result.lengthInBytes,
      );
      while (i + 3 < length) {
        // Copy in 4-byte chunks.
        // We must use host endian during reading.
        optimizedDestination[i] = _byteData.getUint32(index + i, Endian.host);
        i += 4;
      }
    }
    for (var i = 0; i < result.length; i++) {
      result[i] = _byteData.getUint8(index + i);
    }
    this.index = index + length;
    return result;
  }

  /// Returns the next bytes. Length is determined by the argument.
  ///
  /// If [isCopyOnRead] is true, the method will return a new copy of the bytes.
  /// Otherwise the method will return a view at the bytes.
  Uint8List readUint8ListViewOrCopy(int length) {
    final index = this.index;
    if (index < 0 || index > _byteData.lengthInBytes) {
      throw new ArgumentError.value(index, "index");
    }
    if (length == null) {
      length = availableLengthInBytes;
    } else if (length > _byteData.lengthInBytes - index) {
      throw new ArgumentError.value(length, "length");
    }
    if (isCopyOnRead == false) {
      // We can return a view
      return new Uint8List.view(
        _byteData.buffer,
        _byteData.offsetInBytes + index,
        length,
      );
    }
    return readUint8ListCopy(length);
  }

  /// Reads UTF-8 string.
  String readUtf8(int length) {
    final bytes = readUint8ListViewOrCopy(length);
    return utf8.decode(bytes);
  }

  /// Reads a null-terminated UTF-8 string.
  String readUtf8NullEnding() {
    final length = lengthUntilZero();
    if (length < 0) {
      return readUtf8(availableLengthInBytes);
    }
    final result = readUtf8(length);
    readUint8();
    return result;
  }

  /// Reads a variable-length signed integer.
  int readVarInt() {
    final value = readVarUint();
    if (value % 2 == 0) {
      return value ~/ 2;
    }
    return (value ~/ -2) - 1;
  }

  /// Reads a variable-length unsigned integer.
  int readVarUint() {
    final byteData = this._byteData;
    final start = this.index;
    var index = start;
    var result = 0;
    for (var i = 0; i < 64; i += 7) {
      if (index >= byteData.lengthInBytes) {
        throw new StateError("Never-ending variable-length integer at $start");
      }
      final byte = byteData.getUint8(index);
      index++;
      result |= (0x7F & byte) << i;
      if (0x80 & byte == 0) {
        break;
      }
    }
    this.index = index;
    return result;
  }
}
