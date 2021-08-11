import 'package:ninja_ed25519/src/util/hex.dart';

class PrivateKey {
  final List<int> bytes;

  PrivateKey(this.bytes);

  factory PrivateKey.fromHex(String hex) {
    final bytes = hex64ToBytes(hex);
    return PrivateKey(bytes);
  }
}

class PublicKey {
  final List<int> bytes;

  PublicKey(this.bytes);
}
