import 'dart:typed_data';

import 'package:ninja/ninja.dart';

import 'package:ninja_ed25519/src/curve25519/field_element/combine.dart';
import 'package:ninja_ed25519/src/util/int.dart';

/// FieldElement represents an element of the field GF(2^255 - 19).  An element
/// t, entries t[0]...t[9], represents the integer t[0]+2^26 t[1]+2^51 t[2]+2^77
/// t[3]+2^102 t[4]+...+2^230 t[9].  Bounds on each t[i] vary depending on
/// context.
class FieldElement {
  final List<int> elements;
  FieldElement() : elements = List<int>.filled(10, 0, growable: false);
  const FieldElement.constant(this.elements);

  factory FieldElement.fromList(Iterable<int> list) =>
      FieldElement()..copyFrom(list);

  factory FieldElement.fromBytes(Iterable<int> src) =>
      FieldElement()..copyFromBytes(src);
  factory FieldElement.fromBigInt(BigInt number) {
    if (number.isNegative) {
      throw ArgumentError.value(number, 'number', 'should be positive');
    } else if (number.bitLength > 256) {
      throw ArgumentError.value(
          number, 'number', 'should be less than 256 bits long');
    }
    return FieldElement.fromBytes(
        Uint8List.fromList(number.asBytes(outLen: 32).reversed.toList()));
  }
  static FieldElement one() => FieldElement()..[0] = 1;

  int operator [](int index) {
    return elements[index];
  }

  void operator []=(int index, int value) {
    elements[index] = value;
  }

  int get length => elements.length;

  void set(FieldElement other) {
    for (int i = 0; i < elements.length; i++) {
      elements[i] = other[i];
    }
  }

  void copyFrom(Iterable<int> src) {
    for (int i = 0; i < elements.length; i++) {
      elements[i] = src.elementAt(i);
    }
  }

  void copyFromBytes(Iterable<int> src) {
    elements[0] = load4(src.take(src.length));
    elements[1] = load3(src.skip(4)) << 6;
    elements[2] = load3(src.skip(7)) << 5;
    elements[3] = load3(src.skip(10)) << 3;
    elements[4] = load3(src.skip(13)) << 2;
    elements[5] = load4(src.skip(16));
    elements[6] = load3(src.skip(20)) << 7;
    elements[7] = load3(src.skip(23)) << 5;
    elements[8] = load3(src.skip(26)) << 4;
    elements[9] = (load3(src.skip(29)) & 8388607) << 2;
    combine(elements);
  }

  FieldElement operator +(FieldElement other) {
    final dst = FieldElement();
    for (int i = 0; i < elements.length; i++) {
      dst[i] = elements[i] + other[i];
    }
    return dst;
  }

  FieldElement operator -(FieldElement other) {
    final dst = FieldElement();
    for (int i = 0; i < elements.length; i++) {
      dst[i] = elements[i] - other[i];
    }
    return dst;
  }

  /// FeNeg sets h = -f
  ///
  /// Preconditions:
  ///    |f| bounded by 1.1*2^25,1.1*2^24,1.1*2^25,1.1*2^24,etc.
  ///
  /// Postconditions:
  ///    |h| bounded by 1.1*2^25,1.1*2^24,1.1*2^25,1.1*2^24,etc.
  FieldElement operator -() {
    final dst = FieldElement();
    for (int i = 0; i < elements.length; i++) {
      dst[i] = -elements[i];
    }
    return dst;
  }

  FieldElement operator %(Object /* int | BigInt | FieldElement */ other) {
    BigInt v;
    if (other is BigInt) {
      v = other;
    } else if (other is FieldElement) {
      v = other.asBigInt;
    } else if (other is int) {
      v = BigInt.from(other);
    } else {
      throw Exception('invalid type');
    }
    if (v.isNegative) {
      throw Exception('cannot be negative');
    }
    final resInt = asBigInt % v;
    return FieldElement.fromBigInt(resInt);
  }

