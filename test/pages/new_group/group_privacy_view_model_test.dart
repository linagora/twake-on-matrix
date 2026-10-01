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

typedef _TransitionCase = ({
  String name,
  Map<String, dynamic> publicGroups,
  bool startsPublic,
  void Function(GroupPrivacyViewModel viewModel) act,
  GroupPrivacyState expected,
});

final _transitionCases = <_TransitionCase>[
  (
    name: 'setPublic_whenWellKnownHasNoDefault_limitsToTheServer',
    publicGroups: {'enabled': true},
    startsPublic: false,
    act: (viewModel) => viewModel.setPublic(isPublic: true),
    expected: const GroupPrivacyState(isPublic: true, isServerLimited: true),
  ),
  (
    name: 'setPublic_whenWellKnownOpensGroupsByDefault_doesNotLimit',
    publicGroups: {'enabled': true, 'default_server_limited': false},
    startsPublic: false,
    act: (viewModel) => viewModel.setPublic(isPublic: true),
    expected: const GroupPrivacyState(isPublic: true),
  ),
  (
    name: 'setPublic_whenBackToPrivate_clearsTheServerLimit',
    publicGroups: {'enabled': true},
    startsPublic: true,
    act: (viewModel) => viewModel.setPublic(isPublic: false),
    expected: const GroupPrivacyState(),
  ),
  (
    name: 'setServerLimited_whenPublic_keepsTheGroupPublic',
    publicGroups: {'enabled': true},
    startsPublic: true,
    act: (viewModel) => viewModel.setServerLimited(isServerLimited: false),
    expected: const GroupPrivacyState(isPublic: true),
  ),
];

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

    for (final testCase in _transitionCases) {
      test(testCase.name, () {
        // Arrange
        final container = _container(testCase.publicGroups);
        final viewModel = container.read(
          groupPrivacyViewModelProvider.notifier,
        );
        if (testCase.startsPublic) viewModel.setPublic(isPublic: true);

        // Act
        testCase.act(viewModel);

        // Assert
        expect(
          container.read(groupPrivacyViewModelProvider),
          testCase.expected,
        );
      });
    }
  });
}
