import 'package:matrix/matrix.dart';

class AccountBundles {
  String? prefix;
  List<AccountBundle>? bundles;

  AccountBundles({this.prefix, this.bundles});

  AccountBundles.fromJson(Map<String, dynamic> json)
    : prefix = json.tryGet<String>('prefix'),
      bundles = json['bundles'] is List
          ? json['bundles']
                .map((b) {
                  try {
                    return AccountBundle.fromJson(b);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<AccountBundle>()
                .toList()
          : null;

  Map<String, dynamic> toJson() => {
    if (prefix != null) 'prefix': prefix,
    if (bundles != null) 'bundles': bundles!.map((v) => v.toJson()).toList(),
  };
}

class AccountBundle {
  String? name;
  int? priority;

  AccountBundle({this.name, this.priority});

  AccountBundle.fromJson(Map<String, dynamic> json)
    : name = json.tryGet<String>('name'),
      priority = json.tryGet<int>('priority');

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (name != null) 'name': name,
    if (priority != null) 'priority': priority,
  };
}

const accountBundlesType = 'im.twake.account_bundles';

/// Legacy account-data type used before the FluffyChat-to-Twake rename.
///
/// Kept as a read fallback so accounts with bundles saved under the old
/// type don't lose their configuration after upgrading.
const _legacyAccountBundlesType = 'im.fluffychat.account_bundles';

extension AccountBundlesExtension on Client {
  Map<String, dynamic>? get _accountBundlesContent =>
      accountData[accountBundlesType]?.content ??
      accountData[_legacyAccountBundlesType]?.content;

  List<AccountBundle> get accountBundles {
    List<AccountBundle>? ret;
    final content = _accountBundlesContent;
    if (content != null) {
      ret = AccountBundles.fromJson(content).bundles;
    }
    ret ??= [];
    if (ret.isEmpty) {
      ret.add(AccountBundle(name: userID, priority: 0));
    }
    return ret;
  }

  Future<void> setAccountBundle(String name, [int? priority]) async {
    final data = AccountBundles.fromJson(_accountBundlesContent ?? {});
    var foundBundle = false;
    final bundles = data.bundles ??= [];
    for (final bundle in bundles) {
      if (bundle.name == name) {
        bundle.priority = priority;
        foundBundle = true;
        break;
      }
    }
    if (!foundBundle) {
      bundles.add(AccountBundle(name: name, priority: priority));
    }
    await setAccountData(userID!, accountBundlesType, data.toJson());
  }

  Future<void> removeFromAccountBundle(String name) async {
    final content = _accountBundlesContent;
    if (content == null) {
      return; // nothing to do
    }
    final data = AccountBundles.fromJson(content);
    if (data.bundles == null) return;
    data.bundles!.removeWhere((b) => b.name == name);
    await setAccountData(userID!, accountBundlesType, data.toJson());
  }

  String get sendPrefix {
    final data = AccountBundles.fromJson(_accountBundlesContent ?? {});
    return data.prefix!;
  }
}
