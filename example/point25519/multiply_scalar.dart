// https://steemit.com/monero/@luigi1111/understanding-monero-cryptography-privacy-part-2-stealth-addresses

// R = 396fc23bc389046b214087a9522c0fbd673d2f3f00ab9768f35fa52f953fef22
// a = fadf3558b700b88936113be1e5342245bd68a6b1deeb496000c4148ad4b61f02

import 'package:ninja/ninja.dart';
import 'package:ninja_ed25519/curve.dart';
import 'package:ninja_ed25519/src/curve25519/point.dart';

void mul1() {
  final RStr = '396fc23bc389046b214087a9522c0fbd673d2f3f00ab9768f35fa52f953fef22';
  final aStr = 'fadf3558b700b88936113be1e5342245bd68a6b1deeb496000c4148ad4b61f02';
  final R = Point25519.fromHex(RStr);
  final a = BigInt.parse(aStr, radix: 16);
  final D = R.multiplyScalar(a, Curve25519.order);
  print(D.asBytes.reversed.toHex(outLen: 64));
}

void mul2() {
  final RStr = '396fc23bc389046b214087a9522c0fbd673d2f3f00ab9768f35fa52f953fef22';
  final R = Point25519.fromHex(RStr);
  final R2 = R.multiplyScalar(BigInt.two, Curve25519.order);
  print(R2.asBytes.toHex(outLen: 64));
}

void main() {
  // mul1();
  mul2();
}