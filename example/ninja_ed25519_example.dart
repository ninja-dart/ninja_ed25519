import 'package:ninja_ed25519/ninja_ed25519.dart';

void main() {
  final k = PrivateKey.fromHex(
      '96d54cd4f1d71e10a1eb76125aad65219cded6a987fd0b6cc1f758417b99d20c');
  print(k.bytes);
}
