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
  _FakeUserInfoRepository({this.throwFor = const <String>{}});

  final Set<String> throwFor;
  final List<String> requestedUserIds = <String>[];

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    final matrixId = Uri.decodeComponent(userId);
    requestedUserIds.add(matrixId);
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

UnifiedContact _contact(String matrixId, {bool enriched = false}) =>
    UnifiedContact(
      matrixId: matrixId,
      canonicalDisplayName: 'Addressbook name',
      sources: [
        const ContactSourceValue(
          kind: ContactSourceKind.tomAddressBook,
          displayName: 'Addressbook name',
        ),
        if (enriched)
          const ContactSourceValue(
            kind: ContactSourceKind.tomUserInfo,
            displayName: 'Existing',
          ),
      ],
    );

void main() {
  late FakeUnifiedContactRepository repository;
  late _FakeUserInfoRepository userInfoRepository;
  const policy = ContactResolutionPolicy();

  setUp(() {
    repository = FakeUnifiedContactRepository();
    userInfoRepository = _FakeUserInfoRepository();
  });

  tearDown(() => repository.dispose());

  TomUserInfoSource buildSource({int maxPerRun = 50}) => TomUserInfoSource(
    repository: repository,
    userInfoRepository: userInfoRepository,
    policy: policy,
    maxPerRun: maxPerRun,
  );

  test('adds the tomUserInfo profile and re-resolves the contact', () async {
    await repository.upsert(_contact('@a:server'));

    await buildSource().enrich();

    final contact = await repository.getByMatrixId('@a:server');
    expect(
      contact!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isTrue,
    );
    expect(contact.canonicalDisplayName, 'Directory @a:server');
    expect(contact.avatarUrl, 'mxc://server/@a:server');
    expect(contact.emails, contains('@a:server@company.com'));
  });

  test('skips contacts already enriched', () async {
    await repository.upsert(_contact('@a:server', enriched: true));

    await buildSource().enrich();

    expect(userInfoRepository.requestedUserIds, isEmpty);
  });

  test('caps the number of network calls per run', () async {
    await repository.upsertAll([
      _contact('@a:server'),
      _contact('@b:server'),
      _contact('@c:server'),
    ]);

    await buildSource(maxPerRun: 2).enrich();

    expect(userInfoRepository.requestedUserIds, hasLength(2));
  });

  test('a failing profile does not prevent the others', () async {
    userInfoRepository = _FakeUserInfoRepository(throwFor: const {'@a:server'});
    await repository.upsertAll([_contact('@a:server'), _contact('@b:server')]);

    await buildSource().enrich();

    expect(
      (await repository.getByMatrixId(
        '@a:server',
      ))!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isFalse,
    );
    expect(
      (await repository.getByMatrixId(
        '@b:server',
      ))!.sources.any((s) => s.kind == ContactSourceKind.tomUserInfo),
      isTrue,
    );
  });
}
