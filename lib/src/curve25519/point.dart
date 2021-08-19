import 'dart:html';
import 'dart:typed_data';

import 'package:ninja_ed25519/curve.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/constants.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';
import 'package:ninja_ed25519/src/curve25519/projective.dart';
import 'package:ninja_ed25519/src/util/hex.dart';

abstract class IPoint25519 {
  Point25519 get toAffine;
  ProjectiveGroupElement get toProjective;
  ExtendedGroupElement get toExtended;
  Uint8List get asBytes;
}

class Point25519 implements IPoint25519 {
  FieldElement x;
  FieldElement y;
  Point25519({FieldElement? x, FieldElement? y})
      : x = x ?? FieldElement(),
        y = y ?? FieldElement.one();

  factory Point25519.fromHex(String hex) {
    if (hex.length != 64) {
      throw ArgumentError.value(hex, 'hex', 'invalid key length');
    }
    final bytes = hex64ToBytes(hex);
    return Point25519.fromBytes(bytes);
  }

  factory Point25519.fromBytes(Uint8List s) {
    FieldElement tY = FieldElement.fromBytes(s);
    FieldElement tZ = FieldElement.one();
    FieldElement u = tY.squared;
    FieldElement v = u * d;
    u = u - tZ; // y = y^2-1
    v = v + tZ; // v = dy^2+1

    FieldElement v3 = v * v * v;
    FieldElement tX = v3.squared;
    tX = tX * v;
    tX = tX * u; // x = uv^7

    tX = tX.pow22523; // x = (uv^7)^((q-5)/8)
    tX = tX * v3;
    tX = tX * u; // x = uv^3(uv^7)^((q-5)/8)

    FieldElement vxx = tX.squared;
    vxx = vxx * v;
    FieldElement check = vxx - u; // vx^2-u
    if (check.isNonZero) {
      check = vxx + u; // vx^2+u
      if (check.isNonZero) {
        throw Exception('error converting bytes to ExtendedGroupElement');
      }
      tX = tX * sqrtM1;
    }

    if (tX.isNegative != (s[31] & 0x80 != 0)) {
      tX = -tX;
    }

    return Point25519(x: tX, y: tY);
  }

  void zero() {
    x = FieldElement();
    y = FieldElement.one();
  }

  @override
  Point25519 get toAffine => this;

  @override
  ProjectiveGroupElement get toProjective => ProjectiveGroupElement(
        X: x,
        Y: y,
        Z: FieldElement.one(),
      );

  @override
  ExtendedGroupElement get toExtended =>
      ExtendedGroupElement(X: x, Y: y, Z: FieldElement.one(), T: x * y);

  @override
  Uint8List get asBytes {
    Uint8List s = y.asBytes;
    if (x.isNegative) {
      s[31] ^= 0x80;
    }
    return s;
  }

  Point25519 get clone => Point25519(x: x.clone, y: y.clone);

  Point25519 operator +(IPoint25519 other) {
    final added = toExtended + other.toExtended;
    return added.toAffine;
  }

  Point25519 operator %(BigInt mod) => Point25519(x: x % mod, y: y % mod);

  Point25519 multiplyScalar(BigInt other, BigInt mod) {
    if (other == BigInt.zero) {
      return Point25519();
    }
    BigInt mask = other;
    Point25519 ret = Point25519();
    Point25519 pivot = clone;
    while (mask != BigInt.zero) {
      if (other.isOdd) {
        ret = (ret + pivot) % mod;
      }
      mask >>= 1;
      pivot = (pivot + pivot) % mod;
    }
    return ret;
  }
}
