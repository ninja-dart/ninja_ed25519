import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

abstract class CachablePoint {
  CachedGroupElement get toCached;
  // PreComputedGroupElement get toPreComputed;
}

abstract class PrecomputablePoint {
  PreComputedGroupElement get toPrecomputed;
// PreComputedGroupElement get toPreComputed;
}

class PreComputedGroupElement implements PrecomputablePoint {
  FieldElement yPlusX;
  FieldElement yMinusX;
  FieldElement xy2d;

  PreComputedGroupElement(
      {FieldElement? yPlusX, FieldElement? yMinusX, FieldElement? xy2d})
      : yPlusX = yPlusX ?? FieldElement.one(),
        yMinusX = yMinusX ?? FieldElement.one(),
        xy2d = xy2d ?? FieldElement();

  PreComputedGroupElement.positional(this.yPlusX, this.yMinusX, this.xy2d);

  void zero() {
    yPlusX = FieldElement.one();
    yMinusX = FieldElement.one();
    xy2d = FieldElement();
  }

  void set(PreComputedGroupElement other) {
    yPlusX.set(other.yPlusX);
    yMinusX.set(other.yMinusX);
    xy2d.set(other.xy2d);
  }

  @override
  PreComputedGroupElement get toPrecomputed => this;
}

class CachedGroupElement implements CachablePoint {
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
