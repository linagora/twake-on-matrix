import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_intent_source.provider.dart';
import 'package:twake_chat/domain/drive/usecases/create_drive_intent_usecase.dart';

part 'create_drive_intent_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
CreateDriveIntentUseCase createDriveIntentUseCase(Ref ref) =>
    CreateDriveIntentUseCase(ref.watch(driveIntentSourceProvider));
