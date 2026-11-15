import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/data/drive/datasources_impl/twake_sso_source.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.provider.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.provider.dart';
import 'package:twake_chat/domain/drive/usecases/resolve_drive_session_usecase.dart';

part 'resolve_drive_session_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
ResolveDriveSessionUseCase resolveDriveSessionUseCase(Ref ref) =>
    ResolveDriveSessionUseCase(
      ssoSource: ref.watch(
        twakeSsoSourceProvider(ref.watch(driveConfigProvider)),
      ),
      urlPolicy: ref.watch(drivePlatformUrlPolicyProvider),
      expiryPolicy: ref.watch(idTokenExpiryPolicyProvider),
      now: DateTime.now,
    );
