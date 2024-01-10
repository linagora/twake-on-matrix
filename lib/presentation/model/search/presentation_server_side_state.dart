import 'package:equatable/equatable.dart';

abstract class PresentationServerSideUIState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

class PresentationServerSideInitial extends PresentationServerSideUIState {}
