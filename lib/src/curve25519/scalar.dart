import 'package:ninja/ninja.dart';
import 'dart:typed_data';

class Scalar {
  BigInt value;

  Scalar(this.value);

  factory Scalar.fromBytes(Iterable<int> bytes,
      {Endian endian = Endian.little}) {
    if (endian == Endian.big) {
      bytes = bytes.toList().reversed;
    }
    return Scalar(bytes.asBigInt(endian: Endian.little));
  }

  factory Scalar.fromString(String string,
      {int? radix, Endian endian = Endian.little}) {
    final bigInt = BigInt.parse(string, radix: radix);
    if (endian == Endian.big) {
      return Scalar.fromBigEndian(bigInt);
    }
    return Scalar(bigInt);
  }

  factory Scalar.fromBigEndian(BigInt value) {
    return Scalar(value.asBytes(outLen: 32, endian: Endian.little).asBigInt());
  }

  String toHex({int? outLen = 32, Endian endian = Endian.little}) =>
      value.asBytes(outLen: 32, endian: Endian.little).toHex(endian: endian);

  String toIntString({Endian endian = Endian.little}) {
    return value
        .asBytes(outLen: 32, endian: Endian.little)
        .asBigInt(endian: endian)
        .toString();
  }
}
