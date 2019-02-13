import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' show Int64;

class RawWriter {
  /// Minimum length for copying bytes in uin32 chunks.
  static const int _minLengthForUin32CopyMethod = 128;
  ByteData _byteData;
  int index = 0;

  final bool isExpanding;

  RawWriter.withByteData(this._byteData, {this.isExpanding: true});

  factory RawWriter.withCapacity(int capacity, {bool isExpanding: true}) {
    return new RawWriter.withByteData(new ByteData(capacity),
        isExpanding: isExpanding);
  }

  ByteData get byteData => _byteData;

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

  void ensureAvailableLength(int length) {
    // See whether old buffer has enough capacity.
    final oldByteData = this._byteData;
    final minCapacity = index + length;
    if (oldByteData.lengthInBytes >= minCapacity) {
      return;
    }

    // Choose a new capacity that's a power of 2.
    var newCapacity = 64;
    while (newCapacity < minCapacity) {
      newCapacity *= 2;
    }

    // Switch to the new buffer.
    _byteData = new ByteData(newCapacity);
    final oldIndex = this.index;
    this.index = 0;

    // Write contents of the old buffer.
    //
    // We write the whole buffer so we eliminate complex bugs when index is
    // non-monotonic or data is written directly.
    writeByteData(oldByteData);

    this.index = oldIndex;
  }

  ByteData toByteDataCopy() {
    final length = index;
    final result = new ByteData(length);
    final writer = new RawWriter.withByteData(result);
    writer.writeByteData(_byteData, length);
    return result;
  }

  ByteData toByteDataView() {
    final byteData = this.byteData;
    final index = this.index;
    if (index == byteData.lengthInBytes) {
      return byteData;
    }
    return new ByteData.view(
      byteData.buffer,
      byteData.offsetInBytes,
      index,
    );
  }

