import 'dart:ui';

import 'package:twake_chat/presentation/state/failure.dart';
import 'package:twake_chat/presentation/state/success.dart';

class SavingLanguage extends UIState {}

class SaveLanguageSuccess extends UIState {
  final Locale localeStored;

  SaveLanguageSuccess(this.localeStored);

  @override
  List<Object?> get props => [localeStored];
}

class SaveLanguageFailure extends FeatureFailure {
  const SaveLanguageFailure(dynamic exception) : super(exception: exception);
}