  /// calculates h = f * g
  ///
  /// Preconditions:
  ///    |f| bounded by 1.1*2^26,1.1*2^25,1.1*2^26,1.1*2^25,etc.
  ///    |g| bounded by 1.1*2^26,1.1*2^25,1.1*2^26,1.1*2^25,etc.
  ///
  /// Postconditions:
  ///    |h| bounded by 1.1*2^25,1.1*2^24,1.1*2^25,1.1*2^24,etc.
  ///
  /// Notes on implementation strategy:
  ///
  /// Using schoolbook multiplication.
  /// Karatsuba would save a little in some cost models.
  ///
  /// Most multiplications by 2 and 19 are 32-bit precomputations;
  /// cheaper than 64-bit postcomputations.
  ///
  /// There is one remaining multiplication by 19 in the carry chain;
  /// one *19 precomputation can be merged into this,
  /// but the resulting data flow is considerably less clean.
  ///
  /// There are 12 carries below.
  /// 10 of them are 2-way parallelizable and vectorizable.
  /// Can get away with 11 carries, but then data flow is much deeper.
  ///
  /// With tighter constraints on inputs, can squeeze carries into int32.
  FieldElement operator *(FieldElement g) {
    /*if (this == g) {
      return squared;
    }*/

    var f0 = elements[0];
    var f1 = elements[1];
    var f2 = elements[2];
    var f3 = elements[3];
    var f4 = elements[4];
    var f5 = elements[5];
    var f6 = elements[6];
    var f7 = elements[7];
    var f8 = elements[8];
    var f9 = elements[9];

    var f1_2 = 2 * elements[1];
    var f3_2 = 2 * elements[3];
    var f5_2 = 2 * elements[5];
    var f7_2 = 2 * elements[7];
    var f9_2 = 2 * elements[9];

    var g0 = g[0];
    var g1 = g[1];
    var g2 = g[2];
    var g3 = g[3];
    var g4 = g[4];
    var g5 = g[5];
    var g6 = g[6];
    var g7 = g[7];
    var g8 = g[8];
    var g9 = g[9];

    var g1_19 = 19 * g[1]; /* 1.4*2^29 */
    var g2_19 = 19 * g[2]; /* 1.4*2^30; still ok */
    var g3_19 = 19 * g[3];
    var g4_19 = 19 * g[4];
    var g5_19 = 19 * g[5];
    var g6_19 = 19 * g[6];
    var g7_19 = 19 * g[7];
    var g8_19 = 19 * g[8];
    var g9_19 = 19 * g[9];

    final h = FieldElement();
    h[0] = f0 * g0 +
        f1_2 * g9_19 +
        f2 * g8_19 +
        f3_2 * g7_19 +
        f4 * g6_19 +
        f5_2 * g5_19 +
        f6 * g4_19 +
        f7_2 * g3_19 +
        f8 * g2_19 +
        f9_2 * g1_19;
    h[1] = f0 * g1 +
        f1 * g0 +
        f2 * g9_19 +
        f3 * g8_19 +
        f4 * g7_19 +
        f5 * g6_19 +
        f6 * g5_19 +
        f7 * g4_19 +
        f8 * g3_19 +
        f9 * g2_19;
    h[2] = f0 * g2 +
        f1_2 * g1 +
        f2 * g0 +
        f3_2 * g9_19 +
        f4 * g8_19 +
        f5_2 * g7_19 +
        f6 * g6_19 +
        f7_2 * g5_19 +
        f8 * g4_19 +
        f9_2 * g3_19;
    h[3] = f0 * g3 +
        f1 * g2 +
        f2 * g1 +
        f3 * g0 +
        f4 * g9_19 +
        f5 * g8_19 +
        f6 * g7_19 +
        f7 * g6_19 +
        f8 * g5_19 +
        f9 * g4_19;
    h[4] = f0 * g4 +
        f1_2 * g3 +
        f2 * g2 +
        f3_2 * g1 +
        f4 * g0 +
        f5_2 * g9_19 +
        f6 * g8_19 +
        f7_2 * g7_19 +
        f8 * g6_19 +
        f9_2 * g5_19;
    h[5] = f0 * g5 +
        f1 * g4 +
        f2 * g3 +
        f3 * g2 +
        f4 * g1 +
        f5 * g0 +
        f6 * g9_19 +
        f7 * g8_19 +
        f8 * g7_19 +
        f9 * g6_19;
    h[6] = f0 * g6 +
        f1_2 * g5 +
        f2 * g4 +
        f3_2 * g3 +
        f4 * g2 +
        f5_2 * g1 +
        f6 * g0 +
        f7_2 * g9_19 +
        f8 * g8_19 +
        f9_2 * g7_19;
    h[7] = f0 * g7 +
        f1 * g6 +
        f2 * g5 +
        f3 * g4 +
        f4 * g3 +
        f5 * g2 +
        f6 * g1 +
        f7 * g0 +
        f8 * g9_19 +
        f9 * g8_19;
    h[8] = f0 * g8 +
        f1_2 * g7 +
        f2 * g6 +
        f3_2 * g5 +
        f4 * g4 +
        f5_2 * g3 +
        f6 * g2 +
        f7_2 * g1 +
        f8 * g0 +
        f9_2 * g9_19;
    h[9] = f0 * g9 +
        f1 * g8 +
        f2 * g7 +
        f3 * g6 +
        f4 * g5 +
        f5 * g4 +
        f6 * g3 +
        f7 * g2 +
        f8 * g1 +
        f9 * g0;

    combine(h.elements);
    return h;
  }

