import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/presentation/state/success.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

abstract class PickAvatarState extends UIState {}

class GetAvatarInitialUIState extends PickAvatarState {}

class PickingAvatarUIState extends PickAvatarState {
  @override
  List<Object?> get props => [];
}

class GetAvatarOnMobileUIStateSuccess extends PickAvatarState {
  final AssetEntity? assetEntity;

  GetAvatarOnMobileUIStateSuccess({
    this.assetEntity,
  });

  @override
  List<Object?> get props => [assetEntity];
}

class GetAvatarOnWebUIStateSuccess extends PickAvatarState {
  final MatrixFile? matrixFile;

  GetAvatarOnWebUIStateSuccess({this.matrixFile});

  @override
  List<Object?> get props => [matrixFile];
}

class GetAvatarBigSizeUIStateFailure extends Failure {
  const GetAvatarBigSizeUIStateFailure();

  @override
  List<Object?> get props => [];
}

class DeleteAvatarUIStateSuccess extends PickAvatarState {
  DeleteAvatarUIStateSuccess();

  @override
  List<Object?> get props => [];
}
