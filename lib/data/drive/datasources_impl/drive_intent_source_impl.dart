import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/entities/drive_intent.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/sources/drive_intent_source.dart';
import 'package:twake_drive_picker/core.dart';

/// Drive's side of the picker, on the `twake_drive_picker` core. The picker
/// never signs in: it takes the id token this class hands it, trades it for a
/// Drive token and retries once, after a renewal, when Drive calls it stale.
///
/// Logs say where a step failed, never a token or a link.
class DriveIntentSourceImpl implements DriveIntentSource {
  DriveIntentSourceImpl({required Dio dio, required bool requireHttps})
    : _dio = dio,
      _requireHttps = requireHttps;

  final Dio _dio;
  final bool _requireHttps;

  @override
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) async {
    var current = session;
    final repository = _repository();
    final runner = WorkplaceAccessModeRunner(
      exchangeTokenInteractor: ExchangeDriveTokenInteractor(repository),
      oidcTokenGetter: () => current.idToken.value,
      oidcRefreshTrigger: () async {
        final renewed = await renewSession();
        // The exchange and the intent go to the workplace of the first
        // session: a token for another one must not be sent there.
        if (renewed.platformUrl != session.platformUrl) {
          throw const DriveWorkplaceUnknown();
        }
        current = renewed;
        return current.idToken.value;
      },
      // The Cozy bridge is for a page that embeds Drive; the app always
      // trades the token.
      isBridgeAvailable: () => false,
    );
    try {
      final intent = await runner.run(
        session.platformUrl,
        CreateDriveIntentCall(
          CreateDriveIntentInteractor(repository),
          session.platformUrl,
          _intentConfig(options),
        ),
      );
      return DriveIntent(
        intentId: intent.intentId,
        intentUrl: intent.intentUrl,
        client: intent.client,
      );
    } on DioException catch (e) {
      throw _failureOf(e);
    } on WorkplaceExchangeTokenException {
      Logs().e('DriveIntentSourceImpl::createIntent: exchange failed');
      throw const DriveExchangeRejected();
    } on WorkplaceCreateIntentException {
      Logs().e('DriveIntentSourceImpl::createIntent: no intent');
      throw const DriveIntentFailed();
    } on FormatException {
      Logs().e('DriveIntentSourceImpl::createIntent: unreadable answer');
      throw const DriveIntentFailed();
    }
  }

  WorkplaceRepositoryImpl _repository() {
    final config = WorkplaceConfig(dio: _dio, requireHttps: _requireHttps);
    final executor = WorkplaceRequestExecutor(config: config);
    return WorkplaceRepositoryImpl(
      _ValidatedIntentDataSource(executor: executor, config: config),
      WorkplaceDriveDataSourceImpl(executor: executor),
    );
  }

  WorkplaceIntentConfig _intentConfig(DrivePickerOptions options) =>
      WorkplaceIntentConfig(
        addAsLink: WorkplaceActionConfig(label: options.linkLabel),
        addAsAttachment: options.attachLabel == null
            ? null
            : WorkplaceActionConfig(
                label: options.attachLabel,
                maxFileSize: options.maxAttachmentBytes,
                allowFolder: false,
              ),
        theme: options.darkTheme ? WorkplaceTheme.dark : WorkplaceTheme.light,
      );

  DriveException _failureOf(DioException e) {
    final status = e.response?.statusCode;
    Logs().w(
      'DriveIntentSourceImpl::createIntent: ${e.type.name}, status $status',
    );
    if (status == 429) return const DriveRateLimited();
    if (status == 400 && _isChatAppMissing(e)) {
      return const DriveChatAppMissing();
    }
    return _byConnection(e.type) ?? _byStatus(status);
  }

  /// What a failed connection means, or null when the server answered.
  DriveException? _byConnection(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const DriveTimedOut(),
    DioExceptionType.connectionError => const DriveOffline(),
    DioExceptionType.badCertificate ||
    DioExceptionType.badResponse ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown => null,
  };

  /// The exchange's answer when the Chat app is not on the user's Drive, as
  /// the mobile single login contract gives it.
  bool _isChatAppMissing(DioException e) =>
      e.requestOptions.path.endsWith('/auth/token_exchange') &&
      '${e.response?.data}'.toLowerCase().contains('not installed');

  DriveException _byStatus(int? status) => status == 400 || status == 401
      ? const DriveExchangeRejected()
      : const DriveIntentFailed();
}

/// The picker package's JSON parser uses unchecked casts and Error types for
/// malformed server data. Convert those only at the parser boundary; errors
/// from renewal, request setup and other app code continue to surface.
class _ValidatedIntentDataSource extends WorkplaceDataSourceImpl {
  _ValidatedIntentDataSource({required super.executor, required super.config});

  @override
  Future<String> exchangeToken(Uri platformUrl, String oidcIdToken) async {
    try {
      return await super.exchangeToken(platformUrl, oidcIdToken);
    } on TypeError {
      throw const FormatException('invalid token exchange answer');
    }
  }

  @override
  WorkplaceIntent parseIntentResponse(dynamic data, {bool? requireHttps}) {
    try {
      return super.parseIntentResponse(data, requireHttps: requireHttps);
    } on TypeError {
      throw const FormatException('invalid Drive intent answer');
    } on StateError {
      throw const FormatException('Drive intent answer has no service');
    } on ArgumentError {
      throw const FormatException('Drive intent URL was refused');
    }
  }
}
