import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/capabilities/server_capabilities_repository.provider.dart';
import 'package:twake_chat/domain/capabilities/usecases/fetch_profile_edit_capabilities_usecase.dart';

part 'fetch_profile_edit_capabilities_usecase.provider.g.dart';

@riverpod
FetchProfileEditCapabilitiesUseCase fetchProfileEditCapabilitiesUseCase(
  Ref ref,
) => FetchProfileEditCapabilitiesUseCase(
  ref.watch(serverCapabilitiesRepositoryProvider),
);
