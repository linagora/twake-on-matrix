import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/capabilities/usecases/fetch_profile_edit_capabilities_usecase.provider.dart';

part 'profile_edit_capabilities_provider.g.dart';

@riverpod
Future<ProfileEditCapabilities> profileEditCapabilities(Ref ref) async {
  final capabilities = await ref
      .watch(fetchProfileEditCapabilitiesUseCaseProvider)
      .execute();
  // Cached on success only: a failed load retries on the next open.
  if (ref.mounted) ref.keepAlive();
  return capabilities;
}