  List<int> get _square {
    var f0 = elements[0];
    var f1 = elements[1];
    var f2 = elements[2];
    var f3 = elements[3];
    var f4 = elements[4];
    var f5 = elements[5];
    var f6 = elements[6];
    var f7 = elements[7];
    var f8 = elements[8];
    var f9 = elements[9];
    var f0_2 = 2 * elements[0];
    var f1_2 = 2 * elements[1];
    var f2_2 = 2 * elements[2];
    var f3_2 = 2 * elements[3];
    var f4_2 = 2 * elements[4];
    var f5_2 = 2 * elements[5];
    var f6_2 = 2 * elements[6];
    var f7_2 = 2 * elements[7];
    var f5_38 = 38 * f5; // 1.31*2^30
    var f6_19 = 19 * f6; // 1.31*2^30
    var f7_38 = 38 * f7; // 1.31*2^30
    var f8_19 = 19 * f8; // 1.31*2^30
    var f9_38 = 38 * f9; // 1.31*2^30

    final h = List<int>.filled(10, 0, growable: false);
    h[0] = f0 * f0 +
        f1_2 * f9_38 +
        f2_2 * f8_19 +
        f3_2 * f7_38 +
        f4_2 * f6_19 +
        f5 * f5_38;
    h[1] = f0_2 * f1 + f2 * f9_38 + f3_2 * f8_19 + f4 * f7_38 + f5_2 * f6_19;
    h[2] = f0_2 * f2 +
        f1_2 * f1 +
        f3_2 * f9_38 +
        f4_2 * f8_19 +
        f5_2 * f7_38 +
        f6 * f6_19;
    h[3] = f0_2 * f3 + f1_2 * f2 + f4 * f9_38 + f5_2 * f8_19 + f6 * f7_38;
    h[4] = f0_2 * f4 +
        f1_2 * f3_2 +
        f2 * f2 +
        f5_2 * f9_38 +
        f6_2 * f8_19 +
        f7 * f7_38;
    h[5] = f0_2 * f5 + f1_2 * f4 + f2_2 * f3 + f6 * f9_38 + f7_2 * f8_19;
    h[6] = f0_2 * f6 +
        f1_2 * f5_2 +
        f2_2 * f4 +
        f3_2 * f3 +
        f7_2 * f9_38 +
        f8 * f8_19;
    h[7] = f0_2 * f7 + f1_2 * f6 + f2_2 * f5 + f3_2 * f4 + f8 * f9_38;
    h[8] = f0_2 * f8 +
        f1_2 * f7_2 +
        f2_2 * f6 +
        f3_2 * f5_2 +
        f4 * f4 +
        f9 * f9_38;
    h[9] = f0_2 * f9 + f1_2 * f8 + f2_2 * f7 + f3_2 * f6 + f4_2 * f5;
    return h;
  }

  /// calculates h = f*f.
  ///
  /// Preconditions:
  ///    |f| bounded by 1.1*2^26,1.1*2^25,1.1*2^26,1.1*2^25,etc.
  ///
  /// Postconditions:
  ///    |h| bounded by 1.1*2^25,1.1*2^24,1.1*2^25,1.1*2^24,etc.
  FieldElement get squared {
    final h = _square;
    combine(h);
    return FieldElement.fromList(h);
  }

  FieldElement get squaredMultiply2 {
    final h = _square;
    for (int i = 0; i < h.length; i++) {
      h[i] += h[i];
    }
    combine(h);
    return FieldElement.fromList(h);
  }

