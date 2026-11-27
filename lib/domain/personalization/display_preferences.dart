import 'package:freezed_annotation/freezed_annotation.dart';

part 'display_preferences.freezed.dart';

// The names of the values are what the device stores: never rename them. The
// order of the values is the order the choices show in; the default of each
// is set apart, in [DisplayPreferencesState].

/// The height of the rooms of the chat list.
enum ChatListDensity { comfortable, compact }

/// How the chat list orders the rooms: newest first, or by section.
enum RoomOrder { recent, sections }

/// Where the bubbles go: own messages on the right, or every one on the left.
enum BubbleAlign { ownRight, left }

/// The display choices of this device, kept on it. Each default keeps the
/// look the app had before these choices.
@freezed
abstract class DisplayPreferencesState with _$DisplayPreferencesState {
  const factory DisplayPreferencesState({
    @Default(ChatListDensity.comfortable) ChatListDensity density,
    @Default(RoomOrder.recent) RoomOrder roomOrder,
    @Default(BubbleAlign.ownRight) BubbleAlign bubbleAlign,
  }) = _DisplayPreferencesState;
}
