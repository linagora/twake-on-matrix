class LookUpFederationIdentityNotFoundException implements Exception {
  final dynamic error;

  LookUpFederationIdentityNotFoundException(this.error);

  @override
  String toString() {
    return 'LookUpFederationIdentityNotFoundException $error';
  }
}
