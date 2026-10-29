import 'dart:async';

import 'package:flutter_emoji_mart/flutter_emoji_mart.dart'
    show EmojiPickerConfiguration;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Level, Logs;
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';
import 'package:twake_chat/utils/recent_reactions_extension.dart';

class _FakeReactionsRepository implements ReactionsRepository {
  _FakeReactionsRepository({
    this.reactions = const [],
    this.fails = false,
    this.storeGate,
  });

  final List<String> reactions;
  final bool fails;
  final Completer<void>? storeGate;

  @override
  Future<List<String>> getRecentReactions() async {
    if (fails) throw StateError('io');
    return reactions;
  }

  @override
  Future<void> storeRecentReactions(List<String> recentReactions) async {
    if (fails) throw StateError('io');
    await storeGate?.future;
  }

  @override
  Future<void> removeRecentReactions() async {}
}

void main() {
  setUp(() => Logs().outputEvents.clear());

  group('recentCategory', () {
    test(
      'recentCategory_withStoredReactions_returnsTheRecentCategory',
      () async {
        // Arrange
        final useCase = GetRecentReactionsUseCase(
          _FakeReactionsRepository(reactions: ['smile', 'heart']),
        );

        // Act
        final category = await useCase.recentCategory();

        // Assert
        expect(category?.id, EmojiPickerConfiguration.recentCategoryId);
        expect(category?.emojiIds, ['smile', 'heart']);
      },
    );

    test('recentCategory_whenRepositoryThrows_returnsNullAndLogs', () async {
      // Arrange
      final useCase = GetRecentReactionsUseCase(
        _FakeReactionsRepository(fails: true),
      );

      // Act
      final category = await useCase.recentCategory();

      // Assert
      expect(category, isNull);
      expect(
        Logs().outputEvents.where((event) => event.level == Level.error),
        hasLength(1),
      );
    });
  });

  group('executeOrLog', () {
    test('executeOrLog_whenRepositoryThrows_completesAndLogs', () async {
      // Arrange
      final useCase = StoreRecentReactionsUseCase(
        _FakeReactionsRepository(fails: true),
      );

      // Act
      final result = useCase.executeOrLog(emojiId: 'smile');

      // Assert
      await expectLater(result, completes);
      expect(
        Logs().outputEvents.where((event) => event.level == Level.error),
        hasLength(1),
      );
    });
  });

  group('executeOrLogThen', () {
    test('executeOrLogThen_whileStoreIsPending_doesNotSendYet', () async {
      // Arrange
      final storeGate = Completer<void>();
      final useCase = StoreRecentReactionsUseCase(
        _FakeReactionsRepository(storeGate: storeGate),
      );
      var sent = false;

      // Act
      final result = useCase.executeOrLogThen(
        emojiId: 'smile',
        send: () async => sent = true,
      );
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(sent, isFalse);
      storeGate.complete();
      await result;
      expect(sent, isTrue);
    });

    test('executeOrLogThen_whenStoreFails_stillSendsAndLogs', () async {
      // Arrange
      final useCase = StoreRecentReactionsUseCase(
        _FakeReactionsRepository(fails: true),
      );
      var sent = false;

      // Act
      await useCase.executeOrLogThen(
        emojiId: 'smile',
        send: () async => sent = true,
      );

      // Assert
      expect(sent, isTrue);
      expect(
        Logs().outputEvents.where((event) => event.level == Level.error),
        hasLength(1),
      );
    });
  });
}
