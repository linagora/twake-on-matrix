import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource_impl/call/livekit_call_media_datasource_impl.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';

void main() {
  test('the user of a LiveKit identity drops the device id', () {
    expect(
      LiveKitCallMediaDatasourceImpl.userIdOf('@alice:localhost:DEV'),
      '@alice:localhost',
    );
    expect(
      LiveKitCallMediaDatasourceImpl.userIdOf('@alice:localhost'),
      '@alice:localhost',
    );
  });

  test('watchParticipants_afterLiveKitGaveUp_failsAsLost', () async {
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    await expectLater(
      datasource.watchParticipants(),
      emitsError(isA<CallConnectionFailedException>()),
    );
  });

  test('watchParticipants_afterADisconnect_forgetsTheLoss', () async {
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    await datasource.disconnect();

    expect(await datasource.watchParticipants().first, isEmpty);
  });
}
