import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/reactions/reactions_datasource.provider.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository_impl.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

part 'reactions_repository.provider.g.dart';

@riverpod
ReactionsRepository reactionsRepository(Ref ref) =>
    ReactionsRepositoryImpl(ref.watch(reactionsDatasourceProvider));
