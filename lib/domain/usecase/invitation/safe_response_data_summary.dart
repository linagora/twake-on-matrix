String safeResponseDataSummary(Object? data) {
  if (data == null) {
    return 'null';
  }
  if (data is Map) {
    return 'Map(keys=${data.keys.join(',')})';
  }
  return data.runtimeType.toString();
}
