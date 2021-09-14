import 'dart:convert';
import 'dart:typed_data';

import 'package:ninja_ed25519/ninja_ed25519.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class TestCase {
  final PrivateKey prvKey;
  final Map<String, String> messages;

  TestCase(String seed, this.messages) : prvKey = PrivateKey.fromBase64(seed);

  void perform() {
    for (final message in messages.keys) {
      final msg = utf8.encode(message) as Uint8List;
      final sig = prvKey.sign(msg);
      expect(base64Encode(sig), messages[message]);

      expect(prvKey.publicKey.verify(msg, sig), true);
    }
  }
}

void main() {
  group('signing', () {
    test('', () {
      final tc = TestCase(
          'EIKfPPFkqu9BRtpHq5kg7nqVRjyXDZiksxWq3gFcOh5Q3qQNqlsPhFLz4blZv7usf6MmJErzn5ONz0U2xEu2Jw==',
          {
            'test message':
                '7PpT574dtrX3ok7tXBULqE2cq6PzJP3BUYTq2VWdZ1AnEo4Le/RGlRgHqBnH1qNY7sycLkcHGUUMza7CITwzBQ==',
            'hello':
                'mcFLg61RbRbDBOIrM47dJBBWZhiVKjxoRV05kYVpvcN1a4b50L3r/NjWWUpACBnPZQs3ZfjaQQPSM8HdI4IyAQ==',
            '': '0H9qYyOAazEoI5GEpQji+M0qKBOw/7UM3J2FDXJpoGNY9nYc24vavD8zkWF0OLlgM4BgrgacZ+IPwvi8wT8xBg==',
          });
      tc.perform();
    });
  });
}