  /// Marshals h to s.
  /// Preconditions:
  ///   |h| bounded by 1.1*2^25,1.1*2^24,1.1*2^25,1.1*2^24,etc.
  ///
  /// Write p=2^255-19; q=floor(h/p).
  /// Basic claim: q = floor(2^(-255)(h + 19 2^(-25)h9 + 2^(-1))).
  ///
  /// Proof:
  ///   Have |h|<=p so |q|<=1 so |19^2 2^(-255) q|<1/4.
  ///   Also have |h-2^230 h9|<2^230 so |19 2^(-255)(h-2^230 h9)|<1/4.
  ///
  ///   Write y=2^(-1)-19^2 2^(-255)q-19 2^(-255)(h-2^230 h9).
  ///   Then 0<y<1.
  ///
  ///   Write r=h-pq.
  ///   Have 0<=r<=p-1=2^255-20.
  ///   Thus 0<=r+19(2^-255)r<r+19(2^-255)2^255<=2^255-1.
  ///
  ///   Write x=r+19(2^-255)r+y.
  ///   Then 0<x<2^255 so floor(2^(-255)x) = 0 so floor(q+2^(-255)x) = q.
  ///
  ///   Have q+2^(-255)x = 2^(-255)(h + 19 2^(-25) h9 + 2^(-1))
  ///   so floor(2^(-255)(h + 19 2^(-25) h9 + 2^(-1))) = q.
  Uint8List get asBytes {
    var carry = List<int>.filled(10, 0);
    final h = elements.toList(growable: false);

    var q = (19 * h[9] + (1 << 24)) >> 25;
    q = (h[0] + q) >> 26;
    q = (h[1] + q) >> 25;
    q = (h[2] + q) >> 26;
    q = (h[3] + q) >> 25;
    q = (h[4] + q) >> 26;
    q = (h[5] + q) >> 25;
    q = (h[6] + q) >> 26;
    q = (h[7] + q) >> 25;
    q = (h[8] + q) >> 26;
    q = (h[9] + q) >> 25;

    // Goal: Output h-(2^255-19)q, which is between 0 and 2^255-20.
    h[0] += 19 * q;
    // Goal: Output h-2^255 q, which is between 0 and 2^255-20.

    carry[0] = h[0] >> 26;
    h[1] += carry[0];
    h[0] -= carry[0] << 26;
    carry[1] = h[1] >> 25;
    h[2] += carry[1];
    h[1] -= carry[1] << 25;
    carry[2] = h[2] >> 26;
    h[3] += carry[2];
    h[2] -= carry[2] << 26;
    carry[3] = h[3] >> 25;
    h[4] += carry[3];
    h[3] -= carry[3] << 25;
    carry[4] = h[4] >> 26;
    h[5] += carry[4];
    h[4] -= carry[4] << 26;
    carry[5] = h[5] >> 25;
    h[6] += carry[5];
    h[5] -= carry[5] << 25;
    carry[6] = h[6] >> 26;
    h[7] += carry[6];
    h[6] -= carry[6] << 26;
    carry[7] = h[7] >> 25;
    h[8] += carry[7];
    h[7] -= carry[7] << 25;
    carry[8] = h[8] >> 26;
    h[9] += carry[8];
    h[8] -= carry[8] << 26;
    carry[9] = h[9] >> 25;
    h[9] -= carry[9] << 25;
    // h10 = carry9

    // Goal: Output h[0]+...+2^255 h10-2^255 q, which is between 0 and 2^255-20.
    // Have h[0]+...+2^230 h[9] between 0 and 2^255-1;
    // evidently 2^255 h10-2^255 q = 0.
    // Goal: Output h[0]+...+2^230 h[9].

    final s = Uint8List(32);
    s[0] = h[0] >> 0;
    s[1] = h[0] >> 8;
    s[2] = h[0] >> 16;
    s[3] = (h[0] >> 24) | (h[1] << 2);
    s[4] = h[1] >> 6;
    s[5] = h[1] >> 14;
    s[6] = (h[1] >> 22) | (h[2] << 3);
    s[7] = h[2] >> 5;
    s[8] = h[2] >> 13;
    s[9] = (h[2] >> 21) | (h[3] << 5);
    s[10] = h[3] >> 3;
    s[11] = h[3] >> 11;
    s[12] = (h[3] >> 19) | (h[4] << 6);
    s[13] = h[4] >> 2;
    s[14] = h[4] >> 10;
    s[15] = h[4] >> 18;
    s[16] = h[5] >> 0;
    s[17] = h[5] >> 8;
    s[18] = h[5] >> 16;
    s[19] = (h[5] >> 24) | (h[6] << 1);
    s[20] = h[6] >> 7;
    s[21] = h[6] >> 15;
    s[22] = (h[6] >> 23) | (h[7] << 3);
    s[23] = h[7] >> 5;
    s[24] = h[7] >> 13;
    s[25] = (h[7] >> 21) | (h[8] << 4);
    s[26] = h[8] >> 4;
    s[27] = h[8] >> 12;
    s[28] = (h[8] >> 20) | (h[9] << 6);
    s[29] = h[9] >> 2;
    s[30] = h[9] >> 10;
    s[31] = h[9] >> 18;
    return s;
  }

