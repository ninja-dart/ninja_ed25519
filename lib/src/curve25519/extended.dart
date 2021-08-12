import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/cached.dart';
import 'package:ninja_ed25519/src/curve25519/completed.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/constants.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';
import 'package:ninja_ed25519/src/curve25519/point.dart';
import 'package:ninja_ed25519/src/curve25519/projective.dart';

class ExtendedGroupElement implements IPoint25519, CachablePoint {
  FieldElement X;
  FieldElement Y;
  FieldElement Z;
  FieldElement T;

  ExtendedGroupElement(
      {FieldElement? X, FieldElement? Y, FieldElement? Z, FieldElement? T})
      : X = X ?? FieldElement(),
        Y = Y ?? FieldElement.one(),
        Z = Z ?? FieldElement.one(),
        T = T ?? FieldElement();

  factory ExtendedGroupElement.fromBytes(Uint8List s) =>
      Point25519.fromBytes(s).toExtended;

  void zero() {
    X = FieldElement();
    Y = FieldElement.one();
    Z = FieldElement.one();
    T = FieldElement();
  }

  CompletedGroupElement get twice => toProjective.twice;

  @override
  Point25519 get toAffine {
    FieldElement recip = Z.inverted;
    return Point25519(x: X * recip, y: Y * recip);
  }

  @override
  ExtendedGroupElement get toExtended => this;

  @override
  CachedGroupElement get toCached =>
      CachedGroupElement(yPlusX: Y + X, yMinusX: Y - X, z: Z, t2d: T * d2);

  @override
  ProjectiveGroupElement get toProjective =>
      ProjectiveGroupElement(X: X, Y: Y, Z: Z);

  @override
  Uint8List get asBytes => toAffine.asBytes;

  CompletedGroupElement operator +(Object /* CachablePoint */ other) {
    if (other is CachablePoint) {
      CachedGroupElement q = other.toCached;

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
    } else if (other is PrecomputablePoint) {
      PreComputedGroupElement q = other.toPrecomputed;

      final r = CompletedGroupElement();
      r.X = Y + X;
      r.Y = Y - X;
      r.Z = r.X * q.yPlusX;
      r.Y = r.Y * q.yMinusX;
      r.T = q.xy2d * T;

      FieldElement t0 = Z + Z;
      r.X = r.Z - r.Y;
      r.Y = r.Z + r.Y;
      r.Z = t0 + r.T;
      r.T = t0 - r.T;
      return r;
    }

    throw ArgumentError('invalid argument');
  }

  CompletedGroupElement operator -(Object /* CachablePoint */ other) {
    if(other is CachablePoint) {
      final q = other.toCached;

      final r = CompletedGroupElement();
      r.X = Y + X;
      r.Y = Y - X;
      r.Z = r.X * q.yMinusX;
      r.Y = r.Y * q.yPlusX;
      r.T = q.t2d * T;

      FieldElement t0 = Z * q.z;
      t0 = t0 + t0;
      r.X = r.Z - r.Y;
      r.Y = r.Z + r.Y;
      r.Z = t0 - r.T;
      r.T = t0 + r.T;
      return r;
    } else if (other is PrecomputablePoint) {
      PreComputedGroupElement q = other.toPrecomputed;

      final r = CompletedGroupElement();
      r.X = Y + X;
      r.Y = Y - X;
      r.Z = r.X * q.yMinusX;
      r.Y = r.Y * q.yPlusX;
      r.T = q.xy2d * T;

      FieldElement t0 = Z + Z;
      r.X = r.Z - r.Y;
      r.Y = r.Z + r.Y;
      r.Z = t0 - r.T;
      r.T = t0 + r.T;
      return r;
    }

    throw ArgumentError('invalid argument');
  }
}
