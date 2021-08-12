import 'package:ninja_ed25519/ninja_ed25519.dart';

void printPubKey(String pkeyHex) {
  final k = PrivateKey.fromHex(pkeyHex);
  print(k.bytes);
  print(k.publicKey.asHex);
}

void main() {
  printPubKey('96d54cd4f1d71e10a1eb76125aad65219cded6a987fd0b6cc1f758417b99d20c');
  printPubKey('9468b7a83b937c0a438a802c841183401d690f18742cfea6b9096f865ef84e02');
}
