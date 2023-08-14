import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/presentation/model/file/default_asset_entity.dart';
import 'package:fluffychat/presentation/model/file/image_asset_entity.dart';
import 'package:fluffychat/presentation/model/file/video_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class FileAssetEntity with EquatableMixin {
  final AssetEntity assetEntity;

  FileAssetEntity({required this.assetEntity});

  Future<FileInfo?> toFileInfo();

  Future<MatrixFile?> toMatrixFile();

  String get messageType;

  factory FileAssetEntity.createAssetEntity(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.video:
        return VideoAssetEntity(
          assetEntity: asset,
        );
      case AssetType.image:
        return ImageAssetEntity(
          assetEntity: asset,
        );
      case AssetType.audio:
      case AssetType.other:
        return DefaultAssetEntity(
          assetEntity: asset,
        );
    }
  }

  Future<Uint8List?> get placeholderBytes =>
      throw UnimplementedError('unrecognized file type.');

  @override
  List<Object?> get props => [assetEntity];
}
