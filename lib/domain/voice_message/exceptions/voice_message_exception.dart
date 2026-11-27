class FindNextVoiceMessageException implements Exception {
  const FindNextVoiceMessageException(this.cause);

  final Object cause;

  @override
  String toString() => 'FindNextVoiceMessageException($cause)';
}
