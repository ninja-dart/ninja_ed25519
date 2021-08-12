import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/curve25519.dart';
import 'package:ninja_ed25519/src/util/hex.dart';

class PrivateKey {
  final Uint8List bytes;

  PrivateKey(this.bytes);

  factory PrivateKey.fromHex(String hex) {
    final bytes = hex64ToBytes(hex);
    return PrivateKey(bytes);
  }

  PublicKey get publicKey {
    final pubBytes = curve25519.scalarMultiplyBase(bytes).asBytes;
    return PublicKey(pubBytes);
  }

  String get asHex => bytesToHex(bytes);
}

class PublicKey {
  final Uint8List bytes;

  PublicKey(this.bytes);

  String get asHex => bytesToHex(bytes);
}
