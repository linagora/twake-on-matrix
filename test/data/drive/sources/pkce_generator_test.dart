import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/sources/pkce_generator.dart';

void main() {
  group('PkceGenerator', () {
    test('challengeOf matches the RFC 7636 appendix B vector', () {
      final generator = PkceGenerator(Random(1));

      final challenge = generator.challengeOf(
        'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      );

      expect(challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
    });

    test(
      'generate gives an unreserved-charset verifier of 43 to 128 chars',
      () {
        final pair = PkceGenerator(Random(1)).generate();

        expect(pair.verifier.length, inInclusiveRange(43, 128));
        expect(pair.verifier, matches(RegExp(r'^[A-Za-z0-9\-._~]+$')));
      },
    );

    test('generate derives the challenge from its own verifier', () {
      final generator = PkceGenerator(Random(1));

      final pair = generator.generate();

      expect(pair.challenge, generator.challengeOf(pair.verifier));
    });

    test('two generated verifiers differ', () {
      final generator = PkceGenerator(Random(1));

      expect(
        generator.generate().verifier,
        isNot(generator.generate().verifier),
      );
    });

    test('randomToken has no padding and differs between calls', () {
      final generator = PkceGenerator(Random(1));

      final first = generator.randomToken();

      expect(first, isNot(contains('=')));
      expect(first, isNot(generator.randomToken()));
    });
  });
}
