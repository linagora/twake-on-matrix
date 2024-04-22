import 'package:equatable/equatable.dart';

abstract class AutoHomeServerPickerState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

class AutoHomeServerPickerInitialState extends AutoHomeServerPickerState {
  @override
  List<Object?> get props => [];
}

class AutoHomeServerPickerLoadingState extends AutoHomeServerPickerState {
  @override
  List<Object?> get props => [];
}

class AutoHomeServerPickerSuccessState extends AutoHomeServerPickerState {
  @override
  List<Object?> get props => [];
}

class AutoHomeServerPickerFailureState extends AutoHomeServerPickerState {
  final String? error;

  AutoHomeServerPickerFailureState({
    this.error,
  });

  @override
  List<Object?> get props => [error];
}
