import 'dart:convert';
import 'dart:typed_data';

import 'package:ninja_ed25519/ninja_ed25519.dart';

void main() {
  final seed = PrivateKey.fromBase64(
      'EIKfPPFkqu9BRtpHq5kg7nqVRjyXDZiksxWq3gFcOh5Q3qQNqlsPhFLz4blZv7usf6MmJErzn5ONz0U2xEu2Jw==');
  print(seed.publicKey.asBase64);
  final msg = utf8.encode('test message') as Uint8List;
  final sig = seed.sign(msg);
  print(base64Encode(sig));
  print(seed.publicKey.verify(msg, sig) ? 'Verified!' : 'Invalid!');
}
