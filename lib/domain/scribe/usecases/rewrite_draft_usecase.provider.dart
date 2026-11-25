import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_source.provider.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';

part 'rewrite_draft_usecase.provider.g.dart';

/// The Scribe signs in with the Drive session. The notifier is read at call
/// time, so a request always uses the session of the active account; a
/// renewal for an account that is no longer active is refused.
@Riverpod(keepAlive: true)
RewriteDraftUseCase rewriteDraftUseCase(Ref ref) => RewriteDraftUseCase(
  source: ref.watch(scribeSourceProvider),
  obtainSession: () => ref.read(driveSessionProvider.notifier).obtain(),
  renewSession: () => ref.read(driveSessionProvider.notifier).renew(),
  currentAccount: () => ref.read(activeUserIdProvider),
);
