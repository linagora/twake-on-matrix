import 'package:dio/dio.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_drive_picker/core.dart';

abstract interface class WorkplaceTokenExchange {
  Future<T> run<T>({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required WorkplaceCall<T> Function(
      WorkplaceRequestExecutor executor,
      WorkplaceRepository repository,
    )
    callOf,
  });
}

class WorkplaceTokenExchangeImpl implements WorkplaceTokenExchange {
  WorkplaceTokenExchangeImpl({required Dio dio, required bool requireHttps})
    : _dio = dio,
      _requireHttps = requireHttps;

  final Dio _dio;
  final bool _requireHttps;

  @override
  Future<T> run<T>({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required WorkplaceCall<T> Function(
      WorkplaceRequestExecutor executor,
      WorkplaceRepository repository,
    )
    callOf,
  }) {
    var current = session;
    final config = WorkplaceConfig(dio: _dio, requireHttps: _requireHttps);
    final executor = WorkplaceRequestExecutor(config: config);
    final repository = WorkplaceRepositoryImpl(
      _ValidatedWorkplaceDataSource(executor: executor, config: config),
      WorkplaceDriveDataSourceImpl(executor: executor),
    );
    final runner = WorkplaceAccessModeRunner(
      exchangeTokenInteractor: ExchangeDriveTokenInteractor(repository),
      oidcTokenGetter: () => current.idToken.value,
      oidcRefreshTrigger: () async {
        final renewed = await renewSession();
        _refuseTokenForAnotherWorkplace(session, renewed);
        current = renewed;
        return current.idToken.value;
      },
      isBridgeAvailable: () => false,
    );
    return runner.run(session.platformUrl, callOf(executor, repository));
  }

  void _refuseTokenForAnotherWorkplace(
    DriveSession session,
    DriveSession renewed,
  ) {
    if (renewed.platformUrl != session.platformUrl) {
      throw const DriveWorkplaceUnknown();
    }
  }
}

class _ValidatedWorkplaceDataSource extends WorkplaceDataSourceImpl {
  _ValidatedWorkplaceDataSource({
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
