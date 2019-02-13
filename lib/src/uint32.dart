/// Replaces bits specified by `shift` and `mask`.
int transformUint32Bits(int uint32, int shift, int mask, int newValue) {
  if (mask | newValue != mask) {
    throw new ArgumentError.value(newValue, "newValue", "too many bits");
  }
  return ((0xFFFFFFFF ^ (mask << shift)) & uint32) | (newValue << shift);
}

/// Replaces a single bit of a 32-bit unsigned integer.
int transformUint32Bool(int uint32, int shift, bool newValue) {
  return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) |
      ((newValue ? 1 : 0) << shift);
}

/// Takes a 32-bit unsigned integer and returns bits specified by `shift` and `mask`.
///
/// Example:
///   viewUint32(0xF0A0, 8, 0xF) // --> 0xA
int extractUint32Bits(int uint32, int shift, int mask) {
  return mask & (uint32 >> shift);
}

/// Takes a 32-bit unsigned integer and returns a single bit as a boolean.
///
/// Example:
///   viewUint32Bool(0xF010, 8) // --> true
bool extractUint32Bool(int uint32, int shift) {
  return 0x1 & (uint32 >> shift) != 0;
}
