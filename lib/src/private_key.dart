import 'dart:convert';
import 'dart:typed_data';

import 'package:ninja_ed25519/src/curve25519/curve25519.dart';
import 'package:ninja_ed25519/src/util/hex.dart';

class PrivateKey {
  final Uint8List bytes;

  PrivateKey(this.bytes);

  factory PrivateKey.fromHex(String hex) {
    if (hex.length == 128) {
      hex = hex.substring(0, 64);
    }
    if (hex.length != 64) {
      throw ArgumentError.value(hex, 'hex', 'invalid key length');
    }
    final bytes = hex64ToBytes(hex);
    return PrivateKey(bytes);
  }
  factory PrivateKey.fromBase64(String input) {
    Uint8List bytes = base64Decode(input);
    if (bytes.length == 64) {
      bytes = bytes.sublist(0, 32);
    }
    if (bytes.length != 32) {
      throw ArgumentError.value(input, 'input', 'invalid key length');
    }
    return PrivateKey(bytes);
  }
  // TODO fromBech32

  PublicKey get publicKey {
    final pubBytes = curve25519.scalarMultiplyBase(bytes).asBytes;
    return PublicKey(pubBytes);
  }

  String get asHex => bytesToHex(bytes);
  String get asBase64 => base64Encode(bytes);
  // TODO toBech32
}

class PublicKey {
  final Uint8List bytes;

  PublicKey(this.bytes);

  factory PublicKey.fromHex(String hex) {
    if (hex.length != 64) {
      throw ArgumentError.value(hex, 'hex', 'invalid key length');
    }
    final bytes = hex64ToBytes(hex);
    return PublicKey(bytes);
  }
  factory PublicKey.fromBase64(String input) {
    Uint8List bytes = base64Decode(input);
    if (bytes.length != 32) {
      throw ArgumentError.value(input, 'input', 'invalid key length');
    }
    return PublicKey(bytes);
  }
  // TODO fromBech32

  String get asHex => bytesToHex(bytes);
  String get asBase64 => base64Encode(bytes);
  // TODO toBech32
}
