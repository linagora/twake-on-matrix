import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';

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
  });
}
