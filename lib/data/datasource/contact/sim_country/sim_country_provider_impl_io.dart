import 'dart:io';

import 'package:fluffychat/data/datasource/contact/sim_country/sim_country_provider.dart';
import 'package:matrix/matrix.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart' as pnp;
import 'package:sim_country_code_plus/sim_country_code_plus.dart';

class SimCountryProviderImpl implements SimCountryProvider {
  Future<String?>? _countryCodeFuture;

  @override
  Future<String?> getCountryCode() => _countryCodeFuture ??= _resolve();

  // Accept only codes that phone_numbers_parser itself recognises the same
  // lookup used by IsoCode.fromJson. This rejects syntactically valid but
  // unknown codes (e.g. "ZZ") that would otherwise throw downstream.
  bool _isValidSimCode(String? code) =>
      code != null && pnp.isoCodeConversionMap.containsKey(code.toUpperCase());

  Future<String?> _resolve() async {
    // 1. Try SIM card country (most accurate for phone number context).
    try {
      final simCode = await SimCountryCodePlus.simCountryCode;
      if (_isValidSimCode(simCode)) {
        return simCode!.toUpperCase();
      }
    } catch (e) {
      Logs().w('SimCountryProvider: SIM country unavailable – $e');
    }

    // 2. Fallback: derive country from device locale.
    // Handles POSIX ("fr_FR", "fr_FR.UTF-8", "zh_Hans_CN") and BCP-47 ("fr-FR").
    try {
      final locale = Platform.localeName;
      final parts = locale.split(RegExp(r'[_\-]'));
      if (parts.length >= 2) {
        // Strip any trailing codec suffix (e.g. ".UTF-8") before validating.
        String stripped(String s) => s.split('.').first;

        // Prefer the last token (handles "zh_Hans_CN" → "CN");
        // fall back to the second token only if the last is not a valid alpha-2.
        final last = stripped(parts.last);
        final second = stripped(parts[1]);
        final token = _isValidSimCode(last)
            ? last
            : (_isValidSimCode(second) ? second : null);
        if (token != null) return token.toUpperCase();
      }
    } catch (e) {
      Logs().w('SimCountryProvider: locale unavailable – $e');
    }

    return null;
  }
}
