import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/localizations/localizations_repository.provider.dart';
import 'package:twake_chat/domain/localizations/usecases/save_language_usecase.dart';

part 'save_language_usecase.provider.g.dart';

@riverpod
SaveLanguageUseCase saveLanguageUseCase(Ref ref) =>
    SaveLanguageUseCase(ref.watch(localizationsRepositoryProvider));
