import 'package:ninja_ed25519/ninja_ed25519.dart';

void main() {
  final key = PrivateKey.fromBase64(
      'IPcJXD+9bFmDKE0JFkidJ1dd13W5ztweOSnM8kbDMSQ+hNOytI32IRpO9jvxjOyPTyCuEEhRW1TTgXy+5cEr4Q==');
  print(key.publicKey.asBase64);
}
