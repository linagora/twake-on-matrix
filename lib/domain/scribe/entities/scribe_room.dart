import 'package:freezed_annotation/freezed_annotation.dart';

part 'scribe_room.freezed.dart';

/// What decides whether a room offers the Scribe, read from the room by the
/// caller.
@freezed
abstract class ScribeRoom with _$ScribeRoom {
  const ScribeRoom._();

  const factory ScribeRoom({
    required bool isEncrypted,
    required bool isDirect,

    /// The room's owner turned the Scribe on (state `app.twake.chat.scribe`,
    /// `enabled: true`, shared with Chat web). Only read in an encrypted room.
    required bool scribeEnabled,
    @Default(false) bool isSpace,

    /// The user may invite and has the top power level, as Chat web's
    /// `isRoomOwner`: the one who may turn the Scribe on or off.
    @Default(false) bool isOwner,
  }) = _ScribeRoom;

  /// A clear room offers it. An encrypted one only when its owner turned it
  /// on, since the draft then leaves end-to-end encryption, and never a
  /// direct one. Same rule as Chat web (`offersScribe`).
  bool get offersScribe => !isEncrypted || (!isDirect && scribeEnabled);

  /// The settings say whether the Scribe works here: an encrypted group only,
  /// as Chat web's room info.
  bool get hasScribeSetting => isEncrypted && !isDirect && !isSpace;

  /// Only the owner flips the setting.
  bool get canChangeScribe => hasScribeSetting && isOwner;
}
