import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/pages/new_group/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/group_privacy_view_model.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

HomeserverSummary _summaryWith(Map<String, dynamic> publicGroups) =>
    HomeserverSummary(
      discoveryInformation: DiscoveryInformation(
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.parse('https://matrix.example.com'),
        ),
        additionalProperties: {
          'app.twake.chat': {'public_groups': publicGroups},
        },
      ),
      versions: GetVersionsResponse(versions: ['r1.6.0']),
      loginFlows: [],
    );

ProviderContainer _container(Map<String, dynamic> publicGroups) {
  final container = ProviderContainer(
    overrides: [
      loginHomeserverSummaryProvider.overrideWithBuild(
        (_, _) => _summaryWith(publicGroups),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Keeps the auto-disposed view model alive for the whole test.
  container.listen(groupPrivacyViewModelProvider, (_, _) {});
  return container;
}

void main() {
  group('GroupPrivacyViewModel', () {
    test('build_whenCreated_startsPrivate', () {
      // Arrange
      final container = _container({'enabled': true});

      // Act
      final state = container.read(groupPrivacyViewModelProvider);

      // Assert
      expect(state, const GroupPrivacyState());
    });

    test('setPublic_whenWellKnownHasNoDefault_limitsToTheServer', () {
      // Arrange
      final container = _container({'enabled': true});

      // Act
      container
          .read(groupPrivacyViewModelProvider.notifier)
          .setPublic(isPublic: true);

      // Assert
      expect(
        container.read(groupPrivacyViewModelProvider),
        const GroupPrivacyState(isPublic: true, isServerLimited: true),
      );
    });

    test('setPublic_whenWellKnownOpensGroupsByDefault_doesNotLimit', () {
      // Arrange
      final container = _container({
        'enabled': true,
        'default_server_limited': false,
      });

      // Act
      container
          .read(groupPrivacyViewModelProvider.notifier)
          .setPublic(isPublic: true);

      // Assert
      expect(
        container.read(groupPrivacyViewModelProvider),
        const GroupPrivacyState(isPublic: true),
      );
    });

    test('setPublic_whenBackToPrivate_clearsTheServerLimit', () {
      // Arrange
      final container = _container({'enabled': true});
      final viewModel = container.read(groupPrivacyViewModelProvider.notifier)
        ..setPublic(isPublic: true);

      // Act
      viewModel.setPublic(isPublic: false);

      // Assert
      expect(
        container.read(groupPrivacyViewModelProvider),
        const GroupPrivacyState(),
      );
    });

    test('setServerLimited_whenPublic_keepsTheGroupPublic', () {
      // Arrange
      final container = _container({'enabled': true});
      final viewModel = container.read(groupPrivacyViewModelProvider.notifier)
        ..setPublic(isPublic: true);

      // Act
      viewModel.setServerLimited(isServerLimited: false);

      // Assert
      expect(
        container.read(groupPrivacyViewModelProvider),
        const GroupPrivacyState(isPublic: true),
      );
    });
  });
}
