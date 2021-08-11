import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

abstract class CachableGroupElement {
  CachedGroupElement get toCached;
  // PreComputedGroupElement get toPreComputed;
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
