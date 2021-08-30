import 'dart:typed_data';

import 'package:ninja_ed25519/curve.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Scalar', () {
    test('Scalar_fromString_hex_littleendian', () {
      final scalar = Scalar.fromString(
          '0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed');
      expect(scalar.toHex(),
          '7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed');
      expect(scalar.toIntString(),
          '57896044618658097711785492504343953926634992332820282019728792003956564819949');
      expect(scalar.toHex(endian: Endian.big),
          'edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f');
    });

    test('Scalar_fromString_hex_bigendian', () {
      final scalar = Scalar.fromString(
          '0xedffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f',
          endian: Endian.big);
      expect(scalar.toHex(),
          '7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed');
      expect(scalar.toIntString(),
          '57896044618658097711785492504343953926634992332820282019728792003956564819949');
    });
  });
}
