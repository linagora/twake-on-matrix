sealed class RecoveryWordsException implements Exception {
  const RecoveryWordsException(this.cause);

  final Object cause;
}

class GetRecoveryWordsException extends RecoveryWordsException {
  const GetRecoveryWordsException(super.cause);

  // The cause may quote the ToM response; the datasource logs it.
  @override
  String toString() => 'GetRecoveryWordsException';
}
