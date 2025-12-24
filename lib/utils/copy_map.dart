/// The database always gives back an `_InternalLinkedHasMap<dynamic, dynamic>`.
/// This creates a deep copy of the json and makes sure that the format is
/// always `Map<String, Object?>`.
Map<String, Object?> copyMap(Map map) {
  final copy = Map<String, dynamic>.from(map);
  for (final entry in copy.entries) {
    copy[entry.key] = _castValue(entry.value);
  }
  return copy;
}

dynamic _castValue(dynamic value) {
  if (value is Map) {
    return copyMap(value);
  }
  if (value is List) {
    return value.map(_castValue).toList();
  }
  return value;
}
