import 'package:raw/raw.dart';

class ExampleStruct extends RawValue {
  int intField = 0;
  String stringField = "";

  @override
  void decodeRaw(RawReader reader) {
    intField = reader.readVarInt();
    stringField = reader.readUtf8NullEnding();
  }

  @override
  void encodeRaw(RawWriter writer) {
    writer.writeVarInt(intField);
    writer.writeUtf8(stringField);
  }
}
