sealed class RecoveryWordsException implements Exception {
  const RecoveryWordsException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}

class GetRecoveryWordsException extends RecoveryWordsException {
  const GetRecoveryWordsException(super.cause);
}
