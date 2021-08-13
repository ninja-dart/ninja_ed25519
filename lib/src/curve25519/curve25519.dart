import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/cached.dart';
import 'package:ninja_ed25519/src/curve25519/completed.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/curve25519/field_element/constants.dart';
import 'package:ninja_ed25519/src/curve25519/projective.dart';
import 'package:ninja_ed25519/src/util/int.dart';

const curve25519 = Curve25519();

class Curve25519 {
  const Curve25519();

  /// computes h = a*B, where
  ///   a = a[0]+256*a[1]+...+256^31 a[31]
  ///   B is the Ed25519 base point (x,4/5) with x positive.
  ///
  /// Preconditions:
  ///   a[31] <= 127
  ExtendedGroupElement scalarMultiplyBase(Uint8List a) {
    final e = List<int>.filled(64, 0);

    for (var i = 0; i < a.length; i++) {
      var v = a[i];
      e[2 * i] = v & 15;
      e[2 * i + 1] = (v >> 4) & 15;
    }

    // each e[i] is between 0 and 15 and e[63] is between 0 and 7.

    var carry = 0;
    for (var i = 0; i < 63; i++) {
      e[i] += carry;
      carry = (e[i] + 8) >> 4;
      e[i] -= carry << 4;
    }
    e[63] += carry;
    // each e[i] is between -8 and 8.

    ExtendedGroupElement h = ExtendedGroupElement();
    for (var i = 1; i < 64; i += 2) {
      PreComputedGroupElement t = _selectPoint(i ~/ 2, e[i]);
      CompletedGroupElement r = h + t;
      h = r.toExtended;
    }

    h = h.twice.twice.twice.twice.toExtended;

    for (var i = 0; i < 64; i += 2) {
      PreComputedGroupElement t = _selectPoint(i ~/ 2, e[i]);
      CompletedGroupElement r = h + t;
      h = r.toExtended;
    }

    return h;
  }

  PreComputedGroupElement _selectPoint(int pos, int b) {
    int bAbs = b.abs();

    PreComputedGroupElement t = PreComputedGroupElement();
    for (var i = 0; i < 8; i++) {
      if (bAbs == i + 1) {
        t.set(base[pos][i]);
      }
    }
    if (b.isNegative) {
      return PreComputedGroupElement(
        yPlusX: t.yMinusX.clone,
        yMinusX: t.yPlusX.clone,
        xy2d: -t.xy2d,
      );
    } else {
      return t;
    }
  }

  /// The scalars are GF(2^252 + 27742317777372353535851937790883648493).

