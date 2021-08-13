import 'dart:convert';
import 'dart:typed_data';

import 'package:ninja_ed25519/ninja_ed25519.dart';

void main() {
  final key = PrivateKey.fromBase64Seed(
      'EIKfPPFkqu9BRtpHq5kg7nqVRjyXDZiksxWq3gFcOh5Q3qQNqlsPhFLz4blZv7usf6MmJErzn5ONz0U2xEu2Jw==');
  print(key.publicKey.asBase64);
  final sig = key.sign(utf8.encode('test message') as Uint8List);
  print(base64Encode(sig));
}
