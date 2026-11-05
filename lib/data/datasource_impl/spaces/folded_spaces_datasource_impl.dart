import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource/spaces/folded_spaces_datasource.dart';

class FoldedSpacesDatasourceImpl implements FoldedSpacesDatasource {
  const FoldedSpacesDatasourceImpl();

  String _key(String userId) => 'twake-chat.folded-spaces:$userId';

  @override
  Future<Set<String>> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.get(_key(userId));
    return stored is List ? stored.whereType<String>().toSet() : const {};
  }

  @override
  Future<void> write(String userId, Set<String> spaceIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), spaceIds.toList());
  }
}
