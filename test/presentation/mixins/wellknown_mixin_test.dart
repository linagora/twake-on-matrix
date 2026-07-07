import 'dart:convert';

import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart';

class DummyController with WellKnownMixin {}

void main() {
  group('WellKnownMixin', () {
    late DummyController controller;

    setUp(() {
      controller = DummyController();
    });

    test('supportInvitation returns true when invitations are enabled', () {
      controller.discoveryInformationNotifier.value = DiscoveryInformation(
        additionalProperties: {
          'app.twake.chat': {'enable_invitations': true},
        },
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
        ),
      );

      expect(controller.supportInvitation(), isTrue);
    });

    test(
      'supportInvitation returns false when invitations are not enabled',
      () {
        controller.discoveryInformationNotifier.value = DiscoveryInformation(
          additionalProperties: {
            'app.twake.chat': {'enable_invitations': false},
          },
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
          ),
        );

        expect(controller.supportInvitation(), isFalse);
      },
    );

    test(
      'supportInvitation returns false when discoveryInformationNotifier is null',
      () {
        controller.discoveryInformationNotifier.value = null;

        expect(controller.supportInvitation(), isFalse);
      },
    );

    test(
      'supportInvitation returns false when no enable_invitations is found',
      () {
        controller.discoveryInformationNotifier.value = DiscoveryInformation(
          additionalProperties: {
            'app.twake.chat': {'enable_invitation': false},
          },
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
          ),
        );

        expect(controller.supportInvitation(), isFalse);
      },
    );

    test(
      'supportInvitation returns false when nothing inside app.twake.chat',
      () {
        controller.discoveryInformationNotifier.value = DiscoveryInformation(
          additionalProperties: {'app.twake.chat': <String, dynamic>{}},
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
          ),
        );

        expect(controller.supportInvitation(), isFalse);
      },
    );

    test('supportInvitation returns false when no app.twake.chat', () {
      controller.discoveryInformationNotifier.value = DiscoveryInformation(
        additionalProperties: {'app': {}},
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
        ),
      );

      expect(controller.supportInvitation(), isFalse);
    });

    test('supportInvitation returns false when no additionalProperties', () {
      controller.discoveryInformationNotifier.value = DiscoveryInformation(
        additionalProperties: {},
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.tryParse('https://matrix.domain.xyz')!,
        ),
      );

      expect(controller.supportInvitation(), isFalse);
    });

    test('discoverFromHomeserver uses homeserver well-known URL', () async {
      final requests = <Uri>[];
      final httpClient = MockClient((request) async {
        requests.add(request.url);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'm.homeserver': {'base_url': 'https://matrix.domain.xyz'},
              'app.twake.chat': {'enable_invitations': true},
            }),
          ),
          200,
        );
      });

      final result = await WellKnownMixin.discoverFromHomeserver(
        Uri.parse('https://matrix.domain.xyz/some/path'),
        httpClient: httpClient,
      );

      expect(requests, [
        Uri.parse('https://matrix.domain.xyz/.well-known/matrix/client'),
      ]);
      expect(result, isNotNull);
      expect(result!.additionalProperties['app.twake.chat'], {
        'enable_invitations': true,
      });
    });
  });
}
