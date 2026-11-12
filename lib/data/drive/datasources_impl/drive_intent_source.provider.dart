import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_intent_source_impl.dart';
import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:twake_chat/domain/drive/sources/drive_intent_source.dart';

part 'drive_intent_source.provider.g.dart';

@Riverpod(keepAlive: true)
DriveIntentSource driveIntentSource(Ref ref) =>
    DriveIntentSourceImpl(dio: ref.watch(driveDioProvider), requireHttps: true);
