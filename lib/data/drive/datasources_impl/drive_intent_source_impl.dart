import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/drive/sources/workplace_token_exchange.dart';
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
  DriveIntentSourceImpl({required WorkplaceTokenExchange exchange})
    : _exchange = exchange;

  final WorkplaceTokenExchange _exchange;

  @override
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) async {
    try {
      final intent = await _exchange.run(
        session: session,
        renewSession: renewSession,
        callOf: (_, repository) => CreateDriveIntentCall(
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
    if (_exchange.isChatAppMissing(e)) return const DriveChatAppMissing();
    return _exchange.connectionFailureOf(e.type) ?? _byStatus(status);
  }

  DriveException _byStatus(int? status) => status == 400 || status == 401
      ? const DriveExchangeRejected()
      : const DriveIntentFailed();
}
