import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/new_group/new_group_datasource.provider.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository_impl.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

part 'new_group_repository.provider.g.dart';

@riverpod
NewGroupRepository newGroupRepository(Ref ref) =>
    NewGroupRepositoryImpl(ref.watch(newGroupDatasourceProvider));
