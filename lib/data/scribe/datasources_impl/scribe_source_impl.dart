import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/drive/sources/workplace_token_exchange.dart';
import 'package:twake_chat/data/scribe/scribe_prompts.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';
import 'package:twake_drive_picker/core.dart';

class ScribeSourceImpl implements ScribeSource {
  ScribeSourceImpl({required WorkplaceTokenExchange exchange})
    : _exchange = exchange;

  final WorkplaceTokenExchange _exchange;
  final _prompts = const ScribePrompts();

  @override
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    try {
      final answer = await _exchange.run(
        session: session,
        renewSession: renewSession,
        callOf: (executor, _) => _CompletionCall(
          executor: executor,
          platformUrl: session.platformUrl,
          messages: _prompts.messagesFor(prompt, draft),
        ),
      );
      return _textOf(answer);
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(_failureOfRun(e, s), s);
    }
  }

  Exception _failureOfRun(Exception e, StackTrace s) {
    switch (e) {
      case ScribeException() || DriveException():
        return e;
      case DioException():
        return _failureOf(e);
      case WorkplaceExchangeTokenException():
        Logs().w('ScribeSourceImpl::rewrite: exchange failed');
        return const DriveExchangeRejected();
      case FormatException():
        Logs().w('ScribeSourceImpl::rewrite: unreadable exchange answer');
        return const DriveExchangeRejected();
      default:
        Logs().e('ScribeSourceImpl::rewrite: unexpected failure', e, s);
        return const ScribeRewriteFailed();
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
    if (_exchange.isExchangeFailure(e)) {
      if (_exchange.isChatAppMissing(e)) return const DriveChatAppMissing();
      return _exchange.connectionFailureOf(e.type) ??
          const DriveExchangeRejected();
    }
    return _exchange.connectionFailureOf(e.type) ?? const ScribeRewriteFailed();
  }
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
