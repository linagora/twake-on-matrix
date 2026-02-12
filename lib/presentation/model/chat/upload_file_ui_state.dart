import 'package:equatable/equatable.dart';

abstract class UploadFileUIState with EquatableMixin {
  const UploadFileUIState();

  @override
  List<Object?> get props => [];
}

class UploadFileUISateInitial extends UploadFileUIState {
  const UploadFileUISateInitial();

  @override
  List<Object?> get props => [];
}

class UploadingFileUIState extends UploadFileUIState {
  final int? receive;
  final int? total;

  const UploadingFileUIState({this.receive, this.total});

  @override
  List<Object?> get props => [receive, total];
}

class UploadFileSuccessUIState extends UploadFileUIState {
  const UploadFileSuccessUIState();

  @override
  List<Object?> get props => [];
}

class UploadFileFailedUIState extends UploadFileUIState {
  const UploadFileFailedUIState();

  @override
  List<Object?> get props => [];
}
