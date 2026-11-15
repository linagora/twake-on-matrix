import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_file_download_source_impl.dart';
import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:twake_chat/domain/drive/sources/drive_file_download_source.dart';

part 'drive_file_download_source.provider.g.dart';

/// Through the Drive client for the same reason as `driveDio`: the link of a
/// file is Drive's secret, and the Matrix token must not go with it.
@Riverpod(keepAlive: true)
DriveFileDownloadSource driveFileDownloadSource(Ref ref) =>
    DriveFileDownloadSourceImpl(
      dio: ref.watch(driveDioProvider),
      tempRoot: getTemporaryDirectory,
      randomId: () => Random.secure().nextInt(1 << 32).toRadixString(36),
      now: DateTime.now,
      staleAfter: const Duration(days: 1),
      requireHttps: true,
      concurrency: 3,
    );
