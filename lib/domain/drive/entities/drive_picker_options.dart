import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_options.freezed.dart';

/// What Chat asks Drive to show: a button that shares a link and one that
/// attaches the files.
@freezed
abstract class DrivePickerOptions with _$DrivePickerOptions {
  const factory DrivePickerOptions({
    /// Label of the button that shares a link, in the user's language.
    required String linkLabel,

    required bool darkTheme,

    /// Label of the button that attaches the files, in the user's language.
    /// Null hides the button, so Drive only offers links.
    String? attachLabel,

    /// Largest file Drive may offer to attach (the homeserver upload limit);
    /// null when it is not known, so Drive applies none.
    int? maxAttachmentBytes,
  }) = _DrivePickerOptions;
}
