import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/completed.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';
import 'package:ninja_ed25519/src/curve25519/point.dart';

/// Group elements are members of the elliptic curve -x^2 + y^2 = 1 + d * x^2 *
/// y^2 where d = -121665/121666.
///
/// Several representations are used:
///   ProjectiveGroupElement: (X:Y:Z) satisfying x=X/Z, y=Y/Z
///   ExtendedGroupElement: (X:Y:Z:T) satisfying x=X/Z, y=Y/Z, XY=ZT
///   CompletedGroupElement: ((X:Z),(Y:T)) satisfying x=X/Z, y=Y/T
///   PreComputedGroupElement: (y+x,y-x,2dxy)
class ProjectiveGroupElement implements IPoint25519 {
  FieldElement X;
  FieldElement Y;
  FieldElement Z;

  ProjectiveGroupElement({FieldElement? X, FieldElement? Y, FieldElement? Z})
      : X = X ?? FieldElement(),
        Y = Y ?? FieldElement.one(),
        Z = Z ?? FieldElement.one();

  factory ProjectiveGroupElement.fromBytes(Uint8List s) =>
      Point25519.fromBytes(s).toProjective;

  void zero() {
    X = FieldElement();
    Y = FieldElement.one();
    Z = FieldElement.one();
  }

  @override
  Point25519 get toAffine {
    FieldElement recip = Z.inverted;
    return Point25519(x: X * recip, y: Y * recip);
  }

  @override
  ProjectiveGroupElement get toProjective => this;

  @override
  ExtendedGroupElement get toExtended =>
      ExtendedGroupElement(X: X, Y: Y, Z: Z, T: X * Y * Z.inverted);

  CompletedGroupElement get twice {
    CompletedGroupElement r = CompletedGroupElement(
      X: X.squared,
      Y: X + Y,
      Z: Y.squared,
      T: Z.squaredMultiply2,
    );
    var t0 = r.Y.squared;
    r.Y = r.Z + r.X;
    r.Z = r.Z - r.X;
    r.X = t0 - r.Y;
    r.T = r.T - r.Z;
    return r;
  }

  @override
  Uint8List get asBytes => toAffine.asBytes;
}
