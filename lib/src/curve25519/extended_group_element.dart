import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/field_element/constants.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

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

class ExtendedGroupElement {
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

  void zero() {
    X = FieldElement();
    Y = FieldElement.one();
    Z = FieldElement.one();
    T = FieldElement();
  }

  CompletedGroupElement get twice => toProjective.twice;

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

  bool FromBytes(Uint8List s) {
    var u = FieldElement();
    var v = FieldElement();
    var v3 = FieldElement();
    var vxx = FieldElement();
    var check = FieldElement();

    FeFromBytes(Y, s);
    FeOne(Z);
    FeSquare(u, Y);
    FeMul(v, u, d);
    FeSub(u, u, Z); // y = y^2-1
    FeAdd(v, v, Z); // v = dy^2+1

    FeSquare(v3, v);
    FeMul(v3, v3, v); // v3 = v^3
    FeSquare(X, v3);
    FeMul(X, X, v);
    FeMul(X, X, u); // x = uv^7

    fePow22523(X, X); // x = (uv^7)^((q-5)/8)
    FeMul(X, X, v3);
    FeMul(X, X, u); // x = uv^3(uv^7)^((q-5)/8)

    var tmpX = Uint8List(32);
    var tmp2 = Uint8List(32);

    FeSquare(vxx, X);
    FeMul(vxx, vxx, v);
    FeSub(check, vxx, u); // vx^2-u
    if (FeIsNonZero(check) == 1) {
      FeAdd(check, vxx, u); // vx^2+u
      if (FeIsNonZero(check) == 1) {
        return false;
      }
      FeMul(X, X, SqrtM1);

      FeToBytes(tmpX, X);
      for (var i = 0; i < tmp2.length; i++) {
        tmp2[31 - i] = tmp2[i];
      }
    }

    if (FeIsNegative(X) != (s[31] >> 7)) {
      FeNeg(X, X);
    }

    FeMul(T, X, Y);
    return true;
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

class CachedGroupElement {
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
}
