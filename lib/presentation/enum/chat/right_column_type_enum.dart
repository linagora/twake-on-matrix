enum RightColumnType {
  none,
  search,
  profileInfo,
}

extension RightColumnTypeExtension on RightColumnType {
  bool get isShown => this != RightColumnType.none;

  String? get initialRoute => ({
        RightColumnType.search: RightColumnRouteNames.search,
        RightColumnType.profileInfo: RightColumnRouteNames.profileInfo,
      })[this];
}

class RightColumnRouteNames {
  static const search = 'rightColumn/search';
  static const profileInfo = 'rightColumn/profileInfo';
}