  /// Input:
  ///   a[0]+256*a[1]+...+256^31*a[31] = a
  ///   b[0]+256*b[1]+...+256^31*b[31] = b
  ///   c[0]+256*c[1]+...+256^31*c[31] = c
  ///
  /// Output:
  ///   s[0]+256*s[1]+...+256^31*s[31] = (ab+c) mod l
  ///   where l = 2^252 + 27742317777372353535851937790883648493.
  Uint8List scalarMultiplyAdd(Uint8List a, Uint8List b, Uint8List c) {
    var a0 = 2097151 & load3(a.sublist(0, a.length));
    var a1 = 2097151 & (load4(a.sublist(2, a.length)) >> 5);
    var a2 = 2097151 & (load3(a.sublist(5, a.length)) >> 2);
    var a3 = 2097151 & (load4(a.sublist(7, a.length)) >> 7);
    var a4 = 2097151 & (load4(a.sublist(10, a.length)) >> 4);
    var a5 = 2097151 & (load3(a.sublist(13, a.length)) >> 1);
    var a6 = 2097151 & (load4(a.sublist(15, a.length)) >> 6);
    var a7 = 2097151 & (load3(a.sublist(18, a.length)) >> 3);
    var a8 = 2097151 & load3(a.sublist(21, a.length));
    var a9 = 2097151 & (load4(a.sublist(23, a.length)) >> 5);
    var a10 = 2097151 & (load3(a.sublist(26, a.length)) >> 2);
    var a11 = (load4(a.sublist(28, a.length)) >> 7);

    var b0 = 2097151 & load3(b.sublist(0, b.length));
    var b1 = 2097151 & (load4(b.sublist(2, b.length)) >> 5);
    var b2 = 2097151 & (load3(b.sublist(5, b.length)) >> 2);
    var b3 = 2097151 & (load4(b.sublist(7, b.length)) >> 7);
    var b4 = 2097151 & (load4(b.sublist(10, b.length)) >> 4);
    var b5 = 2097151 & (load3(b.sublist(13, b.length)) >> 1);
    var b6 = 2097151 & (load4(b.sublist(15, b.length)) >> 6);
    var b7 = 2097151 & (load3(b.sublist(18, b.length)) >> 3);
    var b8 = 2097151 & load3(b.sublist(21, b.length));
    var b9 = 2097151 & (load4(b.sublist(23, b.length)) >> 5);
    var b10 = 2097151 & (load3(b.sublist(26, b.length)) >> 2);
    var b11 = (load4(b.sublist(28, b.length)) >> 7);

    var c0 = 2097151 & load3(c.sublist(0, c.length));
    var c1 = 2097151 & (load4(c.sublist(2, c.length)) >> 5);
    var c2 = 2097151 & (load3(c.sublist(5, c.length)) >> 2);
    var c3 = 2097151 & (load4(c.sublist(7, c.length)) >> 7);
    var c4 = 2097151 & (load4(c.sublist(10, c.length)) >> 4);
    var c5 = 2097151 & (load3(c.sublist(13, c.length)) >> 1);
    var c6 = 2097151 & (load4(c.sublist(15, c.length)) >> 6);
    var c7 = 2097151 & (load3(c.sublist(18, c.length)) >> 3);
    var c8 = 2097151 & load3(c.sublist(21, c.length));
    var c9 = 2097151 & (load4(c.sublist(23, c.length)) >> 5);
    var c10 = 2097151 & (load3(c.sublist(26, c.length)) >> 2);
    var c11 = (load4(c.sublist(28, c.length)) >> 7);

    var carry = List<int>.filled(23, 0);

    var s0 = c0 + a0 * b0;
    var s1 = c1 + a0 * b1 + a1 * b0;
    var s2 = c2 + a0 * b2 + a1 * b1 + a2 * b0;
    var s3 = c3 + a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0;
    var s4 = c4 + a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0;
    var s5 = c5 + a0 * b5 + a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1 + a5 * b0;
    var s6 = c6 +
        a0 * b6 +
        a1 * b5 +
        a2 * b4 +
        a3 * b3 +
        a4 * b2 +
        a5 * b1 +
        a6 * b0;
    var s7 = c7 +
        a0 * b7 +
        a1 * b6 +
        a2 * b5 +
        a3 * b4 +
        a4 * b3 +
        a5 * b2 +
        a6 * b1 +
        a7 * b0;
    var s8 = c8 +
        a0 * b8 +
        a1 * b7 +
        a2 * b6 +
        a3 * b5 +
        a4 * b4 +
        a5 * b3 +
        a6 * b2 +
        a7 * b1 +
        a8 * b0;
    var s9 = c9 +
        a0 * b9 +
        a1 * b8 +
        a2 * b7 +
        a3 * b6 +
        a4 * b5 +
        a5 * b4 +
        a6 * b3 +
        a7 * b2 +
        a8 * b1 +
        a9 * b0;
    var s10 = c10 +
        a0 * b10 +
        a1 * b9 +
        a2 * b8 +
        a3 * b7 +
        a4 * b6 +
        a5 * b5 +
        a6 * b4 +
        a7 * b3 +
        a8 * b2 +
        a9 * b1 +
        a10 * b0;
    var s11 = c11 +
        a0 * b11 +
        a1 * b10 +
        a2 * b9 +
        a3 * b8 +
        a4 * b7 +
        a5 * b6 +
        a6 * b5 +
        a7 * b4 +
        a8 * b3 +
        a9 * b2 +
        a10 * b1 +
        a11 * b0;
    var s12 = a1 * b11 +
        a2 * b10 +
        a3 * b9 +
        a4 * b8 +
        a5 * b7 +
        a6 * b6 +
        a7 * b5 +
        a8 * b4 +
        a9 * b3 +
        a10 * b2 +
        a11 * b1;
    var s13 = a2 * b11 +
        a3 * b10 +
        a4 * b9 +
        a5 * b8 +
        a6 * b7 +
        a7 * b6 +
        a8 * b5 +
        a9 * b4 +
        a10 * b3 +
        a11 * b2;
    var s14 = a3 * b11 +
        a4 * b10 +
        a5 * b9 +
        a6 * b8 +
        a7 * b7 +
        a8 * b6 +
        a9 * b5 +
        a10 * b4 +
        a11 * b3;
    var s15 = a4 * b11 +
        a5 * b10 +
        a6 * b9 +
        a7 * b8 +
        a8 * b7 +
        a9 * b6 +
        a10 * b5 +
        a11 * b4;
    var s16 =
        a5 * b11 + a6 * b10 + a7 * b9 + a8 * b8 + a9 * b7 + a10 * b6 + a11 * b5;
    var s17 = a6 * b11 + a7 * b10 + a8 * b9 + a9 * b8 + a10 * b7 + a11 * b6;
    var s18 = a7 * b11 + a8 * b10 + a9 * b9 + a10 * b8 + a11 * b7;
    var s19 = a8 * b11 + a9 * b10 + a10 * b9 + a11 * b8;
    var s20 = a9 * b11 + a10 * b10 + a11 * b9;
    var s21 = a10 * b11 + a11 * b10;
    var s22 = a11 * b11;
    var s23 = 0;

    carry[0] = (s0 + (1 << 20)) >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[2] = (s2 + (1 << 20)) >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[4] = (s4 + (1 << 20)) >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[6] = (s6 + (1 << 20)) >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[8] = (s8 + (1 << 20)) >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[10] = (s10 + (1 << 20)) >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;
    carry[12] = (s12 + (1 << 20)) >> 21;
    s13 += carry[12];
    s12 -= carry[12] << 21;
    carry[14] = (s14 + (1 << 20)) >> 21;
    s15 += carry[14];
    s14 -= carry[14] << 21;
    carry[16] = (s16 + (1 << 20)) >> 21;
    s17 += carry[16];
    s16 -= carry[16] << 21;
    carry[18] = (s18 + (1 << 20)) >> 21;
    s19 += carry[18];
    s18 -= carry[18] << 21;
    carry[20] = (s20 + (1 << 20)) >> 21;
    s21 += carry[20];
    s20 -= carry[20] << 21;
    carry[22] = (s22 + (1 << 20)) >> 21;
    s23 += carry[22];
    s22 -= carry[22] << 21;

    carry[1] = (s1 + (1 << 20)) >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[3] = (s3 + (1 << 20)) >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[5] = (s5 + (1 << 20)) >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[7] = (s7 + (1 << 20)) >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[9] = (s9 + (1 << 20)) >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[11] = (s11 + (1 << 20)) >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;
    carry[13] = (s13 + (1 << 20)) >> 21;
    s14 += carry[13];
    s13 -= carry[13] << 21;
    carry[15] = (s15 + (1 << 20)) >> 21;
    s16 += carry[15];
    s15 -= carry[15] << 21;
    carry[17] = (s17 + (1 << 20)) >> 21;
    s18 += carry[17];
    s17 -= carry[17] << 21;
    carry[19] = (s19 + (1 << 20)) >> 21;
    s20 += carry[19];
    s19 -= carry[19] << 21;
    carry[21] = (s21 + (1 << 20)) >> 21;
    s22 += carry[21];
    s21 -= carry[21] << 21;

    s11 += s23 * 666643;
    s12 += s23 * 470296;
    s13 += s23 * 654183;
    s14 -= s23 * 997805;
    s15 += s23 * 136657;
    s16 -= s23 * 683901;
    s23 = 0;

    s10 += s22 * 666643;
    s11 += s22 * 470296;
    s12 += s22 * 654183;
    s13 -= s22 * 997805;
    s14 += s22 * 136657;
    s15 -= s22 * 683901;
    s22 = 0;

    s9 += s21 * 666643;
    s10 += s21 * 470296;
    s11 += s21 * 654183;
    s12 -= s21 * 997805;
    s13 += s21 * 136657;
    s14 -= s21 * 683901;
    s21 = 0;

    s8 += s20 * 666643;
    s9 += s20 * 470296;
    s10 += s20 * 654183;
    s11 -= s20 * 997805;
    s12 += s20 * 136657;
    s13 -= s20 * 683901;
    s20 = 0;

    s7 += s19 * 666643;
    s8 += s19 * 470296;
    s9 += s19 * 654183;
    s10 -= s19 * 997805;
    s11 += s19 * 136657;
    s12 -= s19 * 683901;
    s19 = 0;

    s6 += s18 * 666643;
    s7 += s18 * 470296;
    s8 += s18 * 654183;
    s9 -= s18 * 997805;
    s10 += s18 * 136657;
    s11 -= s18 * 683901;
    s18 = 0;

    carry[6] = (s6 + (1 << 20)) >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[8] = (s8 + (1 << 20)) >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[10] = (s10 + (1 << 20)) >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;
    carry[12] = (s12 + (1 << 20)) >> 21;
    s13 += carry[12];
    s12 -= carry[12] << 21;
    carry[14] = (s14 + (1 << 20)) >> 21;
    s15 += carry[14];
    s14 -= carry[14] << 21;
    carry[16] = (s16 + (1 << 20)) >> 21;
    s17 += carry[16];
    s16 -= carry[16] << 21;

    carry[7] = (s7 + (1 << 20)) >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[9] = (s9 + (1 << 20)) >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[11] = (s11 + (1 << 20)) >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;
    carry[13] = (s13 + (1 << 20)) >> 21;
    s14 += carry[13];
    s13 -= carry[13] << 21;
    carry[15] = (s15 + (1 << 20)) >> 21;
    s16 += carry[15];
    s15 -= carry[15] << 21;

    s5 += s17 * 666643;
    s6 += s17 * 470296;
    s7 += s17 * 654183;
    s8 -= s17 * 997805;
    s9 += s17 * 136657;
    s10 -= s17 * 683901;
    s17 = 0;

    s4 += s16 * 666643;
    s5 += s16 * 470296;
    s6 += s16 * 654183;
    s7 -= s16 * 997805;
    s8 += s16 * 136657;
    s9 -= s16 * 683901;
    s16 = 0;

    s3 += s15 * 666643;
    s4 += s15 * 470296;
    s5 += s15 * 654183;
    s6 -= s15 * 997805;
    s7 += s15 * 136657;
    s8 -= s15 * 683901;
    s15 = 0;

    s2 += s14 * 666643;
    s3 += s14 * 470296;
    s4 += s14 * 654183;
    s5 -= s14 * 997805;
    s6 += s14 * 136657;
    s7 -= s14 * 683901;
    s14 = 0;

    s1 += s13 * 666643;
    s2 += s13 * 470296;
    s3 += s13 * 654183;
    s4 -= s13 * 997805;
    s5 += s13 * 136657;
    s6 -= s13 * 683901;
    s13 = 0;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = (s0 + (1 << 20)) >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[2] = (s2 + (1 << 20)) >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[4] = (s4 + (1 << 20)) >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[6] = (s6 + (1 << 20)) >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[8] = (s8 + (1 << 20)) >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[10] = (s10 + (1 << 20)) >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;

    carry[1] = (s1 + (1 << 20)) >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[3] = (s3 + (1 << 20)) >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[5] = (s5 + (1 << 20)) >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[7] = (s7 + (1 << 20)) >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[9] = (s9 + (1 << 20)) >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[11] = (s11 + (1 << 20)) >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = s0 >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[1] = s1 >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[2] = s2 >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[3] = s3 >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[4] = s4 >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[5] = s5 >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[6] = s6 >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[7] = s7 >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[8] = s8 >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[9] = s9 >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[10] = s10 >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;
    carry[11] = s11 >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = s0 >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[1] = s1 >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[2] = s2 >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[3] = s3 >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[4] = s4 >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[5] = s5 >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[6] = s6 >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[7] = s7 >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[8] = s8 >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[9] = s9 >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[10] = s10 >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;

    final Uint8List s = Uint8List(32);
    s[0] = s0 >> 0;
    s[1] = s0 >> 8;
    s[2] = (s0 >> 16) | (s1 << 5);
    s[3] = s1 >> 3;
    s[4] = s1 >> 11;
    s[5] = (s1 >> 19) | (s2 << 2);
    s[6] = s2 >> 6;
    s[7] = (s2 >> 14) | (s3 << 7);
    s[8] = s3 >> 1;
    s[9] = s3 >> 9;
    s[10] = (s3 >> 17) | (s4 << 4);
    s[11] = s4 >> 4;
    s[12] = s4 >> 12;
    s[13] = (s4 >> 20) | (s5 << 1);
    s[14] = s5 >> 7;
    s[15] = (s5 >> 15) | (s6 << 6);
    s[16] = s6 >> 2;
    s[17] = s6 >> 10;
    s[18] = (s6 >> 18) | (s7 << 3);
    s[19] = s7 >> 5;
    s[20] = s7 >> 13;
    s[21] = s8 >> 0;
    s[22] = s8 >> 8;
    s[23] = (s8 >> 16) | (s9 << 5);
    s[24] = s9 >> 3;
    s[25] = s9 >> 11;
    s[26] = (s9 >> 19) | (s10 << 2);
    s[27] = s10 >> 6;
    s[28] = (s10 >> 14) | (s11 << 7);
    s[29] = s11 >> 1;
    s[30] = s11 >> 9;
    s[31] = s11 >> 17;
    return s;
  }

