import 'dart:typed_data';

import 'package:ninja_ed25519/curve.dart';
import 'package:ninja_ed25519/ninja_ed25519.dart';
import 'package:test/test.dart';

void main() {
  group('PrivateKey', () {
    test('FromHex', () {
      final k = Scalar.fromString(
          '96d54cd4f1d71e10a1eb76125aad65219cded6a987fd0b6cc1f758417b99d20c',
          radix: 16,
          endian: Endian.big);
      expect(k.toBytes(), [
        150,
        213,
        76,
        212,
        241,
        215,
        30,
        16,
        161,
        235,
        118,
        18,
        90,
        173,
        101,
        33,
        156,
        222,
        214,
        169,
        135,
        253,
        11,
        108,
        193,
        247,
        88,
        65,
        123,
        153,
        210,
        12
      ]);
    });
  });
}
