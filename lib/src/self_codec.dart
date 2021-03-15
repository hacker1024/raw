import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'raw_reader.dart';
import 'raw_writer.dart';

/// Anything that implements both [SelfEncoder] and [SelfDecoder].
abstract class SelfCodec extends SelfEncoder with SelfDecoder {}

abstract class SelfDecoder {
  /// Decodes state from the bytes.
  /// Existing state should be discarded.
  void decodeSelf(RawReader reader);

  /// Decodes state from the value.
  /// Returned boolean tells whether the operation succeeded.
  bool decodeSelfFromObject(Object value) {
    if (value is SelfEncoder) {
      final byteData = value.toImmutableByteData();
      final reader = new RawReader.withByteData(byteData);
      try {
        decodeSelf(reader);
      } catch (e) {
        return false;
      }
      if (!reader.isEndOfBytes) {
        return false;
      }
      return true;
    } else {
      throw new ArgumentError.value(value, "value", "could not be encoded");
    }
  }
}

abstract class SelfEncoder {
  const SelfEncoder();

  @override
  int get hashCode => const SelfEncoderEquality().hash(this);

  @override
  bool operator ==(other) {
    return other is SelfEncoder &&
        const SelfEncoderEquality().equals(this, other);
  }

  int encodedLength() => toImmutableBytes().length;

  int encodedMaxLength();

  /// Encode serialization of the value to the [ByteData].
  /// Returns index after writing bytes.
  void encodeSelf(RawWriter writer);

  ByteData toImmutableByteData() {
    final maxLength = encodedMaxLength();
    final writer = new RawWriter.withCapacity(maxLength);
    encodeSelf(writer);
    return writer.toByteDataView();
  }

  /// Shorthand for converting the value to bytes.
  /// The returned list must not be mutated.
  Uint8List toImmutableBytes() {
    final maxLength = encodedMaxLength();
    final writer = new RawWriter.withCapacity(maxLength);
    encodeSelf(writer);
    return writer.toUint8ListView();
  }

  @override
  String toString() {
    Uint8List bytes;
    try {
      bytes = toImmutableBytes();
    } catch (e) {
      return super.toString();
    }
    if (bytes.length > 255) {
      return super.toString();
    }
    final result = new StringBuffer();
    for (var i = 0; i < result.length; i++) {
      if (i % 4 == 0 && i > 0) {
        result.write(":");
      }
      final byte = bytes[i];
      result.write((byte >> 4).toRadixString(16));
      result.write((0xF & byte).toRadixString(16));
    }
    return result.toString();
  }
}

class SelfEncoderEquality implements Equality<SelfEncoder> {
  const SelfEncoderEquality();

  @override
  bool equals(SelfEncoder e1, SelfEncoder e2) {
    final bytes = e1.toImmutableBytes();
    final otherBytes = e2.toImmutableBytes();
    if (bytes.length != otherBytes.length) {
      return false;
    }
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != otherBytes[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int hash(SelfEncoder e) {
    final bytes = e.toImmutableBytes();
    var result = 0;
    for (var i = 0; i < bytes.length; i++) {
      result ^= bytes[i] << ((i * 7) % 24);
    }
    return result;
  }

  @override
  bool isValidKey(Object? o) => o is SelfEncoder;
}
