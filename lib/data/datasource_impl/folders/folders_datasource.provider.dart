import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/folders/folders_datasource.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'folders_datasource.provider.g.dart';

// TODO: [transitional] Reads the active client until matrixClientProvider exists.
@riverpod
FoldersDatasource foldersDatasource(Ref ref) =>
    FoldersDatasourceImpl(ref.watch(activeMatrixClientProvider));
