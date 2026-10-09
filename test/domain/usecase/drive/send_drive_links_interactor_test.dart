import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';
import 'package:twake_chat/domain/model/drive/drive_link_message.dart';
import 'package:twake_chat/domain/repository/drive/drive_link_message_repository.dart';
import 'package:twake_chat/domain/usecase/drive/send_drive_links_interactor.dart';

DrivePickedEntry _document(
  String id, {
  String? link = 'https://drive.example/d',
}) => DrivePickedEntry(
  id: id,
  name: '$id.pdf',
  size: 10,
  mimeType: 'application/pdf',
  sharingLink: link == null ? null : Uri.parse('$link/$id'),
  downloadLink: Uri.parse('https://drive.example/dl/$id'),
);

class _FakeLinkRepository implements DriveLinkMessageRepository {
  _FakeLinkRepository({this.canSend = true, this.failingFileId});

  final bool canSend;
  final String? failingFileId;
  final List<DriveLinkMessage> sent = [];

  @override
  Future<bool> canSendTo(String roomId) async => canSend;

  @override
  Future<void> send(String roomId, DriveLinkMessage message) async {
    if (message.fileId == failingFileId) throw StateError('send failed');
    sent.add(message);
  }
}

Future<int> _run(_FakeLinkRepository repository, List<DrivePickedEntry> docs) =>
    SendDriveLinksInteractor(
      repository,
    ).execute(roomId: '!room:example', documents: docs);

Future<void> _sendsOneMessagePerDocument() async {
  final repository = _FakeLinkRepository();

  final count = await _run(repository, [_document('a'), _document('b')]);

  expect(count, 2);
  expect(repository.sent.map((m) => m.fileId), ['a', 'b']);
  expect(repository.sent.first.body, 'a.pdf\nhttps://drive.example/d/a');
}

Future<void> _sendsNothingWhenTheUserCannotSendAnymore() async {
  final repository = _FakeLinkRepository(canSend: false);

  final count = await _run(repository, [_document('a')]);

  expect(count, 0);
  expect(repository.sent, isEmpty);
}

Future<void> _skipsDocumentsWithoutASharingLink() async {
  final repository = _FakeLinkRepository();

  final count = await _run(repository, [
    _document('a', link: null),
    _document('b'),
  ]);

  expect(count, 1);
  expect(repository.sent.single.fileId, 'b');
}

Future<void> _keepsSendingAfterOneMessageFails() async {
  final repository = _FakeLinkRepository(failingFileId: 'a');

  final count = await _run(repository, [_document('a'), _document('b')]);

  expect(count, 1);
  expect(repository.sent.single.fileId, 'b');
}

void main() {
  test('sends one message per document', _sendsOneMessagePerDocument);
  test(
    'sends nothing when the user cannot send anymore',
    _sendsNothingWhenTheUserCannotSendAnymore,
  );
  test(
    'skips documents without a sharing link',
    _skipsDocumentsWithoutASharingLink,
  );
  test(
    'keeps sending after one message fails',
    _keepsSendingAfterOneMessageFails,
  );
}
