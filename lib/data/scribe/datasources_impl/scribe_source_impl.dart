import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/scribe/scribe_prompts.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';
import 'package:twake_drive_picker/core.dart';

class ScribeSourceImpl implements ScribeSource {
  ScribeSourceImpl({required Dio dio, required bool requireHttps})
    : _dio = dio,
      _requireHttps = requireHttps;

  final Dio _dio;
  final bool _requireHttps;
  final _prompts = const ScribePrompts();

  @override
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    var current = session;
    final config = WorkplaceConfig(dio: _dio, requireHttps: _requireHttps);
    final executor = WorkplaceRequestExecutor(config: config);
    final runner = WorkplaceAccessModeRunner(
      exchangeTokenInteractor: ExchangeDriveTokenInteractor(
        WorkplaceRepositoryImpl(
          _ValidatedExchangeDataSource(executor: executor, config: config),
          WorkplaceDriveDataSourceImpl(executor: executor),
        ),
      ),
      oidcTokenGetter: () => current.idToken.value,
      oidcRefreshTrigger: () async {
        final renewed = await renewSession();
        if (renewed.platformUrl != session.platformUrl) {
          throw const DriveWorkplaceUnknown();
        }
        current = renewed;
        return current.idToken.value;
      },
      isBridgeAvailable: () => false,
    );
    try {
      final answer = await runner.run(
        session.platformUrl,
        _CompletionCall(
          executor: executor,
          platformUrl: session.platformUrl,
          messages: _prompts.messagesFor(prompt, draft),
        ),
      );
      return _textOf(answer);
    } on DioException catch (e) {
      throw _failureOf(e);
    } on WorkplaceExchangeTokenException {
      Logs().w('ScribeSourceImpl::rewrite: exchange failed');
      throw const DriveExchangeRejected();
    } on FormatException {
      Logs().w('ScribeSourceImpl::rewrite: unreadable exchange answer');
      throw const DriveExchangeRejected();
    } on ScribeException {
      rethrow;
    } on DriveException {
      rethrow;
    } on Exception catch (e, s) {
      Logs().e('ScribeSourceImpl::rewrite: unexpected failure', e, s);
      throw const ScribeRewriteFailed();
    }
  }

  String _textOf(Object? answer) {
    final text = switch (answer) {
      {'choices': [{'message': {'content': final String content}}, ...]} =>
        content.trim(),
      _ => '',
    };
    if (text.isEmpty) {
      Logs().w('ScribeSourceImpl::rewrite: no text in the answer');
      throw const ScribeRewriteFailed();
    }
    return text;
  }

  Exception _failureOf(DioException e) {
    final status = e.response?.statusCode;
    Logs().w('ScribeSourceImpl::rewrite: ${e.type.name}, status $status');
    if (status == 429) return const DriveRateLimited();
    if (e.requestOptions.uri.path.endsWith('/auth/token_exchange')) {
      if (status == 400 && _isChatAppMissing(e)) {
        return const DriveChatAppMissing();
      }
      return _byConnection(e.type) ?? const DriveExchangeRejected();
    }
    return _byConnection(e.type) ?? const ScribeRewriteFailed();
  }

  bool _isChatAppMissing(DioException e) =>
      '${e.response?.data}'.toLowerCase().contains('not installed');

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
}

class _CompletionCall extends WorkplaceCall<Object?> {
  const _CompletionCall({
    required WorkplaceRequestExecutor executor,
    required Uri platformUrl,
    required List<Map<String, String>> messages,
  }) : _executor = executor,
       _platformUrl = platformUrl,
       _messages = messages;

  final WorkplaceRequestExecutor _executor;
  final Uri _platformUrl;
  final List<Map<String, String>> _messages;

  @override
  BridgePolicy get bridgePolicy => BridgePolicy.never;

  @override
  Future<Object?> call(WorkplaceAccessMode accessMode) => _executor.send(
    context: WorkplaceRequestContext(
      platformUrl: _platformUrl,
      accessMode: accessMode,
    ),
    route: const WorkplaceRequestRoute(
      method: 'POST',
      pathSegments: ['ai', 'v1', 'chat', 'completions'],
    ),
    body: WorkplaceRequestBody(data: {'messages': _messages}),
  );
}

class _ValidatedExchangeDataSource extends WorkplaceDataSourceImpl {
  _ValidatedExchangeDataSource({
    required super.executor,
    required super.config,
  });

  @override
  Future<String> exchangeToken(Uri platformUrl, String oidcIdToken) async {
    final String token;
    try {
      token = await super.exchangeToken(platformUrl, oidcIdToken);
    } on TypeError {
      throw const FormatException('invalid token exchange answer');
    }
    if (token.trim().isEmpty) {
      throw const FormatException('blank token exchange answer');
    }
    return token;
  }
}
