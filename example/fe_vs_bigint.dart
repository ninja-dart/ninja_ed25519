import 'dart:typed_data';

import 'package:ninja/ninja.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

void main() {
  final bytes = Uint8List(32);
  bytes[0] = 0x5a;
  bytes[1] = 0x5a;
  bytes[15] = 0x5a;
  final fe = FieldElement.fromBytes(bytes);
  final fei = fe.inverted;
  BigInt bi = bytes.reversed.asBigInt;
  BigInt inv = fei.asBytes.reversed.asBigInt;
  print(bi);
  print(inv);
  print((fe * fei).asBytes.reversed.asBigInt);

  print(bi * inv);
}
