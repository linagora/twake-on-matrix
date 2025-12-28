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

    test('should merge Twake info with Matrix profile avatarUrl',
        () async {
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

    group('Caching behavior', () {
      test('should cache user info when cache parameter is true', () async {
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

        // Act - First call should fetch from repository
        final result1 = await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Act - Second call should use cache
        final result2 = await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Assert
        expect(result1.uid, testUserId);
        expect(result2.uid, testUserId);
        expect(result1.displayName, result2.displayName);
        expect(result1.avatarUrl, result2.avatarUrl);

        // Repository should only be called once due to caching
        verify(mockUserInfoRepository.getUserInfo(testUserId)).called(1);
        verify(
          mockClient.getProfileFromUserId(
            testUserId,
            getFromRooms: true,
            cache: true,
          ),
        ).called(1);
      });

      test('should not cache when cache parameter is false', () async {
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
            cache: false,
          ),
        ).thenAnswer((_) async => testMatrixProfile);

        when(mockUserInfoRepository.getUserInfo(testUserId))
            .thenAnswer((_) async => twakeUserInfo);

        // Act - Both calls should fetch from repository
        await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: false,
        );

        await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: false,
        );

        // Assert - Repository should be called twice (no caching)
        verify(mockUserInfoRepository.getUserInfo(testUserId)).called(2);
        verify(
          mockClient.getProfileFromUserId(
            testUserId,
            getFromRooms: true,
            cache: false,
          ),
        ).called(2);
      });

      test('should clear cache when clearCache is called', () async {
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

        // Act - First call to populate cache
        await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Clear the cache
        manager.clearCache();

        // Second call after cache clear
        await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Assert - Repository should be called twice since cache was cleared
        verify(mockUserInfoRepository.getUserInfo(testUserId)).called(2);
      });

      test(
        'should remove specific user from cache when removeFromCache is called',
        () async {
          // Arrange
          const testUserId2 = '@test2:example.com';
          const twakeUserInfo1 = UserInfo(
            uid: testUserId,
            displayName: testDisplayName,
            avatarUrl: testAvatarUrl,
          );
          const twakeUserInfo2 = UserInfo(
            uid: testUserId2,
            displayName: 'Test User 2',
            avatarUrl: 'mxc://example.com/avatar456',
          );

          final testMatrixProfile2 = Profile(
            userId: testUserId2,
            displayName: 'Matrix Display Name 2',
            avatarUrl: Uri.parse('mxc://example.com/matrixavatar2'),
          );

          when(
            mockClient.getProfileFromUserId(
              testUserId,
              getFromRooms: true,
              cache: true,
            ),
          ).thenAnswer((_) async => testMatrixProfile);

          when(
            mockClient.getProfileFromUserId(
              testUserId2,
              getFromRooms: true,
              cache: true,
            ),
          ).thenAnswer((_) async => testMatrixProfile2);

          when(mockUserInfoRepository.getUserInfo(testUserId))
              .thenAnswer((_) async => twakeUserInfo1);

          when(mockUserInfoRepository.getUserInfo(testUserId2))
              .thenAnswer((_) async => twakeUserInfo2);

          // Act - Cache both users
          await manager.getTwakeProfileFromUserId(
            client: mockClient,
            userId: testUserId,
            cache: true,
          );

          await manager.getTwakeProfileFromUserId(
            client: mockClient,
            userId: testUserId2,
            cache: true,
          );

          // Remove only the first user from cache
          manager.removeFromCache(testUserId);

          // Try to get both users again
          await manager.getTwakeProfileFromUserId(
            client: mockClient,
            userId: testUserId,
            cache: true,
          );

          await manager.getTwakeProfileFromUserId(
            client: mockClient,
            userId: testUserId2,
            cache: true,
          );

          // Assert - First user should be fetched twice (cache was removed)
          // Second user should be fetched once (still cached)
          verify(mockUserInfoRepository.getUserInfo(testUserId)).called(2);
          verify(mockUserInfoRepository.getUserInfo(testUserId2)).called(1);
        },
      );

      test('should cache fallback to Matrix profile when error occurs',
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

        // Act - First call should fetch and cache fallback
        final result1 = await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Second call should use cached fallback
        final result2 = await manager.getTwakeProfileFromUserId(
          client: mockClient,
          userId: testUserId,
          cache: true,
        );

        // Assert
        expect(result1.uid, testMatrixProfile.userId);
        expect(result2.uid, testMatrixProfile.userId);
        expect(result1.displayName, result2.displayName);

        // Repository should only be called once (error cached)
        verify(mockUserInfoRepository.getUserInfo(testUserId)).called(1);
        verify(
          mockClient.getProfileFromUserId(
            testUserId,
            getFromRooms: true,
            cache: true,
          ),
        ).called(1);
      });
    });
  });
}
