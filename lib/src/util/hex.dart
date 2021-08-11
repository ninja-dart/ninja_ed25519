List<int> hex64ToBytes(String hex) {
  if (hex.length != 64) {
    throw ArgumentError('invalid key');
  }
  final bytes = List.generate(32, (i) {
    final sb = hex.substring(i * 2, (i + 1) * 2);
    return int.parse(sb, radix: 16);
  }).toList();
  return bytes;
}