import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/sources/tom_user_info_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

class _FakeUserInfoRepository implements UserInfoRepository {
  _FakeUserInfoRepository({this.throwFor = const <String>{}, this.onRequest});

  final Set<String> throwFor;
  final void Function()? onRequest;
  final List<String> requestedUserIds = <String>[];

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    final matrixId = Uri.decodeComponent(userId);
    requestedUserIds.add(matrixId);
    onRequest?.call();
    if (throwFor.contains(matrixId)) throw Exception('unreachable');
    return UserInfo(
      uid: matrixId,
      displayName: 'Directory $matrixId',
      avatarUrl: 'mxc://server/$matrixId',
      emails: ['$matrixId@company.com'],
      phones: const ['+33000000000'],
    );
  }

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) async =>
      UserInfoVisibility();

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest userInfoVisibility,
  ) async => UserInfoVisibility();
}

UnifiedContact _contact(
  String matrixId, {
  bool enriched = false,
  DateTime? enrichedAt,
}) => UnifiedContact(
  matrixId: matrixId,
  canonicalDisplayName: 'Addressbook name',
  sources: [
    const ContactSourceValue(
      kind: ContactSourceKind.tomAddressBook,
      displayName: 'Addressbook name',
    ),
    if (enriched)
      ContactSourceValue(
        kind: ContactSourceKind.tomUserInfo,
        displayName: 'Existing',
        updatedAt: enrichedAt ?? DateTime.now().toUtc(),
      ),
  ],
);

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late _FakeUserInfoRepository userInfoRepository;
  const policy = ContactResolutionPolicy();

  setUp(() {
    repository = FakeUnifiedContactRepository();
    userInfoRepository = _FakeUserInfoRepository();
  });

  tearDown(() => repository.dispose());

  TomUserInfoSource buildSource({
    int maxPerRun = 50,
    Duration failureCooldown = const Duration(minutes: 5),
    Duration refreshAfter = const Duration(hours: 24),
    String? Function()? activeUserId,
  }) => TomUserInfoSource(
    repository: repository,
    userInfoRepository: userInfoRepository,
    policy: policy,
    activeUserId: activeUserId,
    maxPerRun: maxPerRun,
    failureCooldown: failureCooldown,
    refreshAfter: refreshAfter,
  );

  test('adds the tomUserInfo profile and re-resolves the contact', () async {
    await repository.upsert(userId, _contact('@a:server'));

    await buildSource().enrich(userId);

    final contact = await repository.getByMatrixId(userId, '@a:server');
    expect(
      contact!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isTrue,
    );
    expect(contact.canonicalDisplayName, 'Directory @a:server');
    expect(contact.avatarUrl, 'mxc://server/@a:server');
    expect(contact.emails, contains('@a:server@company.com'));
  });

  test('skips contacts already enriched', () async {
    await repository.upsert(userId, _contact('@a:server', enriched: true));

    await buildSource().enrich(userId);

    expect(userInfoRepository.requestedUserIds, isEmpty);
  });

  test('caps the number of network calls per run', () async {
    await repository.upsertAll(userId, [
      _contact('@a:server'),
      _contact('@b:server'),
      _contact('@c:server'),
    ]);

    await buildSource(maxPerRun: 2).enrich(userId);

    expect(userInfoRepository.requestedUserIds, hasLength(2));
  });

  test('an all-failure run is still capped by maxPerRun', () async {
    userInfoRepository = _FakeUserInfoRepository(
      throwFor: const {'@a:server', '@b:server', '@c:server'},
    );
    await repository.upsertAll(userId, [
      _contact('@a:server'),
      _contact('@b:server'),
      _contact('@c:server'),
    ]);

    await buildSource(maxPerRun: 2).enrich(userId);

    expect(userInfoRepository.requestedUserIds, hasLength(2));
  });

  test('a failing contact in cooldown does not starve the next ones', () async {
    userInfoRepository = _FakeUserInfoRepository(throwFor: const {'@a:server'});
    await repository.upsertAll(userId, [
      _contact('@a:server'),
      _contact('@b:server'),
    ]);
    final source = buildSource(maxPerRun: 1);

    await source.enrich(userId);
    await source.enrich(userId);

    expect(userInfoRepository.requestedUserIds, ['@a:server', '@b:server']);
    expect(
      (await repository.getByMatrixId(
        userId,
        '@b:server',
      ))!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isTrue,
    );
  });

  test('a failing contact is retried once the cooldown has elapsed', () async {
    userInfoRepository = _FakeUserInfoRepository(throwFor: const {'@a:server'});
    await repository.upsert(userId, _contact('@a:server'));
    final source = buildSource(failureCooldown: Duration.zero);

    await source.enrich(userId);
    await source.enrich(userId);

    expect(userInfoRepository.requestedUserIds, ['@a:server', '@a:server']);
  });

  test('a failing profile does not prevent the others', () async {
    userInfoRepository = _FakeUserInfoRepository(throwFor: const {'@a:server'});
    await repository.upsertAll(userId, [
      _contact('@a:server'),
      _contact('@b:server'),
    ]);

    await buildSource().enrich(userId);

    expect(
      (await repository.getByMatrixId(
        userId,
        '@a:server',
      ))!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isFalse,
    );
    expect(
      (await repository.getByMatrixId(
        userId,
        '@b:server',
      ))!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isTrue,
    );
  });

  test('refetches a user_info value older than refreshAfter', () async {
    final stale = DateTime.now().toUtc().subtract(const Duration(days: 2));
    await repository.upsert(
      userId,
      _contact('@a:server', enriched: true, enrichedAt: stale),
    );

    await buildSource().enrich(userId);

    expect(userInfoRepository.requestedUserIds, ['@a:server']);
    final contact = await repository.getByMatrixId(userId, '@a:server');
    final userInfoValues = contact!.sources.where(
      (s) => s.kind == ContactSourceKind.tomUserInfo,
    );
    // Replaced, not duplicated.
    expect(userInfoValues, hasLength(1));
    expect(userInfoValues.single.displayName, 'Directory @a:server');
    expect(userInfoValues.single.updatedAt!.isAfter(stale), isTrue);
  });

  test('a user_info value without timestamp is treated as stale', () async {
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: '@a:server',
        sources: [ContactSourceValue(kind: ContactSourceKind.tomUserInfo)],
      ),
    );

    await buildSource().enrich(userId);

    expect(userInfoRepository.requestedUserIds, ['@a:server']);
  });

  test('skips the run when another account is active', () async {
    await repository.upsert(userId, _contact('@a:server'));

    await buildSource(activeUserId: () => '@other:server').enrich(userId);

    expect(userInfoRepository.requestedUserIds, isEmpty);
  });

  test('does not write a profile fetched before an account switch', () async {
    await repository.upsert(userId, _contact('@a:server'));
    var active = userId;
    userInfoRepository = _FakeUserInfoRepository(
      onRequest: () => active = '@other:server',
    );

    await buildSource(activeUserId: () => active).enrich(userId);

    expect(userInfoRepository.requestedUserIds, ['@a:server']);
    final contact = await repository.getByMatrixId(userId, '@a:server');
    expect(
      contact!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isFalse,
    );
  });
}
