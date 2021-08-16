import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:ninja_ed25519/src/curve25519/curve25519.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/util/hex.dart';

import 'package:ninja/ninja.dart';

class RFC8032Seed {
  final Uint8List seed;
  final PrivateKey privateKey;
  final Uint8List prefix;

  RFC8032Seed(this.seed, this.privateKey, this.prefix);

  factory RFC8032Seed.fromHexSeed(String seedHex) {
    if (seedHex.length == 128) {
      seedHex = seedHex.substring(0, 64);
    }
    if (seedHex.length != 64) {
      throw ArgumentError.value(seedHex, 'hex', 'invalid key length');
    }
    final seed = hex64ToBytes(seedHex);
    return RFC8032Seed.fromSeed(seed);
  }

  factory RFC8032Seed.fromSeed(Uint8List seed) {
    if (seed.length != 32) {
      throw ArgumentError('ed25519: bad seed length ${seed.length}');
    }
    Uint8List h = sha512.convert(seed).bytes as Uint8List;
    var privateKey = h.sublist(0, 32);
    privateKey[0] &= 248;
    privateKey[31] &= 127;
    privateKey[31] |= 64;

    return RFC8032Seed(seed, PrivateKey(privateKey), h.sublist(32));
  }

  factory RFC8032Seed.fromBase64(String seedStr) {
    Uint8List seed = base64Decode(seedStr);
    if (seed.length == 64) {
      seed = seed.sublist(0, 32);
    }
    if (seed.length != 32) {
      throw ArgumentError('invalid seed');
    }
    return RFC8032Seed.fromSeed(seed);
  }
  // TODO fromBech32

  PublicKey get publicKey => privateKey.publicKey;

  String get seedAsHex => bytesToHex(seed);
  String get seedAsBase64 => base64Encode(seed);
  // TODO toBech32

  String get keyAsHex => privateKey.keyAsHex;
  String get keyAsBase64 => privateKey.keyAsBase64;
  // TODO toBech32

  Uint8List sign(Uint8List message) => privateKey.sign(message, prefix);

  final int keySize = 32;
  final int signatureSize = 64;
}

class PrivateKey {
  final Uint8List keyBytes;

  PrivateKey(this.keyBytes);

  factory PrivateKey.fromHex(String hex) {
    if (hex.length != 64) {
      throw ArgumentError.value(hex, 'hex', 'invalid key length');
    }
    final keyBytes = hex64ToBytes(hex);
    return PrivateKey(keyBytes);
  }
  // TODO fromBech32

  PublicKey? _publicKey;
  PublicKey get publicKey =>
      _publicKey ??= PublicKey(curve25519.scalarMultiplyBase(keyBytes).asBytes);

  String get keyAsHex => bytesToHex(keyBytes);
  String get keyAsBase64 => base64Encode(keyBytes);
  // TODO toBech32

  /// Sign signs the message with privateKey and returns a signature. It will
  /// throw ArumentError if privateKey.bytes.length is not PrivateKeySize.
  Uint8List sign(Uint8List message, Uint8List prefix) {
    if (keyBytes.length != 32) {
      throw ArgumentError('ed25519: bad privateKey length ${keyBytes.length}');
    }

    Uint8List messageDigest = sha512Many([prefix, message]);

    final Uint8List r = curve25519.reduce(messageDigest);
    ExtendedGroupElement R = curve25519.scalarMultiplyBase(r);
    Uint8List encodedR = R.asBytes;

    Uint8List k = sha512Many([encodedR, publicKey.bytes, message]);
    final kReduced = curve25519.reduce(k);

    final Uint8List S = curve25519.scalarMultiplyAdd(kReduced, keyBytes, r);

    var signature = Uint8List(signatureSize);
    signature.setRange(0, 32, encodedR);
    signature.setRange(32, 64, S);

    return signature;
  }

  static const int keySize = 32;
  static const int signatureSize = 64;
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

  bool verify(Uint8List message, Uint8List sig) {
    if (sig.length != PrivateKey.signatureSize || sig[63] & 224 != 0) {
      return false;
    }

    ExtendedGroupElement A = ExtendedGroupElement.fromBytes(bytes);
    A.X = -A.X;
    A.T = -A.T;

    Uint8List h = sha512Many([sig.sublist(0, 32), bytes, message]);
    final hReduced = curve25519.reduce(h);

    final s = sig.sublist(32);
    if (!curve25519.isLessThanOrder(s)) {
      return false;
    }
    final R = curve25519.scalarDualMultiply(hReduced, A, s);
    final Uint8List checkR = R.asBytes;
    return ListEquality().equals(sig.sublist(0, 32), checkR);
  }
}

Uint8List sha512Many(List<List<int>> messages) {
  final output = DigestSink();
  final input = sha512.startChunkedConversion(output);
  for (final message in messages) {
    input.add(message);
  }
  input.close();
  return output.value.bytes as Uint8List;
}