  /// Returns a*A + b*B
  /// where a = a[0]+256*a[1]+...+256^31 a[31].
  /// and b = b[0]+256*b[1]+...+256^31 b[31].
  /// B is the Ed25519 base point (x,4/5) with x positive.
  ProjectiveGroupElement scalarDualMultiply(
      Uint8List a, ExtendedGroupElement A, Uint8List b) {
    var Ai = List.generate(
        8, (index) => CachedGroupElement()); // A,3A,5A,7A,9A,11A,13A,15A
    int i;

    final aSlide = _slide(a);
    final bSlide = _slide(b);

    Ai[0] = A.toCached;
    CompletedGroupElement t = A.twice;
    ExtendedGroupElement A2 = t.toExtended;

    for (i = 0; i < 7; i++) {
      t = A2 + Ai[i];
      ExtendedGroupElement u = t.toExtended;
      Ai[i + 1] = u.toCached;
    }

    for (i = 255; i >= 0; i--) {
      if (aSlide[i] != 0 || bSlide[i] != 0) {
        break;
      }
    }

    final r = ProjectiveGroupElement();
    for (; i >= 0; i--) {
      t = r.twice;

      if (aSlide[i] > 0) {
        ExtendedGroupElement u = t.toExtended;
        t = u + Ai[aSlide[i] ~/ 2];
      } else if (aSlide[i] < 0) {
        ExtendedGroupElement u = t.toExtended;
        t = u - Ai[(-aSlide[i]) ~/ 2];
      }

      if (bSlide[i] > 0) {
        ExtendedGroupElement u = t.toExtended;
        t = u + bi[bSlide[i] ~/ 2];
      } else if (bSlide[i] < 0) {
        ExtendedGroupElement u = t.toExtended;
        t = u - bi[(-bSlide[i]) ~/ 2];
      }

      r.set(t.toProjective);
    }

    return r;
  }

