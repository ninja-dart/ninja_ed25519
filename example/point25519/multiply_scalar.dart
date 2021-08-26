// https://steemit.com/monero/@luigi1111/understanding-monero-cryptography-privacy-part-2-stealth-addresses

// R = 396fc23bc389046b214087a9522c0fbd673d2f3f00ab9768f35fa52f953fef22
// a = fadf3558b700b88936113be1e5342245bd68a6b1deeb496000c4148ad4b61f02

import 'dart:typed_data';

import 'package:ninja/ninja.dart';
import 'package:ninja_ed25519/curve.dart';
import 'package:ninja_ed25519/src/curve25519/point.dart';

void mul1() {
  // 15801352132382701228853580656953290170733521530718767515862554642989229174585
  final RStr =
      '396fc23bc389046b214087a9522c0fbd673d2f3f00ab9768f35fa52f953fef22';
  final aStr =
      'fadf3558b700b88936113be1e5342245bd68a6b1deeb496000c4148ad4b61f02';
  final R = Point25519.fromHex(RStr);
  final a = BigInt.parse(aStr, radix: 16);
  final D = R.multiplyScalar(a);
  print(D.asBytes.reversed.toHex(outLen: 64));
}

/*
final scalar = BigInt.parse('1', radix: 16);
final scalarEndian = Endian.little;
9468b7a83b937c0a438a802c841183401d690f18742cfea6b9096f865ef84e02
 */

final scalar = BigInt.parse(
    '9468b7a83b937c0a438a802c841183401d690f18742cfea6b9096f865ef84e02',
    radix: 16);
final scalarEndian = Endian.big;

void mul2() {
  final RStr =
      '46316835694926478169428394003475163141307993866256225615783033603165251855960';
  final R = Point25519.fromCompressedIntString(RStr);

  BigInt tmpScalar = scalar;
  if (scalarEndian != Endian.little) {
    tmpScalar = scalar.asBytes(outLen: 32).reversed.asBigInt();
  }

  final R2 = R.multiplyScalar(tmpScalar);
  print('${R2.asCompressedIntString} ${R2.asCompressedHex}');
  print(R2);
}

// https://crypto.stackexchange.com/questions/27392/base-point-in-ed25519
void mul3() {
  final v =
      curve25519.scalarMultiplyBase(scalar, endian: scalarEndian).toAffine;
  print('${v.asCompressedIntString} ${v.asCompressedHex}');
  print(v);
}

void main() {
  // mul1();
  mul2();
  mul3();
  // mul4();
}
