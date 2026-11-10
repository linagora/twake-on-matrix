import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/sso_refresh_token_store_impl.dart';
import 'package:twake_chat/domain/drive/sources/sso_refresh_token_store.dart';

part 'sso_refresh_token_store.provider.g.dart';

/// The refresh token of the SSO survives a restart in the secure store, so the
/// first Drive use after it needs no browser.
@Riverpod(keepAlive: true)
SsoRefreshTokenStore ssoRefreshTokenStore(Ref ref) =>
    SsoRefreshTokenStoreImpl(const FlutterSecureStorage());
