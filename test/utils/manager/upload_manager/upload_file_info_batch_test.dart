import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_file_info.dart';

void main() {
  UploadFileInfo build({String? batchId}) => UploadFileInfo(
    txid: 'tx1',
    createdAt: DateTime.utc(2026, 11, 6),
    uploadStateStreamController: BehaviorSubject(),
    cancelToken: CancelToken(),
    batchId: batchId,
  );

  test('keeps the batch id through JSON, so a retry stamps the same album', () {
    final restored = UploadFileInfo.fromJson(build(batchId: 'b-1').toJson());

    expect(restored.batchId, 'b-1');
  });

  test('has no batch id for a single file', () {
    expect(UploadFileInfo.fromJson(build().toJson()).batchId, isNull);
  });
}
