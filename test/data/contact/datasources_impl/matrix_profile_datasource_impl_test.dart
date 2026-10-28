import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/contact/datasources_impl/matrix_profile_datasource_impl.dart';

import 'matrix_profile_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  const matrixId = '@alice:server';
  late MockClient client;
  late MatrixProfileDatasourceImpl datasource;

  void stubProfile({required DateTime updated}) {
    when(
      client.getUserProfile(matrixId, maxCacheAge: Duration.zero),
    ).thenAnswer(
      (_) async => CachedProfileInformation.fromProfile(
        ProfileInformation(
          avatarUrl: Uri.parse('mxc://server/avatar'),
          displayname: 'Alice',
        ),
        outdated: false,
        updated: updated,
      ),
    );
  }

  setUp(() {
    client = MockClient();
    datasource = MatrixProfileDatasourceImpl(client);
  });

  test('a fresh read returns the profile the server just sent', () async {
    stubProfile(updated: DateTime.now().add(const Duration(seconds: 1)));

    final profile = await datasource.fetchProfile(matrixId, fresh: true);

    expect(profile?.avatarUrl, 'mxc://server/avatar');
    expect(profile?.displayName, 'Alice');
  });

  test('a fresh read ignores the stale cache the SDK falls back to', () async {
    stubProfile(updated: DateTime.now().subtract(const Duration(hours: 1)));

    final profile = await datasource.fetchProfile(matrixId, fresh: true);

    expect(profile, isNull);
  });
}
