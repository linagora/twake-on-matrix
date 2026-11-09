import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/spaces/space_datasource.provider.dart';
import 'package:twake_chat/data/repository/spaces/space_repository_impl.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';

part 'space_repository.provider.g.dart';

@riverpod
SpaceRepository spaceRepository(Ref ref) =>
    SpaceRepositoryImpl(ref.watch(spaceDatasourceProvider));
