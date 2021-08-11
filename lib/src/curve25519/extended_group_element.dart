import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/field_element/constants.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

abstract class CachableGroupElement {
  CachedGroupElement get toCached;
  // PreComputedGroupElement get toPreComputed;
}

/// Group elements are members of the elliptic curve -x^2 + y^2 = 1 + d * x^2 *
/// y^2 where d = -121665/121666.
///
/// Several representations are used:
///   ProjectiveGroupElement: (X:Y:Z) satisfying x=X/Z, y=Y/Z
///   ExtendedGroupElement: (X:Y:Z:T) satisfying x=X/Z, y=Y/Z, XY=ZT
///   CompletedGroupElement: ((X:Z),(Y:T)) satisfying x=X/Z, y=Y/T
///   PreComputedGroupElement: (y+x,y-x,2dxy)
class ProjectiveGroupElement {
  FieldElement X;
  FieldElement Y;
  FieldElement Z;

  ProjectiveGroupElement({FieldElement? X, FieldElement? Y, FieldElement? Z})
      : X = X ?? FieldElement(),
        Y = Y ?? FieldElement(),
        Z = Z ?? FieldElement();

  void zero() {
    X = FieldElement();
    Y = FieldElement.one();
    Z = FieldElement.one();
  }

  CompletedGroupElement get twice {
    CompletedGroupElement r = CompletedGroupElement(
      X: X.squared,
      Y: X + Y,
      Z: Y.squared,
      T: Z.squared * 2,
    );
    var t0 = r.Y.squared;
    r.Y = r.Z + r.X;
    r.Z = r.Z - r.X;
    r.X = t0 - r.Y;
    r.T = r.T - r.Z;
    return r;
  }

  Uint8List get asBytes {
    FieldElement recip = Z.inverted;
    FieldElement x = X * recip;
    FieldElement y = Y * recip;
    Uint8List s = y.asBytes;
    if (x.isNegative) {
      s[31] ^= 0x80;
    }

    return s;
  }
}

class ExtendedGroupElement implements CachableGroupElement {
  FieldElement X;
  FieldElement Y;
  FieldElement Z;
  FieldElement T;

  ExtendedGroupElement(
      {FieldElement? X, FieldElement? Y, FieldElement? Z, FieldElement? T})
      : X = X ?? FieldElement(),
        Y = Y ?? FieldElement(),
        Z = Z ?? FieldElement(),
        T = T ?? FieldElement();

  factory ExtendedGroupElement.fromBytes(Uint8List bytes) {
    return ExtendedGroupElement()..copyFromBytes(bytes);
  }

  void zero() {
    X = FieldElement();
    Y = FieldElement.one();
    Z = FieldElement.one();
    T = FieldElement();
  }

  CompletedGroupElement get twice => toProjective.twice;

  @override
  CachedGroupElement get toCached =>
      CachedGroupElement(yPlusX: Y + X, yMinusX: Y - X, z: Z, t2d: T * d2);

  ProjectiveGroupElement get toProjective =>
      ProjectiveGroupElement(X: X, Y: Y, Z: Z);

  Uint8List get toBytes {
    FieldElement recip = Z.inverted;
    FieldElement x = X * recip;
    FieldElement y = Y * recip;
    final Uint8List s = y.asBytes;
    if (x.isNegative) {
      s[31] ^= 0x80;
    }
    return s;
  }

  void copyFromBytes(Uint8List s) {
    FieldElement tY = FieldElement.fromBytes(s);
    FieldElement tZ = FieldElement.one();
    FieldElement u = tY.squared;
    FieldElement v = u * d;
    u = u - tZ; // y = y^2-1
    v = v + tZ; // v = dy^2+1

    FieldElement v3 = v.squared;
    v3 = v3 * v; // v3 = v^3
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

    X = tX;
    Y = tY;
    Z = tZ;
    T = X * Y;
  }

  CompletedGroupElement operator +(CachableGroupElement other) {
    final q = other.toCached;

    final r = CompletedGroupElement();
    r.X = Y + X;
    r.Y = Y - X;
    r.Z = r.X * q.yPlusX;
    r.Y = r.Y * q.yMinusX;
    r.T = q.t2d * T;
    FieldElement t0 = Z * q.z;
    t0 = t0 + t0;
    r.X = r.Z - r.Y;
    r.Y = r.Z + r.Y;
    r.Z = t0 + r.T;
    r.T = t0 - r.T;
    return r;
  }

  CompletedGroupElement operator -(CachedGroupElement other) {
    final q = other.toCached;

    final r = CompletedGroupElement();
    r.X = Y + X;
    r.Y = Y - X;
    r.Z = r.X * q.yMinusX;
    r.Y = r.Y * q.yPlusX;
    r.T = q.t2d * T;
    r.X = Z * q.z;
    FieldElement t0 = r.X + r.X;
    r.X = r.Z - r.Y;
    r.Y = r.Z + r.Y;
    r.Z = t0 - r.T;
    r.T = t0 + r.T;
    return r;
  }
}

class CompletedGroupElement {
  FieldElement X;
  FieldElement Y;
  FieldElement Z;
  FieldElement T;

  CompletedGroupElement(
      {FieldElement? X, FieldElement? Y, FieldElement? Z, FieldElement? T})
      : X = X ?? FieldElement(),
        Y = Y ?? FieldElement(),
        Z = Z ?? FieldElement(),
        T = T ?? FieldElement();

  ProjectiveGroupElement get toProjective =>
      ProjectiveGroupElement(X: X * T, Y: Y * Z, Z: Z * T);

  ExtendedGroupElement get toExtended =>
      ExtendedGroupElement(X: X * T, Y: Y * Z, Z: Z * T, T: X * Y);
}

class PreComputedGroupElement {
  FieldElement yPlusX;
  FieldElement yMinusX;
  FieldElement xy2d;

  PreComputedGroupElement(
      {FieldElement? yPlusX, FieldElement? yMinusX, FieldElement? xy2d})
      : yPlusX = yPlusX ?? FieldElement(),
        yMinusX = yMinusX ?? FieldElement(),
        xy2d = xy2d ?? FieldElement();

  void zero() {
    yPlusX = FieldElement.one();
    yMinusX = FieldElement.one();
    xy2d = FieldElement();
  }
}

class CachedGroupElement implements CachableGroupElement {
  FieldElement yPlusX;
  FieldElement yMinusX;
  FieldElement z;
  FieldElement t2d;

  CachedGroupElement(
      {FieldElement? yPlusX,
      FieldElement? yMinusX,
      FieldElement? z,
      FieldElement? t2d})
      : yPlusX = yPlusX ?? FieldElement(),
        yMinusX = yMinusX ?? FieldElement(),
        z = z ?? FieldElement(),
        t2d = t2d ?? FieldElement();

  @override
  CachedGroupElement get toCached => this;
}
