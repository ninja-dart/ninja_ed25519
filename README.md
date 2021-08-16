# ninja_ed25519

Dart package to generate Ed25519 keys, sign and verify messages.

# Example

## Read private key hex

```dart
import 'package:ninja_ed25519/ninja_ed25519.dart';

void printPubKey(String pkeyHex) {
  final k = PrivateKey.fromHex(pkeyHex);
  print(k.publicKey.asHex);
}

void main() {
  // 9e29899c25c007f38449c3df583870b6a843baa9598cba83b53b4501716aa9fb
  printPubKey(
      '96d54cd4f1d71e10a1eb76125aad65219cded6a987fd0b6cc1f758417b99d20c');
  // 7a9433b483f275485300b834f4489786d2c3acc6b00efa89435e9ed45ebfa9ed
  printPubKey(
      '9468b7a83b937c0a438a802c841183401d690f18742cfea6b9096f865ef84e02');
}
```

## Sign and verify

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:ninja_ed25519/ninja_ed25519.dart';

void main() {
  final seed = RFC8032Seed.fromBase64(
      'EIKfPPFkqu9BRtpHq5kg7nqVRjyXDZiksxWq3gFcOh5Q3qQNqlsPhFLz4blZv7usf6MmJErzn5ONz0U2xEu2Jw==');
  print(seed.publicKey.asBase64);
  final msg = utf8.encode('test message') as Uint8List;
  final sig = seed.sign(msg);
  print(base64Encode(sig));
  print(seed.publicKey.verify(msg, sig) ? 'Verified!' : 'Invalid!');
}
```