  bool get isNegative {
    return asBytes[0] & 1 == 1;
  }

  bool get isNonZero {
    final bytes = asBytes;
    var x = 0;
    for (int i = 0; i < bytes.length; i++) {
      x |= bytes[i];
    }
    return x != 0;
  }

  FieldElement get inverted {
    FieldElement t0 = squared; // 2^1
    FieldElement t1 = t0.squared; // 2^2
    t1 = t1.squared; // 2^3

    t1 = this * t1; // 2^3 + 2^0
    t0 = t0 * t1; // 2^3 + 2^1 + 2^0
    FieldElement t2 = t0.squared; // 2^4 + 2^2 + 2^1
    t1 = t1 * t2; // 2^4 + 2^3 + 2^2 + 2^1 + 2^0
    t2 = t1.squared; // 5,4,3,2,1
    for (int i = 1; i < 5; i++) {
      t2 = t2.squared; // 9,8,7,6,5
    }
    t1 = t2 * t1; // 9,8,7,6,5,4,3,2,1,0
    t2 = t1.squared; // 10..1
    for (int i = 1; i < 10; i++) {
      t2 = t2.squared; // 19..10
    }
    t2 = t2 * t1; // 19..0
    FieldElement t3 = t2.squared; // 20..1
    for (int i = 1; i < 20; i++) {
      t3 = t3.squared; // 39..20
    }
    t2 = t3 * t2; // 39..0
    t2 = t2.squared; // 40..1
    for (int i = 1; i < 10; i++) {
      t2 = t2.squared; // 49..10
    }
    t1 = t2 * t1; // 49..0
    t2 = t1.squared; // 50..1
    for (int i = 1; i < 50; i++) {
      t2 = t2.squared; // 99..50
    }
    t2 = t2 * t1; // 99..0
    t3 = t2.squared; // 100..1
    for (int i = 1; i < 100; i++) {
      t3 = t3.squared; // 199..100
    }
    t2 = t3 * t2; // 199..0
    t2 = t2.squared; // 200..1
    for (int i = 1; i < 50; i++) {
      t2 = t2.squared; // 249..50
    }
    t1 = t2 * t1; // 249..0
    t1 = t1.squared; // 250..1
    for (int i = 1; i < 5; i++) {
      t1 = t1.squared; // 254..5
    }
    FieldElement out = t1 * t0; // 254..5,3,1,0
    return out;
  }

  FieldElement get pow22523 {
    var t0 = squared;
    var t1 = t0.squared;
    t1 = t1.squared;
    t1 = this * t1;
    t0 = t0 * t1;
    t0 = t0.squared;
    t0 = t1 * t0;
    t1 = t0.squared;
    for (int i = 1; i < 5; i++) {
      t1 = t1.squared;
    }
    t0 = t1 * t0;
    t1 = t0.squared;
    for (int i = 1; i < 10; i++) {
      t1 = t1.squared;
    }
    t1 = t1 * t0;
    FieldElement t2 = t1.squared;
    for (int i = 1; i < 20; i++) {
      t2 = t2.squared;
    }
    t1 = t2 * t1;
    t1 = t1.squared;
    for (int i = 1; i < 10; i++) {
      t1 = t1.squared;
    }
    t0 = t1 * t0;
    t1 = t0.squared;
    for (int i = 1; i < 50; i++) {
      t1 = t1.squared;
    }
    t1 = t1 * t0;
    t2 = t1.squared;
    for (int i = 1; i < 100; i++) {
      t2 = t2.squared;
    }
    t1 = t2 * t1;
    t1 = t1.squared;
    for (int i = 1; i < 50; i++) {
      t1 = t1.squared;
    }
    t0 = t1 * t0;
    t0 = t0.squared;
    t0 = t0.squared;
    FieldElement out = t0 * this;
    return out;
  }

  FieldElement get clone => FieldElement.fromList(elements);

  BigInt get asBigInt => asBytes.reversed.asBigInt;
}
