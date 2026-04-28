import 'dart:io';

import 'package:fluffychat/data/datasource/contact/sim_country/sim_country_provider.dart';
import 'package:matrix/matrix.dart';
import 'package:sim_country_code_plus/sim_country_code_plus.dart';

class SimCountryProviderImpl implements SimCountryProvider {
  String? _cache;
  bool _fetched = false;

  @override
  Future<String?> getCountryCode() async {
    if (_fetched) return _cache;
    _fetched = true;
    _cache = await _resolve();
    return _cache;
  }

  bool _isValidSimCode(String? code) =>
      code != null && code.isNotEmpty && code != '--';

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
    // Handles both POSIX ("fr_FR", "fr_FR.UTF-8") and BCP-47 ("fr-FR") formats.
    try {
      final locale = Platform.localeName;
      final parts = locale.split(RegExp(r'[_\-]'));
      if (parts.length >= 2) {
        return parts[1].split('.').first.toUpperCase();
      }
    } catch (e) {
      Logs().w('SimCountryProvider: locale unavailable – $e');
    }

    return null;
  }
}
