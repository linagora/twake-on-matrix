abstract class SimCountryProvider {
  /// Returns the ISO 3166-1 alpha-2 country code of the SIM card
  /// (e.g. "FR", "US"), or null if it cannot be determined.
  Future<String?> getCountryCode();
}