  /// Input:
  ///   s[0]+256*s[1]+...+256^63*s[63] = s
  ///
  /// Output:
  ///   s[0]+256*s[1]+...+256^31*s[31] = s mod l
  ///   where l = 2^252 + 27742317777372353535851937790883648493.
  Uint8List reduce(Uint8List s) {
    var s0 = 2097151 & load3(s.sublist(0, s.length));
    var s1 = 2097151 & (load4(s.sublist(2, s.length)) >> 5);
    var s2 = 2097151 & (load3(s.sublist(5, s.length)) >> 2);
    var s3 = 2097151 & (load4(s.sublist(7, s.length)) >> 7);
    var s4 = 2097151 & (load4(s.sublist(10, s.length)) >> 4);
    var s5 = 2097151 & (load3(s.sublist(13, s.length)) >> 1);
    var s6 = 2097151 & (load4(s.sublist(15, s.length)) >> 6);
    var s7 = 2097151 & (load3(s.sublist(18, s.length)) >> 3);
    var s8 = 2097151 & load3(s.sublist(21, s.length));
    var s9 = 2097151 & (load4(s.sublist(23, s.length)) >> 5);
    var s10 = 2097151 & (load3(s.sublist(26, s.length)) >> 2);
    var s11 = 2097151 & (load4(s.sublist(28, s.length)) >> 7);
    var s12 = 2097151 & (load4(s.sublist(31, s.length)) >> 4);
    var s13 = 2097151 & (load3(s.sublist(34, s.length)) >> 1);
    var s14 = 2097151 & (load4(s.sublist(36, s.length)) >> 6);
    var s15 = 2097151 & (load3(s.sublist(39, s.length)) >> 3);
    var s16 = 2097151 & load3(s.sublist(42, s.length));
    var s17 = 2097151 & (load4(s.sublist(44, s.length)) >> 5);
    var s18 = 2097151 & (load3(s.sublist(47, s.length)) >> 2);
    var s19 = 2097151 & (load4(s.sublist(49, s.length)) >> 7);
    var s20 = 2097151 & (load4(s.sublist(52, s.length)) >> 4);
    var s21 = 2097151 & (load3(s.sublist(55, s.length)) >> 1);
    var s22 = 2097151 & (load4(s.sublist(57, s.length)) >> 6);
    var s23 = (load4(s.sublist(60, s.length)) >> 3);

    s11 += s23 * 666643;
    s12 += s23 * 470296;
    s13 += s23 * 654183;
    s14 -= s23 * 997805;
    s15 += s23 * 136657;
    s16 -= s23 * 683901;
    s23 = 0;

    s10 += s22 * 666643;
    s11 += s22 * 470296;
    s12 += s22 * 654183;
    s13 -= s22 * 997805;
    s14 += s22 * 136657;
    s15 -= s22 * 683901;
    s22 = 0;

    s9 += s21 * 666643;
    s10 += s21 * 470296;
    s11 += s21 * 654183;
    s12 -= s21 * 997805;
    s13 += s21 * 136657;
    s14 -= s21 * 683901;
    s21 = 0;

    s8 += s20 * 666643;
    s9 += s20 * 470296;
    s10 += s20 * 654183;
    s11 -= s20 * 997805;
    s12 += s20 * 136657;
    s13 -= s20 * 683901;
    s20 = 0;

    s7 += s19 * 666643;
    s8 += s19 * 470296;
    s9 += s19 * 654183;
    s10 -= s19 * 997805;
    s11 += s19 * 136657;
    s12 -= s19 * 683901;
    s19 = 0;

    s6 += s18 * 666643;
    s7 += s18 * 470296;
    s8 += s18 * 654183;
    s9 -= s18 * 997805;
    s10 += s18 * 136657;
    s11 -= s18 * 683901;
    s18 = 0;

    var carry = List<int>.filled(64, 0);

    carry[6] = (s6 + (1 << 20)) >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[8] = (s8 + (1 << 20)) >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[10] = (s10 + (1 << 20)) >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;
    carry[12] = (s12 + (1 << 20)) >> 21;
    s13 += carry[12];
    s12 -= carry[12] << 21;
    carry[14] = (s14 + (1 << 20)) >> 21;
    s15 += carry[14];
    s14 -= carry[14] << 21;
    carry[16] = (s16 + (1 << 20)) >> 21;
    s17 += carry[16];
    s16 -= carry[16] << 21;

    carry[7] = (s7 + (1 << 20)) >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[9] = (s9 + (1 << 20)) >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[11] = (s11 + (1 << 20)) >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;
    carry[13] = (s13 + (1 << 20)) >> 21;
    s14 += carry[13];
    s13 -= carry[13] << 21;
    carry[15] = (s15 + (1 << 20)) >> 21;
    s16 += carry[15];
    s15 -= carry[15] << 21;

    s5 += s17 * 666643;
    s6 += s17 * 470296;
    s7 += s17 * 654183;
    s8 -= s17 * 997805;
    s9 += s17 * 136657;
    s10 -= s17 * 683901;
    s17 = 0;

    s4 += s16 * 666643;
    s5 += s16 * 470296;
    s6 += s16 * 654183;
    s7 -= s16 * 997805;
    s8 += s16 * 136657;
    s9 -= s16 * 683901;
    s16 = 0;

    s3 += s15 * 666643;
    s4 += s15 * 470296;
    s5 += s15 * 654183;
    s6 -= s15 * 997805;
    s7 += s15 * 136657;
    s8 -= s15 * 683901;
    s15 = 0;

    s2 += s14 * 666643;
    s3 += s14 * 470296;
    s4 += s14 * 654183;
    s5 -= s14 * 997805;
    s6 += s14 * 136657;
    s7 -= s14 * 683901;
    s14 = 0;

    s1 += s13 * 666643;
    s2 += s13 * 470296;
    s3 += s13 * 654183;
    s4 -= s13 * 997805;
    s5 += s13 * 136657;
    s6 -= s13 * 683901;
    s13 = 0;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = (s0 + (1 << 20)) >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[2] = (s2 + (1 << 20)) >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[4] = (s4 + (1 << 20)) >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[6] = (s6 + (1 << 20)) >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[8] = (s8 + (1 << 20)) >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[10] = (s10 + (1 << 20)) >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;

    carry[1] = (s1 + (1 << 20)) >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[3] = (s3 + (1 << 20)) >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[5] = (s5 + (1 << 20)) >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[7] = (s7 + (1 << 20)) >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[9] = (s9 + (1 << 20)) >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[11] = (s11 + (1 << 20)) >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = s0 >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[1] = s1 >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[2] = s2 >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[3] = s3 >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[4] = s4 >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[5] = s5 >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[6] = s6 >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[7] = s7 >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[8] = s8 >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[9] = s9 >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[10] = s10 >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;
    carry[11] = s11 >> 21;
    s12 += carry[11];
    s11 -= carry[11] << 21;

    s0 += s12 * 666643;
    s1 += s12 * 470296;
    s2 += s12 * 654183;
    s3 -= s12 * 997805;
    s4 += s12 * 136657;
    s5 -= s12 * 683901;
    s12 = 0;

    carry[0] = s0 >> 21;
    s1 += carry[0];
    s0 -= carry[0] << 21;
    carry[1] = s1 >> 21;
    s2 += carry[1];
    s1 -= carry[1] << 21;
    carry[2] = s2 >> 21;
    s3 += carry[2];
    s2 -= carry[2] << 21;
    carry[3] = s3 >> 21;
    s4 += carry[3];
    s3 -= carry[3] << 21;
    carry[4] = s4 >> 21;
    s5 += carry[4];
    s4 -= carry[4] << 21;
    carry[5] = s5 >> 21;
    s6 += carry[5];
    s5 -= carry[5] << 21;
    carry[6] = s6 >> 21;
    s7 += carry[6];
    s6 -= carry[6] << 21;
    carry[7] = s7 >> 21;
    s8 += carry[7];
    s7 -= carry[7] << 21;
    carry[8] = s8 >> 21;
    s9 += carry[8];
    s8 -= carry[8] << 21;
    carry[9] = s9 >> 21;
    s10 += carry[9];
    s9 -= carry[9] << 21;
    carry[10] = s10 >> 21;
    s11 += carry[10];
    s10 -= carry[10] << 21;

    final out = Uint8List(32);
    out[0] = s0 >> 0;
    out[1] = s0 >> 8;
    out[2] = (s0 >> 16) | (s1 << 5);
    out[3] = s1 >> 3;
    out[4] = s1 >> 11;
    out[5] = (s1 >> 19) | (s2 << 2);
    out[6] = s2 >> 6;
    out[7] = (s2 >> 14) | (s3 << 7);
    out[8] = s3 >> 1;
    out[9] = s3 >> 9;
    out[10] = (s3 >> 17) | (s4 << 4);
    out[11] = s4 >> 4;
    out[12] = s4 >> 12;
    out[13] = (s4 >> 20) | (s5 << 1);
    out[14] = s5 >> 7;
    out[15] = (s5 >> 15) | (s6 << 6);
    out[16] = s6 >> 2;
    out[17] = s6 >> 10;
    out[18] = (s6 >> 18) | (s7 << 3);
    out[19] = s7 >> 5;
    out[20] = s7 >> 13;
    out[21] = s8 >> 0;
    out[22] = s8 >> 8;
    out[23] = (s8 >> 16) | (s9 << 5);
    out[24] = s9 >> 3;
    out[25] = s9 >> 11;
    out[26] = (s9 >> 19) | (s10 << 2);
    out[27] = s10 >> 6;
    out[28] = (s10 >> 14) | (s11 << 7);
    out[29] = s11 >> 1;
    out[30] = s11 >> 9;
    out[31] = s11 >> 17;
    return out;
  }

