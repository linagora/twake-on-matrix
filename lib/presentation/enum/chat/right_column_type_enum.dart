import 'package:equatable/equatable.dart';

abstract class RightColumnType extends Equatable {
  const RightColumnType();
}

class SearchRightColumnType extends RightColumnType {
  const SearchRightColumnType();

  @override
  List<Object?> get props => [];
}

class ProfileInfoRightColumnType extends RightColumnType {
  final String? userId;

  const ProfileInfoRightColumnType({
    this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
