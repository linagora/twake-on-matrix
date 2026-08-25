import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/presentation/model/file/default_asset_entity.dart';
import 'package:twake_chat/presentation/model/file/image_asset_entity.dart';
import 'package:twake_chat/presentation/model/file/video_asset_entity.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class FileAssetEntity with EquatableMixin {
  final AssetEntity assetEntity;

  FileAssetEntity({required this.assetEntity});

  Future<FileInfo?> toFileInfo();

  String get messageType;

  factory FileAssetEntity.createAssetEntity(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.video:
        return VideoAssetEntity(assetEntity: asset);
      case AssetType.image:
        return ImageAssetEntity(assetEntity: asset);
      case AssetType.audio:
      case AssetType.other:
        return DefaultAssetEntity(assetEntity: asset);
    }
  }

  Future<Uint8List?> get placeholderBytes =>
      throw UnimplementedError('unrecognized file type.');

  @override
  List<Object?> get props => [assetEntity];
}
