void main() {
  final f = 0xaa55;
  final g = 0x5a5a;
  final c = 0;
  print((f ^ c & (f ^ g)).toRadixString(16));
}
