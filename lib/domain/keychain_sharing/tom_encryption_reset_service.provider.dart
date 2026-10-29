import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/keychain_sharing/tom_encryption_reset_service.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.provider.dart';

part 'tom_encryption_reset_service.provider.g.dart';

// TODO: [transitional] Keyed by Client until matrixClientProvider exists (plan v2, Step 1).
@riverpod
TomEncryptionResetService tomEncryptionResetService(Ref ref, Client client) =>
    TomEncryptionResetService(
      client: client,
      getRecoveryWordsUseCase: ref.watch(getRecoveryWordsUseCaseProvider),
    );
