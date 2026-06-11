// lib/features/invitation/invitation_providers.dart

import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '04_invitation_api_datasource.dart';
import '05_invitation_local_datasource.dart';
import '06_invitation_api_datasource_impl.dart';
import '06b_invitation_endpoint.dart';
import '07_invitation_repository.dart';
import '08_invitation_repository_impl.dart';
import '09_generate_invitation_link_usecase.dart';
import '10_get_invitation_status_usecase.dart';
import '11_send_invitation_usecase.dart';
import '12_invitation_service.dart';

part '15_invitation_providers.g.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

// databaseProvider is overridden at app startup with the real implementation
// (e.g. FlutterMatrixSqfliteDatabase)
@Riverpod(keepAlive: true)
DatabaseApi database(Ref ref) =>
    throw UnimplementedError('override databaseProvider at app startup');

// matrixClientProvider is keepAlive — it survives the entire session
// Defined once for the whole app (lib/providers/matrix_client_provider.dart)
@Riverpod(keepAlive: true)
Client matrixClient(Ref ref) {
  final client = Client('TwakeApp', database: ref.watch(databaseProvider));
  ref.onDispose(() => client.dispose());
  return client;
}

// dioProvider provides a configured Dio instance for the Tom server
// Interceptors (auth, cache, logging) are added here
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://tom.example.com'));
  // dio.interceptors.add(AuthorizationInterceptor(...));
  ref.onDispose(() => dio.close());
  return dio;
}

// ─── Network ──────────────────────────────────────────────────────────────────

@riverpod
InvitationEndpoint invitationEndpoint(Ref ref) =>
    InvitationEndpoint(ref.watch(dioProvider));

// ─── DataSources ──────────────────────────────────────────────────────────────

@riverpod
InvitationApiDataSource invitationApiDataSource(Ref ref) =>
    InvitationApiDataSourceImpl(ref.watch(invitationEndpointProvider));

@riverpod
InvitationLocalDataSource invitationLocalDataSource(Ref ref) =>
    throw UnimplementedError('provide a real InvitationLocalDataSourceImpl');

// ─── Repository ───────────────────────────────────────────────────────────────

@riverpod
InvitationRepository invitationRepository(Ref ref) => InvitationRepositoryImpl(
      ref.watch(invitationApiDataSourceProvider),
      ref.watch(invitationLocalDataSourceProvider),
    );

// ─── Use cases ────────────────────────────────────────────────────────────────

@riverpod
GenerateInvitationLinkUseCase generateInvitationLinkUseCase(Ref ref) =>
    GenerateInvitationLinkUseCase(ref.watch(invitationRepositoryProvider));

@riverpod
GetInvitationStatusUseCase getInvitationStatusUseCase(Ref ref) =>
    GetInvitationStatusUseCase(ref.watch(invitationRepositoryProvider));

@riverpod
SendInvitationUseCase sendInvitationUseCase(Ref ref) =>
    SendInvitationUseCase(ref.watch(invitationRepositoryProvider));

// ─── Service ──────────────────────────────────────────────────────────────────

@riverpod
InvitationService invitationService(Ref ref) => InvitationService(
      generateLink: ref.watch(generateInvitationLinkUseCaseProvider),
      getStatus: ref.watch(getInvitationStatusUseCaseProvider),
      sendInvitation: ref.watch(sendInvitationUseCaseProvider),
    );

// InvitationController is declared with @riverpod in 14_invitation_controller.dart
// → invitationControllerProvider(roomId) available everywhere
