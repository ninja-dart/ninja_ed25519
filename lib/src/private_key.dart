import 'dart:convert';
import 'dart:typed_data';
import 'package:ninja_ed25519/src/util/encodeBech32.dart';
import 'package:ninja_hex/ninja_hex.dart';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:ninja_ed25519/curve.dart';
import 'package:ninja_ed25519/src/curve25519/curve25519.dart';
import 'package:ninja_ed25519/src/curve25519/extended.dart';
import 'package:ninja_ed25519/src/util/hex.dart';

import 'package:ninja/ninja.dart';

class PrivateKey {
  final Uint8List? seed;
  final Uint8List privateKey;
  final Uint8List prefix;

  PrivateKey(this.seed, this.privateKey, this.prefix);

  factory PrivateKey.fromHexSeed(String seedHex) {
    if (seedHex.length != 64) {
      throw ArgumentError.value(seedHex, 'hex', 'invalid key length');
    }
    final seed = hex64ToBytes(seedHex);
    return PrivateKey.fromSeed(seed);
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

    return PrivateKey(seed, privateKey, h.sublist(32));
  }

  factory PrivateKey.fromBase64Seed(String seedStr) {
    Uint8List seed = base64Decode(seedStr);
    if (seed.length != 32) {
      throw ArgumentError('invalid seed');
    }
    return PrivateKey.fromSeed(seed);
  }

  factory PrivateKey.fromHex(String hex) {
    if (hex.length != 128) {
      throw ArgumentError.value(hex, 'seedHex', 'invalid length');
    }
    final seed = hexDecode(hex);
    return PrivateKey.fromBytes(seed);
  }

  factory PrivateKey.fromBytes(Uint8List bytes) {
    if (bytes.length != 64) {
      throw ArgumentError.value(bytes, 'bytes', 'invalid length');
    }

    return PrivateKey(null, bytes.sublist(0, 32), bytes.sublist(32));
  }

  factory PrivateKey.fromBase64(String input) {
    Uint8List bytes = base64Decode(input);
    return PrivateKey.fromBytes(bytes);
  }

  factory PrivateKey.fromBech32(String key) {
    List<int> data = decodeBech32(key, maxBechLength: 200);
    if (data.length < 64) {
      throw Exception('invalid data in bech32 encoded input');
    }
    data = data.sublist(0, 64);
    return PrivateKey.fromBytes(Uint8List.fromList(data));
  }

  PublicKey get publicKey =>
      PublicKey(curve25519.scalarMultiplyBase(privateKey).asBytes);

  String? get seedAsHex => seed != null ? bytesToHex(seed!) : null;
  String? get seedAsBase64 => seed != null ? base64Encode(seed!) : null;

  BigInt get keyAsBigInt => privateKey.asBigInt(endian: Endian.little);
  String get keyAsHex => bytesToHex(privateKey);
  String get keyAsBase64 => base64Encode(privateKey);

  String toBech32(String hrp) {
    final bechBytes = List<int>.filled(64, 0)
      ..setRange(0, 32, privateKey)
      ..setRange(32, 64, prefix);
    return encodeBech32(hrp, bechBytes, maxBechLength: 200);
  }

  /// Sign signs the message with privateKey and returns a signature. It will
  /// throw ArgumentError if privateKey.bytes.length is not PrivateKeySize.
  Uint8List sign(Uint8List message) {
    Uint8List messageDigest = sha512Many([prefix, message]);

    final Uint8List r = curve25519.reduce(messageDigest);
    Point25519 R = curve25519.scalarMultiplyBase(r);
    Uint8List encodedR = R.asBytes;

    Uint8List k = sha512Many([encodedR, publicKey.bytes, message]);
    final kReduced = curve25519.reduce(k);

    final Uint8List S = curve25519.scalarMultiplyAdd(kReduced, privateKey, r);

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
  factory PublicKey.fromBech32(String key) {
    List<int> data = decodeBech32(key, maxBechLength: 32);
    if (data.length != 32) {
      throw Exception('invalid data in bech32 encoded input');
    }
    return PublicKey(Uint8List.fromList(data));
  }

  BigInt get asBigInt => bytes.asBigInt(endian: Endian.little);
  Point25519 get asPoint => Point25519.fromBytes(bytes);
  String get asHex => bytesToHex(bytes);
  String get asBase64 => base64Encode(bytes);

  String toBech32(String hrp) {
    final bechBytes = List<int>.filled(32, 0)..setRange(0, 32, bytes);
    return encodeBech32(hrp, bechBytes, maxBechLength: 200);
  }

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
