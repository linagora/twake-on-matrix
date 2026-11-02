import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/spaces/folded_spaces_datasource.dart';
import 'package:twake_chat/data/datasource_impl/spaces/folded_spaces_datasource_impl.dart';

part 'folded_spaces_datasource.provider.g.dart';

@riverpod
FoldedSpacesDatasource foldedSpacesDatasource(Ref ref) =>
    const FoldedSpacesDatasourceImpl();
