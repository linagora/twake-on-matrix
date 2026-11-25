import 'package:freezed_annotation/freezed_annotation.dart';

part 'scribe_room.freezed.dart';

@freezed
abstract class ScribeRoom with _$ScribeRoom {
  const ScribeRoom._();

  const factory ScribeRoom({
    required bool isEncrypted,
    required bool isDirect,

    required bool scribeEnabled,
    @Default(false) bool isSpace,

    @Default(false) bool isOwner,
  }) = _ScribeRoom;

  bool get offersScribe => !isEncrypted || (!isDirect && scribeEnabled);

  bool get hasScribeSetting => isEncrypted && !isDirect && !isSpace;

  bool get canChangeScribe => hasScribeSetting && isOwner;
}
