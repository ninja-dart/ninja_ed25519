import 'package:ninja_ed25519/src/curve25519/field_element/field_element.dart';

var d = FieldElement.fromList([
  -10913610,
  13857413,
  -15372611,
  6949391,
  114729,
  -8787816,
  -6275908,
  -3247719,
  -18696448,
  -12055116,
]);

/// d2 is 2*d.
var d2 = FieldElement.fromList([
  -21827239,
  -5839606,
  -30745221,
  13898782,
  229458,
  15978800,
  -12551817,
  -6495438,
  29715968,
  9444199,
]);

/// SqrtM1 is the square-root of -1 in the field.
var sqrtM1 = FieldElement.fromList([
  -32595792,
  -7943725,
  9377950,
  3500415,
  12389472,
  -272473,
  -25146209,
  -2005654,
  326686,
  11406482,
]);