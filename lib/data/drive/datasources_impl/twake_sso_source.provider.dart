import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/twake_sso_source_impl.dart';
import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:twake_chat/data/drive/sources/pkce_generator.provider.dart';
import 'package:twake_chat/data/drive/sources/web_auth_launcher.provider.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';

part 'twake_sso_source.provider.g.dart';

/// The SSO of [config]: the active account's for Drive, or, during a login,
/// the one of the homeserver being signed in to.
@Riverpod(keepAlive: true)
TwakeSsoSource twakeSsoSource(Ref ref, DriveConfig config) =>
    TwakeSsoSourceImpl(
      config: config,
      dio: ref.watch(driveDioProvider),
      pkce: ref.watch(pkceGeneratorProvider),
      launcher: ref.watch(webAuthLauncherProvider),
      now: DateTime.now,
      requireHttps: true,
    );