  Uint8List toUint8ListCopy() {
    final byteData = toByteDataCopy();
    return new Uint8List.view(
      byteData.buffer,
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  Uint8List toUint8ListView() {
    final byteData = this.byteData;
    return new Uint8List.view(
      byteData.buffer,
      byteData.offsetInBytes,
      index,
    );
  }

  /// Fills a [ByteData] span with the [ByteData] span.
  void writeByteData(ByteData value, [int index = 0, int length]) {
    final maxLength = value.lengthInBytes - index;
    if (length == null) {
      length = maxLength;
    } else if (length > maxLength) {
      throw new ArgumentError.value(length, "length");
    }
    ensureAvailableLength(length);

    final byteData = this.byteData;
    var byteDataIndex = this.index;
    if (length >= _minLengthForUin32CopyMethod) {
      final hostEndian = Endian.host;
      while (length >= 4) {
        byteData.setUint32(
            byteDataIndex, value.getUint32(index, hostEndian), hostEndian);
        byteDataIndex += 4;
        index += 4;
        length -= 4;
      }
    }
    while (length > 0) {
      byteData.setUint8(byteDataIndex, value.getUint8(index));
      byteDataIndex++;
      index++;
      length--;
    }
    this.index = byteDataIndex;
  }

  /// Fills a [ByteData] span with the byte list span.
  void writeBytes(List<int> value, [int index = 0, int length]) {
    final maxLength = value.length - index;
    if (length == null) {
      length = maxLength;
    } else if (length > maxLength) {
      throw new ArgumentError.value(length, "length");
    }
    if (length >= _minLengthForUin32CopyMethod && value is Uint8List) {
      writeByteData(
          new ByteData.view(value.buffer, value.offsetInBytes + index, length));
      return;
    }
    ensureAvailableLength(length);

    final byteData = this.byteData;
    var byteDataIndex = this.index;
    for (final end = index + length; index < end; index++) {
      byteData.setUint8(byteDataIndex, value[index]);
      byteDataIndex++;
    }
    this.index = byteDataIndex;
  }

  void writeFixInt64(Int64 value, [Endian endian = Endian.big]) {
    ensureAvailableLength(8);

    final bytes = value.toBytes();
    if (endian == Endian.little) {
      for (var i = 0; i < bytes.length; i++) {
        byteData.setUint8(index + 7 - i, bytes[i]);
      }
    } else {
      for (var i = 0; i < bytes.length; i++) {
        byteData.setUint8(index + i, bytes[i]);
      }
    }
    this.index = index + 8;
  }

  void writeFloat32(double value, [Endian endian = Endian.big]) {
    ensureAvailableLength(4);

    final index = this.index;
    byteData.setFloat32(index, value, endian);
    this.index = index + 4;
  }

  void writeFloat64(double value, [Endian endian = Endian.big]) {
    ensureAvailableLength(8);

    final index = this.index;
    byteData.setFloat64(index, value, endian);
    this.index = index + 8;
  }

  void writeInt16(int value, [Endian endian = Endian.big]) {
    ensureAvailableLength(2);

    final index = this.index;
    byteData.setInt16(index, value, endian);
    this.index = index + 2;
  }

  void writeInt32(int value, [Endian endian = Endian.big]) {
    ensureAvailableLength(4);

    final index = this.index;
    byteData.setInt32(index, value, endian);
    this.index = index + 4;
  }

  void writeInt8(int value) {
    ensureAvailableLength(1);

    final index = this.index;
    byteData.setInt8(index, value);
    this.index = index + 1;
  }

  /// Writes a safe latin string.
  /// Returns number of written bytes.
  int writeSafeLatin(String value, {int maxLengthInBytes}) {
    if (maxLengthInBytes != null && value.length >= maxLengthInBytes) {
      throw new ArgumentError.value(
        value,
        "value",
        "string exceeds maximum length ($maxLengthInBytes)",
      );
    }
    final byteData = this.byteData;
    var index = this.index;
    final start = index;
    for (var i = 0; i < value.length; i++) {
      final charCode = value.codeUnitAt(i);
      if (charCode > 126) {
        // We don't allow escape character (127)
        throw new ArgumentError.value(
          value,
          "value",
          "string contains unsafe codepoint $charCode",
        );
      }
      byteData.setUint8(index, charCode);
      index++;
    }
    this.index = index;
    return index - start;
  }

  void writeUint16(int value, [Endian endian = Endian.big]) {
    ensureAvailableLength(2);

    final index = this.index;
    byteData.setUint16(index, value, endian);
    this.index = index + 2;
  }

  void writeUint32(int value, [Endian endian = Endian.big]) {
    ensureAvailableLength(4);

    final index = this.index;
    byteData.setUint32(index, value, endian);
    this.index = index + 4;
  }

  void writeUint8(int value) {
    ensureAvailableLength(1);

    final index = this.index;
    byteData.setUint8(index, value);
    this.index = index + 1;
  }

  /// Writes an UTF-8 string.
  /// Returns number of written bytes.
  int writeUtf8(String value, {int maxLengthInBytes}) {
    if (maxLengthInBytes != null && value.length >= maxLengthInBytes) {
      throw new ArgumentError.value(
        value,
        "value",
        "string exceeds maximum length ($maxLengthInBytes) when encoded to UTF-8",
      );
    }

    final utf8Bytes = utf8.encode(value);
    if (maxLengthInBytes != null && utf8Bytes.length >= maxLengthInBytes) {
      throw new ArgumentError.value(
        value,
        "value",
        "string exceeds maximum length ($maxLengthInBytes) when encoded to UTF-8",
      );
    }
    writeBytes(utf8Bytes);
    return utf8Bytes.length;
  }

  /// Writes an UTF-8 string.
  /// Returns number of written bytes, including the final null-character.
  int writeUtf8NullEnding(String value, {int maxLengthInBytes}) {
    for (var i = 0; i < value.length; i++) {
      if (value.codeUnitAt(i) == 0) {
        throw new ArgumentError.value(value, "value", "contains null byte");
      }
    }
    final n = writeUtf8(value);
    writeUint8(0);
    return n + 1;
  }

  void writeVarInt(int value) {
    if (value < 0) {
      writeVarUint(-2 * value - 1);
    } else {
      writeVarUint(2 * value);
    }
  }

  void writeVarUint(int value) {
    if (value < 0) {
      throw new ArgumentError.value(value);
    }
    while (true) {
      final byte = 0x7F & value;
      final nextValue = value >> 7;
      if (nextValue == 0) {
        writeUint8(byte);
        return;
      }
      writeUint8(0x80 | byte);
      value = nextValue;
    }
  }

  void writeZeroes(int length) {
    ensureAvailableLength(length);
    final byteData = this.byteData;
    var index = this.index;
    while (length >= 4) {
      byteData.setUint32(index, 0);
      index += 4;
      length -= 4;
    }
    while (length > 0) {
      byteData.setUint8(index, 0);
      index++;
      length--;
    }
    this.index = index;
  }
}
