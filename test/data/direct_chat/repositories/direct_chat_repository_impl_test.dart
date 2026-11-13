import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/direct_chat/datasources/direct_chat_datasource.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.dart';

class _RecordingDatasource implements DirectChatDatasource {
  final created = <String>[];
  final checked = <({String roomId, String contactMxId})>[];

  @override
  Future<String> createDirectChat({required String contactMxId}) async {
    created.add(contactMxId);
    return '!room:server';
  }

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) {
    checked.add((roomId: roomId, contactMxId: contactMxId));
    return false;
  }

  @override
  String? findDirectChat({required String contactMxId}) =>
      contactMxId == '@a:s' ? '!dm:s' : null;
}

void main() {
  test('hands the creation and the check to the datasource', () async {
    final datasource = _RecordingDatasource();
    final repository = DirectChatRepositoryImpl(datasource);

    expect(
      await repository.createDirectChat(contactMxId: '@a:s'),
      '!room:server',
    );
    expect(
      repository.isUsableDirectChat(roomId: '!r:s', contactMxId: '@a:s'),
      isFalse,
    );
    expect(datasource.created, ['@a:s']);
    expect(datasource.checked, [(roomId: '!r:s', contactMxId: '@a:s')]);
  });

  test('hands the lookup to the datasource', () {
    final repository = DirectChatRepositoryImpl(_RecordingDatasource());

    expect(repository.findDirectChat(contactMxId: '@a:s'), '!dm:s');
    expect(repository.findDirectChat(contactMxId: '@b:s'), isNull);
  });
}
