import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_message.dart';

String _doneMessage(List<Map<String, dynamic>> documents) =>
    jsonEncode({'type': 'intent-abc:done', 'document': documents});

/// A valid document; entries of [overrides] replace it, a `null` value drops
/// the key.
Map<String, dynamic> _document([Map<String, Object?> overrides = const {}]) {
  final document = <String, Object?>{
    'id': '1',
    'name': 'a.pdf',
    'size': 10,
    'sharingLink': 'https://drive.example/s/1',
    ...overrides,
  };
  return {
    for (final entry in document.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

List<DrivePickedEntry> _parseDocuments(List<Map<String, dynamic>> documents) {
  final message = parseDrivePickerMessage('abc', _doneMessage(documents));
  return (message as DrivePickerDoneMessage).documents;
}

void main() {
  group('parseDrivePickerMessage', () {
    test('ignores a message addressed to another intent id', () {
      final message = parseDrivePickerMessage(
        'abc',
        jsonEncode({'type': 'intent-zzz:done', 'document': []}),
      );

      expect(message, isA<DrivePickerUnknownMessage>());
    });

    test('maps ready, readyToUse, cancel and error', () {
      DrivePickerMessage parse(String suffix) => parseDrivePickerMessage(
        'abc',
        jsonEncode({'type': 'intent-abc:$suffix'}),
      );

      expect(parse('ready'), isA<DrivePickerReadyMessage>());
      expect(parse('readyToUse'), isA<DrivePickerReadyToUseMessage>());
      expect(parse('cancel'), isA<DrivePickerCancelMessage>());
      expect(parse('error'), isA<DrivePickerErrorMessage>());
    });

    test('treats a non-string type as an unknown message', () {
      final message = parseDrivePickerMessage('abc', '{"type": 1}');

      expect(message, isA<DrivePickerUnknownMessage>());
    });

    test('throws FormatException for a payload that is not JSON', () {
      expect(
        () => parseDrivePickerMessage('abc', 'not json'),
        throwsFormatException,
      );
    });
  });

  group('done message documents', () {
    test('keeps a valid https document', () {
      final documents = _parseDocuments([_document()]);

      expect(documents.single.id, '1');
      expect(
        documents.single.sharingLink,
        Uri.parse('https://drive.example/s/1'),
      );
    });

    test('drops javascript: and negative size documents', () {
      final documents = _parseDocuments([
        _document({'sharingLink': 'javascript:alert(1)'}),
        _document({'id': '2', 'size': -1}),
      ]);

      expect(documents, isEmpty);
    });

    test('drops documents with blank id or name', () {
      final documents = _parseDocuments([
        _document({'id': ' '}),
        _document({'id': '3', 'name': ''}),
      ]);

      expect(documents, isEmpty);
    });

    test('drops a document whose sharing link is http', () {
      final documents = _parseDocuments([
        _document({'sharingLink': 'http://drive.example/s/1'}),
      ]);

      expect(documents, isEmpty);
    });

    test('drops a document without any link', () {
      final documents = _parseDocuments([
        _document({'sharingLink': null}),
      ]);

      expect(documents, isEmpty);
    });

    test('drops a document whose download link is not https', () {
      final documents = _parseDocuments([
        _document({
          'sharingLink': null,
          'downloadLink': 'ftp://drive.example/d/1',
        }),
      ]);

      expect(documents, isEmpty);
    });

    test('an insecure thumbnail removes only the thumbnail', () {
      final documents = _parseDocuments([
        _document({
          'thumbnail': {'link': 'http://drive.example/t.png'},
        }),
      ]);

      expect(documents.single.thumbnailLink, isNull);
    });

    test('keeps a secure thumbnail', () {
      final documents = _parseDocuments([
        _document({
          'thumbnail': {'link': 'https://drive.example/t.png'},
        }),
      ]);

      expect(
        documents.single.thumbnailLink,
        Uri.parse('https://drive.example/t.png'),
      );
    });

    test('falls back to octet-stream when mime type is missing', () {
      final documents = _parseDocuments([_document()]);

      expect(documents.single.mimeTypeOrDefault, 'application/octet-stream');
    });
  });
}
