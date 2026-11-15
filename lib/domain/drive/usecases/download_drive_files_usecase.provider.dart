import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_file_download_source.provider.dart';
import 'package:twake_chat/domain/drive/usecases/download_drive_files_usecase.dart';

part 'download_drive_files_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
DownloadDriveFilesUseCase downloadDriveFilesUseCase(Ref ref) =>
    DownloadDriveFilesUseCase(ref.watch(driveFileDownloadSourceProvider));
