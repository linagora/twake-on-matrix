import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';

part 'drive_picker_message.freezed.dart';

/// Parses a message posted by the Drive picker for [id].
///
/// Throws [FormatException] when [raw] is not a JSON object. Messages for
/// another session id are reported as [DrivePickerUnknownMessage].
DrivePickerMessage parseDrivePickerMessage(String id, String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Drive picker message is not a JSON object');
  }
  final rawType = decoded['type'];
  return switch (_messageTypeOf(id, rawType)) {
    DrivePickerMessageType.ready => const DrivePickerReadyMessage(),
    DrivePickerMessageType.readyToUse => const DrivePickerReadyToUseMessage(),
    DrivePickerMessageType.done => _doneMessage(decoded),
    DrivePickerMessageType.error => const DrivePickerErrorMessage(),
    DrivePickerMessageType.cancel => const DrivePickerCancelMessage(),
    null => DrivePickerUnknownMessage(rawType is String ? rawType : ''),
  };
}

/// Message kinds a Drive picker posts; on the wire they read `intent-<id>:<kind>`.
enum DrivePickerMessageType { ready, readyToUse, done, error, cancel }

DrivePickerMessageType? _messageTypeOf(String id, Object? rawType) {
  final prefix = 'intent-$id:';
  if (rawType is! String || !rawType.startsWith(prefix)) return null;
  return DrivePickerMessageType.values.asNameMap()[rawType.substring(
    prefix.length,
  )];
}

@freezed
sealed class DrivePickerMessage with _$DrivePickerMessage {
  const factory DrivePickerMessage.ready() = DrivePickerReadyMessage;

  const factory DrivePickerMessage.readyToUse() = DrivePickerReadyToUseMessage;

  const factory DrivePickerMessage.error() = DrivePickerErrorMessage;

  const factory DrivePickerMessage.cancel() = DrivePickerCancelMessage;

  const factory DrivePickerMessage.unknown(String type) =
      DrivePickerUnknownMessage;

  const factory DrivePickerMessage.done(List<DrivePickedEntry> documents) =
      DrivePickerDoneMessage;
}

DrivePickerDoneMessage _doneMessage(Map<String, dynamic> json) {
  final rawDocuments = json['document'];
  final documents = rawDocuments is List
      ? rawDocuments
            .map(DrivePickedEntry.tryParse)
            .whereType<DrivePickedEntry>()
            .toList()
      : <DrivePickedEntry>[];
  return DrivePickerDoneMessage(documents);
}