  /// returns true if the given scalar is less than the order of the
  /// curve.
  bool isLessThanOrder(Uint8List other) {
    for (int i = 31; i >= 0; i--) {
      if (other[i] == _order[i]) {
        continue;
      }
      return other[i] < _order[i];
    }
    return false;
  }

  /// order is the order of Curve25519 in little-endian form.
  static final _order = Uint8List.fromList([
    0xed,
    0xd3,
    0xf5,
    0x5c,
    0x1a,
    0x63,
    0x12,
    0x58,
    0xd6,
    0x9c,
    0xf7,
    0xa2,
    0xde,
    0xf9,
    0xde,
    0x14,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x10,
  ]);
}

Int8List _slide(Uint8List a) {
  final r = Int8List(256);
  for (int i = 0; i < r.length; i++) {
    r[i] = 1 & (a[i >> 3] >> (i & 7));
  }

  for (var i = 0; i < r.length; i++) {
    if (r[i] != 0) {
      for (var b = 1; b <= 6 && i + b < 256; b++) {
        if (r[i + b] != 0) {
          if (r[i] + (r[i + b] << b) <= 15) {
            r[i] += r[i + b] << b;
            r[i + b] = 0;
          } else if (r[i] - (r[i + b] << b) >= -15) {
            r[i] -= r[i + b] << b;
            for (var k = i + b; k < 256; k++) {
              if (r[k] == 0) {
                r[k] = 1;
                break;
              }
              r[k] = 0;
            }
          } else {
            break;
          }
        }
      }
    }
  }

  return r;
}
