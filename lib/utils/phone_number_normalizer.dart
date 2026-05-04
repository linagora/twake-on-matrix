import 'package:phone_numbers_parser/phone_numbers_parser.dart' as pnp;

/// Attempts to normalize [rawNumber] to E.164 (e.g. "+33612345678").
///
/// When [callerIsoCode] (ISO 3166-1 alpha-2, e.g. "FR") is provided, it is
/// used as the default region for local/national numbers. Without it, only
/// numbers already carrying an explicit "+" country prefix can be resolved.
///
/// Returns null if the number cannot be parsed or is invalid. The caller
/// should discard it rather than forwarding an unresolvable 3PID to the
/// identity server.
String? tryNormalizePhoneNumberToE164(String rawNumber, String? callerIsoCode) {
  try {
    final pnp.PhoneNumber phone;
    if (callerIsoCode != null) {
      final isoCode = pnp.IsoCode.fromJson(callerIsoCode.toUpperCase());
      phone = pnp.PhoneNumber.parse(rawNumber, callerCountry: isoCode);
    } else {
      // No country context: only E.164 numbers with "+" can be resolved.
      phone = pnp.PhoneNumber.parse(rawNumber);
    }
    if (!phone.isValid()) return null;
    return phone.international;
  } catch (_) {
    return null;
  }
}
