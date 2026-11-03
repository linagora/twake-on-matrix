import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/emoji_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('emojiDataProvider', () {
    test('always_findsACommonEmoji', () async {
      final container = ProviderContainer.test(retry: (_, _) => null);

      final emojis = await container.read(emojiDataProvider.future);

      expect(emojis.getIdByEmoji('😀'), isNotEmpty);
    });

    test('once_loaded_isReadableAtOnce', () async {
      final container = ProviderContainer.test(retry: (_, _) => null);

      final loaded = await container.read(emojiDataProvider.future);

      expect(container.read(emojiDataProvider).requireValue, same(loaded));
    });

    test('always_leavesOutEmojisNewerThanThePickerSupports', () async {
      final container = ProviderContainer.test(retry: (_, _) => null);

      final emojis = await container.read(emojiDataProvider.future);

      // Melting face, from Emoji 14.
      expect(() => emojis.getIdByEmoji('🫠'), throwsArgumentError);
    });
  });
}
