import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('Customization field test cases', () {
    test('multiple valid customization fields', () {
      final multipleCustomizationFields = {
        "m.homeserver": {"base_url": "matrix.tom-dev.xyz"},
        "m.identity_server": {"base_url": "https://tom.tom-dev.xyz/"},
        "t.server": {"base_url": "https://tom.tom-dev.xyz/"},
        "m.integrations": {
          "jitsi": {
            "preferredDomain": "jitsi.linagora.com",
            "baseUrl": "https://jitsi.linagora.com",
            "useJwt": false,
          },
        },
        "t.domain": {"url": "tom-dev.xyz"},
      };

      final actual = DiscoveryInformation.fromJson(multipleCustomizationFields);
      expect(actual, isNotNull);
      expect(actual.additionalProperties['m.integrations'], isNotNull);
      expect(actual.additionalProperties['t.server'], isNotNull);
      expect(actual.additionalProperties['t.domain'], isNotNull);
    });

    test('multiple valid customization from ToM', () {
      final multipleCustomizationFields = {
        "m.homeserver": {"base_url": "matrix.tom-dev.xyz"},
        "m.identity_server": {"base_url": "https://tom.tom-dev.xyz/"},
        "t.server": {
          "base_url": "https://tom.tom-dev.xyz/",
          "server_name": "tom-dev.xyz",
        },
        "m.integrations": {
          "jitsi": {
            "preferredDomain": "jitsi.linagora.com",
            "baseUrl": "https://jitsi.linagora.com",
            "useJwt": false,
          },
        },
      };

      final actual = DiscoveryInformation.fromJson(multipleCustomizationFields);

      expect(actual, isNotNull);
      expect(actual.additionalProperties['m.integrations'], isNotNull);
      expect(actual.additionalProperties['t.server'], isNotNull);
    });

    test('one invalid customization field', () {
      final multipleCustomizationFields = {
        "m.homeserver": {"base_url": "matrix.tom-dev.xyz"},
        "m.identity_server": {"base_url": "https://tom.tom-dev.xyz/"},
        "t.server": {"base_url": "https://tom.tom-dev.xyz/"},
        "m.integrations": {
          "jitsi": {
            "preferredDomain": "jitsi.linagora.com",
            "baseUrl": "https://jitsi.linagora.com",
            "useJwt": false,
          },
        },
        "t.domain": "tom-dev.xyz",
      };
      expect(
        () => DiscoveryInformation.fromJson(multipleCustomizationFields),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
