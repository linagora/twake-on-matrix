import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource_impl/call/livekit_call_media_datasource_impl.dart';

part 'call_media_datasource.provider.g.dart';

// Holds the LiveKit room of the ongoing call.
@Riverpod(keepAlive: true)
CallMediaDatasource callMediaDatasource(Ref ref) {
  final datasource = LiveKitCallMediaDatasourceImpl();
  ref.onDispose(() => unawaited(datasource.dispose()));
  return datasource;
}
