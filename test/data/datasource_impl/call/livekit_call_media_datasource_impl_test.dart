import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource_impl/call/livekit_call_media_datasource_impl.dart';

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
}
