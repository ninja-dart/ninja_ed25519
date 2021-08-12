import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';
import 'package:ninja_ed25519/src/curve25519/point.dart';
import 'package:ninja_ed25519/src/curve25519/projective.dart';

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

  Point25519 get toAffine => toProjective.toAffine;

  ProjectiveGroupElement get toProjective =>
      ProjectiveGroupElement(X: X * T, Y: Y * Z, Z: Z * T);

  ExtendedGroupElement get toExtended =>
      ExtendedGroupElement(X: X * T, Y: Y * Z, Z: Z * T, T: X * Y);

  CompletedGroupElement get twice => toProjective.twice;

  Uint8List get asBytes => toAffine.asBytes;
}
