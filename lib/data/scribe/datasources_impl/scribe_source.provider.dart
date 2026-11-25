import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_source_impl.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';

part 'scribe_source.provider.g.dart';

/// On the Drive client: the shared one adds the Matrix bearer token, which the
/// workplace must not receive.
@Riverpod(keepAlive: true)
ScribeSource scribeSource(Ref ref) =>
    ScribeSourceImpl(dio: ref.watch(driveDioProvider), requireHttps: true);
