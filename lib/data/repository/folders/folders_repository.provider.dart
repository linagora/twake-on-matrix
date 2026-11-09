import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_datasource.provider.dart';
import 'package:twake_chat/data/repository/folders/folders_repository_impl.dart';
import 'package:twake_chat/domain/repository/folders/folders_repository.dart';

part 'folders_repository.provider.g.dart';

@riverpod
FoldersRepository foldersRepository(Ref ref) =>
    FoldersRepositoryImpl(ref.watch(foldersDatasourceProvider));
