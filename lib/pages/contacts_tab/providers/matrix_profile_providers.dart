import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/data/contact/datasources_impl/matrix_profile_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'matrix_profile_providers.g.dart';

/// The Matrix SDK sits behind this provider: consumers never touch
/// `Matrix.of(context).client` to resolve a profile.
///
/// Rebuilds only when the `Client` instance changes, not on every snapshot
/// push of the same one.
@riverpod
MatrixProfileDatasource matrixProfileDatasource(Ref ref) {
  final client = ref.watch(
    activeMatrixClientProvider.select((snapshot) => snapshot.client),
  );
  return MatrixProfileDatasourceImpl(client);
}

/// One-shot network profile lookup (only used as a fallback when the unified
/// store has no entry for the user).
@riverpod
Future<MatrixUserProfile?> matrixUserProfile(Ref ref, String matrixId) =>
    ref.watch(matrixProfileDatasourceProvider).fetchProfile(matrixId);
