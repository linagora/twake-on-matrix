import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';

void main() {
  group('the display preferences', () {
    test('by default: the look the app has today', () {
      const preferences = DisplayPreferencesState();

      expect(preferences.density, ChatListDensity.comfortable);
      expect(preferences.roomOrder, RoomOrder.recent);
      expect(preferences.seenStyle, SeenStyle.ticks);
      expect(preferences.bubbleAlign, BubbleAlign.ownRight);
    });

    test('hold the choices they are given', () {
      const preferences = DisplayPreferencesState(
        density: ChatListDensity.compact,
        roomOrder: RoomOrder.sections,
        seenStyle: SeenStyle.names,
        bubbleAlign: BubbleAlign.left,
      );

      expect(preferences.density, ChatListDensity.compact);
      expect(preferences.roomOrder, RoomOrder.sections);
      expect(preferences.seenStyle, SeenStyle.names);
      expect(preferences.bubbleAlign, BubbleAlign.left);
    });

    test('two sets of the same choices are equal', () {
      expect(
        const DisplayPreferencesState(seenStyle: SeenStyle.avatars),
        const DisplayPreferencesState(seenStyle: SeenStyle.avatars),
      );
      expect(
        const DisplayPreferencesState(seenStyle: SeenStyle.avatars),
        isNot(const DisplayPreferencesState()),
      );
    });

    test('the stored names of the choices never change, in the order they '
        'are shown', () {
      // What a device has stored must still be read after an update.
      expect(ChatListDensity.values.map((value) => value.name), [
        'comfortable',
        'compact',
      ]);
      expect(RoomOrder.values.map((value) => value.name), [
        'recent',
        'sections',
      ]);
      expect(SeenStyle.values.map((value) => value.name), [
        'ticks',
        'avatars',
        'names',
      ]);
      expect(BubbleAlign.values.map((value) => value.name), [
        'ownRight',
        'left',
      ]);
    });
  });
}
