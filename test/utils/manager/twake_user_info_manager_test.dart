import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'twake_user_info_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<UserInfoRepository>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TwakeUserInfoManager manager;
  late MockClient mockClient;
  late MockUserInfoRepository mockUserInfoRepository;
  final getIt = GetIt.instance;

  setUp(() {
    mockClient = MockClient();
    mockUserInfoRepository = MockUserInfoRepository();

    manager = TwakeUserInfoManager(
      userInfoRepository: mockUserInfoRepository,
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('TwakeUserInfoManager', () {
    const testUserId = '@test:example.com';
    const testDisplayName = 'Test User';
    const testAvatarUrl = 'mxc://example.com/avatar123';

    final testMatrixProfile = Profile(
      userId: testUserId,
      displayName: 'Matrix Display Name',
      avatarUrl: Uri.parse('mxc://example.com/matrixavatar'),
    );

    test('should return Twake user info when available', () async {
      // Arrange
      const twakeUserInfo = UserInfo(
        uid: testUserId,
        displayName: testDisplayName,
        avatarUrl: testAvatarUrl,
      );

      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => testMatrixProfile);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenAnswer((_) async => twakeUserInfo);

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
      );

      // Assert
      expect(result.uid, testUserId);
      expect(result.displayName, testDisplayName);
      expect(result.avatarUrl, testAvatarUrl);
      verify(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).called(1);
      verify(mockUserInfoRepository.getUserInfo(testUserId)).called(1);
    });

    test('should fallback to Matrix profile when Twake info unavailable',
        () async {
      // Arrange
      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => testMatrixProfile);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenThrow(Exception('User info not found'));

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
      );

      // Assert
      expect(result.uid, testMatrixProfile.userId);
      expect(result.displayName, testMatrixProfile.displayName);
      expect(result.avatarUrl, testMatrixProfile.avatarUrl.toString());
    });

    test('should merge Twake info with Matrix profile avatarUrl', () async {
      // Arrange
      final profileWithNullAvatar = Profile(
        userId: testUserId,
        displayName: testDisplayName,
        avatarUrl: null,
      );

      const twakeUserInfo = UserInfo(
        uid: testUserId,
        displayName: testDisplayName,
        avatarUrl: testAvatarUrl,
      );

      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => profileWithNullAvatar);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenAnswer((_) async => twakeUserInfo);

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
      );

      // Assert
      expect(result.avatarUrl, testAvatarUrl);
    });

    test('should use Matrix avatar when Twake avatarUrl is empty', () async {
      // Arrange
      const twakeUserInfoWithEmptyAvatar = UserInfo(
        uid: testUserId,
        displayName: testDisplayName,
        avatarUrl: '',
      );

      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => testMatrixProfile);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenAnswer((_) async => twakeUserInfoWithEmptyAvatar);

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
      );

      // Assert
      expect(result.avatarUrl, testMatrixProfile.avatarUrl.toString());
    });

    test('should respect cache parameter', () async {
      // Arrange
      const twakeUserInfo = UserInfo(
        uid: testUserId,
        displayName: testDisplayName,
        avatarUrl: testAvatarUrl,
      );

      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: false,
          cache: false,
        ),
      ).thenAnswer((_) async => testMatrixProfile);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenAnswer((_) async => twakeUserInfo);

      // Act
      await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
        getFromRooms: false,
        cache: false,
      );

      // Assert
      verify(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: false,
          cache: false,
        ),
      ).called(1);
    });

    test('should handle empty userId gracefully', () async {
      // Arrange
      const emptyUserId = '';
      final emptyProfile = Profile(
        userId: emptyUserId,
        displayName: '',
        avatarUrl: null,
      );

      when(
        mockClient.getProfileFromUserId(
          emptyUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => emptyProfile);

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: emptyUserId,
      );

      // Assert
      expect(result.uid, emptyUserId);
      expect(result.displayName, '');
      expect(result.avatarUrl, '');
      verifyNever(mockUserInfoRepository.getUserInfo(any));
    });

    test('should use Matrix displayName when Twake displayName is null',
        () async {
      // Arrange
      const twakeUserInfoWithNullDisplayName = UserInfo(
        uid: testUserId,
        displayName: null,
        avatarUrl: testAvatarUrl,
      );

      when(
        mockClient.getProfileFromUserId(
          testUserId,
          getFromRooms: true,
          cache: true,
        ),
      ).thenAnswer((_) async => testMatrixProfile);

      when(mockUserInfoRepository.getUserInfo(testUserId))
          .thenAnswer((_) async => twakeUserInfoWithNullDisplayName);

      // Act
      final result = await manager.getTwakeProfileFromUserId(
        client: mockClient,
        userId: testUserId,
      );

      // Assert
      expect(result.displayName, testMatrixProfile.displayName);
    });
  });
}
