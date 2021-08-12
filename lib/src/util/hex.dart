import 'dart:typed_data';

Uint8List hex64ToBytes(String hex) {
  if (hex.length != 64) {
    throw ArgumentError('invalid key');
  }
  final bytes = List.generate(32, (i) {
    final sb = hex.substring(i * 2, (i + 1) * 2);
    return int.parse(sb, radix: 16);
  }).toList();
  return Uint8List.fromList(bytes);
}

String bytesToHex(Uint8List b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
