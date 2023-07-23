import 'package:equatable/equatable.dart';

abstract class Success extends Equatable {
  const Success();
}

abstract class ViewState extends Success {}

class UIState extends ViewState {
  static final idle = UIState();

  UIState() : super();

  @override
  List<Object?> get props => [];
}