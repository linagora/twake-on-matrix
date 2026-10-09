import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/drive/drive_link_message_repository_impl.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';
import 'package:twake_chat/domain/model/drive/drive_link_message.dart';

final _documentWithoutMimeType = DrivePickedEntry(
  id: 'file-1',
  name: 'data.bin',
  size: 3,
  sharingLink: Uri.parse('https://drive.example/d/1'),
);

final _message = DriveLinkMessage(
  fileId: 'file-1',
  name: 'report.pdf',
  size: 42,
  mimeType: 'application/pdf',
  url: Uri.parse('https://drive.example/d/1'),
);

void _buildsAPlainTextMessageWithTheDriveData() {
  final content = driveLinkMessageContent(_message);

  expect(content['msgtype'], 'm.text');
  expect(content['body'], 'report.pdf\nhttps://drive.example/d/1');
  expect(content[driveFileContentKey], {
    'id': 'file-1',
    'name': 'report.pdf',
    'size': 42,
    'mime_type': 'application/pdf',
    'url': 'https://drive.example/d/1',
  });
}

void _addsTheThumbnailOnlyWhenPresent() {
  final withThumbnail = DriveLinkMessage(
    fileId: 'file-1',
    name: 'photo.png',
    size: 1,
    mimeType: 'image/png',
    url: Uri.parse('https://drive.example/d/1'),
    thumbnailUrl: Uri.parse('https://drive.example/t/1'),
  );

  final content = driveLinkMessageContent(withThumbnail);

  final data = content[driveFileContentKey] as Map;
  expect(data['thumbnail_url'], 'https://drive.example/t/1');
}

void _usesAnOctetStreamTypeWhenTheDocumentHasNone() {
  final message = DriveLinkMessage.fromDocument(_documentWithoutMimeType);

  expect(message?.mimeType, 'application/octet-stream');
}

void main() {
  test(
    'builds a plain text message with the Drive data',
    _buildsAPlainTextMessageWithTheDriveData,
  );
  test(
    'adds the thumbnail only when present',
    _addsTheThumbnailOnlyWhenPresent,
  );
  test(
    'uses an octet-stream type when the document has none',
    _usesAnOctetStreamTypeWhenTheDocumentHasNone,
  );
}
