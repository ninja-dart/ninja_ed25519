import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:ninja_ed25519/src/curve25519/curve25519.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
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
  factory PrivateKey.fromSeed(Uint8List seed) {
    if (seed.length != 32) {
      throw ArgumentError('ed25519: bad seed length ${seed.length}');
    }
    Uint8List h = sha512.convert(seed).bytes as Uint8List;
    var privateKey = h.sublist(0, 32);
    privateKey[0] &= 248;
    privateKey[31] &= 127;
    privateKey[31] |= 64;
    return PrivateKey(privateKey);
  }
  factory PrivateKey.fromBase64Seed(String seedStr) {
    Uint8List seed = base64Decode(seedStr);
    if (seed.length == 64) {
      seed = seed.sublist(0, 32);
    }
    if(seed.length != 32) {
      throw ArgumentError('invalid seed');
    }
    return PrivateKey.fromSeed(seed);
  }
  // TODO fromBech32

  PublicKey? _publicKey;

  PublicKey get publicKey =>
      _publicKey ??= PublicKey(curve25519.scalarMultiplyBase(bytes).asBytes);

  String get asHex => bytesToHex(bytes);
  String get asBase64 => base64Encode(bytes);
  // TODO toBech32

  /// Sign signs the message with privateKey and returns a signature. It will
  /// throw ArumentError if privateKey.bytes.length is not PrivateKeySize.
  Uint8List sign(Uint8List message) {
    if (bytes.length != 32) {
      throw ArgumentError('ed25519: bad privateKey length ${bytes.length}');
    }

    var output = AccumulatorSink<Digest>();
    var input = sha512.startChunkedConversion(output);
    // TODO dom2
    input.add(bytes);
    input.add(message);
    input.close();
    var messageDigest = output.events.single.bytes;

    final Uint8List r = curve25519.reduce(messageDigest as Uint8List);
    ExtendedGroupElement R = curve25519.scalarMultiplyBase(r);
    Uint8List encodedR = R.asBytes;

    output = AccumulatorSink<Digest>();
    input = sha512.startChunkedConversion(output);
    // TODO dom2
    input.add(encodedR);
    input.add(publicKey.bytes);
    input.add(message);
    input.close();
    var k = output.events.single.bytes;
    final kReduced = curve25519.reduce(k as Uint8List);

    final Uint8List S = curve25519.scalarMultiplyAdd(kReduced, bytes, r);

    var signature = Uint8List(signatureSize);
    signature.setRange(0, 32, encodedR);
    signature.setRange(32, 64, S);

    return signature;
  }

  final int keySize = 32;
  final int signatureSize = 64;
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
